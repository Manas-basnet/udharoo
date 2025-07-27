import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:udharoo/core/data/base_repository.dart';
import 'package:udharoo/core/network/api_result.dart';
import 'package:udharoo/core/utils/exception_handler.dart';
import 'package:udharoo/features/transactions/data/datasources/remote/transaction_remote_datasource.dart';
import 'package:udharoo/features/transactions/data/models/transaction_model.dart';
import 'package:udharoo/features/transactions/domain/entities/transaction.dart';
import 'package:udharoo/features/transactions/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl extends BaseRepository implements TransactionRepository {
  final TransactionRemoteDatasource _remoteDatasource;
  final FirebaseAuth _firebaseAuth;
  final DeviceInfoPlugin _deviceInfo;

  TransactionRepositoryImpl({
    required TransactionRemoteDatasource remoteDatasource,
    required super.networkInfo,
    FirebaseAuth? firebaseAuth,
    DeviceInfoPlugin? deviceInfo,
  })  : _remoteDatasource = remoteDatasource,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  String get _currentUserId {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }
    return user.uid;
  }

  @override
  Future<ApiResult<void>> createTransaction({
    required double amount,
    required String otherPartyUid,
    required String otherPartyName,
    required String description,
    required TransactionType type,
  }) async {
    return ExceptionHandler.handleExceptions(() async {
      final transactionId = _generateTransactionId();
      final deviceInfo = await _getCurrentDeviceInfo();
      
      final transactionModel = TransactionModel(
        transactionId: transactionId,
        type: type,
        amount: amount,
        otherParty: OtherPartyModel(
          uid: otherPartyUid,
          name: otherPartyName,
        ),
        description: description,
        status: TransactionStatus.pendingVerification,
        createdAt: DateTime.now(),
        createdBy: _currentUserId,
        createdFromDevice: deviceInfo,
        activities: [
          TransactionActivityModel(
            action: TransactionStatus.pendingVerification,
            timestamp: DateTime.now(),
            performedBy: _currentUserId,
            deviceInfo: deviceInfo,
          ),
        ],
      );

      await _remoteDatasource.createTransaction(transactionModel);
      return ApiResult.success(null);
    });
  }

  @override
  Stream<List<Transaction>> getTransactions() {
    return _remoteDatasource.getTransactions().map((transactionModels) {
      return transactionModels.map((model) => model as Transaction).toList();
    });
  }

  @override
  Future<ApiResult<void>> updateTransactionStatus({
    required String transactionId,
    required TransactionStatus status,
  }) async {
    return ExceptionHandler.handleExceptions(() async {
      final deviceInfo = await _getCurrentDeviceInfo();
      final activity = TransactionActivityModel(
        action: status,
        timestamp: DateTime.now(),
        performedBy: _currentUserId,
        deviceInfo: deviceInfo,
      );
      
      await _remoteDatasource.updateTransactionStatus(transactionId, status, activity);
      return ApiResult.success(null);
    });
  }

  @override
  Future<ApiResult<void>> verifyTransaction(String transactionId) async {
    return updateTransactionStatus(
      transactionId: transactionId,
      status: TransactionStatus.verified,
    );
  }

  @override
  Future<ApiResult<void>> completeTransaction(String transactionId) async {
    return updateTransactionStatus(
      transactionId: transactionId,
      status: TransactionStatus.completed,
    );
  }

  @override
  Future<ApiResult<void>> rejectTransaction(String transactionId) async {
    return updateTransactionStatus(
      transactionId: transactionId,
      status: TransactionStatus.rejected,
    );
  }

  @override
  Future<ApiResult<List<Transaction>>> getTransactionsByType(TransactionType type) async {
    return ExceptionHandler.handleExceptions(() async {
      final transactionModels = await _remoteDatasource.getTransactionsByType(type);
      final transactions = transactionModels.map((model) => model as Transaction).toList();
      return ApiResult.success(transactions);
    });
  }

  @override
  Future<ApiResult<List<Transaction>>> getTransactionsByStatus(TransactionStatus status) async {
    return ExceptionHandler.handleExceptions(() async {
      final transactionModels = await _remoteDatasource.getTransactionsByStatus(status);
      final transactions = transactionModels.map((model) => model as Transaction).toList();
      return ApiResult.success(transactions);
    });
  }

  @override
  Future<ApiResult<Transaction?>> getTransactionById(String transactionId) async {
    return ExceptionHandler.handleExceptions(() async {
      final transactionModel = await _remoteDatasource.getTransactionById(transactionId);
      return ApiResult.success(transactionModel);
    });
  }

  Future<DeviceInfoModel> _getCurrentDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return DeviceInfoModel(
          deviceId: androidInfo.id,
          deviceName: '${androidInfo.brand} ${androidInfo.model}',
          platform: 'Android',
          model: androidInfo.model,
        );
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return DeviceInfoModel(
          deviceId: iosInfo.identifierForVendor ?? 'unknown-ios-device',
          deviceName: iosInfo.name,
          platform: 'iOS',
          model: iosInfo.model,
        );
      } else {
        return const DeviceInfoModel(
          deviceId: 'unknown-device',
          deviceName: 'Unknown Device',
          platform: 'Unknown',
        );
      }
    } catch (e) {
      return const DeviceInfoModel(
        deviceId: 'unknown-device',
        deviceName: 'Unknown Device',
        platform: 'Unknown',
      );
    }
  }

  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000 + _currentUserId.hashCode).abs();
    return 'txn_${timestamp}_$random';
  }
}

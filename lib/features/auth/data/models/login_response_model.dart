import 'package:udharoo/core/data/base_response.dart';

class LoginResponseModel extends BaseResponseResult {
  final String? token;
  final String? refreshToken;
  
  LoginResponseModel({
    this.token,
    this.refreshToken,
    super.message,
    super.statusCode,
    super.errorCode,
    super.id,
    super.extra,
  });
  
  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final result = json['Result'] as Map<String, dynamic>?;
    final resultCommon = json['ResultCommon'] as Map<String, dynamic>?;
    
    return LoginResponseModel(
      token: resultCommon?['Token'] as String?,
      refreshToken: resultCommon?['RefreshToken'] as String?,
      message: result?['Message'] as String?,
      statusCode: result?['StatusCode'] as int?,
      errorCode: result?['ErrorCode'] as int?,
      id: result?['Id'] as String?,
      extra: result?['Extra'],
    );
  }
}
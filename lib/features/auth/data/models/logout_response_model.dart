import 'package:udharoo/core/data/base_response.dart';

class LogoutResponseModel extends BaseResponseResult {
  LogoutResponseModel({
    super.message,
    super.statusCode,
    super.errorCode,
    super.id,
    super.extra,
  });
  
  factory LogoutResponseModel.fromJson(Map<String, dynamic> json) {
    return LogoutResponseModel(
      message: json['message'] as String?,
      statusCode: json['statusCode'] as int?,
      errorCode: json['errorCode'] as int?,
      id: json['id'] as String?,
      extra: json['extra'],
    );
  }
}
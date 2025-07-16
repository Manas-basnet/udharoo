abstract class BaseResponseResult {
  String? message;
  int? statusCode;
  int? errorCode;
  String? id;
  dynamic extra;

  BaseResponseResult({this.message, this.statusCode, this.errorCode, this.id, this.extra});
}


//YO test model ho on how to make models that extend BaseResponseResult
class TestModel extends BaseResponseResult {
  String? testField;

  TestModel({this.testField, super.message, super.statusCode, super.errorCode, super.id, super.extra});

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      testField: json['testField'] as String?,
      message: json['message'] as String?,
      statusCode: json['statusCode'] as int?,
      errorCode: json['errorCode'] as int?,
      id: json['id'] as String?,
      extra: json['extra'],
    );
  }
}
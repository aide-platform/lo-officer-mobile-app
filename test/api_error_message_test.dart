import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liaison_officer/core/network/api_error_message.dart';
import 'package:liaison_officer/core/network/api_exception.dart';

void main() {
  test('HTML error page from the gateway is never shown raw', () {
    const html = '<!DOCTYPE html>\n<html lang="en">\n<head><title>Error</title></head>';
    final error = DioException(
      requestOptions: RequestOptions(path: '/app/my-lo/me'),
      response: Response(
        requestOptions: RequestOptions(path: '/app/my-lo/me'),
        statusCode: 502,
        data: html,
      ),
      type: DioExceptionType.badResponse,
      error: ApiException(html, statusCode: 502),
    );
    final message = apiErrorMessage(error);
    expect(message, isNot(contains('<')));
    expect(message, contains('temporarily unavailable'));
  });

  test('JSON server messages still come through', () {
    final error = ApiException('Aadhaar number is invalid', statusCode: 400);
    expect(apiErrorMessage(error), 'Aadhaar number is invalid');
  });
}

import 'package:dio/dio.dart';
import 'package:liaison_officer/core/config/api_config.dart';
import 'package:liaison_officer/core/network/api_exception.dart';
import 'package:liaison_officer/core/network/dio_provider.dart';
import 'package:liaison_officer/features/faq/domain/faq_category.dart';

/// Guest FAQ list on event-services. No LO session token.
class FaqRepository {
  FaqRepository({Dio? dio})
    : _dio = dio ??
          createDio(
            baseUrl: ApiConfig.eventServiceUrl,
            attachSession: false,
          );

  final Dio _dio;

  Future<List<FaqCategory>> fetch() async {
    final response = await _dio.get<dynamic>(
      ApiConfig.faqGuestPath,
      queryParameters: {'eventId': ApiConfig.eventId},
    );
    final body = response.data;
    if (body is Map && body['status'] != null) {
      final status = body['status'].toString().toUpperCase();
      if (status != 'OK' && status != 'SUCCESS') {
        throw ApiException(
          body['message']?.toString() ?? 'Could not load FAQs.',
          statusCode: response.statusCode,
        );
      }
    }
    return FaqCategory.parse(body);
  }
}

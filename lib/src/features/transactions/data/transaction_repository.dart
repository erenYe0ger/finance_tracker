import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/network/api_client.dart';
import '../domain/transaction_record.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(ref.watch(dioProvider)),
);

class TransactionRepository {
  const TransactionRepository(this._dio);

  final Dio _dio;

  Future<List<TransactionRecord>> list({
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    String? category,
  }) async {
    final query = <String, dynamic>{};
    if (startDate != null) {
      query['start_date'] = transactionDateParameter(startDate);
    }
    if (endDate != null) query['end_date'] = transactionDateParameter(endDate);
    if (type != null) query['type'] = type.name;
    if (category != null) query['category'] = category;

    final response = await _dio.get(
      AppConstants.transactionsEndpoint,
      queryParameters: query,
    );
    _requireSuccess(response, expectedStatus: 200);
    final body = response.data;
    if (body is! List) {
      throw const FormatException('Invalid transactions response');
    }
    return body
        .map((item) => TransactionRecord.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<TransactionRecord> create(TransactionDraft draft) async {
    final response = await _dio.post(
      AppConstants.transactionsEndpoint,
      data: draft.toJson(),
    );
    _requireSuccess(response, expectedStatus: 201);
    return TransactionRecord.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TransactionRecord> update(int id, TransactionDraft draft) async {
    final response = await _dio.patch(
      '${AppConstants.transactionsEndpoint}/$id',
      data: draft.toJson(),
    );
    _requireSuccess(response, expectedStatus: 200);
    return TransactionRecord.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    final response = await _dio.delete('${AppConstants.transactionsEndpoint}/$id');
    _requireSuccess(response, expectedStatus: 204);
  }

  void _requireSuccess(Response<dynamic> response, {required int expectedStatus}) {
    if (response.statusCode == expectedStatus) return;
    final responseData = response.data;
    final detail = responseData is Map<String, dynamic>
        ? responseData['detail']?.toString() ?? 'Request failed'
        : 'Request failed';
    throw ServerException.fromStatus(response.statusCode ?? 0, detail);
  }
}

import 'package:liaison_officer/features/liaison_officer/domain/catering_repository.dart';

class MockCateringRepository implements CateringRepository {
  final List<Map<String, dynamic>> _reqs = [
    {
      'id': 'cr-1',
      'diningAreaName': 'VIP Lounge A',
      'diningArea': 'VIP Lounge A',
      'reqDate': '2027-02-09',
      'date': '2027-02-09',
      'mealTypeName': 'Lunch',
      'mealType': 'Lunch',
      'qtyRequested': 40,
      'persons': 40,
      'statusCode': 'APPROVED',
      'statusName': 'Approved',
      'status': 'APPROVED',
      'couponQuota': 40,
      'couponsDistributed': 20,
      'undistributed': 20,
    },
    {
      'id': 'cr-2',
      'diningAreaName': 'Media Hall',
      'diningArea': 'Media Hall',
      'reqDate': '2027-02-10',
      'date': '2027-02-10',
      'mealTypeName': 'Dinner',
      'mealType': 'Dinner',
      'qtyRequested': 25,
      'persons': 25,
      'statusCode': 'PENDING',
      'statusName': 'Pending',
      'status': 'PENDING',
      'couponQuota': 0,
      'couponsDistributed': 0,
      'undistributed': 25,
    },
  ];

  final List<Map<String, dynamic>> _coupons = [
    {
      'id': 'ec-1',
      'couponCode': 'LO-COUPON-001',
      'diningAreaName': 'VIP Lounge A',
      'diningArea': 'VIP Lounge A',
      'mealTypeName': 'Lunch',
      'mealType': 'Lunch',
      'couponDate': '2027-02-09',
      'date': '2027-02-09',
      'statusName': 'Distributed',
      'isDistributed': true,
    },
  ];

  final List<Map<String, dynamic>> _recipients = [
    {
      'personId': 'person-sub-1',
      'fullName': 'Demo Sub Nodal',
      'email': 'subnodal@test.com',
    },
  ];

  @override
  Future<List<Map<String, dynamic>>> listMine() async =>
      List<Map<String, dynamic>>.from(
        _reqs.map((e) => Map<String, dynamic>.from(e)),
      );

  @override
  Future<List<Map<String, dynamic>>> listAll() => listMine();

  @override
  Future<List<Map<String, dynamic>>> listPending() async =>
      listMine().then(
        (all) => all
            .where(
              (e) =>
                  (e['status'] ?? e['statusCode'] ?? '')
                      .toString()
                      .toUpperCase()
                      .contains('PEND'),
            )
            .toList(),
      );

  @override
  Future<Map<String, dynamic>> getById(String id) async {
    return Map<String, dynamic>.from(
      _reqs.firstWhere(
        (e) => e['id'] == id,
        orElse: () => {'id': id},
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> createRequirement(
    Map<String, dynamic> body,
  ) async {
    final persons = body['persons'] ??
        body['numberOfPersons'] ??
        body['qtyRequested'] ??
        0;
    final item = {
      'id': 'cr-${_reqs.length + 1}',
      'diningAreaName': body['diningArea'] ?? body['diningAreaName'],
      'diningArea': body['diningArea'] ?? body['diningAreaName'],
      'reqDate': body['date'] ?? body['reqDate'],
      'date': body['date'] ?? body['reqDate'],
      'mealTypeName': body['mealType'] ?? body['mealTypeName'],
      'mealType': body['mealType'] ?? body['mealTypeName'],
      'qtyRequested': persons,
      'persons': persons,
      'statusCode': 'PENDING',
      'statusName': 'Pending',
      'status': 'PENDING',
      'undistributed': persons,
      ...body,
    };
    _reqs.add(item);
    return Map<String, dynamic>.from(item);
  }

  @override
  Future<void> deleteRequirement(String id) async {
    _reqs.removeWhere((e) => e['id'] == id);
  }

  @override
  Future<Map<String, dynamic>> approve(
    String id, {
    int? qtyApproved,
    String? remarks,
  }) async {
    final idx = _reqs.indexWhere((e) => e['id'] == id);
    if (idx < 0) return {'id': id};
    final qty = qtyApproved ?? (_reqs[idx]['qtyRequested'] as num?)?.toInt();
    _reqs[idx] = {
      ..._reqs[idx],
      'status': 'APPROVED',
      'statusCode': 'APPROVED',
      'statusName': 'Approved',
      'qtyApproved': qty,
      'couponQuota': qty,
      'decisionRemarks': remarks,
    };
    return Map<String, dynamic>.from(_reqs[idx]);
  }

  @override
  Future<Map<String, dynamic>> reject(
    String id, {
    required String remarks,
  }) async {
    final idx = _reqs.indexWhere((e) => e['id'] == id);
    if (idx < 0) return {'id': id, 'decisionRemarks': remarks};
    _reqs[idx] = {
      ..._reqs[idx],
      'status': 'REJECTED',
      'statusCode': 'REJECTED',
      'statusName': 'Rejected',
      'decisionRemarks': remarks,
    };
    return Map<String, dynamic>.from(_reqs[idx]);
  }

  @override
  Future<List<Map<String, dynamic>>> listCommitteeRecipients() async =>
      List<Map<String, dynamic>>.from(
        _recipients.map((e) => Map<String, dynamic>.from(e)),
      );

  @override
  Future<List<Map<String, dynamic>>> listCommitteeCoupons() async =>
      List<Map<String, dynamic>>.from(
        _coupons.map((e) => Map<String, dynamic>.from(e)),
      );

  @override
  Future<List<Map<String, dynamic>>> listMyCoupons() => listCommitteeCoupons();

  @override
  Future<void> distribute({
    required String cateringReqId,
    required String subNodalId,
    int? quantity,
  }) async {
    for (final r in _reqs) {
      if (r['id'] != cateringReqId) continue;
      final left = (r['undistributed'] as num?)?.toInt() ?? 0;
      final take = quantity ?? 1;
      r['undistributed'] = (left - take).clamp(0, left);
      r['couponsDistributed'] =
          ((r['couponsDistributed'] as num?)?.toInt() ?? 0) + take;
    }
    _coupons.add({
      'id': 'ec-${_coupons.length + 1}',
      'couponCode': 'LO-COUPON-${(_coupons.length + 1).toString().padLeft(3, '0')}',
      'cateringReqId': cateringReqId,
      'holderPersonId': subNodalId,
      'isDistributed': true,
      'diningArea': 'VIP Lounge A',
      'mealType': 'Lunch',
      'date': DateTime.now().toIso8601String().split('T').first,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> distributeFromPool(
    Map<String, dynamic> body,
  ) async {
    final count = (body['count'] as num?)?.toInt() ?? 1;
    final created = <Map<String, dynamic>>[];
    for (var i = 0; i < count; i++) {
      final item = {
        'id': 'ec-${_coupons.length + 1}',
        'couponCode':
            'LO-COUPON-${(_coupons.length + 1).toString().padLeft(3, '0')}',
        'holderPersonId': body['holderPersonId'],
        'isDistributed': true,
        ...body,
      };
      _coupons.add(item);
      created.add(Map<String, dynamic>.from(item));
    }
    return created;
  }

  @override
  Future<List<int>> downloadCouponPdf(String couponId) async =>
      'Mock coupon PDF $couponId'.codeUnits;

  @override
  Future<List<int>> downloadAllCommitteeCouponsPdf() async =>
      'Mock all coupons PDF'.codeUnits;

  @override
  Future<List<int>> downloadMyCouponsPdf() async =>
      'Mock my coupons PDF'.codeUnits;
}

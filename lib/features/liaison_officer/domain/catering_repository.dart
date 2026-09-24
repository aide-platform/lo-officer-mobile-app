/// Catering requirements + e-coupons (CAP catering / ecoupon modules).
///
/// Payloads are plain maps matching OpenAPI DTOs (`CateringReqDto`, `ECouponDto`).
abstract class CateringRepository {
  // ── Catering requirements ────────────────────────────────────

  /// Requests submitted by the caller (`GET /app/catering-reqs/mine`).
  Future<List<Map<String, dynamic>>> listMine();

  /// All catering requests (`GET /app/catering-reqs`).
  Future<List<Map<String, dynamic>>> listAll();

  /// Pending JS approval queue (`GET /app/catering-reqs/pending`).
  Future<List<Map<String, dynamic>>> listPending();

  Future<Map<String, dynamic>> getById(String id);

  /// Submit a new catering requirement (`POST /app/catering-reqs`).
  Future<Map<String, dynamic>> createRequirement(Map<String, dynamic> body);

  /// Cancel a request (`DELETE /app/catering-reqs/{id}`).
  Future<void> deleteRequirement(String id);

  /// JS approve (`POST …/approve?qtyApproved=&remarks=`).
  Future<Map<String, dynamic>> approve(
    String id, {
    int? qtyApproved,
    String? remarks,
  });

  /// JS reject (`POST …/reject?remarks=` — remarks required).
  Future<Map<String, dynamic>> reject(
    String id, {
    required String remarks,
  });

  /// Potential e-coupon recipients in the caller's committee.
  Future<List<Map<String, dynamic>>> listCommitteeRecipients();

  // ── E-Coupons ────────────────────────────────────────────────

  /// Coupons under the caller's committee (`GET …/for-my-committee`).
  Future<List<Map<String, dynamic>>> listCommitteeCoupons();

  /// Coupons assigned to the caller (`GET /app/ecoupons/mine`).
  Future<List<Map<String, dynamic>>> listMyCoupons();

  /// Legacy per-request distribute (`POST …/distribute/{cateringReqId}`).
  Future<void> distribute({
    required String cateringReqId,
    required String subNodalId,
    int? quantity,
  });

  /// Bucket-based distribute (`POST /app/ecoupons/distribute`).
  Future<List<Map<String, dynamic>>> distributeFromPool(
    Map<String, dynamic> body,
  );

  Future<List<int>> downloadCouponPdf(String couponId);

  Future<List<int>> downloadAllCommitteeCouponsPdf();

  Future<List<int>> downloadMyCouponsPdf();
}

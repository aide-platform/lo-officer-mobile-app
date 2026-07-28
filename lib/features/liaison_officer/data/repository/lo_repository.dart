import '../models/vip.dart';

abstract class LoRepository {
  Future<List<VIP>> fetchVips({String? email});
}

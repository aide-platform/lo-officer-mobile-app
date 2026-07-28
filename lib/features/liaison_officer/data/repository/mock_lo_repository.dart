import 'package:liaison_officer/features/liaison_officer/data/datasources/dummyData.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/vip.dart';
import 'package:liaison_officer/features/liaison_officer/data/repository/lo_repository.dart';

class MockLoRepository implements LoRepository {
  @override
  Future<List<VIP>> fetchVips({String? email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return DummyData.vipList();
  }
}

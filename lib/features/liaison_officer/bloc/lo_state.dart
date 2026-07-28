part of 'lo_bloc.dart';

enum LoStatus { initial, loading, loaded, error }

class LoBlocState {
  final LoStatus status;
  final String email;
  final List<VIP> vipList;
  final bool onDuty;
  final String searchQuery;
  final String filterCategory; // 'All' | 'Foreign' | 'Domestic'
  final String? errorMessage;

  const LoBlocState({
    this.status = LoStatus.initial,
    this.email = '',
    this.vipList = const [],
    this.onDuty = true,
    this.searchQuery = '',
    this.filterCategory = 'All',
    this.errorMessage,
  });

  LoBlocState copyWith({
    LoStatus? status,
    String? email,
    List<VIP>? vipList,
    bool? onDuty,
    String? searchQuery,
    String? filterCategory,
    String? errorMessage,
  }) =>
      LoBlocState(
        status: status ?? this.status,
        email: email ?? this.email,
        vipList: vipList ?? this.vipList,
        onDuty: onDuty ?? this.onDuty,
        searchQuery: searchQuery ?? this.searchQuery,
        filterCategory: filterCategory ?? this.filterCategory,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  List<VIP> get filteredVips {
    final q = searchQuery.toLowerCase();
    return vipList.where((v) {
      final matchSearch = q.isEmpty ||
          v.name.toLowerCase().contains(q) ||
          v.designation.toLowerCase().contains(q) ||
          v.contact.contains(q);
      final matchFilter = filterCategory == 'All' ||
          (filterCategory == 'Foreign') == v.isForeign;
      return matchSearch && matchFilter;
    }).toList();
  }

  int get foreignCount => vipList.where((v) => v.isForeign).length;
  int get domesticCount => vipList.where((v) => !v.isForeign).length;
}

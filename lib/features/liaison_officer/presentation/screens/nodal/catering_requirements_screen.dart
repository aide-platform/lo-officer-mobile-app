import 'package:flutter/material.dart';
import 'package:liaison_officer/core/di/app_dependencies.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/features/liaison_officer/domain/catering_repository.dart';
import 'package:liaison_officer/theme/app_theme.dart';

/// Nodal catering requirements list + submit / distribute (video KPI strip).
class CateringRequirementsScreen extends StatefulWidget {
  const CateringRequirementsScreen({super.key});

  @override
  State<CateringRequirementsScreen> createState() =>
      _CateringRequirementsScreenState();
}

class _CateringRequirementsScreenState
    extends State<CateringRequirementsScreen> {
  static const _meals = ['Breakfast', 'Lunch', 'Dinner', 'High Tea'];

  late final CateringRepository _repo;
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = AppDependencies.instance.cateringRepository;
    _load();
  }

  String _statusOf(Map<String, dynamic> r) =>
      (r['statusName'] ?? r['status'] ?? r['statusCode'] ?? '')
          .toString()
          .toUpperCase();

  int get _submitted => _items.length;

  int get _pending => _items.where((r) {
        final s = _statusOf(r);
        return s.contains('PEND') || s.contains('SUBMIT');
      }).length;

  int get _approved => _items.where((r) {
        final s = _statusOf(r);
        return s.contains('APPROV') && !s.contains('DISTRIB');
      }).length;

  int get _quota {
    var sum = 0;
    for (final r in _items) {
      final s = _statusOf(r);
      if (!s.contains('APPROV') && !s.contains('DISTRIB')) continue;
      final q = r['qtyApproved'] ?? r['quota'] ?? r['qtyRequested'] ?? r['persons'];
      if (q is num) {
        sum += q.toInt();
      } else {
        sum += int.tryParse(q?.toString() ?? '') ?? 0;
      }
    }
    return sum;
  }

  int get _distributed => _items.where((r) {
        final s = _statusOf(r);
        return s.contains('DISTRIB');
      }).length;

  List<String> get _knownDiningAreas {
    final names = <String>{};
    for (final r in _items) {
      final n = (r['diningAreaName'] ?? r['diningArea'])?.toString().trim();
      if (n != null && n.isNotEmpty) names.add(n);
    }
    return names.toList()..sort();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repo.listMine();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _newRequirement() async {
    final diningCtrl = TextEditingController();
    final persons = TextEditingController(text: '10');
    final remarks = TextEditingController();
    final known = _knownDiningAreas;
    String? diningPick = known.isEmpty ? null : known.first;
    String meal = 'Lunch';
    DateTime date = DateTime.now();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('New Catering Requirement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (known.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: diningPick,
                    decoration: const InputDecoration(
                      labelText: 'Dining area *',
                      helperText: 'Coupon-required active dining areas only',
                    ),
                    items: [
                      ...known.map(
                        (d) => DropdownMenuItem(value: d, child: Text(d)),
                      ),
                      const DropdownMenuItem(
                        value: '__other__',
                        child: Text('Other (type below)'),
                      ),
                    ],
                    onChanged: (v) => setLocal(() => diningPick = v),
                  ),
                if (known.isEmpty || diningPick == '__other__')
                  TextField(
                    controller: diningCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Dining area *',
                      hintText: 'Coupon-required active dining areas only',
                    ),
                  ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date *'),
                  subtitle: Text(_fmtDate(date)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime(2026, 1, 1),
                      lastDate: DateTime(2027, 12, 31),
                    );
                    if (picked != null) setLocal(() => date = picked);
                  },
                ),
                DropdownButtonFormField<String>(
                  initialValue: meal,
                  decoration: const InputDecoration(labelText: 'Meal type *'),
                  items: _meals
                      .map(
                        (m) => DropdownMenuItem(value: m, child: Text(m)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setLocal(() => meal = v);
                  },
                ),
                TextField(
                  controller: persons,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Persons *'),
                ),
                TextField(
                  controller: remarks,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Remarks'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Submissions cannot be modified after save.',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit for approval'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;

    final diningName = (diningPick != null && diningPick != '__other__')
        ? diningPick!
        : diningCtrl.text.trim();
    if (diningName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Dining area is required.'),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm submission'),
        content: const Text(
          'Once submitted, this catering requirement cannot be modified. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final qty = int.tryParse(persons.text.trim()) ?? 0;
      final dateStr = _fmtDate(date);
      await _repo.createRequirement({
        'diningArea': diningName,
        'diningAreaName': diningName,
        'date': dateStr,
        'reqDate': dateStr,
        'mealType': meal,
        'mealTypeName': meal,
        'persons': qty,
        'qtyRequested': qty,
        'numberOfPersons': qty,
        if (remarks.text.trim().isNotEmpty) 'remarks': remarks.text.trim(),
      });
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Catering requirement submitted.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text('$e')),
      );
    }
  }

  int _maxDistributeQty(Map<String, dynamic> row) {
    final approved = row['qtyApproved'] ??
        row['quota'] ??
        row['qtyRequested'] ??
        row['persons'] ??
        1;
    final approvedN =
        approved is num ? approved.toInt() : int.tryParse('$approved') ?? 1;
    final distributed = row['qtyDistributed'] ?? row['distributed'] ?? 0;
    final distributedN = distributed is num
        ? distributed.toInt()
        : int.tryParse('$distributed') ?? 0;
    final rem = approvedN - distributedN;
    return rem < 1 ? 1 : rem;
  }

  String _recipientId(Map<String, dynamic> r) =>
      (r['personId'] ?? r['id'] ?? r['holderPersonId'] ?? r['subNodalId'] ?? '')
          .toString();

  String _recipientLabel(Map<String, dynamic> r) {
    final name = (r['fullName'] ??
            r['name'] ??
            r['displayName'] ??
            r['email'] ??
            'Recipient')
        .toString();
    final id = _recipientId(r);
    return id.isEmpty ? name : '$name ($id)';
  }

  Future<void> _distribute(Map<String, dynamic> row) async {
    final id = row['id']?.toString();
    if (id == null) return;

    List<Map<String, dynamic>> recipients = const [];
    try {
      recipients = await _repo.listCommitteeRecipients();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Could not load recipients: $e'),
        ),
      );
      return;
    }
    if (!mounted) return;
    if (recipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('No committee recipients available.'),
        ),
      );
      return;
    }

    final maxQty = _maxDistributeQty(row);
    final qty = TextEditingController(text: '1');
    String? selectedId = _recipientId(recipients.first);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Distribute coupons'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedId,
                decoration: const InputDecoration(labelText: 'Recipient'),
                items: recipients
                    .map(
                      (r) => DropdownMenuItem(
                        value: _recipientId(r),
                        child: Text(
                          _recipientLabel(r),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setLocal(() => selectedId = v),
              ),
              TextField(
                controller: qty,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  helperText: 'Max $maxQty',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Distribute'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || selectedId == null || selectedId!.isEmpty) return;
    var n = int.tryParse(qty.text.trim()) ?? 1;
    if (n > maxQty) n = maxQty;
    if (n < 1) n = 1;
    try {
      await _repo.distribute(
        cateringReqId: id,
        subNodalId: selectedId!,
        quantity: n,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Coupons distributed.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text('$e')),
      );
    }
  }

  Widget _kpiStrip() {
    final cards = <(String, int, Color)>[
      ('SUBMITTED', _submitted, const Color(0xFF7C3AED)),
      ('PENDING', _pending, const Color(0xFFEA580C)),
      ('APPROVED', _approved, AppTheme.indiaGreen),
      ('QUOTA', _quota, AppTheme.royalBlue),
      ('DISTRIBUTED', _distributed, const Color(0xFF0284C7)),
    ];
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = cards[i];
          return Container(
            width: 108,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.$3.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.$3.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.$1,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: c.$3,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                Text(
                  '${c.$2}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: c.$3,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Catering Requirements',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newRequirement,
        icon: const Icon(Icons.add),
        label: const Text('New requirement'),
      ),
      body: _loading
          ? const AppLoading(label: 'Loading catering…')
          : _error != null
              ? AppErrorView(message: _error!, onRetry: _load)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    _kpiStrip(),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _items.isEmpty
                          ? AppEmptyState(
                              message:
                                  'No catering requirements submitted yet. Tap New requirement to start.',
                              action: FilledButton.icon(
                                onPressed: _newRequirement,
                                icon: const Icon(Icons.add),
                                label: const Text('New requirement'),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(0, 8, 0, 88),
                                itemCount: _items.length,
                                itemBuilder: (context, i) {
                                  final r = _items[i];
                                  final status = _statusOf(r);
                                  final dining = r['diningAreaName'] ??
                                      r['diningArea'] ??
                                      'Dining';
                                  final meal =
                                      r['mealTypeName'] ?? r['mealType'] ?? '';
                                  final date = r['reqDate'] ?? r['date'] ?? '—';
                                  final persons = r['qtyRequested'] ??
                                      r['persons'] ??
                                      r['numberOfPersons'] ??
                                      '—';
                                  return AppCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '$dining · $meal',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            StatusChip(
                                              label: status.isEmpty
                                                  ? '—'
                                                  : status,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text('Date $date · Persons $persons'),
                                        if (status.contains('APPROV'))
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton.icon(
                                              onPressed: () => _distribute(r),
                                              icon: const Icon(
                                                Icons.send_outlined,
                                              ),
                                              label: const Text('Distribute'),
                                            ),
                                          ),
                                        if (status.contains('REJECT'))
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton.icon(
                                              onPressed: _newRequirement,
                                              icon: const Icon(Icons.refresh),
                                              label: const Text('Resubmit'),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

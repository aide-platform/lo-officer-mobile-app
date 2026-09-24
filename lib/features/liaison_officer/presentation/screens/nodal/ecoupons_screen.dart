import 'dart:io';

import 'package:flutter/material.dart';
import 'package:liaison_officer/core/di/app_dependencies.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/core/widgets/mobile_ux_kit.dart';
import 'package:liaison_officer/features/liaison_officer/domain/catering_repository.dart';
import 'package:liaison_officer/theme/app_theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// Committee e-coupons list with QR, PDF, and committee quota KPIs (video parity).
class EcouponsScreen extends StatefulWidget {
  const EcouponsScreen({super.key});

  @override
  State<EcouponsScreen> createState() => _EcouponsScreenState();
}

class _EcouponsScreenState extends State<EcouponsScreen> {
  late final CateringRepository _repo;
  List<Map<String, dynamic>> _items = const [];
  List<Map<String, dynamic>> _reqs = const [];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _repo = AppDependencies.instance.cateringRepository;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repo.listCommitteeCoupons();
      List<Map<String, dynamic>> reqs = const [];
      try {
        reqs = await _repo.listMine();
      } catch (_) {
        // Quota section soft-fails if catering list unavailable.
      }
      if (!mounted) return;
      setState(() {
        _items = items;
        _reqs = reqs;
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

  int get _distributed => _items.length;

  int get _approvedQuota {
    var sum = 0;
    for (final r in _reqs) {
      final s = (r['statusName'] ?? r['status'] ?? r['statusCode'] ?? '')
          .toString()
          .toUpperCase();
      if (!s.contains('APPROV') && !s.contains('DISTRIB')) continue;
      final q = r['qtyApproved'] ?? r['quota'] ?? r['qtyRequested'] ?? r['persons'];
      if (q is num) {
        sum += q.toInt();
      } else {
        sum += int.tryParse(q?.toString() ?? '') ?? 0;
      }
    }
    if (sum == 0 && _items.isNotEmpty) {
      // Fallback: treat assigned coupons as the approved pool when reqs empty.
      return _items.length;
    }
    return sum;
  }

  int get _available {
    final a = _approvedQuota - _distributed;
    return a < 0 ? 0 : a;
  }

  List<Map<String, dynamic>> get _quotaRows {
    final map = <String, Map<String, dynamic>>{};
    for (final r in _reqs) {
      final dining =
          (r['diningAreaName'] ?? r['diningArea'] ?? 'Dining').toString();
      final meal = (r['mealTypeName'] ?? r['mealType'] ?? '').toString();
      final date = (r['reqDate'] ?? r['date'] ?? '').toString();
      final key = '$dining|$date|$meal';
      final approved = r['qtyApproved'] ?? r['qtyRequested'] ?? r['persons'] ?? 0;
      final approvedN =
          approved is num ? approved.toInt() : int.tryParse('$approved') ?? 0;
      final row = map.putIfAbsent(
        key,
        () => {
          'dining': dining,
          'date': date,
          'meal': meal,
          'approved': 0,
          'distributed': 0,
        },
      );
      row['approved'] = (row['approved'] as int) + approvedN;
    }
    for (final c in _items) {
      final dining =
          (c['diningAreaName'] ?? c['diningArea'] ?? 'Dining').toString();
      final meal = (c['mealTypeName'] ?? c['mealType'] ?? '').toString();
      final date = (c['couponDate'] ?? c['date'] ?? '').toString();
      final key = '$dining|$date|$meal';
      final row = map.putIfAbsent(
        key,
        () => {
          'dining': dining,
          'date': date,
          'meal': meal,
          'approved': 0,
          'distributed': 0,
        },
      );
      row['distributed'] = (row['distributed'] as int) + 1;
      if ((row['approved'] as int) < (row['distributed'] as int)) {
        row['approved'] = row['distributed'];
      }
    }
    return map.values.toList();
  }

  List<Map<String, dynamic>> get _filteredItems {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((c) {
      final hay = [
        c['couponCode'],
        c['id'],
        c['diningAreaName'],
        c['diningArea'],
        c['mealTypeName'],
        c['mealType'],
        c['holderName'],
        c['loName'],
        c['assignedTo'],
      ].whereType<Object>().join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  Future<void> _shareBytes(List<int> bytes, String name) async {
    if (bytes.isEmpty) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: name);
  }

  void _showQr(Map<String, dynamic> c) {
    final code = c['qrCodeData']?.toString() ??
        c['couponCode']?.toString() ??
        c['qrPayload']?.toString() ??
        c['id']?.toString() ??
        '';
    final label = c['couponCode']?.toString() ?? code;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.isEmpty ? 'Coupon' : label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 16),
            if (code.isNotEmpty)
              QrImageView(
                data: code,
                size: 200,
                backgroundColor: Colors.white,
              )
            else
              const Text('No QR payload available for this coupon.'),
            const SizedBox(height: 8),
            Text(
              [
                c['diningAreaName'] ?? c['diningArea'],
                c['mealTypeName'] ?? c['mealType'],
                c['couponDate'] ?? c['date'],
              ].where((e) => e != null && e.toString().isNotEmpty).join(' · '),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;
    final quotas = _quotaRows;
    return AppPageScaffold(
      title: 'E-Coupons',
      actions: [
        IconButton(
          tooltip: 'Download all (PDF)',
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            try {
              final bytes = await _repo.downloadAllCommitteeCouponsPdf();
              await _shareBytes(bytes, 'ecoupons-all.pdf');
              messenger.showSnackBar(
                const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text('E-coupons PDF ready to share.'),
                ),
              );
            } catch (e) {
              messenger.showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text('$e'),
                ),
              );
            }
          },
          icon: const Icon(Icons.download, color: Colors.white),
        ),
      ],
      body: _loading
          ? const AppLoading(label: 'Loading e-coupons…')
          : _error != null
              ? AppErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    children: [
                      Text(
                        'View and download coupon PDFs. Distribute only from '
                        'Catering → Distribute on approved requirements.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _kpiCard(
                            'APPROVED',
                            _approvedQuota,
                            const Color(0xFF7C3AED),
                          ),
                          const SizedBox(width: 8),
                          _kpiCard(
                            'DISTRIBUTED',
                            _distributed,
                            const Color(0xFF0284C7),
                          ),
                          const SizedBox(width: 8),
                          _kpiCard(
                            'AVAILABLE',
                            _available,
                            AppTheme.indiaGreen,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "My Committee's Quota",
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      if (quotas.isEmpty)
                        const Text('No quota buckets yet.')
                      else
                        ...quotas.map(
                          (q) {
                            final approved = q['approved'] as int;
                            final distributed = q['distributed'] as int;
                            final available =
                                (approved - distributed).clamp(0, 1 << 30);
                            return AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${q['dining']} · ${q['meal']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text('Date ${q['date']}'),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      StatusChip(label: 'Approved $approved'),
                                      StatusChip(
                                        label: 'Distributed $distributed',
                                      ),
                                      StatusChip(
                                        label: 'Available $available',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        'Assigned Coupons',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search coupons',
                          isDense: true,
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                      const SizedBox(height: 8),
                      if (filtered.isEmpty)
                        const AppEmptyState(message: 'No e-coupons yet.')
                      else
                        ...filtered.map((c) {
                          final id = c['id']?.toString();
                          final dining =
                              c['diningAreaName'] ?? c['diningArea'] ?? '';
                          final meal =
                              c['mealTypeName'] ?? c['mealType'] ?? '';
                          final date = c['couponDate'] ?? c['date'] ?? '';
                          final holder = c['holderName'] ??
                              c['loName'] ??
                              c['assignedTo'] ??
                              '';
                          final distributedAt = c['distributedAt'] ??
                              c['assignedAt'] ??
                              c['createdAt'];
                          return AppCard(
                            onTap: () => _showQr(c),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        c['couponCode']?.toString() ??
                                            c['id']?.toString() ??
                                            'Coupon',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    AppStatusChip(
                                      label: c['status']?.toString() ??
                                          c['statusName']?.toString() ??
                                          'Assigned',
                                    ),
                                  ],
                                ),
                                Text(
                                  [
                                    dining,
                                    meal,
                                    date,
                                    if (holder.toString().isNotEmpty) holder,
                                  ].join(' · '),
                                ),
                                if (distributedAt != null)
                                  Text(
                                    'Distributed $distributedAt',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    tooltip: 'Download PDF',
                                    onPressed: id == null
                                        ? null
                                        : () async {
                                            final bytes = await _repo
                                                .downloadCouponPdf(id);
                                            await _shareBytes(
                                              bytes,
                                              'ecoupon-$id.pdf',
                                            );
                                          },
                                    icon: const Icon(Icons.download_outlined),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}

// ignore_for_file: depend_on_referenced_packages
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../../core/design/app_colors.dart';
import '../../../../../core/design/contrast.dart';
import '../../../../../core/design/app_asset_manager.dart';
import '../../../../../core/design/aero_brand_widgets.dart';
import '../../data/models/vip.dart';

// ═══════════════════════════════════════════════════════════════
// VIP WALLET PASS  –  Entry point
//
// Usage (drop into VIPCard's action area or a new screen):
//   VipWalletPassScreen(vips: vipList)
//   VipWalletPassCard(vip: singleVip)   ← embeddable card
// ═══════════════════════════════════════════════════════════════

class VipWalletPassScreen extends StatefulWidget {
  final List<VIP> vips;
  const VipWalletPassScreen({super.key, required this.vips});

  @override
  State<VipWalletPassScreen> createState() => _VipWalletPassScreenState();
}

class _VipWalletPassScreenState extends State<VipWalletPassScreen>
    with TickerProviderStateMixin {
  int _activeIndex = 0;
  late PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(
      viewportFraction: 0.82,
      initialPage: 0,
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AeroColors.cockpit,
      body: Column(children: [
        // ── Header ────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: AeroColors.headerGradient,
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('VIP Passes',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    Text('Aero India 2026 · Yelahanka',
                        style: TextStyle(
                            color: AeroColors.goldLight, fontSize: 11)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AeroColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AeroColors.gold.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${widget.vips.length} pass${widget.vips.length != 1 ? 'es' : ''}',
                    style: const TextStyle(
                        color: AeroColors.goldLight,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ]),
            ),
          ),
        ),

        // ── Passes carousel ────────────────────────────────
        Expanded(
          child: widget.vips.isEmpty
              ? const Center(
                  child: Text('No VIP passes',
                      style: TextStyle(color: Colors.white54)))
              : Column(children: [
                  const SizedBox(height: 24),

                  Expanded(
                    child: PageView.builder(
                      controller: _pageCtrl,
                      itemCount: widget.vips.length,
                      onPageChanged: (i) => setState(() => _activeIndex = i),
                      itemBuilder: (_, i) {
                        final scale = _activeIndex == i ? 1.0 : 0.92;
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: scale, end: scale),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          builder: (_, val, child) => Transform.scale(
                            scale: val,
                            child: child,
                          ),
                          child: _FlipPass(
                            vip: widget.vips[i],
                            isActive: _activeIndex == i,
                          ),
                        );
                      },
                    ),
                  ),

                  // ── Page dots ─────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.vips.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _activeIndex == i ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _activeIndex == i
                                ? AeroColors.gold
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Hint ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app, size: 14, color: Colors.white38),
                        const SizedBox(width: 6),
                        const Text(
                          'Tap to flip · Swipe to browse',
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),

                  // ── Full detail button ─────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.open_in_full, size: 16),
                        label: const Text('View Full Pass Detail'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AeroColors.gold,
                          foregroundColor: AeroColors.navy,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle:
                              const TextStyle(fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _PassDetailScreen(
                                vip: widget.vips[_activeIndex]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FLIP PASS  –  front / back 3-D flip on tap
// ═══════════════════════════════════════════════════════════════

class _FlipPass extends StatefulWidget {
  final VIP vip;
  final bool isActive;

  const _FlipPass({required this.vip, required this.isActive});

  @override
  State<_FlipPass> createState() => _FlipPassState();
}

class _FlipPassState extends State<_FlipPass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );
  late final Animation<double> _flipAnim = Tween<double>(begin: 0, end: 1)
      .animate(
          CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOutCubic));

  bool _showBack = false;

  void _flip() {
    HapticFeedback.lightImpact();
    if (_showBack) {
      _flipCtrl.reverse().then((_) {
        if (mounted) setState(() => _showBack = false);
      });
    } else {
      _flipCtrl.forward().then((_) {
        if (mounted) setState(() => _showBack = true);
      });
    }
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _flipAnim,
        builder: (_, __) {
          final angle = _flipAnim.value * math.pi;
          // Which face to show
          final showingBack = angle > math.pi / 2;
          final displayAngle = showingBack ? angle - math.pi : angle;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(displayAngle),
            child: showingBack
                ? _PassBack(vip: widget.vip)
                : _PassFront(vip: widget.vip),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PASS FRONT FACE
// ═══════════════════════════════════════════════════════════════

class _PassFront extends StatelessWidget {
  final VIP vip;
  const _PassFront({required this.vip});

  Color get _tierColor {
    if (vip.isForeign) return AeroColors.foreign;
    if (vip.engagements.length >= 3) return AeroColors.gold;
    if (vip.engagements.length >= 2) return AeroColors.sky;
    return AeroColors.navyLight;
  }

  String get _tier {
    if (vip.isForeign) return 'DIPLOMATIC';
    if (vip.engagements.length >= 3) return 'PLATINUM';
    if (vip.engagements.length >= 2) return 'GOLD';
    return 'VIP';
  }

  @override
  Widget build(BuildContext context) {
    return HolographicOverlay(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AeroColors.navyMid,
              AeroColors.navy,
              AeroColors.cockpit,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _tierColor.withValues(alpha: 0.35),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AeroShimmer(
          child: Column(
            children: [
              // 1. FIXED TOP STRIPE
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: _tierColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
              ),

              // 2. SCROLLABLE CONTENT AREA
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    children: [
                      // Header row: logo + event name
                      Row(children: [
                        CustomPaint(
                          size: const Size(36, 36),
                          painter: _AeroLogoMini(),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('AERO INDIA 2026',
                                  style: TextStyle(
                                      color: AeroColors.gold,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5)),
                              Text(
                                'Yelahanka · 10–14 Feb',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.55),
                                    fontSize: 9,
                                    letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ),
                        // Tier badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _tierColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _tierColor.withValues(alpha: 0.6), width: 1.5),
                          ),
                          child: Text(_tier,
                              style: TextStyle(
                                  color: _tierColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0)),
                        ),
                      ]),

                      const SizedBox(height: 18),

                      // Avatar + name
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: _tierColor.withValues(alpha: 0.6), width: 2),
                            ),
                            child: vip.imagePath != null
                                ? ClipOval(
                                    child: SafeAssetImage(assetPath: vip.imagePath!,
                                        fit: BoxFit.cover))
                                : Center(
                                    child: Text(
                                      vip.name.isNotEmpty
                                          ? vip.name[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: _tierColor),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(vip.name,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 3),
                                Text(vip.designation,
                                    style: TextStyle(
                                        color: AeroColors.goldLight
                                            .withValues(alpha: 0.8),
                                        fontSize: 11)),
                                const SizedBox(height: 8),
                                if (vip.isForeign && vip.nationality != null)
                                  _PassField(
                                      icon: Icons.flag,
                                      label: 'NATIONALITY',
                                      value: vip.nationality!),
                                _PassField(
                                    icon: Icons.phone,
                                    label: 'CONTACT',
                                    value: vip.contact),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      _DashedDivider(),
                      const SizedBox(height: 12),

                      // Hotel + transport summary
                      Row(children: [
                        Expanded(
                          child: _PassInfoBlock(
                            icon: Icons.hotel,
                            label: 'ACCOMMODATION',
                            value: vip.hotel.name.isNotEmpty
                                ? vip.hotel.name
                                : 'Not Assigned',
                            sub: vip.hotel.roomNumber.isNotEmpty
                                ? 'Room ${vip.hotel.roomNumber}'
                                : null,
                          ),
                        ),
                        Container(
                            width: 1,
                            height: 40,
                            color: Colors.white12,
                            margin: const EdgeInsets.symmetric(horizontal: 12)),
                        Expanded(
                          child: _PassInfoBlock(
                            icon: Icons.directions_car,
                            label: 'TRANSPORT',
                            value: vip.transport.carType.isNotEmpty
                                ? vip.transport.carType
                                : '—',
                            sub: vip.transport.driverName.isNotEmpty
                                ? vip.transport.driverName
                                : null,
                          ),
                        ),
                      ]),

                      const SizedBox(height: 12),

                      // Engagements
                      if (vip.engagements.isNotEmpty)
                        Row(children: [
                          const Icon(Icons.event,
                              color: AeroColors.gold, size: 12),
                          const SizedBox(width: 6),
                          Text(
                            '${vip.engagements.length} engagement${vip.engagements.length != 1 ? 's' : ''} scheduled',
                            style: TextStyle(
                                color: AeroColors.goldLight.withValues(alpha: 0.7),
                                fontSize: 10),
                          ),
                        ]),
                    ],
                  ),
                ),
              ),

              // 3. FIXED BOTTOM STRIPE
              Container(
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('AI2026 · LO VERIFIED',
                          style: TextStyle(
                              color: Colors.white24,
                              fontSize: 8,
                              letterSpacing: 1.5)),
                      Icon(Icons.flip, size: 14, color: Colors.white24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PASS BACK FACE
// ═══════════════════════════════════════════════════════════════

class _PassBack extends StatelessWidget {
  final VIP vip;
  const _PassBack({required this.vip});

  String _qrData() {
    final buf = StringBuffer();
    buf.writeln('AERO INDIA 2026');
    buf.writeln(vip.name);
    buf.writeln(vip.designation);
    buf.writeln(vip.contact);
    if (vip.isForeign) {
      buf.writeln('FOREIGN: ${vip.nationality}');
      buf.writeln('PASSPORT: ${vip.passportNumber}');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    // ── No extra rotateY here ──────────────────────────────
    // _FlipPassState already sets displayAngle = angle - π
    // when showing the back face, which corrects orientation.
    // Adding another rotateY(π) here double-flips everything.
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFF101D40),
            AeroColors.cockpit,
            Color(0xFF0A1225),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      // ── IntrinsicHeight Column — no Spacer allowed ────────
      // Spacer() requires a bounded parent height (e.g. inside
      // an Expanded). This Column is sized to its children, so
      // Spacer causes an unbounded-height overflow. Footer is
      // placed inline at the bottom of the content instead.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Magnetic stripe
          Container(
            height: 40,
            margin: const EdgeInsets.only(top: 20),
            color: Colors.black87,
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // QR code block
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // QR
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data: _qrData(),
                        size: 90,
                        version: QrVersions.auto,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AeroColors.navy,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AeroColors.navy,
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Details beside QR
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SCAN TO VERIFY',
                              style: TextStyle(
                                  color: AeroColors.gold,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2)),
                          const SizedBox(height: 6),
                          Text(vip.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(vip.designation,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 10)),
                          const SizedBox(height: 10),
                          if (vip.isForeign) ...[
                            _BackField(
                                label: 'PASSPORT',
                                value: vip.passportNumber ?? '—'),
                            _BackField(
                                label: 'VISA', value: vip.visaStatus ?? '—'),
                            _BackField(
                                label: 'CLEARANCE',
                                value: vip.securityClearanceStatus ?? '—'),
                          ] else ...[
                            _BackField(
                                label: 'HOTEL',
                                value: vip.hotel.name.isNotEmpty
                                    ? vip.hotel.name
                                    : '—'),
                            _BackField(
                                label: 'ROOM',
                                value: vip.hotel.roomNumber.isNotEmpty
                                    ? vip.hotel.roomNumber
                                    : '—'),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Engagement summary
                if (vip.engagements.isNotEmpty) ...[
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ENGAGEMENTS',
                      style: TextStyle(
                          color: AeroColors.gold.withValues(alpha: 0.7),
                          fontSize: 8,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...vip.engagements.take(3).map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: e.rsvpStatus.toLowerCase() == 'confirmed'
                                  ? AeroColors.confirmed
                                  : AeroColors.pending,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(e.eventName,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 10)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: (e.rsvpStatus.toLowerCase() == 'confirmed'
                                      ? AeroColors.confirmed
                                      : AeroColors.pending)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              e.rsvpStatus.toUpperCase(),
                              style: TextStyle(
                                  color:
                                      e.rsvpStatus.toLowerCase() == 'confirmed'
                                          ? AeroColors.confirmed
                                          : AeroColors.pending,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ]),
                      )),
                  if (vip.engagements.length > 3)
                    Text(
                      '+ ${vip.engagements.length - 3} more',
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 9),
                    ),
                ],

                const SizedBox(height: 12),
              ],
            ),
          ),

          // ── Footer pinned at natural bottom ───────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20)),
            ),
            child: Row(children: [
              const Icon(Icons.security, color: AeroColors.gold, size: 12),
              const SizedBox(width: 6),
              const Text('MINISTRY OF DEFENCE · INDIA',
                  style: TextStyle(
                      color: Colors.white30, fontSize: 8, letterSpacing: 1)),
              const Spacer(),
              const Text('AI2026',
                  style: TextStyle(
                      color: Colors.white30,
                      fontSize: 8,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PASS DETAIL SCREEN  (full-screen version)
// ═══════════════════════════════════════════════════════════════

class _PassDetailScreen extends StatelessWidget {
  final VIP vip;
  const _PassDetailScreen({required this.vip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AeroColors.cockpit,
      body: CustomScrollView(
        slivers: [
          // ── Sliver app bar ─────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AeroColors.navy,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(children: [
                // Gradient background
                Container(
                  decoration: const BoxDecoration(
                    gradient: AeroColors.headerGradient,
                  ),
                ),
                // Pattern overlay
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GridPatternPainter(),
                  ),
                ),
                // Content
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Row(children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AeroColors.gold.withValues(alpha: 0.4),
                            AeroColors.gold.withValues(alpha: 0.1),
                          ],
                        ),
                        border: Border.all(color: AeroColors.gold, width: 2.5),
                      ),
                      child: vip.imagePath != null
                          ? ClipOval(
                              child: SafeAssetImage(assetPath: vip.imagePath!,
                                  fit: BoxFit.cover))
                          : Center(
                              child: Text(
                                vip.name.isNotEmpty ? vip.name[0] : '?',
                                style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AeroColors.gold),
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(vip.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          Text(vip.designation,
                              style: const TextStyle(
                                  color: AeroColors.goldLight, fontSize: 13)),
                          const SizedBox(height: 8),
                          if (vip.isForeign)
                            const AeroBadge(
                                label: 'DIPLOMATIC',
                                color: AeroColors.foreign,
                                icon: Icons.public),
                        ],
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),

          // ── Body ───────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Transport detail
                _DetailSection(
                  title: 'TRANSPORT',
                  icon: Icons.directions_car,
                  children: [
                    _DetailRow('Car Type', vip.transport.carType),
                    _DetailRow('Driver', vip.transport.driverName),
                    _DetailRow('Driver Contact', vip.transport.driverContact),
                    _DetailRow('Status', vip.transport.status,
                        highlight: vip.transport.status == 'Completed'),
                    if (vip.transport.flightNumber != null) ...[
                      _DetailRow('Flight', vip.transport.flightNumber!),
                      _DetailRow(
                          'Terminal', vip.transport.arrivalTerminal ?? '—'),
                      _DetailRow('Arrival Location',
                          vip.transport.arrivalLocation ?? '—'),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Hotel detail
                _DetailSection(
                  title: 'ACCOMMODATION',
                  icon: Icons.hotel,
                  children: [
                    _DetailRow('Hotel', vip.hotel.name),
                    _DetailRow('Room', vip.hotel.roomNumber),
                    _DetailRow('Stay Duration', vip.hotel.stayDuration),
                  ],
                ),
                const SizedBox(height: 12),

                if (vip.isForeign) ...[
                  _DetailSection(
                    title: 'DIPLOMATIC CLEARANCE',
                    icon: Icons.security,
                    accentColor: AeroColors.foreign,
                    children: [
                      _DetailRow('Nationality', vip.nationality ?? '—'),
                      _DetailRow('Passport', vip.passportNumber ?? '—',
                          copyable: true),
                      _DetailRow('Language', vip.language ?? '—'),
                      _DetailRow('Time Zone', vip.timeZone ?? '—'),
                      _DetailRow('Visa Status', vip.visaStatus ?? '—',
                          highlight: vip.visaStatus
                                  ?.toLowerCase()
                                  .contains('approved') ??
                              false),
                      _DetailRow('Security Clearance',
                          vip.securityClearanceStatus ?? '—',
                          highlight: vip.securityClearanceStatus
                                  ?.toLowerCase()
                                  .contains('cleared') ??
                              false),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Engagements
                if (vip.engagements.isNotEmpty) ...[
                  _DetailSection(
                    title: 'ENGAGEMENTS',
                    icon: Icons.event,
                    accentColor: AeroColors.sky,
                    children: vip.engagements
                        .map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(
                                          top: 4, right: 10),
                                      decoration: BoxDecoration(
                                          color: e.rsvpStatus.toLowerCase() ==
                                                  'confirmed'
                                              ? AeroColors.confirmed
                                              : AeroColors.pending,
                                          shape: BoxShape.circle),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            e.eventName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13),
                                          ),
                                          Text(
                                            'RSVP: ${e.rsvpStatus}',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade500),
                                          ),
                                          if (e.comments.isNotEmpty)
                                            Text(e.comments,
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    fontStyle: FontStyle.italic,
                                                    color:
                                                        Colors.grey.shade500)),
                                        ],
                                      ),
                                    ),
                                  ]),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Food
                if (vip.foodPreferences != null) ...[
                  _DetailSection(
                    title: 'DIETARY',
                    icon: Icons.restaurant,
                    accentColor: AeroColors.sky,
                    children: [
                      _DetailRow('Preferences', vip.foodPreferences!),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EMBEDDABLE SINGLE PASS CARD  (used in VIPCard)
// ═══════════════════════════════════════════════════════════════

class VipWalletPassCard extends StatelessWidget {
  final VIP vip;
  const VipWalletPassCard({super.key, required this.vip});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VipWalletPassScreen(vips: [vip]),
          ),
        ),
        child: SizedBox(
          height: 100,
          child: _PassFront(vip: vip),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// DETAIL SCREEN HELPERS
// ═══════════════════════════════════════════════════════════════

class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color accentColor;

  const _DetailSection({
    required this.title,
    required this.icon,
    required this.children,
    this.accentColor = AeroColors.gold,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AeroColors.navyMid : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AeroColors.navy.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.06),
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            border: Border(
                bottom: BorderSide(color: accentColor.withValues(alpha: 0.15))),
          ),
          child: Row(children: [
            Icon(icon, size: 14, color: accentColor),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                    letterSpacing: 1.2)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(children: children),
        ),
      ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool copyable;

  const _DetailRow(this.label, this.value,
      {this.highlight = false, this.copyable = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label,
                  style:
                      TextStyle(fontSize: 11, color: context.semantic.textSecondary)),
            ),
            Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: highlight ? AeroColors.confirmed : null)),
            ),
            if (copyable)
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Copied'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ));
                },
                child: Icon(Icons.copy, size: 13, color: context.semantic.textSecondary),
              ),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// PASS SMALL HELPERS
// ═══════════════════════════════════════════════════════════════

class _PassField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _PassField(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 10, color: AeroColors.goldLight),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 9),
        ),
      ]);
}

class _PassInfoBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? sub;

  const _PassInfoBlock({
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 10, color: AeroColors.goldLight.withValues(alpha: 0.6)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: AeroColors.goldLight.withValues(alpha: 0.5),
                    fontSize: 8,
                    letterSpacing: 0.8)),
          ]),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          if (sub != null)
            Text(sub!,
                style: TextStyle(color: Colors.white38, fontSize: 9),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
        ],
      );
}

class _BackField extends StatelessWidget {
  final String label;
  final String value;
  const _BackField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              child: Text(label,
                  style: TextStyle(
                      color: Colors.white38, fontSize: 9, letterSpacing: 0.5)),
            ),
            Flexible(
              child: Text(value,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 1,
        child: CustomPaint(
          painter: _DashPainter(),
          size: const Size(double.infinity, 1),
        ),
      );
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 6, 0), p);
      x += 12;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _AeroLogoMini extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final ring = Paint()
      ..color = AeroColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(s.width / 2, s.height / 2), s.width * 0.44, ring);
    final plane = Paint()
      ..color = AeroColors.goldLight
      ..style = PaintingStyle.fill;
    final body = Path()
      ..moveTo(s.width * 0.2, s.height * 0.5)
      ..lineTo(s.width * 0.8, s.height * 0.46)
      ..lineTo(s.width * 0.8, s.height * 0.54)
      ..lineTo(s.width * 0.2, s.height * 0.54)
      ..close();
    canvas.drawPath(body, plane);
    final wing = Path()
      ..moveTo(s.width * 0.46, s.height * 0.5)
      ..lineTo(s.width * 0.26, s.height * 0.3)
      ..lineTo(s.width * 0.54, s.height * 0.5)
      ..close();
    canvas.drawPath(wing, plane);
  }

  @override
  bool shouldRepaint(_) => false;
}

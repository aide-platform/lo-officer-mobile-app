// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/contrast.dart';
import '../../../../core/widgets/gradient_app_bar.dart';

// ═══════════════════════════════════════════════════════════════
// LOCATION / VENUE NAVIGATION  (#13)
//
// Integration:
//   Navigator.push(context, MaterialPageRoute(
//     builder: (_) => const LoVenueNavScreen()))
//
// Or add as a drawer item in liaison_officer_screen.dart.
// ═══════════════════════════════════════════════════════════════

class LoVenueNavScreen extends StatefulWidget {
  const LoVenueNavScreen({super.key});

  @override
  State<LoVenueNavScreen> createState() =>
      _LoVenueNavScreenState();
}

class _LoVenueNavScreenState
    extends State<LoVenueNavScreen> {
  final _searchCtrl = TextEditingController();
  VenueCategory?  _filterCat;
  String          _query = '';
  VenueLocation?  _selected;

  List<VenueLocation> get _filtered => _venues.where((v) {
    if (_filterCat != null && v.category != _filterCat) {
      return false;
    }
    if (_query.isNotEmpty &&
        !v.name.toLowerCase()
            .contains(_query.toLowerCase()) &&
        !v.description.toLowerCase()
            .contains(_query.toLowerCase())) {
      return false;
    }
    return true;
  }).toList();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GradientAppBar(
        accent: AppColors.roleLO,
        centerTitle: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Venue Navigation',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text(
              'Yelahanka AFB · Aero India 2026',
              style: TextStyle(color: AppColors.goldLight, fontSize: 11),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _openGoogleMaps(
                  'Yelahanka Air Force Station Bengaluru'),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                ),
                child: const Row(children: [
                  Icon(Icons.map, color: AppColors.goldLight, size: 14),
                  SizedBox(width: 4),
                  Text('Full Map',
                      style: TextStyle(
                          color: AppColors.goldLight,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(118),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search venues…',
                    hintStyle:
                        TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Colors.white54, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            })
                        : null,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Row(children: [
                  _CatChip(
                    label: 'All',
                    icon: Icons.location_on,
                    selected: _filterCat == null,
                    color: context.semantic.accent,
                    onTap: () => setState(() => _filterCat = null),
                  ),
                  ...VenueCategory.values.map((c) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _CatChip(
                          label: _catLabel(c),
                          icon: _catIcon(c),
                          selected: _filterCat == c,
                          color: _catColor(c),
                          onTap: () => setState(() =>
                              _filterCat = _filterCat == c ? null : c),
                        ),
                      )),
                ]),
              ),
            ],
          ),
        ),
      ),
      body: RoleScaffoldBackground(
        accent: AppColors.roleLO,
        child: Column(children: [
        // ── Venue map sketch ─────────────────────────────────
        if (_selected == null)
          _VenueMapSketch(
            venues:     _venues,
            onSelect:   (v) =>
                setState(() => _selected = v),
          ),

        // ── Selected venue card ───────────────────────────────
        if (_selected != null)
          _SelectedVenueCard(
            venue:    _selected!,
            onClose:  () =>
                setState(() => _selected = null),
            onNavigate: () =>
                _openGoogleMaps(_selected!.googleQuery),
          ),

        // ── Venue list ───────────────────────────────────────
        Expanded(
          child: _filtered.isEmpty
              ? Center(
              child: Text('No venues match',
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant)))
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(
                16, 8, 16, 80),
            itemCount: _filtered.length,
            itemBuilder: (_, i) {
              final v = _filtered[i];
              return _VenueTile(
                venue:      v,
                index:      i,
                isSelected: _selected?.id == v.id,
                onTap: () => setState(
                        () => _selected = v),
                onNavigate: () =>
                    _openGoogleMaps(v.googleQuery),
              );
            },
          ),
        ),
      ]),
      ),
    );
  }

  Future<void> _openGoogleMaps(String query) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1'
            '&query=${Uri.encodeComponent(query)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri,
          mode: LaunchMode.externalApplication);
    }
  }
}

class _CatChip extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final bool         selected;
  final Color        color;
  final VoidCallback onTap;

  const _CatChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: selected
            ? color.withValues(alpha: 0.14)
            : AppColors.inputFill(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.55)
                : context.semantic.border,
            width: selected ? 1.5 : 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon,
            size:  13,
            color: selected ? color : context.semantic.textSecondary),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.bold,
                color: selected
                    ? color
                    : context.semantic.textSecondary)),
      ]),
    ),
  );
  }
}



// ═══════════════════════════════════════════════════════════════
// VENUE MAP SKETCH  (floor-plan style top view)
// ═══════════════════════════════════════════════════════════════

class _VenueMapSketch extends StatelessWidget {
  final List<VenueLocation> venues;
  final ValueChanged<VenueLocation> onSelect;

  const _VenueMapSketch(
      {required this.venues, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      height:  180,
      margin:  const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color:        AppColors.surfaceDark2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.2)),
      ),
      child: Stack(children: [
        // Grid pattern
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child:        CustomPaint(
            size:    const Size(double.infinity, 180),
            painter: _MapGridPainter(),
          ),
        ),

        // Label
        Positioned(
          top:  10,
          left: 14,
          child: Text('YELAHANKA AFB — AERO INDIA 2026',
              style: TextStyle(
                  color:        AppColors.goldLight
                      .withValues(alpha: 0.5),
                  fontSize:     9,
                  fontWeight:   FontWeight.bold,
                  letterSpacing: 1)),
        ),

        // Venue dots
        ...venues.where((v) => v.mapX != null).map((v) =>
            Positioned(
              left: v.mapX! - 16,
              top:  v.mapY! - 16,
              child: GestureDetector(
                onTap: () => onSelect(v),
                child: Tooltip(
                  message: v.name,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width:  16,
                        height: 16,
                        decoration: BoxDecoration(
                          color:  _catColor(v.category),
                          shape:  BoxShape.circle,
                          border: Border.all(
                              color: Colors.white,
                              width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: _catColor(v.category)
                                  .withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color:        Colors.black.withValues(alpha: 0.54),
                          borderRadius:
                          BorderRadius.circular(3),
                        ),
                        child: Text(
                          v.shortName,
                          style: const TextStyle(
                              color:    Colors.white,
                              fontSize: 7,
                              fontWeight:
                              FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )),

        // Legend
        Positioned(
          bottom: 10,
          right:  12,
          child:  Wrap(
            spacing:   6,
            runSpacing: 4,
            children: VenueCategory.values.map((c) =>
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width:  7,
                    height: 7,
                    decoration: BoxDecoration(
                        color:  _catColor(c),
                        shape:  BoxShape.circle),
                  ),
                  const SizedBox(width: 3),
                  Text(_catLabel(c),
                      style: TextStyle(
                          color:   Colors.white.withValues(alpha: 0.5),
                          fontSize: 7)),
                ])).toList(),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SELECTED VENUE CARD
// ═══════════════════════════════════════════════════════════════

class _SelectedVenueCard extends StatelessWidget {
  final VenueLocation venue;
  final VoidCallback  onClose;
  final VoidCallback  onNavigate;

  const _SelectedVenueCard({
    required this.venue,
    required this.onClose,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        context.semantic.accent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _catColor(venue.category)
                .withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color:      _catColor(venue.category)
                .withValues(alpha: 0.2),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:        _catColor(venue.category)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_catIcon(venue.category),
              color: _catColor(venue.category),
              size:  22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(venue.name,
                  style: const TextStyle(
                      color:      Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize:   14)),
              Text(venue.description,
                  style: TextStyle(
                      color:   Colors.white.withValues(alpha: 0.55),
                      fontSize: 11)),
              if (venue.distance != null)
                Text('${venue.distance} from main gate',
                    style: TextStyle(
                        color:    AppColors.goldLight
                            .withValues(alpha: 0.7),
                        fontSize: 10)),
            ],
          ),
        ),
        Column(children: [
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close,
                color: Colors.white38, size: 18),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onNavigate,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color:        AppColors.gold,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.navigation,
                      color: context.semantic.accent, size: 13),
                  const SizedBox(width: 4),
                  Text('Go',
                      style: TextStyle(
                          color:      context.semantic.accent,
                          fontSize:   11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// VENUE TILE
// ═══════════════════════════════════════════════════════════════

class _VenueTile extends StatelessWidget {
  final VenueLocation venue;
  final int           index;
  final bool          isSelected;
  final VoidCallback  onTap;
  final VoidCallback  onNavigate;

  const _VenueTile({
    required this.venue,
    required this.index,
    required this.isSelected,
    required this.onTap,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final cat = venue.category;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween:    Tween(begin: 0, end: 1),
      duration: Duration(
          milliseconds: 200 + (index * 40)),
      curve: Curves.easeOut,
      builder: (_, val, child) => Opacity(
        opacity: val,
        child:   Transform.translate(
            offset: Offset(0, 10 * (1 - val)),
            child:  child),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? _catColor(cat).withValues(alpha: 0.06)
                : AppColors.surfaceCard(isDark),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? _catColor(cat).withValues(alpha: 0.4)
                  : context.semantic.border,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color:      Colors.black.withValues(alpha: 
                    isSelected ? 0.06 : 0.03),
                blurRadius: isSelected ? 8 : 4,
                offset:     const Offset(0, 2),
              ),
            ],
          ),
          child: Row(children: [
            // Category icon box
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color:        _catColor(cat)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_catIcon(cat),
                  size:  18, color: _catColor(cat)),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(venue.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize:   13)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color:        _catColor(cat)
                            .withValues(alpha: 0.1),
                        borderRadius:
                        BorderRadius.circular(6),
                      ),
                      child: Text(_catLabel(cat),
                          style: TextStyle(
                              fontSize:   8,
                              fontWeight: FontWeight.bold,
                              color:      _catColor(cat))),
                    ),
                  ]),
                  Text(venue.description,
                      style: TextStyle(
                          fontSize: 11,
                          color:    context.semantic.textMuted)),
                  if (venue.distance != null)
                    Text(venue.distance!,
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.gold
                                .withValues(alpha: 0.8))),
                ],
              ),
            ),

            // Navigate button
            GestureDetector(
              onTap: onNavigate,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:        context.semantic.accent
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.navigation,
                    color: context.semantic.accent, size: 18),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DATA — Yelahanka AFB / Aero India venue locations
// ═══════════════════════════════════════════════════════════════

enum VenueCategory {
  gate, vipLounge, display, pavilion,
  medical, parking, food, briefing
}

class VenueLocation {
  final String        id;
  final String        name;
  final String        shortName;
  final String        description;
  final VenueCategory category;
  final String        googleQuery;
  final String?       distance;
  final double?       mapX;   // relative px on sketch canvas
  final double?       mapY;

  const VenueLocation({
    required this.id,
    required this.name,
    required this.shortName,
    required this.description,
    required this.category,
    required this.googleQuery,
    this.distance,
    this.mapX,
    this.mapY,
  });
}

const List<VenueLocation> _venues = [
  VenueLocation(
    id:          'g1',
    name:        'Main Gate (Gate 1)',
    shortName:   'G1',
    description: 'Primary entry for all VIP and delegate vehicles',
    category:    VenueCategory.gate,
    googleQuery: 'Yelahanka Air Force Station Main Gate Bengaluru',
    distance:    '0 m',
    mapX:        30,
    mapY:        90,
  ),
  VenueLocation(
    id:          'vip1',
    name:        'VIP Lounge — North Wing',
    shortName:   'VL-N',
    description: 'Holding area for dignitaries pre-show. Access by escort only.',
    category:    VenueCategory.vipLounge,
    googleQuery: 'Yelahanka AFB VIP Lounge Aero India',
    distance:    '400 m from G1',
    mapX:        100,
    mapY:        50,
  ),
  VenueLocation(
    id:          'vip2',
    name:        'VVIP Lounge — Defence Ministry',
    shortName:   'VVIP',
    description: 'Exclusive lounge for Cabinet, CDS and foreign defence ministers.',
    category:    VenueCategory.vipLounge,
    googleQuery: 'Aero India 2026 VVIP area Yelahanka',
    distance:    '450 m from G1',
    mapX:        120,
    mapY:        30,
  ),
  VenueLocation(
    id:          'sd1',
    name:        'Static Display — Zone A',
    shortName:   'SD-A',
    description: 'Fixed-wing aircraft. Tejas, Su-30MKI, C-17.',
    category:    VenueCategory.display,
    googleQuery: 'Aero India 2026 static display zone',
    distance:    '800 m from G1',
    mapX:        200,
    mapY:        80,
  ),
  VenueLocation(
    id:          'sd2',
    name:        'Flying Display Zone',
    shortName:   'FD',
    description: 'Airshow observation area. Delegate reserved seating Row A–C.',
    category:    VenueCategory.display,
    googleQuery: 'Aero India 2026 flying display area',
    distance:    '1.1 km from G1',
    mapX:        260,
    mapY:        40,
  ),
  VenueLocation(
    id:          'pav1',
    name:        'HAL Pavilion',
    shortName:   'HAL',
    description: 'Hindustan Aeronautics Ltd. exhibits and briefing rooms.',
    category:    VenueCategory.pavilion,
    googleQuery: 'HAL Pavilion Aero India Yelahanka',
    distance:    '600 m from G1',
    mapX:        160,
    mapY:        110,
  ),
  VenueLocation(
    id:          'pav2',
    name:        'International Pavilion',
    shortName:   'INTL',
    description: 'Foreign OEM exhibitors. B4, B6, B7 halls.',
    category:    VenueCategory.pavilion,
    googleQuery: 'Aero India International Pavilion Yelahanka',
    distance:    '700 m from G1',
    mapX:        190,
    mapY:        135,
  ),
  VenueLocation(
    id:          'med1',
    name:        'Medical Centre',
    shortName:   'MED',
    description: '24 hr medical facility. Ambulance stand-by.',
    category:    VenueCategory.medical,
    googleQuery: 'Yelahanka AFB Medical Centre Bengaluru',
    distance:    '300 m from G1',
    mapX:        70,
    mapY:        140,
  ),
  VenueLocation(
    id:          'pk1',
    name:        'VIP Parking Bay — P1',
    shortName:   'P1',
    description: 'Reserved vehicle parking for delegate convoy. Capacity: 40.',
    category:    VenueCategory.parking,
    googleQuery: 'Aero India VIP parking Yelahanka',
    distance:    '200 m from G1',
    mapX:        55,
    mapY:        60,
  ),
  VenueLocation(
    id:          'fd1',
    name:        'Delegate Food Court',
    shortName:   'FC',
    description: 'Catered meals for delegates and LOs. Breakfast / Lunch / Tea.',
    category:    VenueCategory.food,
    googleQuery: 'Aero India 2026 food court Yelahanka',
    distance:    '500 m from G1',
    mapX:        145,
    mapY:        155,
  ),
  VenueLocation(
    id:          'br1',
    name:        'LO Briefing Room',
    shortName:   'LO',
    description: 'Morning briefings, coordination desk, duty roster.',
    category:    VenueCategory.briefing,
    googleQuery: 'Aero India 2026 liaison officer desk',
    distance:    '150 m from G1',
    mapX:        80,
    mapY:        115,
  ),
];

// ═══════════════════════════════════════════════════════════════
// UTILITY
// ═══════════════════════════════════════════════════════════════

Color _catColor(VenueCategory c) => switch (c) {
  VenueCategory.gate      => AppColors.danger,
  VenueCategory.vipLounge => AppColors.gold,
  VenueCategory.display   => AppColors.sky,
  VenueCategory.pavilion  => AppColors.roleLO,
  VenueCategory.medical   => const Color(0xFFE53935),
  VenueCategory.parking   => Colors.grey,
  VenueCategory.food      => AppColors.warning,
  VenueCategory.briefing  => AppColors.roleLO,
};

IconData _catIcon(VenueCategory c) => switch (c) {
  VenueCategory.gate      => Icons.door_front_door,
  VenueCategory.vipLounge => Icons.star,
  VenueCategory.display   => Icons.flight,
  VenueCategory.pavilion  => Icons.business,
  VenueCategory.medical   => Icons.local_hospital,
  VenueCategory.parking   => Icons.local_parking,
  VenueCategory.food      => Icons.restaurant,
  VenueCategory.briefing  => Icons.meeting_room,
};

String _catLabel(VenueCategory c) => switch (c) {
  VenueCategory.gate      => 'Gate',
  VenueCategory.vipLounge => 'VIP Lounge',
  VenueCategory.display   => 'Display',
  VenueCategory.pavilion  => 'Pavilion',
  VenueCategory.medical   => 'Medical',
  VenueCategory.parking   => 'Parking',
  VenueCategory.food      => 'Food',
  VenueCategory.briefing  => 'Briefing',
};

// ─── Map grid painter ─────────────────────────────────────────
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color      = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    const step = 24.0;
    for (double x = 0; x < size.width;  x += step) {
      canvas.drawLine(
          Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y), p);
    }
    // Runway representation
    final rp = Paint()
      ..color      = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 18;
    canvas.drawLine(
        Offset(size.width * 0.1, size.height * 0.35),
        Offset(size.width * 0.95, size.height * 0.35),
        rp);
    // Runway centre line dashes
    final dp = Paint()
      ..color      = AppColors.goldLight.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    for (double x = size.width * 0.1;
    x < size.width * 0.95;
    x += 20) {
      canvas.drawLine(
          Offset(x, size.height * 0.35),
          Offset(x + 12, size.height * 0.35),
          dp);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
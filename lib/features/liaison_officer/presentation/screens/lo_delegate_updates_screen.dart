import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_semantic_colors.dart';
import '../../../../core/notifications/mock_email_notifier.dart';
import '../../../../core/widgets/gradient_app_bar.dart';
import '../../data/models/connecting_flight.dart';
import '../../data/models/lo_travel_update.dart';
import '../../data/models/vip.dart';
import 'lo_notifications_screen.dart';

class LoDelegateUpdatesScreen extends StatefulWidget {
  const LoDelegateUpdatesScreen({
    super.key,
    required this.vips,
    this.initialDelegateName,
  });

  final List<VIP> vips;
  final String? initialDelegateName;

  @override
  State<LoDelegateUpdatesScreen> createState() =>
      _LoDelegateUpdatesScreenState();
}

class _LoDelegateUpdatesScreenState extends State<LoDelegateUpdatesScreen> {
  final Map<String, LoTravelUpdate> _updates = {};
  String? _selectedName;
  bool _loading = true;
  bool _saving = false;

  final _arrivalFlight = TextEditingController();
  final _arrivalTerminal = TextEditingController();
  final _departureFlight = TextEditingController();
  final _departureTerminal = TextEditingController();

  DateTime? _arrivalDate;
  TimeOfDay? _arrivalTime;
  DateTime? _departureDate;
  TimeOfDay? _departureTime;
  List<ConnectingFlight> _arrivalConnecting = [];
  List<ConnectingFlight> _departureConnecting = [];

  @override
  void initState() {
    super.initState();
    _selectedName = widget.initialDelegateName ??
        (widget.vips.isNotEmpty ? widget.vips.first.name : null);
    _load();
  }

  @override
  void dispose() {
    _arrivalFlight.dispose();
    _arrivalTerminal.dispose();
    _departureFlight.dispose();
    _departureTerminal.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final saved = await LoTravelUpdate.all();
    if (!mounted) return;
    setState(() {
      for (final item in saved) {
        _updates[item.delegateName] = item;
      }
      _loading = false;
    });
    _bindSelected();
  }

  void _bindSelected() {
    final name = _selectedName;
    if (name == null) return;
    VIP? vip;
    for (final v in widget.vips) {
      if (v.name == name) {
        vip = v;
        break;
      }
    }
    final current = _updates[name] ??
        LoTravelUpdate(
          delegateName: name,
          arrivalFlightNumber: vip?.transport.flightNumber ?? '',
          arrivalTerminal: vip?.transport.arrivalTerminal ?? '',
          arrivalDate: vip?.transport.arrivalTime,
          arrivalTime: vip?.transport.arrivalTime != null
              ? _formatTimeOfDay(
                  TimeOfDay.fromDateTime(vip!.transport.arrivalTime!))
              : null,
        );

    _arrivalFlight.text = current.arrivalFlightNumber;
    _arrivalTerminal.text = current.arrivalTerminal;
    _departureFlight.text = current.departureFlightNumber;
    _departureTerminal.text = current.departureTerminal;
    _arrivalDate = current.arrivalDate;
    _departureDate = current.departureDate;
    _arrivalTime = _parseTime(current.arrivalTime);
    _departureTime = _parseTime(current.departureTime);
    _arrivalConnecting = List.of(current.arrivalConnectingFlights);
    _departureConnecting = List.of(current.departureConnectingFlights);
    setState(() {});
  }

  TimeOfDay? _parseTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parts = raw.trim().split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _formatDate(DateTime? d) {
    if (d == null) return 'Select date';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _pickDate({required bool arrival}) async {
    final initial = (arrival ? _arrivalDate : _departureDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (arrival) {
        _arrivalDate = picked;
      } else {
        _departureDate = picked;
      }
    });
  }

  Future<void> _pickTime({required bool arrival}) async {
    final initial =
        (arrival ? _arrivalTime : _departureTime) ?? TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (arrival) {
        _arrivalTime = picked;
      } else {
        _departureTime = picked;
      }
    });
  }

  Future<void> _pickConnectingDate(List<ConnectingFlight> list, int index) async {
    final current = list[index].date ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => list[index] = list[index].copyWith(date: picked));
  }

  Future<void> _pickConnectingTime(List<ConnectingFlight> list, int index) async {
    final existing = list[index].time;
    final initial = _parseTime(existing) ?? TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(
      () => list[index] =
          list[index].copyWith(time: _formatTimeOfDay(picked)),
    );
  }

  Future<void> _save() async {
    final name = _selectedName;
    if (name == null) return;
    setState(() => _saving = true);

    final update = LoTravelUpdate(
      delegateName: name,
      arrivalFlightNumber: _arrivalFlight.text.trim(),
      arrivalTerminal: _arrivalTerminal.text.trim(),
      arrivalDate: _arrivalDate,
      arrivalTime:
          _arrivalTime != null ? _formatTimeOfDay(_arrivalTime!) : null,
      arrivalConnectingFlights: List.of(_arrivalConnecting),
      departureFlightNumber: _departureFlight.text.trim(),
      departureTerminal: _departureTerminal.text.trim(),
      departureDate: _departureDate,
      departureTime:
          _departureTime != null ? _formatTimeOfDay(_departureTime!) : null,
      departureConnectingFlights: List.of(_departureConnecting),
    );

    await LoTravelUpdate.upsert(update);

    LoNotificationStore.instance.add(
      LoNotification(
        id: 'travel_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Travel details updated',
        body:
            'Arrival/departure details for $name were updated and shared with LO Committee Nodal Officer.',
        type: LoNotifType.schedule,
        timestamp: DateTime.now(),
      ),
    );

    await MockEmailNotifier.send(
      to: 'nodal.officer@lo-committee.example',
      subject: 'LO travel update — $name',
      body:
          'Liaison Officer updated travel for $name.\n'
          'Arrival: ${update.arrivalFlightNumber} / ${update.arrivalTerminal} '
          '${_formatDate(update.arrivalDate)} ${update.arrivalTime ?? ''}\n'
          'Departure: ${update.departureFlightNumber} / ${update.departureTerminal} '
          '${_formatDate(update.departureDate)} ${update.departureTime ?? ''}',
    );

    if (!mounted) return;
    setState(() {
      _updates[name] = update;
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Travel details saved. Nodal Officer notified.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.semantic;

    return Scaffold(
      backgroundColor: s.scaffold,
      appBar: GradientAppBar(
        accent: AppColors.roleLO,
        centerTitle: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Travel Updates',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Arrival & departure · LO.9.2',
              style: TextStyle(color: AppColors.goldLight, fontSize: 11),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : widget.vips.isEmpty
              ? Center(
                  child: Text(
                    'No assigned delegates.',
                    style: TextStyle(color: s.textMuted),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    Text(
                      'Delegate',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: s.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedName,
                      items: widget.vips
                          .map(
                            (v) => DropdownMenuItem(
                              value: v.name,
                              child: Text(v.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedName = value);
                        _bindSelected();
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: s.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _TravelSection(
                      title: 'Arrival Details',
                      icon: Icons.flight_land,
                      flightController: _arrivalFlight,
                      terminalController: _arrivalTerminal,
                      dateLabel: _formatDate(_arrivalDate),
                      timeLabel: _arrivalTime != null
                          ? _formatTimeOfDay(_arrivalTime!)
                          : 'Select time',
                      onPickDate: () => _pickDate(arrival: true),
                      onPickTime: () => _pickTime(arrival: true),
                      connecting: _arrivalConnecting,
                      onAddConnecting: () => setState(
                        () => _arrivalConnecting.add(const ConnectingFlight()),
                      ),
                      onRemoveConnecting: (i) => setState(
                        () => _arrivalConnecting.removeAt(i),
                      ),
                      onFlightChanged: (i, v) => setState(
                        () => _arrivalConnecting[i] =
                            _arrivalConnecting[i].copyWith(flightNumber: v),
                      ),
                      onTerminalChanged: (i, v) => setState(
                        () => _arrivalConnecting[i] =
                            _arrivalConnecting[i].copyWith(terminal: v),
                      ),
                      onPickConnectingDate: (i) =>
                          _pickConnectingDate(_arrivalConnecting, i),
                      onPickConnectingTime: (i) =>
                          _pickConnectingTime(_arrivalConnecting, i),
                    ),
                    const SizedBox(height: 16),
                    _TravelSection(
                      title: 'Departure Details',
                      icon: Icons.flight_takeoff,
                      flightController: _departureFlight,
                      terminalController: _departureTerminal,
                      dateLabel: _formatDate(_departureDate),
                      timeLabel: _departureTime != null
                          ? _formatTimeOfDay(_departureTime!)
                          : 'Select time',
                      onPickDate: () => _pickDate(arrival: false),
                      onPickTime: () => _pickTime(arrival: false),
                      connecting: _departureConnecting,
                      onAddConnecting: () => setState(
                        () =>
                            _departureConnecting.add(const ConnectingFlight()),
                      ),
                      onRemoveConnecting: (i) => setState(
                        () => _departureConnecting.removeAt(i),
                      ),
                      onFlightChanged: (i, v) => setState(
                        () => _departureConnecting[i] =
                            _departureConnecting[i].copyWith(flightNumber: v),
                      ),
                      onTerminalChanged: (i, v) => setState(
                        () => _departureConnecting[i] =
                            _departureConnecting[i].copyWith(terminal: v),
                      ),
                      onPickConnectingDate: (i) =>
                          _pickConnectingDate(_departureConnecting, i),
                      onPickConnectingTime: (i) =>
                          _pickConnectingTime(_departureConnecting, i),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Saving…' : 'Save & notify Nodal Officer'),
                    ),
                  ],
                ),
    );
  }
}

class _TravelSection extends StatelessWidget {
  const _TravelSection({
    required this.title,
    required this.icon,
    required this.flightController,
    required this.terminalController,
    required this.dateLabel,
    required this.timeLabel,
    required this.onPickDate,
    required this.onPickTime,
    required this.connecting,
    required this.onAddConnecting,
    required this.onRemoveConnecting,
    required this.onFlightChanged,
    required this.onTerminalChanged,
    required this.onPickConnectingDate,
    required this.onPickConnectingTime,
  });

  final String title;
  final IconData icon;
  final TextEditingController flightController;
  final TextEditingController terminalController;
  final String dateLabel;
  final String timeLabel;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final List<ConnectingFlight> connecting;
  final VoidCallback onAddConnecting;
  final ValueChanged<int> onRemoveConnecting;
  final void Function(int, String) onFlightChanged;
  final void Function(int, String) onTerminalChanged;
  final ValueChanged<int> onPickConnectingDate;
  final ValueChanged<int> onPickConnectingTime;

  @override
  Widget build(BuildContext context) {
    final s = context.semantic;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: s.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: s.accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: s.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: flightController,
            decoration: const InputDecoration(
              labelText: 'Flight Number',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: terminalController,
            decoration: const InputDecoration(
              labelText: 'Terminal',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickDate,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(dateLabel, overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickTime,
                  icon: const Icon(Icons.schedule, size: 16),
                  label: Text(timeLabel, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Connecting Flights',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: s.textSecondary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAddConnecting,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          if (connecting.isEmpty)
            Text(
              'No connecting flights added.',
              style: TextStyle(fontSize: 12, color: s.textMuted),
            ),
          ...List.generate(connecting.length, (i) {
            final c = connecting[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: s.inputFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: s.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Leg ${i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: s.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => onRemoveConnecting(i),
                          icon: const Icon(Icons.delete_outline, size: 20),
                        ),
                      ],
                    ),
                    TextFormField(
                      initialValue: c.flightNumber,
                      onChanged: (v) => onFlightChanged(i, v),
                      decoration: const InputDecoration(
                        labelText: 'Flight Number',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: c.terminal,
                      onChanged: (v) => onTerminalChanged(i, v),
                      decoration: const InputDecoration(
                        labelText: 'Terminal',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => onPickConnectingDate(i),
                            child: Text(
                              c.date == null
                                  ? 'Date'
                                  : '${c.date!.day}/${c.date!.month}/${c.date!.year}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => onPickConnectingTime(i),
                            child: Text(c.time?.isNotEmpty == true ? c.time! : 'Time'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

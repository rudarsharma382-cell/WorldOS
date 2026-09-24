import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/watch_zone.dart';

class WatchZoneDialog extends StatefulWidget {
  final double initialLat;
  final double initialLon;
  final Function(WatchZone) onCreate;

  const WatchZoneDialog({
    super.key,
    required this.initialLat,
    required this.initialLon,
    required this.onCreate,
  });

  @override
  State<WatchZoneDialog> createState() => _WatchZoneDialogState();
}

class _WatchZoneDialogState extends State<WatchZoneDialog> {
  late TextEditingController _nameController;
  double _radiusKm = 500.0;
  final Set<String> _selectedTypes = {'EARTHQUAKE', 'WEATHER', 'WILDFIRE'};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: 'Watch Zone (${widget.initialLat.toStringAsFixed(1)}°, ${widget.initialLon.toStringAsFixed(1)}°)',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final zone = WatchZone(
      id: 'wz_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim().isEmpty ? 'Custom Watch Zone' : _nameController.text.trim(),
      latitude: widget.initialLat,
      longitude: widget.initialLon,
      radiusKm: _radiusKm,
      trackedTypes: _selectedTypes.toList(),
      createdAt: DateTime.now(),
    );
    widget.onCreate(zone);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0C1017),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
      ),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(CupertinoIcons.scope, color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'CREATE WATCH ZONE',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              Text('ZONE NAME', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),

              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('MONITORING RADIUS', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
                  Text(
                    '${_radiusKm.toInt()} KM',
                    style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFFF59E0B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  activeTrackColor: const Color(0xFFF59E0B),
                  inactiveTrackColor: Colors.white12,
                  thumbColor: const Color(0xFFF59E0B),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                ),
                child: Slider(
                  value: _radiusKm,
                  min: 100.0,
                  max: 3000.0,
                  onChanged: (val) => setState(() => _radiusKm = val),
                ),
              ),

              const SizedBox(height: 14),
              Text('TRACKED EVENT TYPES', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
              const SizedBox(height: 8),

              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ['EARTHQUAKE', 'WEATHER', 'WILDFIRE', 'SATELLITE', 'STORM'].map((type) {
                  final isSel = _selectedTypes.contains(type);
                  return FilterChip(
                    selected: isSel,
                    selectedColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    backgroundColor: Colors.white.withValues(alpha: 0.04),
                    side: BorderSide(color: isSel ? const Color(0xFFF59E0B) : Colors.white.withValues(alpha: 0.12), width: 0.5),
                    label: Text(
                      type,
                      style: GoogleFonts.inter(
                        color: isSel ? const Color(0xFFF59E0B) : Colors.white54,
                        fontSize: 11,
                        fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedTypes.add(type);
                        } else {
                          _selectedTypes.remove(type);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('CANCEL', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: _submit,
                    child: Text('CREATE ZONE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


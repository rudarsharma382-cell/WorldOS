import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/watch_zone.dart';
import '../../models/investigation.dart';

class LayerDrawer extends StatelessWidget {
  final Set<String> activeLayers;
  final Function(String) onToggleLayer;
  final List<WatchZone> watchZones;
  final List<Investigation> investigations;
  final VoidCallback onCreateWatchZone;
  final Function(WatchZone) onSelectWatchZone;
  final Function(Investigation) onSelectInvestigation;

  const LayerDrawer({
    super.key,
    required this.activeLayers,
    required this.onToggleLayer,
    required this.watchZones,
    required this.investigations,
    required this.onCreateWatchZone,
    required this.onSelectWatchZone,
    required this.onSelectInvestigation,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 270,
          decoration: BoxDecoration(
            color: const Color(0xFF0C1017).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Label
                Row(
                  children: [
                    const Icon(CupertinoIcons.layers, color: Color(0xFF38BDF8), size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'DATA LAYERS',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(color: Colors.white.withValues(alpha: 0.08), height: 1, thickness: 0.5),
                const SizedBox(height: 12),

                // Compact Functional Micro Switch Instrument Rail
                _buildLayerRow('EARTHQUAKE', 'Seismic Activity', 'USGS', const Color(0xFFFF5555), CupertinoIcons.waveform_path_ecg, 14),
                _buildLayerRow('WEATHER', 'Severe Weather', 'NOAA', const Color(0xFF38BDF8), CupertinoIcons.wind, 8),
                _buildLayerRow('WILDFIRE', 'Thermal Anomalies', 'NASA', const Color(0xFFF59E0B), CupertinoIcons.flame, 11),
                _buildLayerRow('SATELLITE', 'Orbital Telemetry', 'CELESTRAK', const Color(0xFFA855F7), CupertinoIcons.radiowaves_right, 6),
                _buildLayerRow('STORM', 'Tropical Cyclones', 'JMA', const Color(0xFF0EA5E9), CupertinoIcons.cloud_bolt, 4),

                const SizedBox(height: 20),

                // Watch Zones Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.scope, color: Color(0xFFF59E0B), size: 14),
                        const SizedBox(width: 8),
                        Text(
                          'WATCH ZONES',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: onCreateWatchZone,
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3), width: 0.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.add, color: Color(0xFFF59E0B), size: 10),
                            const SizedBox(width: 2),
                            Text(
                              'ADD',
                              style: GoogleFonts.inter(color: const Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.white.withValues(alpha: 0.08), height: 1, thickness: 0.5),
                const SizedBox(height: 8),

                if (watchZones.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'No active watch zones configured.',
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                    ),
                  )
                else
                  Column(
                    children: watchZones.map((zone) {
                      return InkWell(
                        onTap: () => onSelectWatchZone(zone),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  zone.name,
                                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
                                ),
                                child: Text(
                                  '${zone.radiusKm.toInt()}km',
                                  style: GoogleFonts.jetBrainsMono(
                                    color: const Color(0xFFF59E0B),
                                    fontSize: 10,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 20),

                // Saved Sessions Section
                Row(
                  children: [
                    const Icon(CupertinoIcons.bookmark, color: Color(0xFF10B981), size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'SAVED SESSIONS',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.white.withValues(alpha: 0.08), height: 1, thickness: 0.5),
                const SizedBox(height: 8),

                if (investigations.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'No saved investigation sessions.',
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                    ),
                  )
                else
                  Column(
                    children: investigations.map((inv) {
                      return InkWell(
                        onTap: () => onSelectInvestigation(inv),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  inv.title,
                                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
                                ),
                                child: Text(
                                  '${inv.eventIds.length} ev',
                                  style: GoogleFonts.jetBrainsMono(
                                    color: const Color(0xFF10B981),
                                    fontSize: 10,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayerRow(String key, String label, String provider, Color accentColor, IconData iconData, int count) {
    final isActive = activeLayers.contains(key) || activeLayers.contains('ALL');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // Vector Icon
          Icon(iconData, color: isActive ? accentColor : Colors.white38, size: 14),
          const SizedBox(width: 10),

          // Layer Name (Inter, 13px, w500)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: isActive ? Colors.white : Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  provider,
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Event Count Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.jetBrainsMono(
                color: isActive ? accentColor : Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Miniature iOS-Style Micro Switch
          Transform.scale(
            scale: 0.65,
            child: CupertinoSwitch(
              value: isActive,
              activeTrackColor: accentColor,
              onChanged: (_) => onToggleLayer(key),
            ),
          ),
        ],
      ),
    );
  }
}


import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/world_event.dart';

class EventDetailPanel extends StatelessWidget {
  final WorldEvent? event;
  final VoidCallback onClose;
  final VoidCallback onFlyToLocation;
  final VoidCallback onSaveToInvestigation;
  final VoidCallback onAskAiBriefing;

  const EventDetailPanel({
    super.key,
    required this.event,
    required this.onClose,
    required this.onFlyToLocation,
    required this.onSaveToInvestigation,
    required this.onAskAiBriefing,
  });

  @override
  Widget build(BuildContext context) {
    if (event == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0C1017).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.scope, color: Colors.white24, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    'NO TARGET SELECTED',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select any target marker on the interactive 3D globe to inspect telemetry metrics.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final ev = event!;
    final typeColor = _getTypeColor(ev.type);
    final typeIcon = _getTypeIcon(ev.type);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 320,
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
                // Top Row Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(typeIcon, color: typeColor, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          ev.type,
                          style: GoogleFonts.inter(
                            color: typeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: onClose,
                      child: const Icon(CupertinoIcons.xmark, color: Colors.white54, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Event Title
                Text(
                  ev.title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 8),

                // Status & Timestamp Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2), width: 0.5),
                      ),
                      child: Text(
                        ev.freshnessStatus.toUpperCase(),
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFF10B981),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ev.timeAgo,
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(color: Colors.white.withValues(alpha: 0.08), height: 1, thickness: 0.5),
                const SizedBox(height: 12),

                // Telemetry Metrics Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MAGNITUDE / SEVERITY',
                          style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ev.severity.toStringAsFixed(1),
                          style: GoogleFonts.jetBrainsMono(
                            color: typeColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'CONFIDENCE',
                          style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${((ev.confidence ?? 0.95) * 100).toInt()}%',
                          style: GoogleFonts.jetBrainsMono(
                            color: const Color(0xFF10B981),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Structured Data Status Chips Rail
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildChip('MAG', ev.severity.toStringAsFixed(1), typeColor),
                    if (ev.altitude != null) _buildChip('DEPTH', '${ev.altitude!.toStringAsFixed(0)}km', Colors.white70),
                    _buildChip('SOURCE', ev.source, const Color(0xFF38BDF8)),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(color: Colors.white.withValues(alpha: 0.08), height: 1, thickness: 0.5),
                const SizedBox(height: 12),

                // Metadata Rows
                _buildMetadataRow('LATITUDE', '${ev.latitude.toStringAsFixed(4)}°'),
                _buildMetadataRow('LONGITUDE', '${ev.longitude.toStringAsFixed(4)}°'),
                if (ev.altitude != null) _buildMetadataRow('ALTITUDE / DEPTH', '${ev.altitude!.toStringAsFixed(1)} km'),
                _buildMetadataRow('SOURCE FEED', ev.source),
                _buildMetadataRow('TIMESTAMP', '${DateFormat('HH:mm:ss').format(ev.timestamp.toUtc())} UTC'),

                const SizedBox(height: 12),

                // Description Context
                if (ev.description != null && ev.description!.isNotEmpty) ...[
                  Text(
                    'TELEMETRY SUMMARY',
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ev.description!,
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons Rail
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                          foregroundColor: const Color(0xFF38BDF8),
                          side: BorderSide(color: const Color(0xFF38BDF8).withValues(alpha: 0.3), width: 0.5),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(CupertinoIcons.location_fill, size: 14),
                        label: Text(
                          'FLY TO TARGET',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        onPressed: onFlyToLocation,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF43F5E),
                          side: BorderSide(color: const Color(0xFFF43F5E).withValues(alpha: 0.3), width: 0.5),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(CupertinoIcons.sparkles, size: 14),
                        label: Text(
                          'REGIONAL BRIEFING',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        onPressed: onAskAiBriefing,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF10B981),
                          side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.3), width: 0.5),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(CupertinoIcons.bookmark_fill, size: 14),
                        label: Text(
                          'SAVE TO SESSION',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        onPressed: onSaveToInvestigation,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w500),
            ),
            TextSpan(
              text: val,
              style: GoogleFonts.jetBrainsMono(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
          Text(
            val,
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'EARTHQUAKE': return const Color(0xFFFF5555);
      case 'WILDFIRE': return const Color(0xFFF59E0B);
      case 'STORM': return const Color(0xFF0EA5E9);
      case 'WEATHER': return const Color(0xFF38BDF8);
      case 'SATELLITE': return const Color(0xFFA855F7);
      default: return const Color(0xFF10B981);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'EARTHQUAKE': return CupertinoIcons.waveform_path_ecg;
      case 'WILDFIRE': return CupertinoIcons.flame_fill;
      case 'STORM': return CupertinoIcons.cloud_bolt;
      case 'WEATHER': return CupertinoIcons.wind;
      case 'SATELLITE': return CupertinoIcons.radiowaves_right;
      default: return CupertinoIcons.info_circle_fill;
    }
  }
}


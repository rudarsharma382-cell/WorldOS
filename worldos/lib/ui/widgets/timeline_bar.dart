import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimelineBar extends StatelessWidget {
  final double timeTravelHours;
  final Function(double) onTimeTravelChanged;
  final String selectedCategory;
  final Function(String) onSelectCategory;
  final String latestEventTitle;

  const TimelineBar({
    super.key,
    required this.timeTravelHours,
    required this.onTimeTravelChanged,
    required this.selectedCategory,
    required this.onSelectCategory,
    required this.latestEventTitle,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0C1017).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
          ),
          child: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 720;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Live Telemetry Ticker Line
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5555).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFFF5555).withValues(alpha: 0.3), width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF5555),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'LIVE STREAM',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFFF5555),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            latestEventTitle.isEmpty
                                ? 'Listening to global C4ISR stream...'
                                : latestEventTitle,
                            style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Category Rail & Razor-Thin Timeline Scrubber
                    Row(
                      children: [
                        // Category Segment Chips
                        if (!isNarrow) ...[
                          _buildSegmentChip('ALL', 'All Layers'),
                          _buildSegmentChip('EARTHQUAKE', 'Seismic'),
                          _buildSegmentChip('WEATHER', 'Weather'),
                          _buildSegmentChip('WILDFIRE', 'Thermal'),
                          _buildSegmentChip('SATELLITE', 'Orbital'),
                          const SizedBox(width: 16),
                        ],

                        // Time Travel Datum Readout
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
                          ),
                          child: Text(
                            timeTravelHours == 0.0
                                ? 'LIVE NOW'
                                : '-${timeTravelHours.toStringAsFixed(1)}h',
                            style: GoogleFonts.jetBrainsMono(
                              color: timeTravelHours == 0.0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Scrubber
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 2.0,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                              activeTrackColor: timeTravelHours == 0.0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              inactiveTrackColor: Colors.white24,
                              thumbColor: timeTravelHours == 0.0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            ),
                            child: Slider(
                              value: timeTravelHours,
                              min: 0.0,
                              max: 24.0,
                              onChanged: onTimeTravelChanged,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentChip(String category, String label) {
    final isSelected = selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => onSelectCategory(category),
        borderRadius: BorderRadius.circular(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF38BDF8).withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? const Color(0xFF38BDF8).withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.06),
              width: 0.5,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected ? const Color(0xFF38BDF8) : Colors.white54,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}


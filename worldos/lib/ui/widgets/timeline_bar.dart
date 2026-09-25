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
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF070B12).withValues(alpha: 0.92),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1.0)),
      ),
      child: Row(
          children: [
            // Live Stream Indicator Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5555).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFFF5555).withValues(alpha: 0.3), width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5555),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFF5555),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Live event marquee title
            Expanded(
              child: Text(
                latestEventTitle.isEmpty ? 'Listening to global C4ISR stream...' : latestEventTitle,
                style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), fontSize: 11),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),

            const SizedBox(width: 12),

            // Category Chips (Desktop)
            LayoutBuilder(
              builder: (context, constraints) {
                return MediaQuery.of(context).size.width > 900
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSegmentChip('ALL', 'All'),
                          _buildSegmentChip('EARTHQUAKE', 'Seismic'),
                          _buildSegmentChip('WEATHER', 'Weather'),
                          _buildSegmentChip('WILDFIRE', 'Thermal'),
                          _buildSegmentChip('SATELLITE', 'Orbital'),
                          const SizedBox(width: 12),
                        ],
                      )
                    : const SizedBox.shrink();
              },
            ),

            // Time Travel Readout
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: timeTravelHours == 0.0
                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: timeTravelHours == 0.0
                      ? const Color(0xFF10B981).withValues(alpha: 0.4)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
              child: Text(
                _formatTimeTravelLabel(timeTravelHours),
                style: GoogleFonts.jetBrainsMono(
                  color: timeTravelHours == 0.0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Scrubber Slider
            SizedBox(
              width: 140,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2.5,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  activeTrackColor: timeTravelHours == 0.0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  inactiveTrackColor: Colors.white24,
                  thumbColor: timeTravelHours == 0.0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                ),
                child: Slider(
                  value: timeTravelHours.clamp(-10.0, 0.0),
                  min: -10.0,
                  max: 0.0,
                  onChanged: onTimeTravelChanged,
                ),
              ),
            ),
          ],
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
              color: isSelected ? const Color(0xFF38BDF8) : Colors.white70,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeTravelLabel(double hoursVal) {
    if (hoursVal >= 0.0) return '[LIVE STREAM: NOW]';
    final absHours = hoursVal.abs();
    final h = absHours.floor();
    final m = ((absHours - h) * 60).round();
    if (h == 0) return '-${m}m AGO';
    if (m == 0) return '-${h}h AGO';
    return '-${h}h ${m}m AGO';
  }
}




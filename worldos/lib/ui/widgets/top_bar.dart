import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TopBar extends StatefulWidget {
  final TextEditingController searchController;
  final Function(String) onSearchSubmitted;
  final int liveEventCount;
  final bool isMobile;
  final VoidCallback onToggleMobileLayers;
  final VoidCallback onToggleMobileDetails;

  const TopBar({
    super.key,
    required this.searchController,
    required this.onSearchSubmitted,
    required this.liveEventCount,
    required this.isMobile,
    required this.onToggleMobileLayers,
    required this.onToggleMobileDetails,
  });

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  late Timer _clockTimer;
  String _timeUtc = '';

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  void _updateClock() {
    setState(() {
      _timeUtc = '${DateFormat('HH:mm:ss').format(DateTime.now().toUtc())} UTC';
    });
  }

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 720;

              return Row(
                children: [
                  // Brand Header
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'WORLDOS',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: isNarrow ? 13 : 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  if (!isNarrow) ...[
                    // Status Badge Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2), width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.radiowaves_right, color: Color(0xFF10B981), size: 12),
                          const SizedBox(width: 6),
                          Text(
                            '4 STREAMS ACTIVE',
                            style: GoogleFonts.jetBrainsMono(
                              color: const Color(0xFF10B981),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],

                  // Unobtrusive Search Field
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: TextField(
                        controller: widget.searchController,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: isNarrow ? 'Search...' : 'Search coordinates, regions, or telemetry events...',
                          hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                          prefixIcon: const Icon(CupertinoIcons.search, color: Colors.white38, size: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onSubmitted: widget.onSearchSubmitted,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // UTC Clock Readout
                  if (!isNarrow)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
                      ),
                      child: Text(
                        _timeUtc,
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),

                  if (widget.isMobile) ...[
                    IconButton(
                      icon: const Icon(CupertinoIcons.slider_horizontal_3, color: Color(0xFF38BDF8), size: 16),
                      onPressed: widget.onToggleMobileLayers,
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.doc_text, color: Color(0xFFF43F5E), size: 16),
                      onPressed: widget.onToggleMobileDetails,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}


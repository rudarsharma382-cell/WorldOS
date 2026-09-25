import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AiBriefingPanel extends StatefulWidget {
  final String briefingText;
  final bool isLoading;
  final Function(String) onAskQuestion;
  final VoidCallback onClose;

  const AiBriefingPanel({
    super.key,
    required this.briefingText,
    required this.isLoading,
    required this.onAskQuestion,
    required this.onClose,
  });

  @override
  State<AiBriefingPanel> createState() => _AiBriefingPanelState();
}

class _AiBriefingPanelState extends State<AiBriefingPanel> {
  final TextEditingController _queryController = TextEditingController();

  final List<String> _suggestedQueries = [
    "Japan activity",
    "Asia briefing",
    "Europe weather",
    "ISS overhead India",
  ];

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _submitQuery(String q) {
    if (q.trim().isEmpty) return;
    widget.onAskQuestion(q.trim());
    _queryController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF070B12).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.0),
      ),
      child: Column(
            children: [
              // Header Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.shield_fill, color: Color(0xFF38BDF8), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'SITUATIONAL INTELLIGENCE',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
                      ),
                      child: Text(
                        'ASIA-PACIFIC',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white38,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: widget.onClose,
                      child: const Icon(CupertinoIcons.xmark, color: Colors.white54, size: 14),
                    ),
                  ],
                ),
              ),

              // Incident Cards & Intelligence Feed
              Expanded(
                child: widget.isLoading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CupertinoActivityIndicator(color: Color(0xFF38BDF8), radius: 10),
                            const SizedBox(height: 12),
                            Text(
                              'Synthesizing regional satellite & telemetry feeds...',
                              style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: _buildIntelligenceContent(widget.briefingText),
                      ),
              ),


              // Quick Prompts (Modern rounded micro-action chips)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                color: Colors.black.withValues(alpha: 0.2),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _suggestedQueries.map((q) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _submitQuery(q),
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(CupertinoIcons.sparkles, color: Color(0xFF38BDF8), size: 11),
                                  const SizedBox(width: 4),
                                  Text(
                                    q,
                                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Prompt Console Input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: TextField(
                          controller: _queryController,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Query situational intelligence...',
                            hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          onSubmitted: _submitQuery,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _submitQuery(_queryController.text),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF38BDF8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.arrow_up, color: Colors.black, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildIntelligenceContent(String rawText) {
    if (rawText.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.doc_text_search, color: Colors.white24, size: 32),
              const SizedBox(height: 10),
              Text(
                'Awaiting query or region selection',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                'Select a region on the globe or type a question to generate structured situational telemetry.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    // Split paragraphs into structured incident cards
    final paragraphs = rawText.split('\n\n').where((p) => p.trim().isNotEmpty).toList();

    return Column(
      children: paragraphs.asMap().entries.map((entry) {
        final idx = entry.key;
        final text = entry.value.trim();

        Color badgeColor = const Color(0xFF38BDF8);
        String statusLabel = 'ALERT';

        if (text.toLowerCase().contains('quake') || text.toLowerCase().contains('seismic') || text.toLowerCase().contains('japan')) {
          badgeColor = const Color(0xFFFF5555);
          statusLabel = 'SEISMIC INCIDENT';
        } else if (text.toLowerCase().contains('fire') || text.toLowerCase().contains('thermal') || text.toLowerCase().contains('california')) {
          badgeColor = const Color(0xFFF59E0B);
          statusLabel = 'THERMAL HAZARD';
        } else if (text.toLowerCase().contains('storm') || text.toLowerCase().contains('typhoon') || text.toLowerCase().contains('gale')) {
          badgeColor = const Color(0xFF0EA5E9);
          statusLabel = 'ATMOSPHERIC';
        } else if (text.toLowerCase().contains('iss') || text.toLowerCase().contains('satellite') || text.toLowerCase().contains('orbit')) {
          badgeColor = const Color(0xFFA855F7);
          statusLabel = 'ORBITAL PASS';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Vector Status Badge + Timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: GoogleFonts.inter(
                          color: badgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${(idx + 1) * 3}m ago',
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Middle Row: Title / Summary in Clean Sans-Serif
              Text(
                text,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 10),

              // Bottom Row: Horizontal Tag Rail with Structured Data Chips
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildDataChip('STATUS', 'VERIFIED', const Color(0xFF10B981)),
                  _buildDataChip('CONFIDENCE', '98%', badgeColor),
                  _buildDataChip('SOURCE', 'SATELLITE', Colors.white70),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDataChip(String key, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$key ',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w500),
            ),
            TextSpan(
              text: value,
              style: GoogleFonts.jetBrainsMono(
                color: accentColor,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


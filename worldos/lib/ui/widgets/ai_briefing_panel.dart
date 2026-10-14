import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../services/serverpod_service.dart';
import '../../services/tactical_navigation_service.dart';
import 'ai_chat_input_widget.dart';

enum MessageSender { user, ai, system }

class ChatMessage {
  final MessageSender sender;
  final String text;
  final DateTime timestamp;
  final String model;
  final double? targetLat;
  final double? targetLon;
  final String? locationName;
  final bool isFlightCommand;
  final String? sectorName;
  final double? zoom;

  ChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
    this.model = 'Qwen 2.5 (72B)',
    this.targetLat,
    this.targetLon,
    this.locationName,
    this.isFlightCommand = false,
    this.sectorName,
    this.zoom,
  });
}

class AiBriefingPanel extends StatefulWidget {
  final String briefingText;
  final bool isLoading;
  final Function(String) onAskQuestion;
  final Function(double lat, double lon)? onFlyTo;
  final VoidCallback onClose;

  const AiBriefingPanel({
    super.key,
    required this.briefingText,
    required this.isLoading,
    required this.onAskQuestion,
    this.onFlyTo,
    required this.onClose,
  });

  @override
  State<AiBriefingPanel> createState() => _AiBriefingPanelState();
}

class _AiBriefingPanelState extends State<AiBriefingPanel> {
  final List<ChatMessage> _chatHistory = [];
  bool _isAiThinking = false;
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestedQueries = [
    "✦ Where is Hyderabad?",
    "✦ Explain recent thermal spikes",
    "✦ Taiwan geopolitical status",
    "✦ ISS overhead India",
  ];

  @override
  void initState() {
    super.initState();
    _initializeChatHistory();
  }

  @override
  void didUpdateWidget(AiBriefingPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.briefingText != oldWidget.briefingText && widget.briefingText.isNotEmpty) {
      _addSystemBriefingCard(widget.briefingText);
    }
  }

  void _initializeChatHistory() {
    if (widget.briefingText.isNotEmpty) {
      _addSystemBriefingCard(widget.briefingText);
    }
  }

  void _addSystemBriefingCard(String briefing) {
    setState(() {
      _chatHistory.add(
        ChatMessage(
          sender: MessageSender.ai,
          text: briefing,
          timestamp: DateTime.now(),
          model: 'Qwen 2.5 (72B)',
        ),
      );
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _handleUserMessage(String query, String selectedModel) async {
    final cleanQuery = query.replaceAll('✦', '').trim();
    if (cleanQuery.isEmpty) return;

    // 1. Immediately insert Operator Prompt card into chat history
    setState(() {
      _chatHistory.add(
        ChatMessage(
          sender: MessageSender.user,
          text: cleanQuery,
          timestamp: DateTime.now(),
        ),
      );
      _isAiThinking = true;
    });
    _scrollToBottom();

    // 2. Resolve coordinates instantly via TacticalNavigationService
    final navResult = await TacticalNavigationService.resolveCoordinates(cleanQuery);

    if (navResult != null) {
      final double lat = navResult['lat'];
      final double lon = navResult['lon'];
      final String displayName = navResult['displayName'];
      final double zoom = navResult['zoom'] ?? 6.0;

      // Automatically execute camera flight to that location immediately
      if (widget.onFlyTo != null) {
        widget.onFlyTo!(lat, lon);
      }

      if (mounted) {
        setState(() {
          _chatHistory.add(
            ChatMessage(
              sender: MessageSender.ai,
              text: 'FLIGHT VECTOR LOCKED // SECTOR TARGET',
              timestamp: DateTime.now(),
              model: selectedModel,
              targetLat: lat,
              targetLon: lon,
              locationName: displayName,
              isFlightCommand: true,
              sectorName: displayName,
              zoom: zoom,
            ),
          );
          _isAiThinking = false;
        });
        _scrollToBottom();
      }
      return;
    }

    // Secondary pipeline: Query backend LLM or present operational note
    try {
      final response = await ServerpodService().askWorldOS(cleanQuery);
      final locData = await _evaluateLocationIntent(cleanQuery, response);

      if (mounted) {
        setState(() {
          _chatHistory.add(
            ChatMessage(
              sender: MessageSender.ai,
              text: response,
              timestamp: DateTime.now(),
              model: selectedModel,
              targetLat: locData?['lat'],
              targetLon: locData?['lon'],
              locationName: locData?['name'],
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatHistory.add(
            ChatMessage(
              sender: MessageSender.system,
              text: "Geospatial coordinates not resolved for: '$cleanQuery'. Please specify valid sector name.",
              timestamp: DateTime.now(),
            ),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAiThinking = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<Map<String, dynamic>?> _evaluateLocationIntent(String query, String response) async {
    final q = query.toLowerCase();

    // Direct location dictionary matchers
    if (q.contains('yemen')) {
      return {'lat': 15.5527, 'lon': 48.5164, 'name': 'YEMEN'};
    } else if (q.contains('hyderabad')) {
      return {'lat': 17.3850, 'lon': 78.4867, 'name': 'HYDERABAD, INDIA'};
    } else if (q.contains('taiwan') || q.contains('taipei')) {
      return {'lat': 25.0330, 'lon': 121.5654, 'name': 'TAIPEI, TAIWAN'};
    } else if (q.contains('japan') || q.contains('tokyo')) {
      return {'lat': 35.6762, 'lon': 139.6503, 'name': 'TOKYO, JAPAN'};
    } else if (q.contains('delhi') || q.contains('india')) {
      return {'lat': 28.6139, 'lon': 77.2090, 'name': 'NEW DELHI, INDIA'};
    } else if (q.contains('london') || q.contains('uk')) {
      return {'lat': 51.5074, 'lon': -0.1278, 'name': 'LONDON, UK'};
    } else if (q.contains('california') || q.contains('san francisco')) {
      return {'lat': 37.7749, 'lon': -122.4194, 'name': 'SAN FRANCISCO, USA'};
    }

    // Dynamic Geocoding Intent Extraction via Photon API
    final locationPatterns = RegExp(
      r'(?:where is|locate|show|find|in|near|city of|region of)\s+([A-Za-z\s]{3,20})',
      caseSensitive: false,
    );
    final match = locationPatterns.firstMatch(query);
    if (match != null) {
      final placeName = match.group(1)?.trim();
      if (placeName != null && placeName.isNotEmpty) {
        try {
          final url = Uri.parse(
            'https://photon.komoot.io/api/?q=${Uri.encodeComponent(placeName)}&limit=1',
          );
          final res = await http.get(url).timeout(const Duration(seconds: 3));
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            final features = data['features'] as List?;
            if (features != null && features.isNotEmpty) {
              final geom = features.first['geometry'];
              final coords = geom['coordinates'] as List?;
              final props = features.first['properties'] as Map?;
              if (coords != null && coords.length >= 2) {
                final lon = (coords[0] as num).toDouble();
                final lat = (coords[1] as num).toDouble();
                final name = (props?['name'] ?? placeName).toString().toUpperCase();
                return {'lat': lat, 'lon': lon, 'name': name};
              }
            }
          }
        } catch (_) {}
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      margin: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xEE080D1A), // Deep translucent space navy
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x3338BDF8), width: 1.0), // Subtle icy-cyan glass border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Column(
            children: [
              // Header Bar with macOS Window Control Dots
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0x1F38BDF8), width: 0.8)),
                ),
                child: Row(
                  children: [
                    // macOS Control Dots
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFFF5F56), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                    const SizedBox(width: 14),

                    // Section Header Title
                    Expanded(
                      child: Text(
                        'SITUATIONAL INTELLIGENCE',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Model Tag Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x3338BDF8), width: 0.5),
                      ),
                      child: Text(
                        'QWEN-72B',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF38BDF8),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Sleek Circular Close Button
                    InkWell(
                      onTap: widget.onClose,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0x3338BDF8), width: 0.8),
                        ),
                        child: const Icon(CupertinoIcons.xmark, color: Color(0xFF94A3B8), size: 14),
                      ),
                    ),
                  ],
                ),
              ),

              // Conversational Intelligence Feed
              Expanded(
                child: _chatHistory.isEmpty && !_isAiThinking
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset('assets/images/worldos_logo.png', width: 40, height: 40),
                              const SizedBox(height: 14),
                              Text(
                                'WorldOS Tactical Intelligence AI',
                                style: GoogleFonts.plusJakartaSans(color: const Color(0xFFF1F5F9), fontSize: 13.5, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Enter flight vectors or query global reconnaissance telemetry. Powered by Qwen 2.5-72B.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 11.5, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        itemCount: _chatHistory.length + (_isAiThinking ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < _chatHistory.length) {
                            final msg = _chatHistory[index];
                            if (msg.sender == MessageSender.user) {
                              return _buildUserMessageCard(msg);
                            } else if (msg.sender == MessageSender.ai) {
                              return _buildAiMessageCard(msg);
                            } else {
                              return _buildSystemMessageCard(msg);
                            }
                          } else {
                            return _buildThinkingIndicatorCard();
                          }
                        },
                      ),
              ),

              // Custom Input Widget Bar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: Color(0x1F38BDF8),
                      width: 0.8,
                    ),
                  ),
                ),
                child: AiChatInputWidget(
                  suggestedQueries: _chatHistory.isEmpty ? _suggestedQueries : [],
                  onSubmit: (query, attachments, model, effort) {
                    if (query.isNotEmpty) {
                      _handleUserMessage(query, model);
                    } else if (attachments.isNotEmpty) {
                      _handleUserMessage(
                        'Analyzing ${attachments.length} intel imagery attachment(s) using $model ($effort)...',
                        model,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserMessageCard(ChatMessage msg) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, left: 32),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x3338BDF8), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'OPERATOR PROMPT',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF94A3B8),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(CupertinoIcons.person_fill, color: Color(0xFF94A3B8), size: 10),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              msg.text,
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFFF1F5F9), fontSize: 12, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiMessageCard(ChatMessage msg) {
    final timeStr =
        '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')} UTC';

    if (msg.isFlightCommand && msg.targetLat != null && msg.targetLon != null) {
      final latStr = msg.targetLat!.toStringAsFixed(4);
      final lonStr = msg.targetLon!.toStringAsFixed(4);
      final sectorName = (msg.sectorName ?? msg.locationName ?? 'TARGET SECTOR').toUpperCase();

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x3338BDF8), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF38BDF8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'FLIGHT VECTOR LOCKED // SECTOR TARGET',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF38BDF8),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  timeStr,
                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 9.5),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Inset Sector Tile
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x3338BDF8), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SECTOR CLASSIFICATION',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF64748B),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sectorName,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFFF1F5F9),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'COORDINATES',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF64748B),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$latStr° N, $lonStr° E',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF38BDF8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x3338BDF8), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF38BDF8)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'WORLDOS INTEL // ${msg.model.toUpperCase()}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF38BDF8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeStr,
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 9.5),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SelectableText(
            msg.text,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFFF1F5F9),
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessageCard(ChatMessage msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF43F5E).withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Color(0xFFF43F5E), size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg.text,
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFFF43F5E), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingIndicatorCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x3338BDF8), width: 0.8),
      ),
      child: Row(
        children: [
          const CupertinoActivityIndicator(color: Color(0xFF38BDF8), radius: 8),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'SYNTHESIZING INTELLIGENCE BRIEFING...',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF38BDF8),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

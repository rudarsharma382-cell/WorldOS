import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/env_config.dart';
import '../../models/world_event.dart';
import '../../services/nasa_service.dart';
import '../../services/flight_route_service.dart';
import '../../services/regional_briefing_service.dart';

class EventDetailPanel extends StatefulWidget {
  final WorldEvent? event;
  final NasaImageData? nasaImagery;
  final bool isImageryLoading;
  final List<Map<String, dynamic>>? cameraFeeds;
  final bool isCamerasLoading;
  final VoidCallback onClose;
  final VoidCallback onFlyToLocation;
  final VoidCallback onSaveToInvestigation;
  final VoidCallback onAskAiBriefing;

  const EventDetailPanel({
    super.key,
    required this.event,
    this.nasaImagery,
    this.isImageryLoading = false,
    this.cameraFeeds,
    this.isCamerasLoading = false,
    this.isMobile = false,
    required this.onClose,
    required this.onFlyToLocation,
    required this.onSaveToInvestigation,
    required this.onAskAiBriefing,
  });

  final bool isMobile;

  @override
  State<EventDetailPanel> createState() => _EventDetailPanelState();
}

class _EventDetailPanelState extends State<EventDetailPanel> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  String _selectedImageTab = 'SATELLITE'; // 'SATELLITE', 'GROUND', or 'CCTV'
  int _selectedCameraIndex = 0;
  final ScrollController _cctvScrollController = ScrollController();
  Timer? _timecodeTimer;
  Timer? _autoRefreshTimer;
  String _liveUtcTime = '';
  int _cacheBustTimestamp = DateTime.now().millisecondsSinceEpoch;

  String? _originTitle;
  String? _destinationTitle;

  Map<String, dynamic>? _openMeteoWeather;
  bool _isWeatherLoading = false;

  bool _isBriefingLoading = false;
  bool _showDossierView = false;
  RegionalDossier? _regionalDossier;

  Map<String, String>? _groundOpticalImage;
  bool _isGroundOpticalLoading = false;

  Future<void> _fetchGroundOpticalImageForEvent() async {
    final ev = widget.event;
    if (ev == null) return;
    if (_groundOpticalImage != null || _isGroundOpticalLoading) return;

    setState(() {
      _isGroundOpticalLoading = true;
    });

    try {
      final res = await RegionalBriefingService.fetchGroundOpticalImage(
        targetTitle: ev.title,
        locationName: ev.region ?? ev.country ?? 'Global Sector',
        countryName: ev.country ?? 'International',
      );

      if (mounted) {
        setState(() {
          _groundOpticalImage = res;
          _isGroundOpticalLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isGroundOpticalLoading = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant EventDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event != widget.event) {
      _showDossierView = false;
      _regionalDossier = null;
      _isBriefingLoading = false;
      _groundOpticalImage = null;
      _isGroundOpticalLoading = false;
      if (widget.event?.type == 'CAMERA' || widget.event?.type == 'CCTV') {
        _selectedImageTab = 'CCTV';
      }
      _selectedCameraIndex = 0;
      _resolveRouteForEvent();
      if (widget.event != null) {
        _fetchOpenMeteoWeather(widget.event!.latitude, widget.event!.longitude);
      }
      _animController.forward(from: 0.0);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.event?.type == 'CAMERA' || widget.event?.type == 'CCTV') {
      _selectedImageTab = 'CCTV';
    }

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0.2, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();

    _updateTimecode();
    _timecodeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateTimecode();
    });

    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && _selectedImageTab == 'CCTV') {
        setState(() {
          _cacheBustTimestamp = DateTime.now().millisecondsSinceEpoch;
        });
      }
    });

    _resolveRouteForEvent();
    if (widget.event != null) {
      _fetchOpenMeteoWeather(widget.event!.latitude, widget.event!.longitude);
    }
  }

  Future<void> _fetchOpenMeteoWeather(double lat, double lon) async {
    setState(() {
      _isWeatherLoading = true;
      _openMeteoWeather = null;
    });

    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,surface_pressure,wind_speed_10m,wind_direction_10m,weather_code',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _openMeteoWeather = data['current'] as Map<String, dynamic>?;
            _isWeatherLoading = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isWeatherLoading = false;
      });
    }
  }

  String _getCardinalDirection(double degrees) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    int index = (((degrees + 22.5) % 360) / 45).floor();
    return directions[index.clamp(0, 7)];
  }

  void _resolveRouteForEvent() {
    final ev = widget.event;
    if (ev == null) return;

    final typeUpper = ev.type.toUpperCase();
    if (typeUpper == 'AIRCRAFT' || typeUpper == 'FLIGHT' || typeUpper == 'AVIATION') {
      _resolveFlightRoute(ev);
    } else if (typeUpper == 'SHIP' || typeUpper == 'MARITIME' || typeUpper == 'VESSEL') {
      _resolveShipRoute(ev);
    }
  }

  Future<void> _resolveFlightRoute(WorldEvent ev) async {
    setState(() {
      _originTitle = null;
      _destinationTitle = null;
    });

    String callsign = '';
    final meta = ev.rawMetadata;
    if (meta is Map) {
      final map = meta as Map;
      if (map['callsign'] != null) {
        callsign = map['callsign'].toString().trim();
      }
    }
    if (callsign.isEmpty) {
      final match = RegExp(r'(?:Flight|AIRCRAFT)\s+([A-Z0-9]+)', caseSensitive: false).firstMatch(ev.title);
      if (match != null) {
        callsign = match.group(1) ?? '';
      }
    }
    if (callsign.isEmpty) {
      callsign = ev.externalId.replaceAll('flight_', '').replaceAll('density_flight_', '');
    }

    final country = ev.country ?? ev.region ?? 'International';
    final routeInfo = await FlightRouteService.resolveFlightRoute(
      rawCallsign: callsign,
      fallbackCountry: country,
    );

    if (mounted && widget.event?.id == ev.id) {
      setState(() {
        _originTitle = routeInfo.originTitle;
        _destinationTitle = routeInfo.destinationTitle;
      });
    }
  }

  void _resolveShipRoute(WorldEvent ev) {
    String flagCountry = ev.country ?? ev.region ?? 'Panama';
    String destinationPort = 'HIGH SEAS EN ROUTE';

    final meta = ev.rawMetadata;
    if (meta is Map) {
      final map = meta as Map;
      if (map['flag'] != null && map['flag'].toString().isNotEmpty) {
        flagCountry = map['flag'].toString();
      }
      if (map['destination'] != null && map['destination'].toString().isNotEmpty) {
        destinationPort = map['destination'].toString();
      }
    }

    if (destinationPort == 'HIGH SEAS EN ROUTE' || destinationPort.isEmpty) {
      final reg = (ev.region ?? '').toUpperCase();
      if (reg.contains('MALACCA')) {
        destinationPort = 'SINGAPORE PORT';
      } else if (reg.contains('SUEZ') || reg.contains('RED SEA')) {
        destinationPort = 'SUEZ CANAL / PORT SAID';
      } else if (reg.contains('ENGLISH') || reg.contains('ROTTERDAM')) {
        destinationPort = 'ROTTERDAM HARBOR';
      } else if (reg.contains('PANAMA') || reg.contains('CARIBBEAN')) {
        destinationPort = 'BALBOA PORT';
      } else if (reg.contains('GIBRALTAR')) {
        destinationPort = 'ALGECIRAS PORT';
      } else if (reg.contains('HORMUZ') || reg.contains('PERSIAN')) {
        destinationPort = 'JEBEL ALI PORT';
      }
    }

    if (mounted) {
      setState(() {
        _originTitle = 'Port of Registry / $flagCountry';
        _destinationTitle = destinationPort;
      });
    }
  }

  void _updateTimecode() {
    final now = DateTime.now().toUtc();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    if (mounted) {
      setState(() {
        _liveUtcTime = '$h:$m:$s UTC';
      });
    }
  }

  Future<void> _fetchRegionalBriefing() async {
    final ev = widget.event;
    if (ev == null) return;

    setState(() {
      _isBriefingLoading = true;
    });

    try {
      if (_openMeteoWeather == null) {
        await _fetchOpenMeteoWeather(ev.latitude, ev.longitude);
      }

      final dossier = await RegionalBriefingService.fetchDossier(
        lat: ev.latitude,
        lon: ev.longitude,
        weatherData: _openMeteoWeather,
        eventSeverity: ev.severity,
        eventType: ev.type,
      );

      if (mounted) {
        setState(() {
          _regionalDossier = dossier;
          _isBriefingLoading = false;
          _showDossierView = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isBriefingLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timecodeTimer?.cancel();
    _autoRefreshTimer?.cancel();
    _cctvScrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.event == null) {
      return SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Container(
            width: widget.isMobile ? null : 330,
            margin: widget.isMobile ? EdgeInsets.zero : const EdgeInsets.only(top: 16, right: 16, bottom: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xEE080D1A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x3338BDF8), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(-4, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFFF5F56), shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Icon(CupertinoIcons.scope, color: Color(0xFF38BDF8), size: 36),
                      const SizedBox(height: 12),
                      Text(
                        'NO TARGET SELECTED',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Select any point or target marker on the interactive 3D globe to inspect telemetry metrics and NASA satellite imagery.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 11.5, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_showDossierView && _regionalDossier != null) {
      return _buildTacticalRegionalDossierView(_regionalDossier!);
    }

    final ev = widget.event!;
    final typeColor = _getTypeColor(ev.type);
    final typeIcon = _getTypeIcon(ev.type);

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          width: widget.isMobile ? null : 330,
          margin: widget.isMobile ? EdgeInsets.zero : const EdgeInsets.only(top: 16, right: 16, bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xEE080D1A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x3338BDF8), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 24,
                offset: const Offset(-4, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Top macOS Window Control Dots & Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFFF5F56), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(typeIcon, color: const Color(0xFF38BDF8), size: 14),
                            const SizedBox(width: 6),
                            Text(
                              ev.type.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF64748B),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.8,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: widget.onClose,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0x3338BDF8), width: 0.8),
                            ),
                            child: const Icon(CupertinoIcons.xmark, color: Color(0xFF94A3B8), size: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Segmented Image Tab Selector [ SATELLITE ] | [ LIVE CCTV ]
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF070B12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _selectedImageTab = 'SATELLITE'),
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), bottomLeft: Radius.circular(5)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: _selectedImageTab == 'SATELLITE'
                                      ? const Color(0xFF38BDF8).withValues(alpha: 0.18)
                                      : Colors.transparent,
                                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), bottomLeft: Radius.circular(5)),
                                ),
                                child: Center(
                                  child: Text(
                                    'SATELLITE',
                                    style: GoogleFonts.jetBrainsMono(
                                      color: _selectedImageTab == 'SATELLITE' ? const Color(0xFF38BDF8) : Colors.white38,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _selectedImageTab = 'CCTV'),
                              borderRadius: const BorderRadius.only(topRight: Radius.circular(5), bottomRight: Radius.circular(5)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: _selectedImageTab == 'CCTV'
                                      ? const Color(0xFF22C55E).withValues(alpha: 0.22)
                                      : Colors.transparent,
                                  borderRadius: const BorderRadius.only(topRight: Radius.circular(5), bottomRight: Radius.circular(5)),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'LIVE CCTV',
                                        style: GoogleFonts.jetBrainsMono(
                                          color: _selectedImageTab == 'CCTV' ? const Color(0xFF22C55E) : Colors.white38,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. Media Player Frame (Satellite, Ground, or Live CCTV Intercept)
                    _selectedImageTab == 'CCTV'
                        ? _buildCctvContainer()
                        : _buildNasaImageryContainer(),

                    const SizedBox(height: 10),

                    // 2b. Tactical Route Trajectory Card (for AIRCRAFT & SHIP targets)
                    if (ev.type.toUpperCase() == 'AIRCRAFT' ||
                        ev.type.toUpperCase() == 'FLIGHT' ||
                        ev.type.toUpperCase() == 'AVIATION' ||
                        ev.type.toUpperCase() == 'SHIP' ||
                        ev.type.toUpperCase() == 'MARITIME' ||
                        ev.type.toUpperCase() == 'VESSEL') ...[
                      _buildTacticalRouteStrip(),
                      const SizedBox(height: 10),
                    ],

                    // 3. Event Title
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

                    // Freshness Status & Time Ago Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3), width: 0.5),
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

                    // 4. Normalized Telemetry Metrics (Magnitude, Confidence, Depth)
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

                    // Structured Chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildChip('MAG', ev.severity.toStringAsFixed(1), typeColor),
                        if (ev.altitude != null) _buildChip('DEPTH', '${ev.altitude!.toStringAsFixed(0)}km', Colors.white70),
                        _buildChip('AGENCY', ev.source, const Color(0xFF38BDF8)),
                        _buildChip('STATUS', 'VERIFIED', const Color(0xFF10B981)),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Divider(color: Colors.white.withValues(alpha: 0.08), height: 1, thickness: 0.5),
                    const SizedBox(height: 12),

                    // 5. Explicit Telemetry Metadata Rows
                    _buildMetadataRow('COORDINATES', '${ev.latitude >= 0 ? "${ev.latitude.toStringAsFixed(4)}° N" : "${(-ev.latitude).toStringAsFixed(4)}° S"}, ${ev.longitude >= 0 ? "${ev.longitude.toStringAsFixed(4)}° E" : "${(-ev.longitude).toStringAsFixed(4)}° W"}'),
                    if (ev.altitude != null) _buildMetadataRow('ALTITUDE / DEPTH', '${ev.altitude!.toStringAsFixed(1)} km'),
                    _buildMetadataRow('AGENCY SOURCE', ev.source),
                    _buildMetadataRow('TIMESTAMP (UTC)', '${DateFormat('HH:mm:ss').format(ev.timestamp.toUtc())} UTC'),

                    const SizedBox(height: 12),

                    // 6. Dynamic Open-Meteo Regional Atmospheric Tactical Briefing
                    _buildAtmosphericBriefingCard(),

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
                    Row(
                      children: [
                            Expanded(
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0x3338BDF8), width: 1),
                                ),
                                child: TextButton.icon(
                                  icon: _isBriefingLoading
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.8,
                                            color: Color(0xFF38BDF8),
                                          ),
                                        )
                                      : const Icon(CupertinoIcons.sparkles, color: Color(0xFFF1F5F9), size: 14),
                                  label: Text(
                                    _isBriefingLoading ? 'DOSSIER...' : 'Briefing',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFFF1F5F9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  onPressed: _isBriefingLoading ? null : _fetchRegionalBriefing,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0x3338BDF8), width: 1),
                                ),
                                child: TextButton.icon(
                                  icon: const Icon(CupertinoIcons.bookmark, color: Color(0xFFF1F5F9), size: 14),
                                  label: Text(
                                    'Save Session',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFFF1F5F9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  onPressed: widget.onSaveToInvestigation,
                                ),
                              ),
                            ),
                          ],
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNasaImageryContainer() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF030712),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image or Shimmer Skeleton Loader
              if (widget.isImageryLoading)
                _buildShimmerSkeletonLoader()
              else
                Image.network(
                  _getImageUrlForTab(),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildImageFallback(),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _buildShimmerSkeletonLoader();
                  },
                ),

              // Tactical Scanline & Crosshair Overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Scanlines
                      CustomPaint(
                        painter: _ScanlineOverlayPainter(),
                      ),
                      // Target Crosshair
                      Center(
                        child: CustomPaint(
                          size: const Size(40, 40),
                          painter: _TacticalCrosshairPainter(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Top Overlay Badge: [NASA EOSDIS / SATELLITE CAPTURE]
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C1017).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4), width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF38BDF8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.nasaImagery?.source ?? '[NASA EOSDIS / SATELLITE CAPTURE]',
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFF38BDF8),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Caption & Acquisition Date
              if (widget.nasaImagery != null)
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.nasaImagery!.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.nasaImagery!.timestamp.length > 10
                            ? widget.nasaImagery!.timestamp.substring(0, 10)
                            : widget.nasaImagery!.timestamp,
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white54,
                          fontSize: 8.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getImageUrlForTab() {
    if (widget.event == null) {
      return 'https://images.unsplash.com/photo-1614728894747-a83421e2b9c9?auto=format&fit=crop&w=1200&q=80';
    }

    final ev = widget.event!;
    if (_selectedImageTab == 'SATELLITE') {
      final fLon = ev.longitude.toStringAsFixed(4);
      final fLat = ev.latitude.toStringAsFixed(4);
      final token = EnvConfig.mapboxToken;
      if (token.isNotEmpty) {
        return 'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12/static/$fLon,$fLat,12,0/800x450@2x?access_token=$token';
      }
    }

    return widget.nasaImagery?.imageUrl ??
        'https://images.unsplash.com/photo-1614728894747-a83421e2b9c9?auto=format&fit=crop&w=1200&q=80';
  }

  Widget _buildShimmerSkeletonLoader() {
    return Container(
      color: const Color(0xFF090D14),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Color(0xFF38BDF8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '[ STREAMING NASA SATELLITE TILE... ]',
              style: GoogleFonts.jetBrainsMono(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageFallback() {
    final fallbackUrl = widget.nasaImagery?.imageUrl ?? 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800&q=80';
    return Image.network(
      fallbackUrl,
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, stack) => Image.network(
        'https://images.unsplash.com/photo-1614728894747-a83421e2b9c9?auto=format&fit=crop&w=1200&q=80',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildCctvContainer() {
    final cameras = widget.cameraFeeds ?? [];
    if (widget.isCamerasLoading) {
      return _buildCctvShimmerLoader();
    }

    if (cameras.isEmpty) {
      return _buildCctvFallback();
    }

    final currentCam = cameras[_selectedCameraIndex.clamp(0, cameras.length - 1)];
    final imageUrl = '${currentCam['fullImageUrl']}?t=$_cacheBustTimestamp';
    final lat = (currentCam['latitude'] as num?)?.toDouble() ?? (widget.event?.latitude ?? 0.0);
    final lon = (currentCam['longitude'] as num?)?.toDouble() ?? (widget.event?.longitude ?? 0.0);
    final title = currentCam['title']?.toString() ?? 'MUNICIPAL CCTV NODE';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Multi-Cam Selector Tabs with Left/Right Scroll Arrows
        if (cameras.length > 1)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            height: 26,
            child: Row(
              children: [
                // Left Arrow Button (<)
                InkWell(
                  onTap: () {
                    if (_cctvScrollController.hasClients) {
                      final targetOffset = (_cctvScrollController.offset - 90.0).clamp(0.0, _cctvScrollController.position.maxScrollExtent);
                      _cctvScrollController.animateTo(
                        targetOffset,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    }
                    if (_selectedCameraIndex > 0) {
                      setState(() => _selectedCameraIndex--);
                    }
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4), width: 0.8),
                    ),
                    child: const Icon(CupertinoIcons.chevron_left, color: Color(0xFF22C55E), size: 12),
                  ),
                ),

                // Scrollable Camera Tabs
                Expanded(
                  child: ListView.builder(
                    controller: _cctvScrollController,
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    itemCount: cameras.length,
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedCameraIndex;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => setState(() => _selectedCameraIndex = index),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF22C55E).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF22C55E) : Colors.white12,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              'CAM ${(index + 1).toString().padLeft(2, '0')}',
                              style: GoogleFonts.jetBrainsMono(
                                color: isSelected ? const Color(0xFF22C55E) : Colors.white60,
                                fontSize: 9.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Right Arrow Button (>)
                InkWell(
                  onTap: () {
                    if (_cctvScrollController.hasClients) {
                      final targetOffset = (_cctvScrollController.offset + 90.0).clamp(0.0, _cctvScrollController.position.maxScrollExtent);
                      _cctvScrollController.animateTo(
                        targetOffset,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    }
                    if (_selectedCameraIndex < cameras.length - 1) {
                      setState(() => _selectedCameraIndex++);
                    }
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4), width: 0.8),
                    ),
                    child: const Icon(CupertinoIcons.chevron_right, color: Color(0xFF22C55E), size: 12),
                  ),
                ),
              ],
            ),
          ),

        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF030712),
                border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4), width: 0.8),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => _buildCctvFallback(),
                  ),

                  // CRT Scanline Overlay
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _CctvScanlinePainter(),
                      ),
                    ),
                  ),

                  // Tactical Top Bar: REC ● 1080p // 30 FPS and Monospaced UTC Timecode
                  Positioned(
                    top: 6,
                    left: 6,
                    right: 6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF070B12).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.5), width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'REC ● 1080p // 30 FPS',
                                style: GoogleFonts.jetBrainsMono(
                                  color: const Color(0xFF22C55E),
                                  fontSize: 8.0,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF070B12).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
                          ),
                          child: Text(
                            _liveUtcTime.isEmpty ? 'LIVE UTC' : _liveUtcTime,
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.white,
                              fontSize: 8.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom-left exact coordinates & Node Title
                  Positioned(
                    bottom: 6,
                    left: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF070B12).withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3), width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'NODE: ${title.toUpperCase()}',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.jetBrainsMono(
                                color: Colors.white70,
                                fontSize: 8.0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'LAT: ${lat.toStringAsFixed(4)}° | LON: ${lon.toStringAsFixed(4)}°',
                            style: GoogleFonts.jetBrainsMono(
                              color: const Color(0xFF22C55E),
                              fontSize: 8.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCctvShimmerLoader() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF08120C),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3), width: 0.5),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Color(0xFF22C55E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '[ INITIALIZING LIVE CCTV STREAM INTERCEPT... ]',
                style: GoogleFonts.jetBrainsMono(
                  color: const Color(0xFF22C55E),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCctvFallback() {
    if (_groundOpticalImage == null && !_isGroundOpticalLoading) {
      _fetchGroundOpticalImageForEvent();
    }

    if (_isGroundOpticalLoading) {
      return _buildCctvShimmerLoader();
    }

    final imageUrl = _groundOpticalImage?['url'] ??
        RegionalBriefingService.getCuratedRegionalImage(
          widget.event?.country ?? 'Global',
          widget.event?.region ?? 'Sector',
        );

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF030712),
            border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.5), width: 0.8),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Image.network(
                  'https://images.unsplash.com/photo-1524492412937-b28074a5d7da?auto=format&fit=crop&w=1200&q=80',
                  fit: BoxFit.cover,
                ),
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return _buildCctvShimmerLoader();
                },
              ),

              // CRT Scanline Overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _CctvScanlinePainter(),
                  ),
                ),
              ),

              // Target Crosshair / Reticle Overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: CustomPaint(
                      size: const Size(40, 40),
                      painter: _TacticalCrosshairPainter(),
                    ),
                  ),
                ),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              ),

              // Header Badge: [ OPTICAL RECON ARCHIVE // GROUND INTERCEPT ]
              Positioned(
                top: 6,
                left: 6,
                right: 6,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF070B12).withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.6), width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            '[ OPTICAL RECON ARCHIVE // GROUND INTERCEPT ]',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.jetBrainsMono(
                              color: const Color(0xFF22C55E),
                              fontSize: 8.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Banner Note: "REAL-TIME WEBCAM OFFLINE // SHOWING VERIFIED GROUND IMAGERY ARCHIVE"
              Positioned(
                bottom: 6,
                left: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF070B12).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4), width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Color(0xFFF59E0B), size: 10),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'REAL-TIME WEBCAM OFFLINE // SHOWING VERIFIED GROUND IMAGERY ARCHIVE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.jetBrainsMono(
                            color: const Color(0xFFF59E0B),
                            fontSize: 8.0,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              val,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
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
      case 'AIRCRAFT': return const Color(0xFF10B981);
      case 'SHIP': return const Color(0xFF06B6D4);
      case 'CAMERA':
      case 'CCTV': return const Color(0xFF22C55E);
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
      case 'AIRCRAFT': return CupertinoIcons.airplane;
      case 'SHIP': return Icons.directions_boat_filled;
      case 'CAMERA':
      case 'CCTV': return CupertinoIcons.videocam_fill;
      default: return CupertinoIcons.info_circle_fill;
    }
  }

  Widget _buildAtmosphericBriefingCard() {
    if (_isWeatherLoading) {
      return Container(
        margin: const EdgeInsets.only(top: 8, bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF38BDF8))),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                "FETCHING ATMOSPHERIC TELEMETRY...",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    if (_openMeteoWeather == null) {
      return const SizedBox.shrink();
    }

    final temp = (_openMeteoWeather!['temperature_2m'] as num?)?.toDouble() ?? 0.0;
    final feelsLike = (_openMeteoWeather!['apparent_temperature'] as num?)?.toDouble() ?? temp;
    final humidity = (_openMeteoWeather!['relative_humidity_2m'] as num?)?.toInt() ?? 0;
    final pressure = (_openMeteoWeather!['surface_pressure'] as num?)?.toDouble() ?? 1013.25;
    final precip = (_openMeteoWeather!['precipitation'] as num?)?.toDouble() ?? 0.0;
    final windSpeed = (_openMeteoWeather!['wind_speed_10m'] as num?)?.toDouble() ?? 0.0;
    final windDirDeg = (_openMeteoWeather!['wind_direction_10m'] as num?)?.toDouble() ?? 0.0;
    final cardinal = _getCardinalDirection(windDirDeg);

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: const [
                    Icon(CupertinoIcons.thermometer_sun, color: Color(0xFF38BDF8), size: 14),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        "ATMOSPHERIC BRIEFING",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(3)),
                child: const Text("OPEN-METEO LIVE", style: TextStyle(color: Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("TEMPERATURE", style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      "${temp.toStringAsFixed(1)}°C (Feels ${feelsLike.toStringAsFixed(1)}°C)",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("SURFACE PRESSURE", style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      "${pressure.toStringAsFixed(1)} hPa",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("HUMIDITY & PRECIP", style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      "$humidity% | ${precip.toStringAsFixed(1)} mm/h",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("WIND VECTOR", style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      "${windSpeed.toStringAsFixed(1)} km/h $cardinal (${windDirDeg.toStringAsFixed(0)}°)",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getWeatherConditionText(int code) {
    switch (code) {
      case 0: return 'CLEAR SKY // STABLE';
      case 1: return 'MAINLY CLEAR';
      case 2: return 'PARTLY CLOUDY';
      case 3: return 'OVERCAST';
      case 45:
      case 48: return 'FOG & ATMOSPHERIC MIST';
      case 51:
      case 53:
      case 55: return 'LIGHT DRIZZLE';
      case 56:
      case 57: return 'FREEZING DRIZZLE';
      case 61: return 'LIGHT RAIN';
      case 63: return 'MODERATE RAIN';
      case 65: return 'HEAVY RAIN';
      case 66:
      case 67: return 'FREEZING RAIN';
      case 71: return 'LIGHT SNOW';
      case 73: return 'MODERATE SNOW';
      case 75: return 'HEAVY SNOW';
      case 77: return 'SNOW GRAINS';
      case 80:
      case 81:
      case 82: return 'RAIN SHOWERS';
      case 85:
      case 86: return 'SNOW SHOWERS';
      case 95: return 'THUNDERSTORM ACTIVITY';
      case 96:
      case 99: return 'THUNDERSTORM WITH HAIL';
      default: return 'STABLE ATMOSPHERIC FIELD';
    }
  }

  Widget _buildDossierWeatherCard(RegionalDossier dossier) {
    if (_isWeatherLoading) {
      return Container(
        margin: const EdgeInsets.only(top: 6, bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.8, color: Color(0xFF38BDF8)),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                "STREAMING OPEN-METEO TELEMETRY...",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.jetBrainsMono(
                  color: const Color(0xFF38BDF8),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final weatherMap = _openMeteoWeather;
    final temp = (weatherMap?['temperature_2m'] as num?)?.toDouble() ?? dossier.temperature ?? 22.0;
    final feelsLike = (weatherMap?['apparent_temperature'] as num?)?.toDouble() ?? temp;
    final humidity = (weatherMap?['relative_humidity_2m'] as num?)?.toInt() ?? dossier.humidity ?? 55;
    final precip = (weatherMap?['precipitation'] as num?)?.toDouble() ?? 0.0;
    final pressure = (weatherMap?['surface_pressure'] as num?)?.toDouble() ?? dossier.pressure ?? 1013.2;
    final windSpeed = (weatherMap?['wind_speed_10m'] as num?)?.toDouble() ?? dossier.windSpeed ?? 12.0;
    final windDirDeg = (weatherMap?['wind_direction_10m'] as num?)?.toDouble() ?? dossier.windDirection ?? 180.0;
    final weatherCode = (weatherMap?['weather_code'] as num?)?.toInt() ?? 0;

    final cardinal = _getCardinalDirection(windDirDeg);
    final conditionText = _getWeatherConditionText(weatherCode);

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1425),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.35), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.cloud_sun_fill, color: Color(0xFF38BDF8), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "ATMOSPHERIC & WEATHER TELEMETRY",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFF38BDF8),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4), width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "LIVE OPEN-METEO",
                      style: GoogleFonts.jetBrainsMono(
                        color: const Color(0xFF10B981),
                        fontSize: 8.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Weather Condition Tag
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white10, width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.sparkles, color: Color(0xFFF59E0B), size: 11),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "CONDITION: $conditionText",
                    style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFFF59E0B),
                      fontSize: 9.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 2x2 Grid of Weather Telemetry
          Row(
            children: [
              Expanded(
                child: _buildDossierWeatherGridCell(
                  icon: CupertinoIcons.thermometer,
                  title: 'TEMP / REAL-FEEL',
                  value: '${temp.toStringAsFixed(1)}°C',
                  subValue: 'Feels ${feelsLike.toStringAsFixed(1)}°C',
                  accentColor: const Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDossierWeatherGridCell(
                  icon: CupertinoIcons.drop_fill,
                  title: 'HUMIDITY / PRECIP',
                  value: '$humidity%',
                  subValue: '${precip.toStringAsFixed(1)} mm/h',
                  accentColor: const Color(0xFF60A5FA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDossierWeatherGridCell(
                  icon: CupertinoIcons.wind,
                  title: 'WIND VECTOR',
                  value: '${windSpeed.toStringAsFixed(1)} km/h',
                  subValue: '$cardinal (${windDirDeg.toStringAsFixed(0)}°)',
                  accentColor: const Color(0xFF34D399),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDossierWeatherGridCell(
                  icon: CupertinoIcons.gauge,
                  title: 'BAROMETRIC PRESS.',
                  value: '${pressure.toStringAsFixed(1)} hPa',
                  subValue: 'Surface Level',
                  accentColor: const Color(0xFFA78BFA),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDossierWeatherGridCell({
    required IconData icon,
    required String title,
    required String value,
    required String subValue,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 11),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: accentColor,
              fontSize: 9.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalRouteStrip() {
    final originTitle = _originTitle ?? 'RESOLVING...';
    final destinationTitle = _destinationTitle ?? 'IN-FLIGHT';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        children: [
          // Departure
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "DEPARTURE",
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  originTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          // Visual Vector Arrow
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Icon(Icons.arrow_forward, color: Color(0xFF38BDF8), size: 16),
          ),
          // Destination
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "DESTINATION",
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  destinationTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalRegionalDossierView(RegionalDossier dossier) {
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          width: widget.isMobile ? null : 330,
          margin: widget.isMobile ? EdgeInsets.zero : const EdgeInsets.only(top: 16, right: 16, bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF070B12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFF43F5E).withValues(alpha: 0.3), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.15),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TOP BACK & CLOSE BAR
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _showDossierView = false),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF43F5E).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFF43F5E).withValues(alpha: 0.4), width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.xmark, color: Color(0xFFF43F5E), size: 12),
                            const SizedBox(width: 5),
                            Text(
                              'RETURN TO TARGET VIEW',
                              style: GoogleFonts.jetBrainsMono(
                                color: const Color(0xFFF43F5E),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: widget.onClose,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.xmark, color: Colors.white60, size: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2. HEADER BLOCK
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF43F5E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '● CLASSIFIED REGIONAL DOSSIER // SECTOR [ ${dossier.latitude.toStringAsFixed(2)}°, ${dossier.longitude.toStringAsFixed(2)}° ]',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFFF43F5E),
                          fontSize: 9.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  dossier.formattedLocationHeader,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.white.withValues(alpha: 0.08), height: 1, thickness: 0.5),
                const SizedBox(height: 12),

                // SECTION 1: GEOPOLITICAL & REGIONAL CONTEXT
                _buildSectionHeader('01', 'GEOPOLITICAL & REGIONAL CONTEXT', const Color(0xFF38BDF8)),
                const SizedBox(height: 8),

                // Regional Classification Badge
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3), width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.map_pin_ellipse, color: Color(0xFF38BDF8), size: 12),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          dossier.localityType,
                          style: GoogleFonts.jetBrainsMono(
                            color: const Color(0xFF38BDF8),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Wikipedia Description Category Tag
                if (dossier.wikiDescription.isNotEmpty) ...[
                  Text(
                    dossier.wikiDescription,
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white38,
                      fontSize: 9.0,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],

                // Wikipedia Extract Body with Accent Left Bar
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.35), width: 0.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 3,
                        height: 38,
                        margin: const EdgeInsets.only(right: 8, top: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          dossier.wikiExtract,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 11.5,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                Divider(color: Colors.white.withValues(alpha: 0.08), height: 1, thickness: 0.5),
                const SizedBox(height: 12),

                // SECTION 2: ATMOSPHERIC & ENVIRONMENTAL CONDITIONS
                _buildSectionHeader('02', 'ATMOSPHERIC & ENVIRONMENTAL CONDITIONS', const Color(0xFFF59E0B)),
                const SizedBox(height: 8),

                // Open-Meteo Weather Telemetry Grid Card
                _buildDossierWeatherCard(dossier),

                const SizedBox(height: 8),

                // Solar & Lighting State Card
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3), width: 0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.sun_max_fill, color: Color(0xFFF59E0B), size: 14),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'LOCAL SOLAR TIME',
                                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    dossier.localSolarTime,
                                    style: GoogleFonts.jetBrainsMono(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4), width: 0.5),
                          ),
                          child: Text(
                            dossier.daylightStatus,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.jetBrainsMono(
                              color: const Color(0xFFF59E0B),
                              fontSize: 8.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                Divider(color: Colors.white.withValues(alpha: 0.08), height: 1, thickness: 0.5),
                const SizedBox(height: 12),

                // SECTION 3: LOCAL INFRASTRUCTURE & THREAT MATRIX
                _buildSectionHeader('03', 'LOCAL INFRASTRUCTURE & THREAT MATRIX', const Color(0xFF10B981)),
                const SizedBox(height: 8),

                // Infrastructure Scans
                _buildDossierMetricRow('NEAREST AIRPORT', dossier.nearestAirportInfo, CupertinoIcons.airplane),
                _buildDossierMetricRow('TRANSIT CORRIDOR', dossier.nearestHighwayInfo, CupertinoIcons.car_fill),
                _buildDossierMetricRow('TECTONIC MARGIN', dossier.nearestFaultLineInfo, CupertinoIcons.waveform_path_ecg),

                const SizedBox(height: 10),

                // Threat Level Badge
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: dossier.threatLevel.contains('NORMAL')
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : const Color(0xFFF43F5E).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: dossier.threatLevel.contains('NORMAL')
                          ? const Color(0xFF10B981).withValues(alpha: 0.4)
                          : const Color(0xFFF43F5E).withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        dossier.threatLevel.contains('NORMAL') ? CupertinoIcons.shield_fill : CupertinoIcons.exclamationmark_triangle_fill,
                        color: dossier.threatLevel.contains('NORMAL') ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ACTIVE SECTOR THREAT LEVEL',
                              style: GoogleFonts.inter(color: Colors.white38, fontSize: 8.5, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              dossier.threatLevel,
                              style: GoogleFonts.jetBrainsMono(
                                color: dossier.threatLevel.contains('NORMAL') ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Bottom Return Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF43F5E),
                      side: BorderSide(color: const Color(0xFFF43F5E).withValues(alpha: 0.4), width: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(CupertinoIcons.xmark, size: 14),
                    label: Text(
                      'RETURN TO TARGET VIEW',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => setState(() => _showDossierView = false),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String indexStr, String title, Color accentColor) {
    return Row(
      children: [
        Text(
          '$indexStr // ',
          style: GoogleFonts.jetBrainsMono(
            color: accentColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDossierMetricRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white38, size: 12),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 8.5, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CctvScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: 0.12)
      ..strokeWidth = 1.0;

    for (double y = 0; y < size.height; y += 3.0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanlineOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    for (double y = 0; y < size.height; y += 4.0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TacticalCrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.75)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    // Center targeting ring
    canvas.drawCircle(Offset(cx, cy), 8.0, paint);
    canvas.drawCircle(Offset(cx, cy), 1.5, Paint()..color = const Color(0xFF38BDF8)..style = PaintingStyle.fill);

    // 4 Crosshair ticks
    canvas.drawLine(Offset(cx - 16, cy), Offset(cx - 10, cy), paint);
    canvas.drawLine(Offset(cx + 10, cy), Offset(cx + 16, cy), paint);
    canvas.drawLine(Offset(cx, cy - 16), Offset(cx, cy - 10), paint);
    canvas.drawLine(Offset(cx, cy + 10), Offset(cx, cy + 16), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

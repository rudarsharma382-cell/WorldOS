import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/world_event.dart';
import '../../services/nasa_service.dart';

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
    required this.onClose,
    required this.onFlyToLocation,
    required this.onSaveToInvestigation,
    required this.onAskAiBriefing,
  });

  @override
  State<EventDetailPanel> createState() => _EventDetailPanelState();
}

class _EventDetailPanelState extends State<EventDetailPanel> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  String _selectedImageTab = 'SATELLITE'; // 'SATELLITE', 'GROUND', or 'CCTV'
  int _selectedCameraIndex = 0;
  Timer? _timecodeTimer;
  Timer? _autoRefreshTimer;
  String _liveUtcTime = '';
  int _cacheBustTimestamp = DateTime.now().millisecondsSinceEpoch;

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

  @override
  void didUpdateWidget(covariant EventDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event != widget.event) {
      if (widget.event?.type == 'CAMERA' || widget.event?.type == 'CCTV') {
        _selectedImageTab = 'CCTV';
      }
      _selectedCameraIndex = 0;
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _timecodeTimer?.cancel();
    _autoRefreshTimer?.cancel();
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
            width: 330,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF070B12).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.0),
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
                    'Select any point or target marker on the interactive 3D globe to inspect telemetry metrics and NASA satellite imagery.',
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

    final ev = widget.event!;
    final typeColor = _getTypeColor(ev.type);
    final typeIcon = _getTypeIcon(ev.type);

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          width: 330,
          decoration: BoxDecoration(
            color: const Color(0xFF070B12).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
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
                    // 1. Top Bar Header & Close Trigger
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(typeIcon, color: typeColor, size: 14),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ev.type,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: GoogleFonts.inter(
                                    color: typeColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
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
                    // Segmented Image Tab Selector [ SATELLITE ] | [ GROUND ] | [ LIVE CCTV ]
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
                                padding: const EdgeInsets.symmetric(vertical: 5),
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
                                      fontSize: 9.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _selectedImageTab = 'GROUND'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                decoration: BoxDecoration(
                                  color: _selectedImageTab == 'GROUND'
                                      ? const Color(0xFF10B981).withValues(alpha: 0.18)
                                      : Colors.transparent,
                                ),
                                child: Center(
                                  child: Text(
                                    'GROUND',
                                    style: GoogleFonts.jetBrainsMono(
                                      color: _selectedImageTab == 'GROUND' ? const Color(0xFF10B981) : Colors.white38,
                                      fontSize: 9.0,
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
                                padding: const EdgeInsets.symmetric(vertical: 5),
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
                                          fontSize: 9.0,
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

                    const SizedBox(height: 12),

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
                              backgroundColor: const Color(0xFF38BDF8).withValues(alpha: 0.14),
                              foregroundColor: const Color(0xFF38BDF8),
                              side: BorderSide(color: const Color(0xFF38BDF8).withValues(alpha: 0.4), width: 0.5),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            icon: const Icon(CupertinoIcons.location_fill, size: 14),
                            label: Text(
                              'FLY TO TARGET',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            onPressed: widget.onFlyToLocation,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF43F5E),
                              side: BorderSide(color: const Color(0xFFF43F5E).withValues(alpha: 0.35), width: 0.5),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            icon: const Icon(CupertinoIcons.sparkles, size: 14),
                            label: Text(
                              'REGIONAL BRIEFING',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            onPressed: widget.onAskAiBriefing,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF10B981),
                              side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.35), width: 0.5),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            icon: const Icon(CupertinoIcons.bookmark_fill, size: 14),
                            label: Text(
                              'SAVE TO SESSION',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            onPressed: widget.onSaveToInvestigation,
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
      final lon = ev.longitude.toStringAsFixed(4);
      final lat = ev.latitude.toStringAsFixed(4);
      const token = String.fromEnvironment('MAPBOX_TOKEN', defaultValue: 'YOUR_MAPBOX_ACCESS_TOKEN');
      return 'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12/static/$lon,$lat,12,0/800x450@2x?access_token=$token';
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
    return Container(
      color: const Color(0xFF090D14),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.satellite_alt_outlined, color: Colors.white24, size: 24),
            const SizedBox(height: 6),
            Text(
              '[ SATELLITE TILE UNAVAILABLE ]',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white38,
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
        // Multi-Cam Selector Tabs
        if (cameras.length > 1)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            height: 24,
            child: ListView.builder(
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
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF070B12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3), width: 0.5),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.videocam_fill, color: Color(0xFF22C55E), size: 24),
              const SizedBox(height: 6),
              Text(
                'PUBLIC MUNICIPAL CCTV NODE',
                style: GoogleFonts.jetBrainsMono(
                  color: const Color(0xFF22C55E),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Searching live feeds within 30km radius...',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
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

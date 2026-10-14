import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/watch_zone.dart';
import '../../models/investigation.dart';
import '../../models/world_event.dart';

/// WorldOS Command Sidebar — Precision Planetary Intelligence Operating System
class LeftSidebar extends StatefulWidget {
  final Set<String> activeLayers;
  final Function(String) onToggleLayer;
  final List<WatchZone> watchZones;
  final List<Investigation> investigations;
  final List<WorldEvent>? events;
  final VoidCallback onCreateWatchZone;
  final Function(WatchZone) onSelectWatchZone;
  final Function(Investigation) onSelectInvestigation;
  final Function(String)? onDeleteWatchZone;
  final Function(String)? onDeleteInvestigation;
  final VoidCallback? onExecuteFlightVector;
  final bool initialCollapsed;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onResetGlobe;

  const LeftSidebar({
    super.key,
    required this.activeLayers,
    required this.onToggleLayer,
    required this.watchZones,
    required this.investigations,
    this.events,
    required this.onCreateWatchZone,
    required this.onSelectWatchZone,
    required this.onSelectInvestigation,
    this.onDeleteWatchZone,
    this.onDeleteInvestigation,
    this.onExecuteFlightVector,
    this.initialCollapsed = false,
    this.onZoomIn,
    this.onZoomOut,
    this.onResetGlobe,
  });

  @override
  State<LeftSidebar> createState() => _LeftSidebarState();
}

class _LeftSidebarState extends State<LeftSidebar> {
  late bool _isCollapsed;
  bool _isDashboardExpanded = true;
  bool _isSavedSessionsExpanded = true;
  bool _showSavedPlacesFlyout = false;

  // Hover State Tracking
  String? _hoveredItemKey;

  // Color System Tokens (Refined Surface & Accent Hierarchy)
  static const Color cBaseSidebar = Color(0xFF07111F);     // Solid dark neutral surface
  static const Color cPrimaryCard = Color(0xFF0D1828);     // Primary card surface
  static const Color cCardHover = Color(0xFF132338);       // Interactive hover surface
  static const Color cNestedCard = Color(0xFF0B1524);      // Deep nested collection container
  static const Color cSubtleBorder = Color(0xFF1A3148);    // Restrained blue-gray divider/border
  static const Color cActiveBorder = Color(0xFF12B8F2);    // Active/Focused accent border
  static const Color cTextPrimary = Color(0xFFE7EDF5);     // Crisp primary typography
  static const Color cTextSecondary = Color(0xFF8796A8);   // Muted secondary typography
  static const Color cTextMuted = Color(0xFF5D6D80);       // System metadata & category labels
  static const Color cCyanAccent = Color(0xFF12B8F2);      // Restrained 5% cyan accent
  static const Color cEmeraldGreen = Color(0xFF10B981);    // System online status dot

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.initialCollapsed;
  }

  int _getLayerCount(String type) {
    if (widget.events == null || widget.events!.isEmpty) return 0;
    return widget.events!.where((e) => e.type.toUpperCase() == type.toUpperCase()).length;
  }

  @override
  Widget build(BuildContext context) {
    final double targetWidth = _isCollapsed ? 68.0 : 280.0;
    final int totalSavedCount = widget.watchZones.length + widget.investigations.length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: targetWidth,
          margin: const EdgeInsets.only(top: 16, left: 16, bottom: 16),
          decoration: BoxDecoration(
            color: cBaseSidebar,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cSubtleBorder, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.65),
                blurRadius: 20,
                offset: const Offset(4, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: _isCollapsed ? _buildCollapsedRail(totalSavedCount) : _buildExpandedSidebar(),
            ),
          ),
        ),

        // Floating Flyout Popover for Saved Places in Collapsed Rail Mode
        if (_isCollapsed && _showSavedPlacesFlyout)
          Positioned(
            left: 92,
            top: 16,
            bottom: 16,
            child: _buildSavedPlacesFlyout(),
          ),
      ],
    );
  }

  // ==========================================
  // EXPANDED SIDEBAR PANEL (Width: 280px)
  // ==========================================
  Widget _buildExpandedSidebar() {
    return Column(
      children: [
        // 1. COMMAND HEADER
        _buildHeader(),

        // 2. SCROLLABLE CONTROL BODY
        Expanded(
          child: RawScrollbar(
            thumbColor: cSubtleBorder.withValues(alpha: 0.6),
            radius: const Radius.circular(4),
            thickness: 3,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 14, right: 14, top: 14, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SECTION 1: MAIN NAVIGATION
                  _buildSectionHeader('MAIN NAVIGATION'),
                  const SizedBox(height: 10),

                  // Dashboard Tree Node
                  _buildDashboardTreeNode(),

                  const SizedBox(height: 6),
                  _buildNavItem('Airspace & Flights', 'Active Airspace', CupertinoIcons.airplane, _getLayerCount('AIRCRAFT'), 'AIRCRAFT'),
                  _buildNavItem('Maritime Fleet', 'Naval AIS Telemetry', Icons.directions_boat_filled, _getLayerCount('SHIP'), 'SHIP'),
                  _buildNavItem('Meteorological Radar', 'Radar Systems', CupertinoIcons.wind, _getLayerCount('WEATHER'), 'WEATHER'),

                  const SizedBox(height: 24),

                  // SECTION 2: SAVED SESSIONS & PLACES
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _buildSectionHeader('SAVED SESSIONS & PLACES')),
                      const SizedBox(width: 8),
                      _buildCreateZoneButton(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildSavedSessionsTree(),

                  const SizedBox(height: 24),

                  // SECTION 3: GLOBAL TELEMETRY LAYERS
                  _buildSectionHeader('GLOBAL TELEMETRY LAYERS'),
                  const SizedBox(height: 10),

                  _buildLayerControlCard('EARTHQUAKE', 'Seismic Activity', 'USGS TEL', CupertinoIcons.waveform_path_ecg, _getLayerCount('EARTHQUAKE')),
                  _buildLayerControlCard('WILDFIRE', 'Thermal Spikes & Fires', 'NASA FIRMS', CupertinoIcons.flame, _getLayerCount('WILDFIRE')),
                  _buildLayerControlCard('SATELLITE', 'Orbital Satellites', 'CELESTRAK', CupertinoIcons.radiowaves_right, _getLayerCount('SATELLITE')),
                  _buildLayerControlCard('CAMERA', 'Live CCTV Feeds', 'MUNICIPAL', CupertinoIcons.videocam_fill, _getLayerCount('CAMERA')),
                  _buildLayerControlCard('STORM', 'Extreme Weather', 'NASA EONET', CupertinoIcons.cloud_bolt, _getLayerCount('STORM')),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // HEADER
  // ==========================================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: cSubtleBorder, width: 1.0)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: cSubtleBorder, width: 1.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/worldos_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => const Icon(Icons.public, color: cCyanAccent, size: 16),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'WORLDOS COMMAND',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: cTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: cEmeraldGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'SYSTEM ONLINE',
                      style: GoogleFonts.inter(
                        color: cTextSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Collapse Chevron Trigger
          MouseRegion(
            onEnter: (_) => setState(() => _hoveredItemKey = 'collapse_btn'),
            onExit: (_) => setState(() => _hoveredItemKey = null),
            child: InkWell(
              onTap: () => setState(() {
                _isCollapsed = true;
                _showSavedPlacesFlyout = false;
              }),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: cPrimaryCard,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _hoveredItemKey == 'collapse_btn' ? const Color(0xFF25476A) : cSubtleBorder,
                    width: 0.8,
                  ),
                ),
                child: const Icon(CupertinoIcons.chevron_left, color: cTextSecondary, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION HEADER PRIMITIVE
  // ==========================================
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        color: cTextMuted,
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.8,
      ),
    );
  }

  Widget _buildCreateZoneButton() {
    final isHovered = _hoveredItemKey == 'create_zone_btn';

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredItemKey = 'create_zone_btn'),
      onExit: (_) => setState(() => _hoveredItemKey = null),
      child: InkWell(
        onTap: widget.onCreateWatchZone,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: isHovered ? cCardHover : cNestedCard,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isHovered ? cCyanAccent : cSubtleBorder,
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.add, color: cCyanAccent, size: 10),
              const SizedBox(width: 3),
              Text(
                'ZONE',
                style: GoogleFonts.inter(
                  color: cCyanAccent,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // DASHBOARD TREE NODE & CHILDREN
  // ==========================================
  Widget _buildDashboardTreeNode() {
    final isHovered = _hoveredItemKey == 'dashboard_node';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hoveredItemKey = 'dashboard_node'),
          onExit: (_) => setState(() => _hoveredItemKey = null),
          child: InkWell(
            onTap: () => setState(() => _isDashboardExpanded = !_isDashboardExpanded),
            borderRadius: BorderRadius.circular(11),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isHovered ? cCardHover : cPrimaryCard,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: isHovered ? const Color(0xFF25476A) : cSubtleBorder,
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.square_grid_2x2, color: cCyanAccent, size: 15),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Dashboard',
                      style: GoogleFonts.inter(
                        color: cTextPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _isDashboardExpanded ? CupertinoIcons.chevron_down : CupertinoIcons.chevron_right,
                    color: cTextSecondary,
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Subordinate Telemetry Rows (Clean Hierarchy from Indentation & Subtle Typography)
        if (_isDashboardExpanded) ...[
          const SizedBox(height: 4),
          _buildDashboardSubRow('Activity', '${widget.events?.length ?? 0} active', CupertinoIcons.waveform_path_ecg),
          _buildDashboardSubRow('Traffic', '${_getLayerCount('AIRCRAFT') + _getLayerCount('SHIP')} vectors', CupertinoIcons.paperplane),
          _buildDashboardSubRow('Sensors', '${_getLayerCount('CAMERA')} feeds', CupertinoIcons.videocam),
        ],
      ],
    );
  }

  Widget _buildDashboardSubRow(String label, String telemetryValue, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, top: 4, bottom: 4, right: 8),
      child: Row(
        children: [
          Icon(icon, color: cTextMuted, size: 12),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: cTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            telemetryValue,
            style: GoogleFonts.jetBrainsMono(
              color: cTextMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PRIMARY NAVIGATION CONTROL ITEM
  // ==========================================
  Widget _buildNavItem(String label, String subtext, IconData icon, int count, String key) {
    final isActive = widget.activeLayers.contains(key) || widget.activeLayers.contains('ALL');
    final isHovered = _hoveredItemKey == key;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredItemKey = key),
        onExit: (_) => setState(() => _hoveredItemKey = null),
        child: InkWell(
          onTap: () => widget.onToggleLayer(key),
          borderRadius: BorderRadius.circular(11),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? cCardHover
                  : (isHovered ? cCardHover : cPrimaryCard),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: isActive
                    ? cActiveBorder
                    : (isHovered ? const Color(0xFF25476A) : cSubtleBorder),
                width: isActive ? 1.2 : 1.0,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: cCyanAccent.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? cCyanAccent : cTextSecondary,
                  size: 15,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          color: isActive ? cTextPrimary : cTextSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtext,
                        style: GoogleFonts.inter(
                          color: cTextSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Compact Telemetry Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: cNestedCard,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: cSubtleBorder, width: 0.8),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.jetBrainsMono(
                      color: isActive ? cCyanAccent : cTextSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SAVED SESSIONS & PLACES TREE
  // ==========================================
  Widget _buildSavedSessionsTree() {
    final totalCount = widget.watchZones.length + widget.investigations.length;
    final isHovered = _hoveredItemKey == 'saved_spaces_node';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hoveredItemKey = 'saved_spaces_node'),
          onExit: (_) => setState(() => _hoveredItemKey = null),
          child: InkWell(
            onTap: () => setState(() => _isSavedSessionsExpanded = !_isSavedSessionsExpanded),
            borderRadius: BorderRadius.circular(11),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isHovered ? cCardHover : cPrimaryCard,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: isHovered ? const Color(0xFF25476A) : cSubtleBorder,
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.bookmark_fill, color: cCyanAccent, size: 15),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Saved Spaces ($totalCount)',
                      style: GoogleFonts.inter(
                        color: cTextPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _isSavedSessionsExpanded ? CupertinoIcons.chevron_down : CupertinoIcons.chevron_right,
                    color: cTextSecondary,
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
        ),

        if (_isSavedSessionsExpanded) ...[
          const SizedBox(height: 8),
          _buildSavedSessionsContent(),
        ],
      ],
    );
  }

  Widget _buildSavedSessionsContent({bool isFlyout = false}) {
    final hasZones = widget.watchZones.isNotEmpty;
    final hasInvestigations = widget.investigations.isNotEmpty;

    if (!hasZones && !hasInvestigations) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cNestedCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cSubtleBorder, width: 0.8),
        ),
        child: Column(
          children: [
            const Icon(CupertinoIcons.bookmark, color: cTextMuted, size: 18),
            const SizedBox(height: 6),
            Text(
              'No Saved Sessions or Places',
              style: GoogleFonts.inter(
                color: cTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create a Watch Zone or Save an Investigation Session on any target location to bookmark it here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: cTextMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cNestedCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cSubtleBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // WATCH ZONES SECTION
          if (hasZones) ...[
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 4),
              child: Text(
                'WATCH ZONES (${widget.watchZones.length})',
                style: GoogleFonts.inter(
                  color: cTextMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            ...widget.watchZones.asMap().entries.map((entry) {
              final idx = entry.key;
              final zone = entry.value;
              final isLast = idx == widget.watchZones.length - 1 && !hasInvestigations;
              return Column(
                children: [
                  _buildWatchZoneItemRow(zone, isFlyout: isFlyout),
                  if (!isLast) const Divider(color: cSubtleBorder, height: 1, thickness: 0.5),
                ],
              );
            }),
          ],

          if (hasZones && hasInvestigations)
            const Divider(color: cSubtleBorder, height: 1, thickness: 0.8),

          // INVESTIGATIONS SECTION
          if (hasInvestigations) ...[
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 4),
              child: Text(
                'SAVED INVESTIGATION SESSIONS (${widget.investigations.length})',
                style: GoogleFonts.inter(
                  color: cTextMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            ...widget.investigations.asMap().entries.map((entry) {
              final idx = entry.key;
              final inv = entry.value;
              final isLast = idx == widget.investigations.length - 1;
              return Column(
                children: [
                  _buildInvestigationItemRow(inv, isFlyout: isFlyout),
                  if (!isLast) const Divider(color: cSubtleBorder, height: 1, thickness: 0.5),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildWatchZoneItemRow(WatchZone zone, {bool isFlyout = false}) {
    final itemKey = 'zone_${zone.id}';
    final isHovered = _hoveredItemKey == itemKey;

    void handleSelect() {
      if (isFlyout) {
        setState(() => _showSavedPlacesFlyout = false);
      }
      widget.onSelectWatchZone(zone);
    }

    final latDir = zone.latitude >= 0 ? 'N' : 'S';
    final lonDir = zone.longitude >= 0 ? 'E' : 'W';
    final formattedCoords = '${zone.latitude.abs().toStringAsFixed(1)}° $latDir, ${zone.longitude.abs().toStringAsFixed(1)}° $lonDir · ${zone.radiusKm.toInt()} km';

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredItemKey = itemKey),
      onExit: (_) => setState(() => _hoveredItemKey = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        color: isHovered ? cCardHover : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: handleSelect,
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.scope, color: cCyanAccent, size: 13),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            zone.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: cTextPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            formattedCoords,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: cTextSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.onDeleteWatchZone != null)
              Tooltip(
                message: 'Delete Watch Zone',
                child: InkWell(
                  onTap: () => widget.onDeleteWatchZone!(zone.id),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      CupertinoIcons.trash,
                      color: isHovered ? const Color(0xFFF43F5E) : cTextMuted,
                      size: 13,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 2),
            Tooltip(
              message: 'Fly to location',
              child: InkWell(
                onTap: handleSelect,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isHovered ? cCyanAccent.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    CupertinoIcons.paperplane_fill,
                    color: isHovered ? cCyanAccent : cTextMuted,
                    size: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestigationItemRow(Investigation inv, {bool isFlyout = false}) {
    final itemKey = 'inv_${inv.id}';
    final isHovered = _hoveredItemKey == itemKey;
    final hasLoc = inv.latitude != null && inv.longitude != null;

    final latDir = (inv.latitude ?? 0) >= 0 ? 'N' : 'S';
    final lonDir = (inv.longitude ?? 0) >= 0 ? 'E' : 'W';
    final formattedCoords = hasLoc
        ? '${inv.latitude!.abs().toStringAsFixed(1)}° $latDir, ${inv.longitude!.abs().toStringAsFixed(1)}° $lonDir'
        : 'Saved Session';

    void handleSelect() {
      if (isFlyout) {
        setState(() => _showSavedPlacesFlyout = false);
      }
      widget.onSelectInvestigation(inv);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredItemKey = itemKey),
      onExit: (_) => setState(() => _hoveredItemKey = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        color: isHovered ? cCardHover : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: handleSelect,
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.bookmark_fill, color: cEmeraldGreen, size: 13),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inv.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: cTextPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            formattedCoords,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: cTextSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.onDeleteInvestigation != null)
              Tooltip(
                message: 'Delete Saved Session',
                child: InkWell(
                  onTap: () => widget.onDeleteInvestigation!(inv.id),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      CupertinoIcons.trash,
                      color: isHovered ? const Color(0xFFF43F5E) : cTextMuted,
                      size: 13,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 2),
            Tooltip(
              message: 'Fly to location',
              child: InkWell(
                onTap: handleSelect,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isHovered ? cCyanAccent.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    CupertinoIcons.paperplane_fill,
                    color: isHovered ? cCyanAccent : cTextMuted,
                    size: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // GLOBAL TELEMETRY LAYER CONTROL CARD
  // ==========================================
  Widget _buildLayerControlCard(String key, String label, String provider, IconData iconData, int count) {
    final isActive = widget.activeLayers.contains(key) || widget.activeLayers.contains('ALL');
    final isHovered = _hoveredItemKey == 'layer_$key';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredItemKey = 'layer_$key'),
        onExit: (_) => setState(() => _hoveredItemKey = null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isHovered ? cCardHover : cPrimaryCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isHovered ? const Color(0xFF25476A) : cSubtleBorder,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                iconData,
                color: isActive ? cCyanAccent : cTextSecondary,
                size: 15,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        color: isActive ? cTextPrimary : cTextSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      provider,
                      style: GoogleFonts.inter(
                        color: cTextMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.65,
                child: CupertinoSwitch(
                  value: isActive,
                  activeTrackColor: cCyanAccent,
                  inactiveTrackColor: cSubtleBorder,
                  thumbColor: Colors.white,
                  onChanged: (_) => widget.onToggleLayer(key),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // COLLAPSED RAIL MODE (Width: 68px)
  // ==========================================
  Widget _buildCollapsedRail(int totalSavedCount) {
    return Column(
      children: [
        // Header Logo & Expand Trigger
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: cSubtleBorder, width: 1.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/images/worldos_logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => const Icon(Icons.public, color: cCyanAccent, size: 16),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              MouseRegion(
                onEnter: (_) => setState(() => _hoveredItemKey = 'rail_expand'),
                onExit: (_) => setState(() => _hoveredItemKey = null),
                child: InkWell(
                  onTap: () => setState(() {
                    _isCollapsed = false;
                    _showSavedPlacesFlyout = false;
                  }),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: cPrimaryCard,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _hoveredItemKey == 'rail_expand' ? cCyanAccent : cSubtleBorder,
                        width: 0.8,
                      ),
                    ),
                    child: const Icon(CupertinoIcons.chevron_right, color: cTextSecondary, size: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: cSubtleBorder, height: 1, thickness: 1),
        const SizedBox(height: 10),

        // Rail Icon Controls
        Expanded(
          child: RawScrollbar(
            thumbColor: cSubtleBorder.withValues(alpha: 0.6),
            radius: const Radius.circular(4),
            thickness: 2,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildRailIconTile('Dashboard', CupertinoIcons.square_grid_2x2, null),
                  _buildRailIconTile('Airspace & Flights', CupertinoIcons.airplane, 'AIRCRAFT'),
                  _buildRailIconTile('Maritime Fleet', Icons.directions_boat_filled, 'SHIP'),
                  _buildRailIconTile('Telemetry Layers', CupertinoIcons.layers, 'ALL'),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Divider(color: cSubtleBorder, height: 1),
                  ),
                  _buildSavedRailIconTile(totalSavedCount),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRailIconTile(String label, IconData icon, String? layerKey) {
    final isActive = layerKey != null && (widget.activeLayers.contains(layerKey) || widget.activeLayers.contains('ALL'));
    final isHovered = _hoveredItemKey == 'rail_$label';

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredItemKey = 'rail_$label'),
      onExit: (_) => setState(() => _hoveredItemKey = null),
      child: Tooltip(
        message: label,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: InkWell(
            onTap: () {
              if (layerKey != null) {
                widget.onToggleLayer(layerKey);
              } else {
                setState(() {
                  _isCollapsed = false;
                  _showSavedPlacesFlyout = false;
                });
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isActive
                    ? cCardHover
                    : (isHovered ? cCardHover : cPrimaryCard),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive ? cActiveBorder : (isHovered ? const Color(0xFF25476A) : cSubtleBorder),
                  width: 1.0,
                ),
              ),
              child: Icon(
                icon,
                color: isActive ? cCyanAccent : cTextPrimary,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedRailIconTile(int totalSavedCount) {
    final label = 'Saved Places ($totalSavedCount)';
    final isFlyoutOpen = _showSavedPlacesFlyout;
    final isHovered = _hoveredItemKey == 'rail_saved_places';

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredItemKey = 'rail_saved_places'),
      onExit: (_) => setState(() => _hoveredItemKey = null),
      child: Tooltip(
        message: label,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: InkWell(
            onTap: () {
              setState(() {
                _showSavedPlacesFlyout = !_showSavedPlacesFlyout;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isFlyoutOpen
                        ? cCardHover
                        : (isHovered ? cCardHover : cPrimaryCard),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isFlyoutOpen ? cCyanAccent : (isHovered ? const Color(0xFF25476A) : cSubtleBorder),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.bookmark_fill,
                    color: isFlyoutOpen ? cCyanAccent : cTextPrimary,
                    size: 18,
                  ),
                ),
                if (totalSavedCount > 0)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: cCyanAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$totalSavedCount',
                        style: GoogleFonts.jetBrainsMono(
                          color: cBaseSidebar,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // FLOATING FLYOUT POPOVER (Collapsed Mode)
  // ==========================================
  Widget _buildSavedPlacesFlyout() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: cBaseSidebar,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cSubtleBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 24,
            offset: const Offset(4, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(CupertinoIcons.bookmark_fill, color: cCyanAccent, size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SAVED SESSIONS & PLACES',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: cTextPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _showSavedPlacesFlyout = false),
                    child: const Icon(CupertinoIcons.xmark_circle_fill, color: cTextMuted, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: cSubtleBorder, height: 1),
              const SizedBox(height: 10),

              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _buildSavedSessionsContent(isFlyout: true),
                ),
              ),

              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cCyanAccent,
                    side: const BorderSide(color: cSubtleBorder, width: 0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    backgroundColor: cPrimaryCard,
                  ),
                  onPressed: () {
                    setState(() => _showSavedPlacesFlyout = false);
                    widget.onCreateWatchZone();
                  },
                  icon: const Icon(CupertinoIcons.add, size: 13),
                  label: Text(
                    'CREATE NEW WATCH ZONE',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

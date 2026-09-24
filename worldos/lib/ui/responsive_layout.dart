import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/world_event.dart';
import '../services/serverpod_service.dart';
import '../globe/globe_widget.dart';
import 'widgets/top_bar.dart';
import 'widgets/layer_drawer.dart';
import 'widgets/event_detail_panel.dart';
import 'widgets/ai_briefing_panel.dart';
import 'widgets/timeline_bar.dart';
import 'widgets/watch_zone_dialog.dart';
import 'widgets/investigation_dialog.dart';

class ResponsiveWorldOSLayout extends StatefulWidget {
  const ResponsiveWorldOSLayout({super.key});

  @override
  State<ResponsiveWorldOSLayout> createState() => _ResponsiveWorldOSLayoutState();
}

class _ResponsiveWorldOSLayoutState extends State<ResponsiveWorldOSLayout> {
  final ServerpodService _serverpodService = ServerpodService();
  final TextEditingController _searchController = TextEditingController();

  // Camera State
  double _centerLat = 20.0;
  double _centerLon = 0.0;
  double _zoom = 1.0;

  // Selected State
  WorldEvent? _selectedEvent;
  final Set<String> _activeLayers = {'ALL', 'EARTHQUAKE', 'WEATHER', 'WILDFIRE', 'SATELLITE', 'STORM'};
  String _selectedCategory = 'ALL';
  double _timeTravelHours = 0.0;

  // HUD Drawer Retractable States
  bool _isLeftPanelOpen = true;
  bool _isRightPanelOpen = true;
  String _rightPanelMode = 'EVENT'; // 'EVENT' or 'AI'

  // AI State
  String _aiBriefingText = '';
  bool _isAiLoading = false;

  // Stream Subscription
  late StreamSubscription<WorldEvent> _streamSubscription;
  List<WorldEvent> _allEvents = [];
  String _latestEventMarquee = '';

  // Mobile Drawer Visibility
  bool _showMobileLayers = false;
  bool _showMobileDetails = false;

  @override
  void initState() {
    super.initState();
    _serverpodService.initialize();
    _allEvents = List.from(_serverpodService.ingestionService.events);

    _streamSubscription = _serverpodService.ingestionService.eventStream.listen((event) {
      setState(() {
        _allEvents = List.from(_serverpodService.ingestionService.events);
        _latestEventMarquee = '${event.type}: ${event.title} (${event.freshnessStatus})';
      });
    });

    _fetchAiBriefing(_centerLat, _centerLon, 'Global View');
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    _serverpodService.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;
    final q = query.toLowerCase().trim();

    if (q.contains('japan') || q.contains('tokyo')) {
      _flyTo(36.2048, 138.2529, 1.8);
      _fetchAiBriefing(36.2048, 138.2529, 'Japan');
    } else if (q.contains('india') || q.contains('delhi')) {
      _flyTo(28.6139, 77.2090, 1.8);
      _fetchAiBriefing(28.6139, 77.2090, 'India');
    } else if (q.contains('europe') || q.contains('london') || q.contains('paris')) {
      _flyTo(48.8566, 2.3522, 1.6);
      _fetchAiBriefing(48.8566, 2.3522, 'Europe');
    } else if (q.contains('california') || q.contains('usa') || q.contains('america')) {
      _flyTo(37.7749, -122.4194, 1.6);
      _fetchAiBriefing(37.7749, -122.4194, 'North America');
    } else {
      final matches = _allEvents.where((e) {
        return e.title.toLowerCase().contains(q) ||
            e.type.toLowerCase().contains(q) ||
            (e.country ?? '').toLowerCase().contains(q);
      }).toList();

      if (matches.isNotEmpty) {
        final ev = matches.first;
        _flyTo(ev.latitude, ev.longitude, 2.0);
        setState(() {
          _selectedEvent = ev;
          _isRightPanelOpen = true;
          _rightPanelMode = 'EVENT';
        });
      }
    }
  }

  void _flyTo(double lat, double lon, double zoomTarget) {
    setState(() {
      _centerLat = lat;
      _centerLon = lon;
      _zoom = zoomTarget;
    });
  }

  void _toggleLayer(String layerKey) {
    setState(() {
      if (layerKey == 'ALL') {
        if (_activeLayers.contains('ALL')) {
          _activeLayers.clear();
        } else {
          _activeLayers.addAll(['ALL', 'EARTHQUAKE', 'WEATHER', 'WILDFIRE', 'SATELLITE', 'STORM']);
        }
      } else {
        if (_activeLayers.contains(layerKey)) {
          _activeLayers.remove(layerKey);
          _activeLayers.remove('ALL');
        } else {
          _activeLayers.add(layerKey);
        }
      }
    });
  }

  Future<void> _fetchAiBriefing(double lat, double lon, [String? region]) async {
    setState(() {
      _isAiLoading = true;
      _isRightPanelOpen = true;
      _rightPanelMode = 'AI';
    });

    final res = await _serverpodService.fetchAiBriefing(
      latitude: lat,
      longitude: lon,
      radiusKm: 2500.0,
      regionName: region,
    );

    setState(() {
      _aiBriefingText = res;
      _isAiLoading = false;
    });
  }

  Future<void> _onAskAiQuestion(String query) async {
    setState(() {
      _isAiLoading = true;
      _isRightPanelOpen = true;
      _rightPanelMode = 'AI';
    });

    final res = await _serverpodService.askWorldOS(query);

    setState(() {
      _aiBriefingText = res;
      _isAiLoading = false;
    });
  }

  void _openWatchZoneModal() {
    showDialog(
      context: context,
      builder: (context) => WatchZoneDialog(
        initialLat: _centerLat,
        initialLon: _centerLon,
        onCreate: (zone) {
          setState(() {
            _serverpodService.addWatchZone(zone);
          });
        },
      ),
    );
  }

  void _openInvestigationModal(WorldEvent? ev) {
    showDialog(
      context: context,
      builder: (context) => InvestigationDialog(
        initialEvent: ev,
        onSave: (inv) {
          setState(() {
            _serverpodService.saveInvestigation(inv);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Investigation "${inv.title}" saved to workspace.', style: GoogleFonts.inter(fontSize: 12)),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        },
      ),
    );
  }

  List<WorldEvent> get _filteredEvents {
    List<WorldEvent> list = _allEvents;

    if (_selectedCategory != 'ALL') {
      list = list.where((e) => e.type == _selectedCategory).toList();
    }

    if (_timeTravelHours > 0.0) {
      final cutoff = DateTime.now().subtract(Duration(minutes: (_timeTravelHours * 60).toInt()));
      list = list.where((e) => e.timestamp.isAfter(cutoff)).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final displayEvents = _filteredEvents;

    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          return Stack(
            children: [
              // 1. Viewport First: Full-Screen Aceternity 3D Dot-Matrix Globe Engine (85%+ screen area)
              Positioned.fill(
                child: WorldOSGlobe3D(
                  markers: displayEvents.map((e) => GlobeMarker(
                    lat: e.latitude,
                    lng: e.longitude,
                    label: e.title,
                    severity: e.severity,
                    type: e.type,
                    data: e,
                  )).toList(),
                  config: const GlobeConfig(
                    atmosphereColor: Color(0xFF4DA6FF),
                    atmosphereIntensity: 0.8,
                    autoRotate: true,
                    autoRotateSpeed: 0.3,
                  ),
                  watchZones: _serverpodService.watchZones,
                  centerLat: _centerLat,
                  centerLon: _centerLon,
                  zoom: _zoom,
                  onCameraChanged: (lat, lon, z) {
                    setState(() {
                      _centerLat = lat;
                      _centerLon = lon;
                      _zoom = z;
                    });
                  },
                  onMarkerClick: (marker) {
                    final ev = marker.data as WorldEvent?;
                    setState(() {
                      _selectedEvent = ev;
                      if (ev != null) {
                        _isRightPanelOpen = true;
                        _rightPanelMode = 'EVENT';
                        if (!isDesktop) _showMobileDetails = true;
                      }
                    });
                  },
                  onLocationSelected: (lat, lon) {
                    _fetchAiBriefing(lat, lon);
                  },
                ),
              ),

              // 2. Razor-Thin Top Bar Translucent HUD Overlay
              Positioned(
                top: 10,
                left: 14,
                right: 14,
                child: TopBar(
                  searchController: _searchController,
                  onSearchSubmitted: _onSearchSubmitted,
                  liveEventCount: displayEvents.length,
                  isMobile: !isDesktop,
                  onToggleMobileLayers: () => setState(() => _showMobileLayers = !_showMobileLayers),
                  onToggleMobileDetails: () => setState(() => _showMobileDetails = !_showMobileDetails),
                ),
              ),

              // 3. Desktop Floating Translucent Left Panel (Data Layers Rail)
              if (isDesktop)
                Positioned(
                  top: 62,
                  bottom: 52,
                  left: 14,
                  child: Row(
                    children: [
                      if (_isLeftPanelOpen)
                        LayerDrawer(
                          activeLayers: _activeLayers,
                          onToggleLayer: _toggleLayer,
                          watchZones: _serverpodService.watchZones,
                          investigations: _serverpodService.investigations,
                          onCreateWatchZone: _openWatchZoneModal,
                          onSelectWatchZone: (zone) {
                            _flyTo(zone.latitude, zone.longitude, 1.8);
                          },
                          onSelectInvestigation: (inv) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Loaded investigation: ${inv.title}', style: GoogleFonts.inter(fontSize: 12)),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          },
                        ),
                      InkWell(
                        onTap: () => setState(() => _isLeftPanelOpen = !_isLeftPanelOpen),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          color: const Color(0xFF0C1017).withValues(alpha: 0.7),
                          child: Icon(
                            _isLeftPanelOpen ? Icons.chevron_left : Icons.tune,
                            color: const Color(0xFF38BDF8),
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 4. Desktop Floating Translucent Right Panel (Telemetry & AI Console)
              if (isDesktop)
                Positioned(
                  top: 62,
                  bottom: 52,
                  right: 14,
                  child: Row(
                    children: [
                      Container(
                        color: const Color(0xFF0C1017).withValues(alpha: 0.7),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.info_outline,
                                color: _rightPanelMode == 'EVENT' && _isRightPanelOpen
                                    ? const Color(0xFF38BDF8)
                                    : Colors.white38,
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (_rightPanelMode == 'EVENT' && _isRightPanelOpen) {
                                    _isRightPanelOpen = false;
                                  } else {
                                    _rightPanelMode = 'EVENT';
                                    _isRightPanelOpen = true;
                                  }
                                });
                              },
                              tooltip: 'Event Telemetry',
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.shield_outlined,
                                color: _rightPanelMode == 'AI' && _isRightPanelOpen
                                    ? const Color(0xFF38BDF8)
                                    : Colors.white38,
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (_rightPanelMode == 'AI' && _isRightPanelOpen) {
                                    _isRightPanelOpen = false;
                                  } else {
                                    _rightPanelMode = 'AI';
                                    _isRightPanelOpen = true;
                                  }
                                });
                              },
                              tooltip: 'Situational Intelligence Console',
                            ),
                          ],
                        ),
                      ),
                      if (_isRightPanelOpen)
                        _rightPanelMode == 'EVENT'
                            ? EventDetailPanel(
                                event: _selectedEvent,
                                onClose: () => setState(() => _isRightPanelOpen = false),
                                onFlyToLocation: () {
                                  if (_selectedEvent != null) {
                                    _flyTo(_selectedEvent!.latitude, _selectedEvent!.longitude, 2.2);
                                  }
                                },
                                onSaveToInvestigation: () => _openInvestigationModal(_selectedEvent),
                                onAskAiBriefing: () {
                                  if (_selectedEvent != null) {
                                    _fetchAiBriefing(_selectedEvent!.latitude, _selectedEvent!.longitude, _selectedEvent!.region);
                                  }
                                },
                              )
                            : AiBriefingPanel(
                                briefingText: _aiBriefingText,
                                isLoading: _isAiLoading,
                                onAskQuestion: _onAskAiQuestion,
                                onClose: () => setState(() => _isRightPanelOpen = false),
                              ),
                    ],
                  ),
                ),

              // 5. Mobile Collapsible Layers Drawer
              if (!isDesktop && _showMobileLayers)
                Positioned(
                  top: 55,
                  bottom: 50,
                  left: 10,
                  child: LayerDrawer(
                    activeLayers: _activeLayers,
                    onToggleLayer: _toggleLayer,
                    watchZones: _serverpodService.watchZones,
                    investigations: _serverpodService.investigations,
                    onCreateWatchZone: _openWatchZoneModal,
                    onSelectWatchZone: (zone) {
                      _flyTo(zone.latitude, zone.longitude, 1.8);
                      setState(() => _showMobileLayers = false);
                    },
                    onSelectInvestigation: (inv) {
                      setState(() => _showMobileLayers = false);
                    },
                  ),
                ),

              // 6. Mobile Collapsible Details & AI Bottom Sheet
              if (!isDesktop && _showMobileDetails)
                Positioned(
                  bottom: 45,
                  left: 10,
                  right: 10,
                  height: 360,
                  child: EventDetailPanel(
                    event: _selectedEvent,
                    onClose: () => setState(() => _showMobileDetails = false),
                    onFlyToLocation: () {
                      if (_selectedEvent != null) {
                        _flyTo(_selectedEvent!.latitude, _selectedEvent!.longitude, 2.2);
                        setState(() => _showMobileDetails = false);
                      }
                    },
                    onSaveToInvestigation: () => _openInvestigationModal(_selectedEvent),
                    onAskAiBriefing: () {
                      if (_selectedEvent != null) {
                        _fetchAiBriefing(_selectedEvent!.latitude, _selectedEvent!.longitude, _selectedEvent!.region);
                      }
                    },
                  ),
                ),

              // 7. Floating Camera Navigation Controls
              Positioned(
                bottom: 52,
                right: isDesktop && _isRightPanelOpen ? 345 : 14,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'fab_reset',
                      backgroundColor: const Color(0xFF0C1017).withValues(alpha: 0.7),
                      foregroundColor: const Color(0xFF38BDF8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
                      ),
                      child: const Icon(CupertinoIcons.globe, size: 16),
                      onPressed: () => _flyTo(20.0, 0.0, 1.0),
                    ),
                    const SizedBox(height: 4),
                    FloatingActionButton.small(
                      heroTag: 'fab_zoom_in',
                      backgroundColor: const Color(0xFF0C1017).withValues(alpha: 0.7),
                      foregroundColor: const Color(0xFF38BDF8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
                      ),
                      child: const Icon(CupertinoIcons.add, size: 16),
                      onPressed: () {
                        setState(() => _zoom = (_zoom + 0.3).clamp(0.6, 4.5));
                      },
                    ),
                    const SizedBox(height: 4),
                    FloatingActionButton.small(
                      heroTag: 'fab_zoom_out',
                      backgroundColor: const Color(0xFF0C1017).withValues(alpha: 0.7),
                      foregroundColor: const Color(0xFF38BDF8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
                      ),
                      child: const Icon(CupertinoIcons.minus, size: 16),
                      onPressed: () {
                        setState(() => _zoom = (_zoom - 0.3).clamp(0.6, 4.5));
                      },
                    ),
                  ],
                ),
              ),

              // 8. Razor-Thin Bottom Timeline Scrubber
              Positioned(
                bottom: 10,
                left: 14,
                right: 14,
                child: TimelineBar(
                  timeTravelHours: _timeTravelHours,
                  onTimeTravelChanged: (val) => setState(() => _timeTravelHours = val),
                  selectedCategory: _selectedCategory,
                  onSelectCategory: (cat) => setState(() => _selectedCategory = cat),
                  latestEventTitle: _latestEventMarquee,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

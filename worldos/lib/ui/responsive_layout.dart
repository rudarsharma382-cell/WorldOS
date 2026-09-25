import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/world_event.dart';
import '../services/serverpod_service.dart';
import '../services/nasa_service.dart';
import '../globe/globe_widget.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
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
  final GlobalKey<WorldOSGlobe3DState> _globeKey = GlobalKey<WorldOSGlobe3DState>();
  final GlobalKey<TopBarState> _topBarKey = GlobalKey<TopBarState>();
  final ServerpodService _serverpodService = ServerpodService();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchDropdownOpen = false;

  // Camera State
  double _centerLat = 10.0;
  double _centerLon = 78.9629;
  double _zoom = 2.2;

  // Selected State & NASA Imagery
  WorldEvent? _selectedEvent;
  NasaImageData? _currentNasaImagery;
  bool _isNasaLoading = false;

  final Set<String> _activeLayers = {'ALL', 'EARTHQUAKE', 'WEATHER', 'WILDFIRE', 'SATELLITE', 'STORM', 'AIRCRAFT', 'SHIP', 'CAMERA'};
  String _selectedCategory = 'ALL';
  double _timeTravelHours = 0.0;
  bool _isGlobeMinimized = false; // PIP Mini-Globe Mode

  // Tactical Camera Feeds State
  List<Map<String, dynamic>> _currentCameraFeeds = [];
  bool _isCamerasLoading = false;

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

  void _onLocationSelectedFromSearch(double lat, double lon, String name) {
    FocusScope.of(context).unfocus();
    _searchController.clear();
    _flyToTactical3DDive(lat, lon, 12.5, 55.0);
    _fetchCameraFeeds(lat, lon);
    final customEv = WorldEvent(
      id: 'target_${DateTime.now().millisecondsSinceEpoch}',
      externalId: 'target_${DateTime.now().millisecondsSinceEpoch}',
      title: name.toUpperCase(),
      type: 'TARGET',
      severity: 4.2,
      latitude: lat,
      longitude: lon,
      timestamp: DateTime.now(),
      updatedAt: DateTime.now(),
      source: 'PHOTON OSM / UNIVERSAL SEARCH',
      description: 'Geographic target selected via Photon OpenStreetMap universal geocoding search.',
      city: name,
    );
    setState(() {
      _selectedEvent = customEv;
      _isRightPanelOpen = true;
      _rightPanelMode = 'EVENT';
    });
    _fetchNasaImagery(lat, lon, name);
  }

  void _onSearchSubmitted(String query) async {
    if (query.trim().isEmpty) return;
    final results = await NasaService().searchPhotonGeocoding(query);
    if (results.isNotEmpty) {
      final first = results.first;
      _onLocationSelectedFromSearch(
        (first['latitude'] as num).toDouble(),
        (first['longitude'] as num).toDouble(),
        first['displayName']?.toString() ?? query,
      );
    }
  }

  void _flyTo(double lat, double lon, [double zoomTarget = 4.8]) {
    setState(() {
      _centerLat = lat;
      _centerLon = lon;
      _zoom = zoomTarget;
    });
    _globeKey.currentState?.flyTo(lat, lon, zoomTarget);
  }

  void _flyToTactical3DDive(double lat, double lon, [double zoomTarget = 12.5, double pitchTarget = 55.0]) {
    setState(() {
      _centerLat = lat;
      _centerLon = lon;
      _zoom = zoomTarget;
    });
    _globeKey.currentState?.flyToCoordinates(lon, lat, zoomTarget, pitchTarget);
  }

  Future<void> _fetchCameraFeeds(double lat, double lon) async {
    setState(() {
      _isCamerasLoading = true;
      _currentCameraFeeds = [];
    });

    try {
      final feeds = await _serverpodService.fetchCamerasNearby(lat, lon, radiusKm: 30);
      if (mounted) {
        setState(() {
          _currentCameraFeeds = feeds;
          _isCamerasLoading = false;

          for (final cam in feeds) {
            final camId = 'cam_${cam['id']}';
            if (!_allEvents.any((e) => e.id == camId)) {
              _allEvents.add(WorldEvent(
                id: camId,
                externalId: cam['id'].toString(),
                title: cam['title'].toString(),
                type: 'CAMERA',
                severity: 3.5,
                latitude: (cam['latitude'] as num).toDouble(),
                longitude: (cam['longitude'] as num).toDouble(),
                timestamp: DateTime.tryParse(cam['updatedAt']?.toString() ?? '') ?? DateTime.now(),
                updatedAt: DateTime.tryParse(cam['updatedAt']?.toString() ?? '') ?? DateTime.now(),
                source: 'WINDY WEBCAMS v3',
                description: 'Live municipal surveillance camera stream.',
                city: cam['title'].toString(),
              ));
            }
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isCamerasLoading = false;
        });
      }
    }
  }

  Future<void> _fetchNasaImagery(double lat, double lon, String? eventType) async {
    setState(() {
      _isNasaLoading = true;
    });

    try {
      final data = await _serverpodService.fetchSatelliteImagery(
        lat: lat,
        lon: lon,
        eventType: eventType,
      );
      if (mounted) {
        setState(() {
          _currentNasaImagery = data;
          _isNasaLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isNasaLoading = false;
        });
      }
    }
  }

  void _toggleLayer(String layerKey) {
    setState(() {
      if (layerKey == 'ALL') {
        if (_activeLayers.contains('ALL')) {
          _activeLayers.clear();
        } else {
          _activeLayers.addAll(['ALL', 'EARTHQUAKE', 'WEATHER', 'WILDFIRE', 'SATELLITE', 'STORM', 'AIRCRAFT', 'SHIP', 'CAMERA']);
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

    final isVisible = _activeLayers.contains(layerKey) || _activeLayers.contains('ALL');
    _globeKey.currentState?.setLayerVisibility(layerKey, isVisible);
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

    if (_timeTravelHours < 0.0) {
      final hoursAgo = _timeTravelHours.abs();
      final targetTime = DateTime.now().subtract(Duration(minutes: (hoursAgo * 60).toInt()));
      list = list.where((e) => e.timestamp.isBefore(targetTime.add(const Duration(hours: 1)))).toList();
    } else if (_timeTravelHours > 0.0) {
      final cutoff = DateTime.now().subtract(Duration(minutes: (_timeTravelHours * 60).toInt()));
      list = list.where((e) => e.timestamp.isAfter(cutoff)).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final displayEvents = _filteredEvents;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF020408),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          return Stack(
            children: [
              // 1. Central Workspace Expanded Dossier View (Active when Globe is Minimized)
              if (_isGlobeMinimized) _buildExpandedCentralDossierView(),

              // 2. 3D Globe Engine (Full Screen or Bottom-Left PIP 220x220 Radar Window)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                top: _isGlobeMinimized ? null : 0,
                bottom: _isGlobeMinimized ? 65 : 0,
                left: _isGlobeMinimized ? 14 : 0,
                right: _isGlobeMinimized ? null : 0,
                width: _isGlobeMinimized ? 220 : null,
                height: _isGlobeMinimized ? 220 : null,
                child: GestureDetector(
                  onTap: _isGlobeMinimized ? () => setState(() => _isGlobeMinimized = false) : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_isGlobeMinimized ? 8 : 0),
                    child: Container(
                      width: _isGlobeMinimized ? 220 : double.infinity,
                      height: _isGlobeMinimized ? 220 : double.infinity,
                      decoration: _isGlobeMinimized
                          ? BoxDecoration(
                              color: const Color(0xFF0C1017),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF38BDF8), width: 1.0),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                            )
                          : null,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: WorldOSGlobe3D(
                              key: _globeKey,
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
                                _centerLat = lat;
                                _centerLon = lon;
                                _zoom = z;
                              },
                              onFlightComplete: () {
                                setState(() {
                                  _isRightPanelOpen = true;
                                  _rightPanelMode = 'EVENT';
                                });
                              },
                              onMarkerClick: (marker) {
                                final ev = marker.data as WorldEvent?;
                                setState(() {
                                  _selectedEvent = ev;
                                  if (!isDesktop) _showMobileDetails = true;
                                });
                                _flyToTactical3DDive(marker.lat, marker.lng, 12.5, 55.0);
                                _fetchNasaImagery(marker.lat, marker.lng, marker.type);
                                _fetchCameraFeeds(marker.lat, marker.lng);
                              },
                              onLocationSelected: (lat, lon) {
                                _onLocationSelectedFromSearch(lat, lon, 'GEOGRAPHIC TARGET');
                              },
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: InkWell(
                              onTap: () => setState(() => _isGlobeMinimized = !_isGlobeMinimized),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0C1017).withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5), width: 0.8),
                                ),
                                child: Icon(
                                  _isGlobeMinimized ? Icons.open_in_full : Icons.close_fullscreen,
                                  color: const Color(0xFF38BDF8),
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                          if (_isGlobeMinimized)
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0C1017).withValues(alpha: 0.88),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFF38BDF8), width: 0.5),
                                ),
                                child: Text(
                                  'PIP RADAR // CLICK TO EXPAND',
                                  style: GoogleFonts.jetBrainsMono(
                                    color: const Color(0xFF38BDF8),
                                    fontSize: 8,
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
              ),

              // 3. Desktop Floating Translucent Left Panel (Data Layers Rail)
              if (isDesktop)
                Positioned(
                  top: 62,
                  bottom: 52,
                  left: 14,
                  child: PointerInterceptor(
                    child: Row(
                      children: [
                        if (_isLeftPanelOpen)
                          LayerDrawer(
                            activeLayers: _activeLayers,
                            onToggleLayer: _toggleLayer,
                            watchZones: _serverpodService.watchZones,
                            investigations: _serverpodService.investigations,
                            events: displayEvents,
                            onCreateWatchZone: _openWatchZoneModal,
                            onSelectWatchZone: (zone) {
                              _flyTo(zone.latitude, zone.longitude, 4.8);
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
                ),

              // 4. Desktop Floating Translucent Right Panel (Telemetry & AI Console)
              if (isDesktop)
                Positioned(
                  top: 62,
                  bottom: 52,
                  right: 14,
                  child: PointerInterceptor(
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
                                      _globeKey.currentState?.scheduleUnfreezeAutoRotation();
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
                                      _globeKey.currentState?.scheduleUnfreezeAutoRotation();
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
                                  nasaImagery: _currentNasaImagery,
                                  isImageryLoading: _isNasaLoading,
                                  cameraFeeds: _currentCameraFeeds,
                                  isCamerasLoading: _isCamerasLoading,
                                  onClose: () {
                                    setState(() => _isRightPanelOpen = false);
                                    _globeKey.currentState?.scheduleUnfreezeAutoRotation();
                                  },
                                  onFlyToLocation: () {
                                    if (_selectedEvent != null) {
                                      _flyToTactical3DDive(_selectedEvent!.latitude, _selectedEvent!.longitude, 12.5, 55.0);
                                      _fetchCameraFeeds(_selectedEvent!.latitude, _selectedEvent!.longitude);
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
                                  onClose: () {
                                    setState(() => _isRightPanelOpen = false);
                                    _globeKey.currentState?.scheduleUnfreezeAutoRotation();
                                  },
                                ),
                      ],
                    ),
                  ),
                ),

              // 5. Mobile Collapsible Layers Drawer
              if (!isDesktop && _showMobileLayers)
                Positioned(
                  top: 55,
                  bottom: 50,
                  left: 10,
                  child: PointerInterceptor(
                    child: LayerDrawer(
                      activeLayers: _activeLayers,
                      onToggleLayer: _toggleLayer,
                      watchZones: _serverpodService.watchZones,
                      investigations: _serverpodService.investigations,
                      events: displayEvents,
                      onCreateWatchZone: _openWatchZoneModal,
                      onSelectWatchZone: (zone) {
                        _flyTo(zone.latitude, zone.longitude, 4.8);
                        setState(() => _showMobileLayers = false);
                      },
                      onSelectInvestigation: (inv) {
                        setState(() => _showMobileLayers = false);
                      },
                    ),
                  ),
                ),

              // 6. Mobile Collapsible Details & AI Bottom Sheet
              if (!isDesktop && _showMobileDetails)
                Positioned(
                  bottom: 45,
                  left: 10,
                  right: 10,
                  height: 320,
                  child: PointerInterceptor(
                    child: EventDetailPanel(
                      event: _selectedEvent,
                      nasaImagery: _currentNasaImagery,
                      isImageryLoading: _isNasaLoading,
                      cameraFeeds: _currentCameraFeeds,
                      isCamerasLoading: _isCamerasLoading,
                      onClose: () {
                        setState(() => _showMobileDetails = false);
                        _globeKey.currentState?.scheduleUnfreezeAutoRotation();
                      },
                      onFlyToLocation: () {
                        if (_selectedEvent != null) {
                          _flyToTactical3DDive(_selectedEvent!.latitude, _selectedEvent!.longitude, 12.5, 55.0);
                          _fetchCameraFeeds(_selectedEvent!.latitude, _selectedEvent!.longitude);
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
                ),

              // 7. Floating Pill Navigation Dock
              _buildFloatingNavigationDock(isDesktop),

              // 8. Razor-Thin Edge-to-Edge Solid Command-Center Bottom Glass Container
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 48,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF070B12),
                    border: Border(
                      top: BorderSide(color: Color(0xFF1E293B), width: 1.0),
                    ),
                  ),
                  child: PointerInterceptor(
                    child: TimelineBar(
                      timeTravelHours: _timeTravelHours,
                      onTimeTravelChanged: (val) => setState(() => _timeTravelHours = val),
                      selectedCategory: _selectedCategory,
                      onSelectCategory: (cat) => setState(() => _selectedCategory = cat),
                      latestEventTitle: _latestEventMarquee,
                    ),
                  ),
                ),
              ),

              // Outside Click Dismiss Barrier for Search Dropdown (above panels)
              if (_isSearchDropdownOpen)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      _topBarKey.currentState?.dismissSearchDropdown();
                      FocusScope.of(context).unfocus();
                      setState(() {
                        _isSearchDropdownOpen = false;
                      });
                    },
                  ),
                ),

              // Razor-Thin Top Bar Translucent HUD Overlay (top z-index)
              Positioned(
                top: 10,
                left: 14,
                right: 14,
                child: PointerInterceptor(
                  child: TopBar(
                    key: _topBarKey,
                    searchController: _searchController,
                    onSearchSubmitted: _onSearchSubmitted,
                    onLocationSelected: (lat, lon, name) {
                      setState(() {
                        _isSearchDropdownOpen = false;
                      });
                      _onLocationSelectedFromSearch(lat, lon, name);
                    },
                    onDropdownVisibilityChanged: (isOpen) {
                      setState(() {
                        _isSearchDropdownOpen = isOpen;
                      });
                    },
                    liveEventCount: displayEvents.length,
                    isMobile: !isDesktop,
                    onToggleMobileLayers: () => setState(() => _showMobileLayers = !_showMobileLayers),
                    onToggleMobileDetails: () => setState(() => _showMobileDetails = !_showMobileDetails),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExpandedCentralDossierView() {
    final ev = _selectedEvent ?? (_filteredEvents.isNotEmpty ? _filteredEvents.first : null);
    final mapboxUrl = ev != null
        ? 'https://api.mapbox.com/styles/v1/mapbox/satellite-v9/static/${ev.longitude},${ev.latitude},14,0/800x500@2x?access_token=YOUR_MAPBOX_ACCESS_TOKEN'
        : null;

    return Positioned.fill(
      child: Container(
        padding: const EdgeInsets.only(top: 70, bottom: 65, left: 245, right: 350),
        color: const Color(0xFF020408),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0C1017),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.satellite_alt, color: Color(0xFF38BDF8), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'TACTICAL INTELLIGENCE WORKSPACE // PIP EXPANDED DOSSIER',
                    style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFF38BDF8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 16),
                    onPressed: () => setState(() => _isGlobeMinimized = false),
                    tooltip: 'Restore Fullscreen Globe',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF080C14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: mapboxUrl != null
                            ? Image.network(
                                mapboxUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.satellite_outlined, color: Colors.white24, size: 48),
                                      const SizedBox(height: 8),
                                      Text(
                                        'HIGH-RES SATELLITE FEED INITIALIZING...',
                                        style: GoogleFonts.jetBrainsMono(color: Colors.white38, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : const Center(
                                child: Text('No location target selected', style: TextStyle(color: Colors.white38)),
                              ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.cyan.withValues(alpha: 0.05),
                                Colors.transparent,
                                Colors.cyan.withValues(alpha: 0.05),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (ev != null)
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0C1017).withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ev.title.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'COORDINATES: ${ev.latitude.toStringAsFixed(4)}° N, ${ev.longitude.toStringAsFixed(4)}° E | REGION: ${(ev.region ?? "GLOBAL").toUpperCase()}',
                                  style: GoogleFonts.jetBrainsMono(
                                    color: const Color(0xFF38BDF8),
                                    fontSize: 10,
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
        ),
      ),
    );
  }

  Widget _buildFloatingNavigationDock(bool isDesktop) {
    return Positioned(
      bottom: 110,
      right: isDesktop && _isRightPanelOpen ? 360.0 : 20.0,
      child: PointerInterceptor(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E17),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF1E293B), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDockButton(
                icon: _isGlobeMinimized ? Icons.aspect_ratio : Icons.picture_in_picture_alt,
                tooltip: _isGlobeMinimized ? 'Expand Globe' : 'Minimize Globe (PIP)',
                onPressed: () => setState(() => _isGlobeMinimized = !_isGlobeMinimized),
              ),
              _buildDockButton(
                icon: CupertinoIcons.globe,
                tooltip: 'Reset to Global View',
                onPressed: () {
                  _globeKey.currentState?.resetView();
                },
              ),
              _buildDockButton(
                icon: CupertinoIcons.add,
                tooltip: 'Zoom In',
                onPressed: () {
                  _globeKey.currentState?.zoomIn();
                },
              ),
              _buildDockButton(
                icon: CupertinoIcons.minus,
                tooltip: 'Zoom Out',
                onPressed: () {
                  _globeKey.currentState?.zoomOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDockButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(20),
            hoverColor: const Color(0xFF38BDF8).withValues(alpha: 0.15),
            highlightColor: const Color(0xFF38BDF8).withValues(alpha: 0.25),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: const Color(0xFF38BDF8),
                  size: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../services/nasa_service.dart';

class TopBar extends StatefulWidget {
  final TextEditingController searchController;
  final Function(String) onSearchSubmitted;
  final Function(double lat, double lon, String name)? onLocationSelected;
  final Function(bool isOpen)? onDropdownVisibilityChanged;
  final int liveEventCount;
  final bool isMobile;
  final VoidCallback onToggleMobileLayers;
  final VoidCallback onToggleMobileDetails;

  const TopBar({
    super.key,
    required this.searchController,
    required this.onSearchSubmitted,
    this.onLocationSelected,
    this.onDropdownVisibilityChanged,
    required this.liveEventCount,
    required this.isMobile,
    required this.onToggleMobileLayers,
    required this.onToggleMobileDetails,
  });

  @override
  State<TopBar> createState() => TopBarState();
}

class TopBarState extends State<TopBar> {
  late Timer _clockTimer;
  String _timeUtc = '';

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isDropdownOpen = false;
  Timer? _debounceTimer;

  bool get isDropdownOpen => _isDropdownOpen && _searchResults.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void dismissSearchDropdown() {
    if (_searchResults.isNotEmpty || _isDropdownOpen) {
      setState(() {
        _searchResults = [];
        _isDropdownOpen = false;
      });
      widget.onDropdownVisibilityChanged?.call(false);
    }
  }

  void _updateClock() {
    setState(() {
      _timeUtc = '${DateFormat('HH:mm:ss').format(DateTime.now().toUtc())} UTC';
    });
  }

  Map<String, double>? parseCoordinates(String input) {
    final clean = input.replaceAll('°', '').trim();
    final regex = RegExp(
      r'^([+-]?\d+(?:\.\d+)?)\s*([NSEW])?[\s,;]+([+-]?\d+(?:\.\d+)?)\s*([NSEW])?$',
      caseSensitive: false,
    );
    final match = regex.firstMatch(clean);
    if (match != null) {
      double lat = double.parse(match.group(1)!);
      String? latDir = match.group(2)?.toUpperCase();
      if (latDir == 'S') lat = -lat.abs();

      double lon = double.parse(match.group(3)!);
      String? lonDir = match.group(4)?.toUpperCase();
      if (lonDir == 'W') lon = -lon.abs();

      if ((latDir == 'E' || latDir == 'W') && (lonDir == 'N' || lonDir == 'S')) {
        final tempLat = lat;
        final tempLatDir = latDir;
        lat = lon;
        latDir = lonDir;
        lon = tempLat;
        lonDir = tempLatDir;
        if (latDir == 'S') lat = -lat.abs();
        if (lonDir == 'W') lon = -lon.abs();
      }

      if (lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {
        return {'lat': lat, 'lon': lon};
      }
    }
    return null;
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    final trimmed = val.trim();
    if (trimmed.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _isDropdownOpen = false;
      });
      widget.onDropdownVisibilityChanged?.call(false);
      return;
    }

    final parsedCoords = parseCoordinates(trimmed);
    if (parsedCoords != null) {
      final lat = parsedCoords['lat']!;
      final lon = parsedCoords['lon']!;
      final targetTitle = 'Geospatial Target [${lat.toStringAsFixed(3)}°, ${lon.toStringAsFixed(3)}°]';

      final coordResult = {
        'displayName': 'FLY TO COORDINATES: ${lat.toStringAsFixed(3)}°, ${lon.toStringAsFixed(3)}°',
        'latitude': lat,
        'longitude': lon,
        'targetTitle': targetTitle,
        'isCoordinate': true,
      };

      setState(() {
        _searchResults = [coordResult];
        _isSearching = false;
        _isDropdownOpen = true;
      });
      widget.onDropdownVisibilityChanged?.call(true);

      // Fetch photon results in background to append if any
      NasaService().searchPhotonGeocoding(val).then((photonResults) {
        if (mounted && widget.searchController.text.trim() == trimmed) {
          setState(() {
            _searchResults = [coordResult, ...photonResults];
          });
        }
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isSearching = true);
      final results = await NasaService().searchPhotonGeocoding(val);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _isDropdownOpen = results.isNotEmpty;
        });
        widget.onDropdownVisibilityChanged?.call(results.isNotEmpty);
      }
    });
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    // 1. Dismiss keyboard and unfocus search field
    FocusScope.of(context).unfocus();

    final lat = (result['latitude'] as num?)?.toDouble() ?? 0.0;
    final lon = (result['longitude'] as num?)?.toDouble() ?? 0.0;
    final name = result['targetTitle']?.toString() ?? result['displayName']?.toString() ?? 'Location';

    widget.searchController.text = name;

    // 2. CLEAR and CLOSE the dropdown immediately
    setState(() {
      _searchResults = [];
      _isDropdownOpen = false;
    });

    widget.onDropdownVisibilityChanged?.call(false);

    // 3. Trigger 3D Fly-To & Update inspection panel state
    if (widget.onLocationSelected != null) {
      widget.onLocationSelected!(lat, lon, name);
    } else {
      widget.onSearchSubmitted(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final isNarrow = outerConstraints.maxWidth < 720;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF070B12).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.0),
              ),
              child: Row(
                children: [
                  // Brand Header
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/images/worldos_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'WORLDOS',
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFFF8FAFC),
                          fontSize: isNarrow ? 13 : 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),



                  // Unobtrusive Universal Search Field
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: TextField(
                        controller: widget.searchController,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: isNarrow ? 'Search Photon OSM...' : 'Search global cities, coordinates (Photon OSM), or flights...',
                          hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                          prefixIcon: _isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.2, color: Color(0xFF38BDF8))),
                                )
                              : const Icon(CupertinoIcons.search, color: Colors.white38, size: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: _onSearchChanged,
                        onSubmitted: (query) {
                          dismissSearchDropdown();
                          FocusScope.of(context).unfocus();
                          final parsedCoords = parseCoordinates(query);
                          if (parsedCoords != null) {
                            final lat = parsedCoords['lat']!;
                            final lon = parsedCoords['lon']!;
                            final targetTitle = 'Geospatial Target [${lat.toStringAsFixed(3)}°, ${lon.toStringAsFixed(3)}°]';
                            if (widget.onLocationSelected != null) {
                              widget.onLocationSelected!(lat, lon, targetTitle);
                            } else {
                              widget.onSearchSubmitted(query);
                            }
                          } else {
                            widget.onSearchSubmitted(query);
                          }
                        },
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
              ),
            ),

            // Photon OSM Autocomplete Suggestions Dropdown
            if (_searchResults.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(left: isNarrow ? 0 : 280),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500, maxHeight: 360),
                    margin: const EdgeInsets.only(top: 6),
                    child: PointerInterceptor(
                      intercepting: true,
                      child: Material(
                        color: const Color(0xFF0A0E17), // Solid opaque slate (no alpha bleed)
                        borderRadius: BorderRadius.circular(6),
                        elevation: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3), width: 0.5),
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final result = _searchResults[index];
                              final name = result['displayName']?.toString() ?? '';
                              final lat = (result['latitude'] as num?)?.toDouble() ?? 0.0;
                              final lon = (result['longitude'] as num?)?.toDouble() ?? 0.0;
                              return InkWell(
                                onTap: () {
                                  _selectSearchResult(result);
                                },
                                hoverColor: const Color(0xFF1E293B),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 16, color: Color(0xFF38BDF8)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: GoogleFonts.inter(color: const Color(0xFFF8FAFC), fontSize: 13, fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${lat.toStringAsFixed(2)}°, ${lon.toStringAsFixed(2)}°',
                                        style: GoogleFonts.jetBrainsMono(color: Colors.white38, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}


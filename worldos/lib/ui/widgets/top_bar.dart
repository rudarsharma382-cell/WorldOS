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

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    if (val.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _isDropdownOpen = false;
      });
      widget.onDropdownVisibilityChanged?.call(false);
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

    final name = result['displayName']?.toString() ?? 'Location';
    final lat = (result['latitude'] as num?)?.toDouble() ?? 0.0;
    final lon = (result['longitude'] as num?)?.toDouble() ?? 0.0;

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
                            '6 STREAMS LIVE',
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
                          widget.onSearchSubmitted(query);
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
                    constraints: const BoxConstraints(maxWidth: 500),
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


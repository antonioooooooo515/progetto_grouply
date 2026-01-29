import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:progetto_grouply/localization/app_localizations.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng _currentLocation = const LatLng(39.3290, 16.2420); //Quattromiglia
  String _address = '';
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_address.isEmpty) {
      final loc = AppLocalizations.of(context);
      _address = loc.t('touch_map');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _searchPlace() async {
    final loc = AppLocalizations.of(context);
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'com.example.grouply',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;

        if (data.isNotEmpty) {
          final firstResult = data[0];
          final lat = double.parse(firstResult['lat']);
          final lon = double.parse(firstResult['lon']);
          final displayName = firstResult['display_name'];

          final newPoint = LatLng(lat, lon);

          _mapController.move(newPoint, 15.0);

          setState(() {
            _currentLocation = newPoint;
            _address = displayName;
          });
        } else {
          _showSnack(loc.t('location_not_found_query', params: {'query': query},),);
        }
      } else {
        throw loc.t('server_error');
      }
    } catch (e) {
      _showSnack(loc.t('connection_error', params: {'query': query},),);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleTap(TapPosition tapPosition, LatLng point) async {
    final loc = AppLocalizations.of(context);
    setState(() {
      _currentLocation = point;
      _isLoading = true;
      _address = loc.t('searching_address');
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${point.latitude}&lon=${point.longitude}&format=json',
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'com.example.grouply',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        String foundAddress = data['display_name'] ?? loc.t('unknown_address');

        List<String> parts = foundAddress.split(',');
        if (parts.length > 2) {
          foundAddress = "${parts[0]}, ${parts[1]}";
        }

        setState(() {
          _address = foundAddress;
        });
      } else {
        setState(() => _address = loc.t('address_not_found'));
      }
    } catch (e) {
      setState(() => _address = loc.t('connection_error'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _searchPlace(),
            decoration: InputDecoration(
              hintText: loc.t('hint_location'),
              hintStyle: TextStyle(color: Colors.grey.shade500),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _searchPlace,
              ),
            ),
          ),
        ),
        backgroundColor: const Color(0xFFE91E63),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 13.0,
              onTap: _handleTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.grouply',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 50,
                    ),
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.map, color: Color(0xFFE91E63)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _isLoading
                            ? Text(loc.t('searching'))
                            : Text(
                          _address,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                      Navigator.of(context).pop(_address);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(loc.t('confirm_position'), style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:convert'; // Per leggere i dati JSON
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http; // Per fare le richieste internet

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng _currentLocation = const LatLng(41.9028, 12.4964); // Roma
  String _address = "Tocca la mappa o cerca un indirizzo";
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // 🔍 1. CERCA INDIRIZZO (Nominatim API)
  Future<void> _searchPlace() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      // Chiamata API gratuita a OpenStreetMap
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
      );

      // L'header User-Agent è OBBLIGATORIO per Nominatim
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
            _address = displayName; // Indirizzo completo fornito da OSM
          });
        } else {
          _showSnack("Nessun luogo trovato per '$query'");
        }
      } else {
        throw "Errore server";
      }
    } catch (e) {
      _showSnack("Errore di connessione. Controlla internet.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 📍 2. TOCCA MAPPA -> TROVA INDIRIZZO (Reverse Geocoding)
  Future<void> _handleTap(TapPosition tapPosition, LatLng point) async {
    setState(() {
      _currentLocation = point;
      _isLoading = true;
      _address = "Ricerca indirizzo...";
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

        // Nominatim restituisce un campo "display_name" molto dettagliato
        // Possiamo pulirlo prendendo solo via e città se vogliamo,
        // ma display_name è il più sicuro.
        String foundAddress = data['display_name'] ?? "Indirizzo sconosciuto";

        // Opzionale: Prendiamo solo le prime 2 parti dell'indirizzo per accorciarlo
        List<String> parts = foundAddress.split(',');
        if (parts.length > 2) {
          foundAddress = "${parts[0]}, ${parts[1]}";
        }

        setState(() {
          _address = foundAddress;
        });
      } else {
        setState(() => _address = "Indirizzo non trovato");
      }
    } catch (e) {
      setState(() => _address = "Errore connessione");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
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
              hintText: "Cerca città o via...",
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
        backgroundColor: const Color(0xFFE91E63), // Usa il tuo colore primario
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

          // PANNELLO CONFERMA
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
                            ? const Text("Ricerca in corso...")
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
                    child: const Text("CONFERMA POSIZIONE", style: TextStyle(fontWeight: FontWeight.bold)),
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
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:UzhavuSei/theme/app_theme.dart';

class LocationPickerResult {
  const LocationPickerResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  final double latitude;
  final double longitude;
  final String address;
}

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({
    super.key,
    this.initialLatLng,
    this.initialAddress,
  });

  final LatLng? initialLatLng;
  final String? initialAddress;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  static const _defaultCenter = LatLng(11.0168, 76.9558);

  late LatLng _selected;
  late final TextEditingController _addressController;
  GoogleMapController? _mapController;
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialLatLng ?? _defaultCenter;
    _addressController = TextEditingController(text: widget.initialAddress ?? '');

    if (widget.initialLatLng == null) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      final currentLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _selected = currentLatLng;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(currentLatLng, 15));
      _fetchAddress(currentLatLng);
    } catch (e) {
      // Ignore location errors
    }
  }

  Future<void> _fetchAddress(LatLng position) async {
    if (!mounted) return;
    setState(() => _isLoadingAddress = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
        
        if (mounted) {
          setState(() {
            _addressController.text = address;
          });
        }
      }
    } catch (e) {
      // Ignore geocoding errors
    } finally {
      if (mounted) {
        setState(() => _isLoadingAddress = false);
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: _selected, zoom: 12),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (controller) => _mapController = controller,
              markers: {
                Marker(
                  markerId: const MarkerId('selected'),
                  position: _selected,
                ),
              },
              onTap: (latLng) {
                setState(() {
                  _selected = latLng;
                });
                _fetchAddress(latLng);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    border: const OutlineInputBorder(),
                    suffixIcon: _isLoadingAddress
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        LocationPickerResult(
                          latitude: _selected.latitude,
                          longitude: _selected.longitude,
                          address: _addressController.text.trim().isEmpty
                              ? '${_selected.latitude.toStringAsFixed(5)}, ${_selected.longitude.toStringAsFixed(5)}'
                              : _addressController.text.trim(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Use This Location'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class Rideshare extends StatefulWidget {
  const Rideshare({super.key});

  @override
  State<Rideshare> createState() => _RideshareState();
}

class _RideshareState extends State<Rideshare> {
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();
  final TextEditingController driverNameController = TextEditingController();
  final TextEditingController carModelController = TextEditingController();
  final TextEditingController carNumberController = TextEditingController();
  final TextEditingController vehicleTypeController = TextEditingController();

  bool _isLoading = false;

  String? get _driverId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _pickLocation(TextEditingController controller) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationPickerMap(),
      ),
    );

    if (result != null && result['address'] != null) {
      setState(() {
        controller.text = result['address'];
      });
    }
  }

  Future<void> _saveSharedRide() async {
    if (fromController.text.isEmpty ||
        toController.text.isEmpty ||
        driverNameController.text.isEmpty ||
        carModelController.text.isEmpty ||
        carNumberController.text.isEmpty ||
        vehicleTypeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_driverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in as a driver'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      String docId = DateTime.now().microsecondsSinceEpoch.toString();

      await FirebaseFirestore.instance
          .collection('shared_rides')
          .doc(docId)
          .set({
        'uid': docId,
        'userId': user.uid,
        'userEmail': user.email ?? 'unknown',
        'fromAddress': fromController.text.trim(),
        'toAddress': toController.text.trim(),
        'driverName': driverNameController.text.trim(),
        'carModel': carModelController.text.trim(),
        'carNumber': carNumberController.text.trim(),
        'vehicleType': vehicleTypeController.text.trim(),
        'driverId': user.uid,  // auto‑filled from Firebase Auth
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Ride shared successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      fromController.clear();
      toController.clear();
      driverNameController.clear();
      carModelController.clear();
      carNumberController.clear();
      vehicleTypeController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to share ride: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Ride'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: fromController,
              decoration: InputDecoration(
                labelText: 'From Location',
                prefixIcon: const Icon(Icons.my_location),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map, color: Colors.blue),
                  onPressed: () => _pickLocation(fromController),
                  tooltip: 'Pick from map',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: toController,
              decoration: InputDecoration(
                labelText: 'To Location',
                prefixIcon: const Icon(Icons.location_on),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map, color: Colors.blue),
                  onPressed: () => _pickLocation(toController),
                  tooltip: 'Pick from map',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: driverNameController,
              decoration: const InputDecoration(
                labelText: 'Driver Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: carModelController,
              decoration: const InputDecoration(
                labelText: 'Car Model',
                prefixIcon: Icon(Icons.directions_car),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: carNumberController,
              decoration: const InputDecoration(
                labelText: 'Car Number',
                prefixIcon: Icon(Icons.confirmation_number),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: vehicleTypeController,
              decoration: const InputDecoration(
                labelText: 'Vehicle Type',
                prefixIcon: Icon(Icons.car_rental),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSharedRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Share Ride',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// LocationPickerMap class – unchanged, keep as is
class LocationPickerMap extends StatefulWidget {
  const LocationPickerMap({super.key});

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  final MapController _mapController = MapController();
  LatLng _selectedLocation = const LatLng(28.6139, 77.2090);
  String _selectedAddress = '';

  @override
  void initState() {
    super.initState();
    _getAddressFromCoordinates(_selectedLocation);
  }

  Future<void> _getAddressFromCoordinates(LatLng point) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        String address = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
        ].where((part) => part != null && part.isNotEmpty).join(', ');
        setState(() {
          _selectedAddress = address;
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = 'Location selected (${point.latitude}, ${point.longitude})';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              if (_selectedAddress.isNotEmpty) {
                Navigator.pop(context, {
                  'address': _selectedAddress,
                  'lat': _selectedLocation.latitude,
                  'lng': _selectedLocation.longitude,
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a location first'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 14,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                });
                _getAddressFromCoordinates(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.eduride',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 50,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Location',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedAddress.isNotEmpty
                        ? _selectedAddress
                        : 'Tap on map to select',
                    style: TextStyle(
                      fontSize: 14,
                      color: _selectedAddress.isNotEmpty
                          ? Colors.black87
                          : Colors.grey,
                    ),
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
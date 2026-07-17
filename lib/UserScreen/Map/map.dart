// Only the changed parts of map.dart are shown below for brevity.
// But here is the complete updated map.dart file (replace yours with this):

// ============= FULL map.dart (with new booking flow) =============

import 'dart:async';
import 'package:eduride/UserScreen/DriverList/DriversList.dart';
import 'package:eduride/UserScreen/RideRequestStatus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

  double rideDistance = 0;
  double rideFare = 0;

  LatLng _currentLocation = const LatLng(30.3782, 76.7767);
  LatLng _pickupLocation = const LatLng(30.3782, 76.7767);
  bool _loading = true;
  StreamSubscription<Position>? _positionSubscription;
  LatLng? destinationLocation;
  List<LatLng> routePoints = [];
  List<LatLng> polygonPoints = [];
  bool isDrawingPolygon = false;

  String apiKey =
      "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImYxZjVhMGJjOTg4MDRjNjg5MjExNDQ0MDFjZjA4YWE3IiwiaCI6Im11cm11cjY0In0=";

  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();

  String? _selectedRideType;
  final List<String> _rideTypes = ['Standard', 'Premium', 'Shared'];

  final List<String> _savedLocations = ['Home', 'Work', 'School', 'Gym'];

  Map<String, dynamic>? _selectedDriver;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getLocation();
    });
  }

  // -------------------- LOCATION / PERMISSIONS (unchanged) --------------------
  Future<void> getCurrentAddress() async {
    try {
      List<Placemark> place = await placemarkFromCoordinates(
        _pickupLocation.latitude,
        _pickupLocation.longitude,
      );
      fromController.text =
      "${place.first.street}, ${place.first.locality}";
    } catch (e) {
      fromController.text = "Current Location";
    }
  }

  Future<void> getLocation() async {
    if (mounted) setState(() => _loading = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enable location services.")),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission permanently denied.")),
        );
      }
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    _currentLocation = LatLng(position.latitude, position.longitude);
    _pickupLocation = _currentLocation;
    await getCurrentAddress();

    if (mounted) {
      setState(() => _loading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_currentLocation, 16);
      });
    }

    await _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      _currentLocation = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {});
      _mapController.move(_currentLocation, _mapController.camera.zoom);
    });
  }

  // -------------------- MAP TAP / DESTINATION (unchanged) --------------------
  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      destinationLocation = point;
      routePoints.clear();
      polygonPoints.clear();
      isDrawingPolygon = false;
      _selectedRideType = null;
      _selectedDriver = null;
      _getAddressFromCoordinates(point);
      _mapController.move(point, 15);
    });
  }

  Future<void> _getAddressFromCoordinates(LatLng point) async {
    try {
      List<Placemark> place = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      toController.text = "${place.first.street}, ${place.first.locality}";
      await getRoute(_pickupLocation, point);
      _calculateFare();
    } catch (e) {
      toController.text = "Selected Location";
      await getRoute(_pickupLocation, point);
      _calculateFare();
    }
  }

  // -------------------- FARE CALCULATION (unchanged) --------------------
  void _calculateFare() {
    if (routePoints.length < 2 && rideDistance == 0) {
      setState(() {
        rideDistance = 0;
        rideFare = 20;
      });
      return;
    }
    if (routePoints.length < 2) return;
    double distanceInKm = 0;
    for (int i = 0; i < routePoints.length - 1; i++) {
      distanceInKm += _calculateDistance(routePoints[i], routePoints[i + 1]);
    }
    double fare = 20;
    if (distanceInKm <= 5) {
      fare += distanceInKm * 10;
    } else {
      fare += (5 * 10) + ((distanceInKm - 5) * 8);
    }
    setState(() {
      rideDistance = distanceInKm;
      rideFare = fare.roundToDouble();
    });
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const double earthRadius = 6371;
    double dLat = _degToRad(p2.latitude - p1.latitude);
    double dLon = _degToRad(p2.longitude - p1.longitude);
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(p1.latitude)) *
            math.cos(_degToRad(p2.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * math.pi / 180;

  // -------------------- POLYGON (unchanged) --------------------
  void _togglePolygonMode() {
    setState(() {
      isDrawingPolygon = !isDrawingPolygon;
      if (!isDrawingPolygon && polygonPoints.isNotEmpty) {
        polygonPoints.add(polygonPoints.first);
      }
    });
  }

  void _addPolygonPoint(TapPosition tapPosition, LatLng point) {
    if (isDrawingPolygon) {
      setState(() => polygonPoints.add(point));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Polygon point added: ${polygonPoints.length} points")),
      );
    }
  }

  void _clearPolygon() {
    setState(() {
      polygonPoints.clear();
      isDrawingPolygon = false;
    });
  }

  // -------------------- SEARCH PICKUP (unchanged) --------------------
  Future<void> searchPickup() async {
    final query = fromController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter pickup location")),
      );
      return;
    }

    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/search?"
          "q=${Uri.encodeComponent(query)}"
          "&format=json"
          "&limit=5"
          "&countrycodes=in"
          "&viewbox=${_currentLocation.longitude - 0.1},${_currentLocation.latitude - 0.1},${_currentLocation.longitude + 0.1},${_currentLocation.latitude + 0.1}"
          "&bounded=1",
    );

    try {
      final response = await http.get(url, headers: {"User-Agent": "EduRide"});
      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Search failed (${response.statusCode})")),
        );
        return;
      }

      final data = jsonDecode(response.body);
      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location not found")),
        );
        return;
      }

      if (data.length > 1) {
        _showPickupSelectionDialog(data);
      } else {
        _selectPickup(data[0]);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error searching: $e")),
      );
    }
  }

  void _showPickupSelectionDialog(List results) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select pickup location'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (ctx, i) {
              final place = results[i];
              return ListTile(
                title: Text(place['display_name'] ?? 'Unnamed'),
                onTap: () {
                  Navigator.pop(ctx);
                  _selectPickup(place);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _selectPickup(Map<String, dynamic> place) {
    final lat = double.parse(place["lat"]);
    final lon = double.parse(place["lon"]);
    final displayName = place['display_name'] ?? 'Selected Location';

    setState(() {
      _pickupLocation = LatLng(lat, lon);
      fromController.text = displayName;
    });

    if (destinationLocation != null) {
      getRoute(_pickupLocation, destinationLocation!).then((_) {
        _calculateFare();
        _mapController.move(_pickupLocation, 15);
      });
    } else {
      _mapController.move(_pickupLocation, 15);
    }
  }

  void _resetPickupToCurrent() {
    setState(() {
      _pickupLocation = _currentLocation;
      fromController.text = "Current Location";
    });
    getCurrentAddress();
    if (destinationLocation != null) {
      getRoute(_pickupLocation, destinationLocation!).then((_) {
        _calculateFare();
        _mapController.move(_pickupLocation, 15);
      });
    } else {
      _mapController.move(_pickupLocation, 15);
    }
  }

  // -------------------- SEARCH DESTINATION (unchanged) --------------------
  Future<void> searchPlace({String? query}) async {
    final searchQuery = query ?? toController.text.trim();
    if (searchQuery.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter destination")),
      );
      return;
    }

    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/search?"
          "q=${Uri.encodeComponent(searchQuery)}"
          "&format=json"
          "&limit=5"
          "&countrycodes=in"
          "&viewbox=${_currentLocation.longitude - 0.1},${_currentLocation.latitude - 0.1},${_currentLocation.longitude + 0.1},${_currentLocation.latitude + 0.1}"
          "&bounded=1",
    );

    try {
      final response = await http.get(url, headers: {"User-Agent": "EduRide"});
      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Search failed (${response.statusCode})")),
        );
        return;
      }

      final data = jsonDecode(response.body);
      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location not found")),
        );
        return;
      }

      if (data.length > 1) {
        _showLocationSelectionDialog(data);
      } else {
        _selectLocation(data[0]);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error searching: $e")),
      );
    }
  }

  void _showLocationSelectionDialog(List results) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select a location'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (ctx, i) {
              final place = results[i];
              return ListTile(
                title: Text(place['display_name'] ?? 'Unnamed'),
                onTap: () {
                  Navigator.pop(ctx);
                  _selectLocation(place);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _selectLocation(Map<String, dynamic> place) {
    final lat = double.parse(place["lat"]);
    final lon = double.parse(place["lon"]);
    final displayName = place['display_name'] ?? 'Selected Location';

    setState(() {
      destinationLocation = LatLng(lat, lon);
      toController.text = displayName;
      polygonPoints.clear();
      isDrawingPolygon = false;
      _selectedRideType = null;
      _selectedDriver = null;
    });

    getRoute(_pickupLocation, destinationLocation!).then((_) {
      _calculateFare();
      _mapController.move(destinationLocation!, 15);
    });
  }

  void _showSearchDialog() {
    final TextEditingController searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Destination'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Enter area, street, city...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            searchPlace(query: value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final query = searchController.text.trim();
              if (query.isNotEmpty) {
                Navigator.pop(context);
                searchPlace(query: query);
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  // -------------------- ROUTE (unchanged) --------------------
  Future<void> getRoute(LatLng start, LatLng end) async {
    if (start.latitude == end.latitude && start.longitude == end.longitude) {
      routePoints.clear();
      routePoints.add(start);
      routePoints.add(end);
      setState(() {
        rideDistance = 0;
        rideFare = 20;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("https://api.openrouteservice.org/v2/directions/driving-car/geojson"),
        headers: {
          "Authorization": apiKey,
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "coordinates": [
            [start.longitude, start.latitude],
            [end.longitude, end.latitude],
          ]
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List coordinates = data["features"][0]["geometry"]["coordinates"];
        routePoints.clear();
        for (final point in coordinates) {
          routePoints.add(LatLng(point[1], point[0]));
        }
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Route Error : ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error getting route: $e")),
      );
    }
  }

  // ==================== NEW FLOW: SEND PENDING REQUEST ====================

  Future<void> _sendRideRequest(Map<String, dynamic> driver) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login first")),
        );
        return;
      }

      double finalFare = rideFare;
      if (_selectedRideType == 'Premium') finalFare = rideFare * 1.5;
      if (_selectedRideType == 'Shared') finalFare = rideFare * 0.7;

      String uid = DateTime.now().microsecondsSinceEpoch.toString();

      Map<String, dynamic> rideData = {
        'uid': uid,
        'fromAddress': fromController.text,
        'toAddress': toController.text,
        'pickup': GeoPoint(_pickupLocation.latitude, _pickupLocation.longitude),
        'destination': GeoPoint(destinationLocation!.latitude, destinationLocation!.longitude),
        'fare': finalFare,
        'rideType': _selectedRideType ?? 'Standard',
        'distance': rideDistance,
        'driverName': driver['driverName'] ?? '',
        'driverCar': driver['carModel'] ?? '',
        'driverNumber': driver['carNumber'] ?? '',
        'driverId': driver['driverId'],
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        if (polygonPoints.isNotEmpty)
          'polygon': polygonPoints.map((p) => GeoPoint(p.latitude, p.longitude)).toList(),
      };

      await FirebaseFirestore.instance.collection('rides').doc(uid).set(rideData);

      // Navigate to waiting screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RideRequestStatusScreen(rideId: uid),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending request: $e")),
      );
    }
  }

  // ==================== BOOK RIDE (show ride types, then driver list) ====================
  void _bookRideAndNavigateToDriverList() {
    if (destinationLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a destination first"), backgroundColor: Colors.orange),
      );
      return;
    }
    if (routePoints.isEmpty && destinationLocation != null) {
      routePoints = [destinationLocation!, destinationLocation!];
      rideDistance = 0;
      rideFare = 20;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "Select Ride Type",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ..._rideTypes.map((type) {
                    double typeFare = rideFare;
                    if (type == 'Premium') typeFare = rideFare * 1.5;
                    if (type == 'Shared') typeFare = rideFare * 0.7;
                    return RadioListTile<String>(
                      title: Text(type),
                      subtitle: Text('₹${typeFare.toStringAsFixed(0)}'),
                      value: type,
                      groupValue: _selectedRideType,
                      onChanged: (value) => setStateModal(() => _selectedRideType = value),
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _selectedRideType == null ? null : () {
                            Navigator.pop(context);
                            _navigateToDriverList();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            disabledBackgroundColor: Colors.grey[300],
                          ),
                          child: const Text(
                            "Find Drivers",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _navigateToDriverList() async {
    double finalFare = rideFare;
    if (_selectedRideType == 'Premium') finalFare = rideFare * 1.5;
    if (_selectedRideType == 'Shared') finalFare = rideFare * 0.7;

    final driver = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => Driverslist(
          pickup: fromController.text,
          destination: toController.text,
          fare: finalFare,
          rideType: _selectedRideType ?? 'Standard',
          distance: rideDistance,
          pickupLatLng: _pickupLocation,
          destinationLatLng: destinationLocation!,
          polygonPoints: polygonPoints,
        ),
      ),
    );

    if (driver != null && driver['driverId'] != null) {
      _sendRideRequest(driver);
    } else {
      print('No driver selected or missing driverId');
    }
  }

  // -------------------- LOCATION PICKER (unchanged) --------------------
  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => LocationPicker(
        savedLocations: _savedLocations,
        currentLocation: toController.text.isEmpty ? 'Select destination' : toController.text,
        onLocationSelected: (String location) {
          toController.text = location;
          searchPlace();
          Navigator.pop(context);
        },
        onCurrentLocationSelected: () {
          setState(() {
            destinationLocation = _currentLocation;
            toController.text = fromController.text;
            routePoints.clear();
          });
          getRoute(_pickupLocation, _currentLocation).then((_) {
            _calculateFare();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Current location set as destination"),
                duration: Duration(seconds: 2),
              ),
            );
          });
          Navigator.pop(context);
        },
        onPickOnMap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Tap anywhere on the map to set destination"),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  // -------------------- BUILD MARKERS (unchanged) --------------------
  List<Marker> _buildMarkers() {
    List<Marker> markers = [];
    markers.add(
      Marker(
        point: _pickupLocation,
        width: 60,
        height: 60,
        child: const Icon(Icons.location_pin, color: Colors.green, size: 45),
      ),
    );
    if (_pickupLocation != _currentLocation) {
      markers.add(
        Marker(
          point: _currentLocation,
          width: 40,
          height: 40,
          child: const Icon(Icons.my_location, color: Colors.red, size: 30),
        ),
      );
    }
    if (destinationLocation != null) {
      markers.add(
        Marker(
          point: destinationLocation!,
          width: 60,
          height: 60,
          child: const Icon(Icons.location_pin, color: Colors.blue, size: 45),
        ),
      );
    }
    for (int i = 0; i < polygonPoints.length; i++) {
      final point = polygonPoints[i];
      markers.add(
        Marker(
          point: point,
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                "${i + 1}",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    fromController.dispose();
    toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> mapChildren = <Widget>[
      TileLayer(
        urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
        userAgentPackageName: "com.example.eduride",
      ),
    ];

    if (routePoints.isNotEmpty) {
      mapChildren.add(
        PolylineLayer(
          polylines: <Polyline>[
            Polyline(points: routePoints, color: Colors.blue, strokeWidth: 5),
          ],
        ),
      );
    }

    if (polygonPoints.length >= 3) {
      mapChildren.add(
        PolygonLayer(
          polygons: <Polygon>[
            Polygon(
              points: polygonPoints,
              color: Colors.orange.withOpacity(0.3),
              borderColor: Colors.orange,
              borderStrokeWidth: 3,
            ),
          ],
        ),
      );
    }

    mapChildren.add(MarkerLayer(markers: _buildMarkers()));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Tracking"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isDrawingPolygon ? Icons.stop : Icons.polyline,
              color: isDrawingPolygon ? Colors.green : null,
            ),
            onPressed: _togglePolygonMode,
            tooltip: isDrawingPolygon ? "Stop drawing polygon" : "Draw polygon",
          ),
          if (polygonPoints.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearPolygon,
              tooltip: "Clear polygon",
            ),
        ],
      ),
      body: Column(
        children: [
          // FROM FIELD
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: fromController,
              readOnly: false,
              decoration: InputDecoration(
                hintText: "Pickup Location",
                prefixIcon: const Icon(Icons.location_pin, color: Colors.green),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.blue),
                      onPressed: searchPickup,
                      tooltip: "Search pickup",
                    ),
                    IconButton(
                      icon: const Icon(Icons.my_location, color: Colors.green),
                      onPressed: _resetPickupToCurrent,
                      tooltip: "Use current location",
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          // MAP
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation,
                    initialZoom: 16,
                    onTap: (tapPosition, point) {
                      if (isDrawingPolygon) {
                        _addPolygonPoint(tapPosition, point);
                      } else {
                        _onMapTap(tapPosition, point);
                      }
                    },
                  ),
                  children: mapChildren,
                ),
                if (isDrawingPolygon)
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          "Tap on map to add polygon points. Click stop to finish.",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                if (polygonPoints.isNotEmpty && !isDrawingPolygon && polygonPoints.length >= 3)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Polygon with ${polygonPoints.length} points",
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                if (polygonPoints.isNotEmpty && polygonPoints.length < 3 && !isDrawingPolygon)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Add more points to create a polygon (minimum 3 points)",
                        style: TextStyle(color: Colors.yellow, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                if (destinationLocation != null)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Trip Details",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Distance: ${rideDistance.toStringAsFixed(1)} km",
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    "Fare: ₹${rideFare.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: _bookRideAndNavigateToDriverList,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  "Book Ride",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // TO FIELD
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextField(
              controller: toController,
              readOnly: true,
              onTap: _showLocationPicker,
              decoration: InputDecoration(
                hintText: "Where to? (Tap to select)",
                prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.blue),
                      onPressed: _showSearchDialog,
                      tooltip: "Search destination",
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_drop_down),
                      onPressed: _showLocationPicker,
                      tooltip: "More options",
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ============================================================
// LOCATION PICKER (unchanged)
// ============================================================
class LocationPicker extends StatefulWidget {
  final List<String> savedLocations;
  final String currentLocation;
  final Function(String) onLocationSelected;
  final VoidCallback onCurrentLocationSelected;
  final VoidCallback onPickOnMap;

  const LocationPicker({
    super.key,
    required this.savedLocations,
    required this.currentLocation,
    required this.onLocationSelected,
    required this.onCurrentLocationSelected,
    required this.onPickOnMap,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  Future<void> _searchLocation(String query) async {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      if (query.isEmpty) {
        setState(() => _searchResults = []);
        return;
      }
      setState(() => _isSearching = true);
      try {
        final url = Uri.parse(
          "https://nominatim.openstreetmap.org/search?"
              "q=${Uri.encodeComponent(query)}"
              "&format=json"
              "&limit=5"
              "&countrycodes=in"
              "&addressdetails=1",
        );
        final response = await http.get(url, headers: {"User-Agent": "EduRide"});
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as List;
          if (data.isNotEmpty) {
            setState(() {
              _searchResults = data.map((e) => e as Map<String, dynamic>).toList();
              _isSearching = false;
            });
            return;
          }
        }
        print("Nominatim returned no results, trying device geocoder...");
        List<Location> locations = await locationFromAddress(query);
        if (locations.isNotEmpty) {
          List<Map<String, dynamic>> fallbackResults = [];
          for (var loc in locations.take(5)) {
            List<Placemark> placemarks = await placemarkFromCoordinates(
              loc.latitude,
              loc.longitude,
            );
            String displayName = placemarks.isNotEmpty
                ? "${placemarks.first.street}, ${placemarks.first.locality}, ${placemarks.first.administrativeArea}"
                : "${loc.latitude}, ${loc.longitude}";
            fallbackResults.add({
              "lat": loc.latitude.toString(),
              "lon": loc.longitude.toString(),
              "display_name": displayName,
            });
          }
          setState(() {
            _searchResults = fallbackResults;
            _isSearching = false;
          });
        } else {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
        }
      } catch (e) {
        print("Search error: $e");
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Search error: $e")),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Location',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for area, street...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchResults = []);
                },
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: _searchLocation,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchController.text.isNotEmpty && _searchResults.isNotEmpty
                ? ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final place = _searchResults[index];
                final displayName = place['display_name'] ?? 'Unnamed';
                return ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.grey),
                  title: Text(displayName),
                  onTap: () {
                    widget.onLocationSelected(displayName);
                  },
                );
              },
            )
                : _searchController.text.isNotEmpty && _searchResults.isEmpty
                ? const Center(child: Text('No results found'))
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.my_location, color: Colors.blue),
                  title: const Text('Use current location'),
                  subtitle: Text(widget.currentLocation),
                  onTap: () {
                    widget.onCurrentLocationSelected();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.map, color: Colors.green),
                  title: const Text('Pick on map'),
                  subtitle: const Text('Tap anywhere on the map to set destination'),
                  onTap: () {
                    widget.onPickOnMap();
                  },
                ),
                const Divider(),
                const Text(
                  'Saved Locations',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...widget.savedLocations.map((loc) => ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.grey),
                  title: Text(loc),
                  onTap: () {
                    widget.onLocationSelected(loc);
                  },
                )),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.add_location, color: Colors.green),
                  title: const Text('Add new location'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddLocationDialog(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddLocationDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Location'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter location name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  widget.onLocationSelected(controller.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}

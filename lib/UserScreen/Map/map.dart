import 'dart:async';

import 'package:eduride/UserScreen/payment/payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'dart:math' as math;

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

  bool _loading = true;

  StreamSubscription<Position>? _positionSubscription;

  LatLng? destinationLocation;

  List<LatLng> routePoints = [];

  // For polygon drawing (multiple points)
  List<LatLng> polygonPoints = [];
  bool isDrawingPolygon = false;

  String apiKey =
      "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImYxZjVhMGJjOTg4MDRjNjg5MjExNDQ0MDFjZjA4YWE3IiwiaCI6Im11cm11cjY0In0=";

  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();

  // Add these variables for ride booking
  bool _isBookingRide = false;
  String? _selectedRideType;
  final List<String> _rideTypes = ['Standard', 'Premium', 'Shared'];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      getLocation();
    });
  }

  Future<void> getCurrentAddress() async {
    try {
      List<Placemark> place = await placemarkFromCoordinates(
        _currentLocation.latitude,
        _currentLocation.longitude,
      );

      fromController.text =
      "${place.first.street}, ${place.first.locality}";
    } catch (e) {
      fromController.text = "Current Location";
    }
  }

  Future<void> getLocation() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    bool serviceEnabled =
    await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enable location services."),
          ),
        );
      }
      return;
    }

    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Location permission permanently denied.",
            ),
          ),
        );
      }
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    _currentLocation =
        LatLng(position.latitude, position.longitude);
    await getCurrentAddress();

    if (mounted) {
      setState(() {
        _loading = false;
      });

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
      _currentLocation =
          LatLng(position.latitude, position.longitude);

      if (!mounted) return;

      setState(() {});

      _mapController.move(
        _currentLocation,
        _mapController.camera.zoom,
      );
    });
  }

  // Method to handle map tap for selecting destination
  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      destinationLocation = point;
      // Clear previous route and polygon points
      routePoints.clear();
      polygonPoints.clear();
      isDrawingPolygon = false;
      _selectedRideType = null; // Reset ride type selection

      // Get address for the tapped location
      _getAddressFromCoordinates(point);

      // Move map to the selected location
      _mapController.move(point, 15);
    });
  }

  // Method to get address from coordinates
  Future<void> _getAddressFromCoordinates(LatLng point) async {
    try {
      List<Placemark> place = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );

      toController.text =
      "${place.first.street}, ${place.first.locality}";

      // Automatically get route to the selected location
      await getRoute(_currentLocation, point);

      // Calculate fare after getting route
      _calculateFare();
    } catch (e) {
      toController.text = "Selected Location";
      await getRoute(_currentLocation, point);
      _calculateFare();
    }
  }

  // Calculate fare based on distance
  void _calculateFare() {
    if (routePoints.length < 2) return;

    double distanceInKm = 0;

    for (int i = 0; i < routePoints.length - 1; i++) {
      distanceInKm += _calculateDistance(
        routePoints[i],
        routePoints[i + 1],
      );
    }

    double fare = 20; // Base Fare

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

  // Calculate distance between two points in km
  double _calculateDistance(LatLng p1, LatLng p2) {
    const double earthRadius = 6371; // km

    double dLat = _degToRad(p2.latitude - p1.latitude);
    double dLon = _degToRad(p2.longitude - p1.longitude);

    double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
            math.cos(_degToRad(p1.latitude)) *
                math.cos(_degToRad(p2.latitude)) *
                math.sin(dLon / 2) *
                math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _degToRad(double deg) {
    return deg * math.pi / 180;
  }

  // Method to toggle polygon drawing mode
  void _togglePolygonMode() {
    setState(() {
      isDrawingPolygon = !isDrawingPolygon;
      if (!isDrawingPolygon && polygonPoints.isNotEmpty) {
        // Close the polygon by adding the first point at the end
        polygonPoints.add(polygonPoints.first);
      }
    });
  }

  // Method to add points to polygon when map is tapped in polygon mode
  void _addPolygonPoint(TapPosition tapPosition, LatLng point) {
    if (isDrawingPolygon) {
      setState(() {
        polygonPoints.add(point);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Polygon point added: ${polygonPoints.length} points"),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  // Method to clear polygon
  void _clearPolygon() {
    setState(() {
      polygonPoints.clear();
      isDrawingPolygon = false;
    });
  }

  Future<void> searchPlace() async {
    if (toController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter destination"),
        ),
      );
      return;
    }

    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(toController.text.trim())}&format=json&limit=1",
    );

    final response = await http.get(
      url,
      headers: {
        "User-Agent": "EduRide",
      },
    );

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Search failed"),
        ),
      );
      return;
    }

    final data = jsonDecode(response.body);

    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Location not found"),
        ),
      );
      return;
    }

    final lat = double.parse(data[0]["lat"]);
    final lon = double.parse(data[0]["lon"]);

    destinationLocation = LatLng(lat, lon);

    // Clear polygon points when searching
    polygonPoints.clear();
    isDrawingPolygon = false;

    await getRoute(
      _currentLocation,
      destinationLocation!,
    );

    _calculateFare();

    setState(() {});

    _mapController.move(destinationLocation!, 15);
  }

  Future<void> getRoute(
      LatLng start,
      LatLng end,
      ) async {
    try {
      final response = await http.post(
        Uri.parse(
          "https://api.openrouteservice.org/v2/directions/driving-car/geojson",
        ),
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

      print(response.statusCode);
      print(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List coordinates =
        data["features"][0]["geometry"]["coordinates"];

        routePoints.clear();

        for (final point in coordinates) {
          routePoints.add(
            LatLng(
              point[1],
              point[0],
            ),
          );
        }

        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Route Error : ${response.statusCode}",
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error getting route: $e"),
        ),
      );
    }
  }

  // NEW METHOD: Navigate to payment page
  void _bookRideAndNavigateToPayment() {
    if (destinationLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a destination first"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (routePoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No route found. Please try again."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show ride type selection dialog
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Ride type options
                  ..._rideTypes.map((type) {
                    return RadioListTile<String>(
                      title: Text(type),
                      subtitle: Text(
                        type == 'Standard' ? '₹${(rideFare).toStringAsFixed(0)}' :
                        type == 'Premium' ? '₹${(rideFare * 1.5).toStringAsFixed(0)}' :
                        '₹${(rideFare * 0.7).toStringAsFixed(0)}',
                      ),
                      value: type,
                      groupValue: _selectedRideType,
                      onChanged: (value) {
                        setStateModal(() {
                          _selectedRideType = value;
                        });
                      },
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
                            _navigateToPayment();
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
                            "Book Ride",
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

  // NEW METHOD: Navigate to payment page
  void _navigateToPayment() {
    // You can pass ride details to the payment page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaymentPage(),
      ),
    ).then((result) {
      // Handle the result if needed (e.g., after payment is complete)
      if (result == true) {
        // Payment successful - show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🎉 Ride booked successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        // Reset the map state
        setState(() {
          destinationLocation = null;
          routePoints.clear();
          toController.clear();
          _selectedRideType = null;
          rideFare = 0;
          rideDistance = 0;
        });
        // Reset map view to current location
        _mapController.move(_currentLocation, 16);
      }
    });
  }

  // Helper method to build markers
  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    // Current location marker
    markers.add(
      Marker(
        point: _currentLocation,
        width: 60,
        height: 60,
        child: const Icon(
          Icons.location_pin,
          color: Colors.red,
          size: 45,
        ),
      ),
    );

    // Destination marker
    if (destinationLocation != null) {
      markers.add(
        Marker(
          point: destinationLocation!,
          width: 60,
          height: 60,
          child: const Icon(
            Icons.location_pin,
            color: Colors.blue,
            size: 45,
          ),
        ),
      );
    }

    // Polygon point markers
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
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                "${i + 1}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
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
    // Build children list dynamically with explicit type
    final List<Widget> mapChildren = <Widget>[
      TileLayer(
        urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
        userAgentPackageName: "com.example.eduride",
      ),
    ];

    // Add polyline layer - using a separate variable and explicit check
    final bool hasRoute = routePoints.isNotEmpty;
    if (hasRoute) {
      mapChildren.add(
        PolylineLayer(
          polylines: <Polyline>[
            Polyline(
              points: routePoints,
              color: Colors.blue,
              strokeWidth: 5,
            ),
          ],
        ),
      );
    }

    // Add polygon layer - only if we have at least 3 points
    final bool hasValidPolygon = polygonPoints.length >= 3;
    if (hasValidPolygon) {
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

    // Add marker layer
    mapChildren.add(
      MarkerLayer(
        markers: _buildMarkers(),
      ),
    );

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
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: fromController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: "Current Location",
                prefixIcon: const Icon(
                  Icons.my_location,
                  color: Colors.green,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation,
                    initialZoom: 16,
                    onTap: (tapPosition, point) {
                      // If in polygon mode, add polygon point
                      if (isDrawingPolygon) {
                        _addPolygonPoint(tapPosition, point);
                      } else {
                        // Otherwise select destination
                        _onMapTap(tapPosition, point);
                      }
                    },
                  ),
                  children: mapChildren,
                ),
                // Floating info button
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
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                // Polygon info
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
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
                        style: TextStyle(
                          color: Colors.yellow,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                // NEW: Ride info overlay when route is found
                if (routePoints.isNotEmpty && destinationLocation != null)
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
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
                                onPressed: _bookRideAndNavigateToPayment,
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
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextField(
              controller: toController,
              decoration: InputDecoration(
                hintText: "Where to? (Tap on map or search)",
                prefixIcon: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: searchPlace,
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
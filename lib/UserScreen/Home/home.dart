import 'package:eduride/UserScreen/BottomNavigationBar/Message.dart';
import 'package:eduride/UserScreen/BottomNavigationBar/Profilepage.dart';
import 'package:eduride/UserScreen/Map/map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int index = 0;

  // Location state
  String? _displayLocation;
  String? _cachedCurrentLocation;
  final List<String> _savedLocations = ['Home', 'Work', 'School', 'Gym'];

  // Fetch current location name (reverse geocoding)
  Future<String> _getCurrentLocationName() async {
    if (_cachedCurrentLocation != null) return _cachedCurrentLocation!;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return 'Location off';

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return 'Permission denied';
    }
    if (permission == LocationPermission.deniedForever) return 'Permission denied';

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String name = place.locality ?? place.subLocality ?? place.administrativeArea ?? 'Unknown';
        _cachedCurrentLocation = name;
        return name;
      } else {
        return 'Unknown';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  // Open the location picker (full‑screen modal bottom sheet)
  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => LocationPicker(
        savedLocations: _savedLocations,
        currentLocation: _displayLocation ?? _cachedCurrentLocation ?? '',
        onLocationSelected: (String location) {
          setState(() {
            _displayLocation = location;
          });
        },
        onCurrentLocationSelected: () async {
          String loc = await _getCurrentLocationName();
          setState(() {
            _displayLocation = loc;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleSpacing: 0,
        title: const Text(
          'EduRide',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          // Location chip with a max width to prevent overflow
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: screenWidth * 0.4),
            child: GestureDetector(
              onTap: _showLocationPicker,
              child: FutureBuilder<String>(
                future: _getCurrentLocationName(),
                builder: (context, snapshot) {
                  String displayText;
                  if (_displayLocation != null) {
                    displayText = _displayLocation!;
                  } else if (snapshot.hasData && snapshot.data != null) {
                    displayText = snapshot.data!;
                  } else if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  } else {
                    displayText = 'Unknown';
                  }

                  return Container(
                    margin: const EdgeInsets.only(right: 12.0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            displayText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(   // ✅ Scrollable body
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            // Responsive search box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                height: 55,
                child: TextFormField(
                  readOnly: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MapPage(),
                      ),
                    );
                  },
                  decoration: InputDecoration(
                    hintText: 'Where to?',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ),
            // Image
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assects/logo/homephoto.png',
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Track Ride button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MapPage(),
                          ),
                        );
                      },
                      child: Container(
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on, color: Colors.white, size: 40),
                            SizedBox(height: 8),
                            Text(
                              "Track Ride",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Today's Ride Card (removed unnecessary Row wrapper)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Ride",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Icon(Icons.school, color: Colors.green),
                        SizedBox(width: 10),
                        Text("ABC Public School"),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.orange),
                        SizedBox(width: 10),
                        Text("Pickup : 7:45 AM"),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.directions_bus, color: Colors.blue),
                        SizedBox(width: 10),
                        Text("Driver : Rahul Sharma"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.black87,
        onTap: (value) {
          setState(() {
            index = value;
          });
          if (value == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MessagePage()),
            );
          }
          if (value == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: "Payment History",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// LocationPicker – full‑screen modal bottom sheet
// ──────────────────────────────────────────────────────────────
class LocationPicker extends StatefulWidget {
  final List<String> savedLocations;
  final String currentLocation;
  final Function(String) onLocationSelected;
  final VoidCallback onCurrentLocationSelected;

  const LocationPicker({
    super.key,
    required this.savedLocations,
    required this.currentLocation,
    required this.onLocationSelected,
    required this.onCurrentLocationSelected,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchResults = [];
  bool _isSearching = false;

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.length > 5) locations = locations.sublist(0, 5);
      List<String> results = [];
      for (var loc in locations) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            loc.latitude,
            loc.longitude,
          );
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks.first;
            List<String> parts = [
              if (place.name != null && place.name!.isNotEmpty) place.name!,
              if (place.street != null && place.street!.isNotEmpty) place.street!,
              if (place.subLocality != null && place.subLocality!.isNotEmpty) place.subLocality!,
              if (place.locality != null && place.locality!.isNotEmpty) place.locality!,
              if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) place.administrativeArea!,
            ];
            String address = parts.join(', ');
            if (address.isNotEmpty) {
              results.add(address);
            } else {
              results.add('${loc.latitude}, ${loc.longitude}');
            }
          } else {
            results.add('${loc.latitude}, ${loc.longitude}');
          }
        } catch (_) {
          results.add('${loc.latitude}, ${loc.longitude}');
        }
      }
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
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
            onChanged: (value) {
              _searchLocation(value);
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchController.text.isNotEmpty && _searchResults.isNotEmpty
                ? ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.grey),
                  title: Text(_searchResults[index]),
                  onTap: () {
                    widget.onLocationSelected(_searchResults[index]);
                    Navigator.pop(context);
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
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                const Text(
                  'Saved Locations',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...widget.savedLocations.map((loc) => ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.grey),
                  title: Text(loc),
                  onTap: () {
                    widget.onLocationSelected(loc);
                    Navigator.pop(context);
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
}
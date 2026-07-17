import 'package:eduride/Driver/RideRequestPage/RideRequestPage.dart';
import 'package:eduride/Driver/RideShare/rideshare.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MapController mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// OpenStreetMap
          FlutterMap(
            mapController: mapController,
            options: const MapOptions(
              initialCenter: LatLng(30.7333, 76.7794),
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate:
                "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.example.eduride",
              ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: const LatLng(30.7333, 76.7794),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          /// Simple Elevated Button
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  print("Online Button Pressed");
                  Navigator.push(context, MaterialPageRoute(builder: (context) =>Rideshare()));
                },
                child: const Text("Ride Now"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
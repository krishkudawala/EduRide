import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduride/UserScreen/Home/home.dart'; // adjust import to your home page
import 'package:eduride/UserScreen/payment/payment_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RideRequestStatusScreen extends StatefulWidget {
  final String rideId;
  const RideRequestStatusScreen({super.key, required this.rideId});

  @override
  State<RideRequestStatusScreen> createState() => _RideRequestStatusScreenState();
}

class _RideRequestStatusScreenState extends State<RideRequestStatusScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ride Request")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .doc(widget.rideId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Ride not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'] ?? '';

          // Driver accepted -> navigate to payment
          if (status == 'accepted') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _navigateToPayment(data);
            });
          }

          // Driver rejected -> show dialog and pop
          if (status == 'rejected') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showRejectedDialog();
            });
          }

          // Payment completed -> go to home
          if (status == 'confirmed') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const Home()),
                    (route) => false,
              );
            });
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.hourglass_empty, size: 80, color: Colors.orange),
                const SizedBox(height: 20),
                const Text(
                  "Waiting for driver to accept...",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "Driver: ${data['driverName'] ?? 'Unknown'}",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
              ],
            ),
          );
        },
      ),
    );
  }

  void _navigateToPayment(Map<String, dynamic> rideData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          amount: (rideData['fare'] ?? 0).toDouble(),
          rideType: rideData['rideType'] ?? 'Standard',
          fromLocation: rideData['fromAddress'] ?? '',
          toLocation: rideData['toAddress'] ?? '',
          distance: (rideData['distance'] ?? 0).toDouble(),
          rideId: widget.rideId,
        ),
      ),
    );
  }

  void _showRejectedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Request Rejected"),
        content: const Text("The driver has rejected your ride request."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close status screen
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
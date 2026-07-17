import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RideRequestPage extends StatelessWidget {
  const RideRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? driver = FirebaseAuth.instance.currentUser;

    if (driver == null) {
      return const Scaffold(
        body: Center(child: Text("Please login as driver")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ride Requests"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("rides")
            .where("driverId", isEqualTo: driver.uid)
            .where("status", isEqualTo: "pending")
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No pending ride requests",
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }

          var rides = snapshot.data!.docs;

          return ListView.builder(
            itemCount: rides.length,
            itemBuilder: (context, index) {
              var ride = rides[index];
              Map<String, dynamic> data = ride.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      const Text(
                        "New Ride Request",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text("Pickup : ${data["fromAddress"]}"),
                      ),
                      ListTile(
                        leading: const Icon(Icons.flag),
                        title: Text("Drop : ${data["toAddress"]}"),
                      ),
                      ListTile(
                        leading: const Icon(Icons.money),
                        title: Text("₹ ${data["fare"]}"),
                      ),
                      ListTile(
                        leading: const Icon(Icons.route),
                        title: Text("${data["distance"]} KM"),
                      ),
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: Text("User: ${data["userEmail"] ?? 'Unknown'}"),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                FirebaseFirestore.instance
                                    .collection("rides")
                                    .doc(ride.id)
                                    .update({"status": "accepted"});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text("Accept"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                FirebaseFirestore.instance
                                    .collection("rides")
                                    .doc(ride.id)
                                    .update({"status": "rejected"});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text("Reject"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
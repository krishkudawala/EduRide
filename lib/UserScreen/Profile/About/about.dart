import 'package:flutter/material.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "About EduRide",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment:
          CrossAxisAlignment.center,

          children: [

            const SizedBox(height: 20),
            // APP NAME
            const Text(
              "EduRide",

              style: TextStyle(

                fontSize: 28,

                fontWeight: FontWeight.bold,

                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            // VERSION
            Text(

              "Version 1.0.0",

              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),

            // ABOUT CARD
            Container(

              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(

                color: Colors.white,

                borderRadius:
                BorderRadius.circular(20),

                boxShadow: [

                  BoxShadow(

                    color: Colors.grey
                        .withOpacity(0.1),

                    blurRadius: 10,

                    spreadRadius: 2,
                  ),
                ],
              ),

              child: Column(

                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  const Text(

                   "About EduRide",

                    style: TextStyle(

                      fontSize: 22,

                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    "EduRide is a smart student transportation application that provides a safe, reliable, and convenient bus tracking experience. Students can track their college buses in real time, view routes, receive notifications, manage their profiles, and stay updated with their daily transportation schedule.",

                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // FEATURES
            const Align(

              alignment: Alignment.centerLeft,

              child: Text(

                "Key Features",

                style: TextStyle(

                  fontSize: 22,

                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 15),

            _buildFeatureTile(
              Icons.location_on,
              "Live Tracking",
            ),

            _buildFeatureTile(
              Icons.route,
              "Route Information",
            ),

            _buildFeatureTile(
              Icons.notifications_active,
              "Real-Time Notifications",
            ),

            _buildFeatureTile(
              Icons.security,
              "Safe & Secure Travel",
            ),

            _buildFeatureTile(
              Icons.person,
              "Student Profile Management",
            ),

            _buildFeatureTile(
              Icons.support_agent,
              "24×7 Support",
            ),
            const SizedBox(height: 30),

            // DEVELOPER INFO
            Container(

              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(

                color: Colors.deepOrange.shade50,

                borderRadius:
                BorderRadius.circular(18),
              ),

              child: Column(

                children: [

                  const Text(

                    "Developed By",

                    style: TextStyle(

                      fontSize: 18,

                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(

                    "Krish Kudawala Rajput",

                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(

                    "Flutter Developer",

                    style: TextStyle(
                      color:
                      Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // COPYRIGHT
            Text(

              "© 2026 EduRide\nAll Rights Reserved",

              textAlign: TextAlign.center,

              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FEATURE TILE
  Widget _buildFeatureTile(
      IconData icon,
      String title,
      ) {

    return Card(

      margin:
      const EdgeInsets.only(bottom: 12),

      elevation: 1,

      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(15),
      ),

      child: ListTile(

        leading: CircleAvatar(

          backgroundColor:
          Colors.deepOrange.shade100,

          child: Icon(
            icon,
            color: Colors.deepOrange,
          ),
        ),

        title: Text(title),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [

            Text(
              "Privacy Policy",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 20),

            Text(
              "Last Updated: July 2026",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),

            SizedBox(height: 25),

            Text(
              "1. Introduction",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text(
              "EduRide is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and protect your personal information while using our application.",
              style: TextStyle(fontSize: 16),
            ),

            SizedBox(height: 20),

            Text(
              "2. Information We Collect",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text(
              "• Full Name\n"
                  "• Email Address\n"
                  "• Phone Number\n"
                  "• Student Information\n"
                  "• Live Location (for bus tracking)\n"
                  "• Device Information",
              style: TextStyle(fontSize: 16),
            ),

            SizedBox(height: 20),

            Text(
              "3. How We Use Your Information",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text(
              "Your information is used to:\n\n"
                  "• Provide bus tracking services.\n"
                  "• Verify your student account.\n"
                  "• Improve app performance.\n"
                  "• Send important notifications.\n"
                  "• Enhance user experience.",
              style: TextStyle(fontSize: 16),
            ),

            SizedBox(height: 20),

            Text(
              "4. Location Access",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text(
              "EduRide accesses your location only to provide live bus tracking and navigation. Your location is never shared with unauthorized third parties.",
              style: TextStyle(fontSize: 16),
            ),

            SizedBox(height: 20),

            Text(
              "5. Data Security",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text(
              "We use Firebase Authentication and Cloud Firestore to securely store user data. We take reasonable measures to protect your personal information.",
              style: TextStyle(fontSize: 16),
            ),

            SizedBox(height: 20),

            Text(
              "6. Sharing Information",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text(
              "EduRide does not sell, rent, or share your personal information with third parties except when required by law.",
              style: TextStyle(fontSize: 16),
            ),

            SizedBox(height: 20),

            Text(
              "7. Your Rights",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text(
              "You may update or delete your personal information through the profile section or by contacting our support team.",
              style: TextStyle(fontSize: 16),
            ),

            SizedBox(height: 20),

            Text(
              "8. Contact Us",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text(
              "Email: support@eduride.com\n"
                  "Phone: +91 XXXXX XXXXX\n"
                  "Website: www.eduride.com",
              style: TextStyle(fontSize: 16),
            ),

            SizedBox(height: 30),

            Center(
              child: Text(
                "© 2026 EduRide. All Rights Reserved.",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & Support"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Center(
              child: CircleAvatar(
                radius: 45,
                backgroundColor: Colors.deepPurple,
                child: Icon(
                  Icons.support_agent,
                  color: Colors.white,
                  size: 45,
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Center(
              child: Text(
                "How can we help you?",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 30),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.email,
                  color: Colors.blue,
                ),
                title: const Text("Email Support"),
                subtitle: const Text("support@eduride.com"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.phone,
                  color: Colors.green,
                ),
                title: const Text("Call Support"),
                subtitle: const Text("+91 9876543210"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.chat,
                  color: Colors.orange,
                ),
                title: const Text("Live Chat"),
                subtitle: const Text("Chat with our support team"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Frequently Asked Questions",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            ExpansionTile(
              leading: Icon(Icons.help_outline),
              title: Text("How can I track my bus?"),
              children: [
                Padding(
                  padding: EdgeInsets.all(15),
                  child: Text(
                    "Open the Live Tracking screen and select your destination to view the bus route and live location.",
                  ),
                ),
              ],
            ),

            ExpansionTile(
              leading: Icon(Icons.help_outline),
              title: Text("How do I update my profile?"),
              children: [
                Padding(
                  padding: EdgeInsets.all(15),
                  child: Text(
                    "Go to Settings → Profile and edit your personal information.",
                  ),
                ),
              ],
            ),

            ExpansionTile(
              leading: Icon(Icons.help_outline),
              title: Text("Forgot my password"),
              children: [
                Padding(
                  padding: EdgeInsets.all(15),
                  child: Text(
                    "Go to Login → Forgot Password and follow the instructions.",
                  ),
                ),
              ],
            ),

            ExpansionTile(
              leading: Icon(Icons.help_outline),
              title: Text("Location is not working"),
              children: [
                Padding(
                  padding: EdgeInsets.all(15),
                  child: Text(
                    "Enable GPS and grant location permission from your device settings.",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Center(
              child: Text(
                "Need more help?\nContact us anytime.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
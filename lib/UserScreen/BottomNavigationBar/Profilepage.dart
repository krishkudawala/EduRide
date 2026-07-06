import 'package:eduride/UserScreen/BottomNavigationBar/Message.dart';
import 'package:eduride/UserScreen/FirstScreen/firstscreen.dart';
import 'package:eduride/UserScreen/LoginScreen/login.dart';
import 'package:eduride/UserScreen/Profile/About/about.dart';
import 'package:eduride/UserScreen/Profile/PersonalInformation/PersonalInformation.dart';
import 'package:eduride/UserScreen/Profile/SettingsScreen/helpsupport/helpsupport.dart';
import 'package:eduride/UserScreen/Profile/SettingsScreen/settingscreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "My Profile",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            const SizedBox(height: 20),

            // Profile Image
            const CircleAvatar(
              radius: 55,
              backgroundImage: AssetImage(
                "assects/logo/profile.jpg",
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              "Krish Kudawala",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              "krish@gmail.com",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),

            profileTile(
              Icons.person_outline,
              "Personal Information",
                  () {
                Navigator.push(context, MaterialPageRoute(builder: (context) =>PersonalInformation()));
                  },
            ),



            profileTile(
              Icons.payment,
              "Payments",
                  () {
                Navigator.push(context, MaterialPageRoute(builder: (context) =>MessagePage()));
                  },
            ),

            profileTile(
              Icons.notifications_none,
              "About",
                  () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) =>AboutAppPage()));

                  },
            ),

            profileTile(
              Icons.settings,
              "Settings",
                  () {
                Navigator.push(context, MaterialPageRoute(builder: (context) =>SettingsScreen()));
                  },
            ),

            profileTile(
              Icons.help_outline,
              "Help & Support",
                  () {
                Navigator.push(context, MaterialPageRoute(builder: (context) =>HelpSupportPage()));
                  },
            ),

        profileTile(
          Icons.logout,
          "Logout",
              () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  title: const Text("Logout"),
                  content: const Text(
                    "Are you sure you want to logout?",
                  ),
                  actions: [

                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Cancel"),
                    ),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Firstscreen(),
                          ),
                              (route) => false,
                        );
                      },
                      child: const Text(
                        "Logout",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          color: Colors.red,
        ),
        ]
        ),
      ),
    );
  }

  Widget profileTile(
      IconData icon,
      String title,
      VoidCallback onTap, {
        Color color =  Colors.black,
      }) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: color,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
      ),
    );
  }
}
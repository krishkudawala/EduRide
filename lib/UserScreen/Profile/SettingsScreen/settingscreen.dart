import 'package:eduride/UserScreen/Profile/SettingsScreen/helpsupport/helpsupport.dart';
import 'package:eduride/UserScreen/Profile/SettingsScreen/privacypolicy/privacypolicy.dart';
import 'package:eduride/UserScreen/forgetpassword/passwordpassword.dart';
import 'package:eduride/UserScreen/Profile/SettingsScreen/profile/editProfilr.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
          (route) => false,
    );
  }

  Widget settingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = Colors.deepPurple,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool notification = true;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          const CircleAvatar(
            radius: 45,
            backgroundColor: Colors.deepPurple,
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 45,
            ),
          ),

          const SizedBox(height: 12),

          const Center(
            child: Text(
              "Student",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 30),

          settingTile(
            icon: Icons.person,
            title: "Profile",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );
            },
          ),

          settingTile(
            icon: Icons.lock,
            title: "Change Password",
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=>ForgetPassword()));
            },
          ),
          settingTile(
            icon: Icons.privacy_tip,
            title: "Privacy Policy",
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) =>PrivacyPolicyPage()));
            },
          ),

          settingTile(
            icon: Icons.help,
            title: "Help & Support",
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) =>HelpSupportPage()));
            },
          ),

          const SizedBox(height: 25),


          const SizedBox(height: 20),

          const Center(
            child: Text(
              "EduRide v1.0.0",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
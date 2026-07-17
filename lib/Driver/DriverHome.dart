import 'package:eduride/Driver/DriverHome.dart';
import 'package:eduride/Driver/bottomNavigationBar/homepage.dart';
import 'package:eduride/Driver/bottomNavigationBar/message.dart';
import 'package:eduride/Driver/bottomNavigationBar/profile.dart';
import 'package:eduride/Driver/bottomNavigationBar/rideapp.dart';
import 'package:flutter/material.dart';

class Driverhome extends StatefulWidget {
  const Driverhome({super.key});

  @override
  State<Driverhome> createState() => _DriverhomeState();
}

class _DriverhomeState extends State<Driverhome> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    HomePage(),
    RidePage(),
    MessagePage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.lightGreenAccent,
        unselectedItemColor: Colors.grey,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: "Rides",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: "Messages",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: "Logout",
          ),
        ],
      ),

    );
  }
}








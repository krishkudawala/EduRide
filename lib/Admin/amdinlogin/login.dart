import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduride/Admin/home/home.dart';
import 'package:eduride/Admin/sigin/Adminsignin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class Adminlogin extends StatefulWidget {

  const Adminlogin({super.key});

  @override
  State<Adminlogin> createState() =>
      _AdminLoginPageState();
}

class _AdminLoginPageState
    extends State<Adminlogin> {

  final TextEditingController email = TextEditingController();

  final TextEditingController password = TextEditingController();

  bool obscure = true;
  final FirebaseAuth auth=FirebaseAuth.instance;
  final db=FirebaseFirestore.instance.collection('Users');

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.white,

      appBar: AppBar(

        backgroundColor: Colors.white,

        elevation: 0,

        centerTitle: true,

        title: const Text(

          "Admin Portal",

          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),

        iconTheme:
        const IconThemeData(
          color: Colors.black,
        ),
      ),

      body: SingleChildScrollView(

        child: Padding(

          padding:
          const EdgeInsets.symmetric(
            horizontal: 25,
            vertical: 20,
          ),

          child: Column(

            children: [

              const SizedBox(height: 30),

              // ================= ADMIN ICON =================

              Container(

                height: 120,
                width: 120,

                decoration: BoxDecoration(

                  color:
                  Colors.blueGrey.shade100,

                  shape: BoxShape.circle,
                ),

                child: const Icon(

                  Icons.admin_panel_settings,

                  size: 70,

                  color: Colors.blueGrey,
                ),
              ),

              const SizedBox(height: 30),

              // ================= TITLE =================

              const Text(

                "Welcome Admin",

                style: TextStyle(

                  fontSize: 28,

                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(

                "Login to manage EduRide",

                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 40),

              // ================= EMAIL =================

              TextField(

                controller: email,

                keyboardType:
                TextInputType.emailAddress,

                decoration: InputDecoration(

                  prefixIcon:
                  const Icon(Icons.email),

                  hintText:
                  "Enter Admin Email",

                  labelText: "Admin Email",

                  border:
                  OutlineInputBorder(

                    borderRadius:
                    BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ================= PASSWORD =================

              TextField(

                controller: password,

                obscureText: obscure,

                decoration: InputDecoration(

                  prefixIcon:
                  const Icon(Icons.lock),

                  suffixIcon: IconButton(

                    onPressed: () {

                      setState(() {

                        obscure = !obscure;
                      });
                    },

                    icon: Icon(

                      obscure

                          ? Icons.visibility_off

                          : Icons.visibility,
                    ),
                  ),

                  hintText:
                  "Enter Password",

                  labelText: "Password",

                  border:
                  OutlineInputBorder(

                    borderRadius:
                    BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 35),

              // ================= LOGIN BUTTON =================

              SizedBox(

                width: double.infinity,
                height: 55,

                child: ElevatedButton.icon(

                  onPressed: () async {
                    try {
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: email.text.trim(),
                        password: password.text.trim(),
                      );

                      if (!mounted) return;

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminHome(),
                        ),
                      );
                    } on FirebaseAuthException catch (e) {
                      String message = "";

                      if (e.code == "user-not-found") {
                        message = "Admin account not found";
                      } else if (e.code == "wrong-password") {
                        message = "Wrong password";
                      } else if (e.code == "invalid-email") {
                        message = "Invalid email";
                      } else if (e.code == "invalid-credential") {
                        message = "Invalid email or password";
                      } else {
                        message = e.message ?? "Login Failed";
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    }
                  },

                  style:
                  ElevatedButton.styleFrom(

                    backgroundColor:
                    Colors.blueGrey,

                    foregroundColor:
                    Colors.white,

                    shape:
                    RoundedRectangleBorder(

                      borderRadius:
                      BorderRadius.circular(15),
                    ),
                  ),

                  icon: const Icon(
                    Icons.login,
                  ),

                  label: const Text(

                    "Admin Login",

                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),


              TextButton(onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder:(context) =>AdminSignupPage()));
              }, child: Text('Signup?')),

              // ================= SECURITY TEXT =================

              const Row(

                mainAxisAlignment:
                MainAxisAlignment.center,

                children: [

                  Icon(

                    Icons.security,

                    color: Colors.green,
                    size: 18,
                  ),

                  SizedBox(width: 5),

                  Text(

                    "Secure Admin Access",

                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduride/Admin/home/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminSignupPage extends StatefulWidget {
  const AdminSignupPage({super.key});

  @override
  State<AdminSignupPage> createState() =>
      _AdminSignupPageState();
}

class _AdminSignupPageState
    extends State<AdminSignupPage> {

  final TextEditingController name =
  TextEditingController();

  final TextEditingController email =
  TextEditingController();

  final TextEditingController phone =
  TextEditingController();

  final TextEditingController password =
  TextEditingController();

  final TextEditingController confirmPassword =
  TextEditingController();

  bool obscure1 = true;
  bool obscure2 = true;

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.white,

      appBar: AppBar(

        backgroundColor: Colors.white,

        elevation: 0,

        centerTitle: true,

        title: const Text(

          "Admin Signup",

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

              const SizedBox(height: 20),

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

                "Create Admin Account",

                style: TextStyle(

                  fontSize: 28,

                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(

                "Register as EduRide Admin",

                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 35),

              // ================= NAME =================

              TextField(

                controller: name,

                decoration: InputDecoration(

                  prefixIcon:
                  const Icon(Icons.person),

                  hintText:
                  "Enter Full Name",

                  labelText: "Full Name",

                  border:
                  OutlineInputBorder(

                    borderRadius:
                    BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 20),

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

              // ================= PHONE =================

              TextField(

                controller: phone,

                keyboardType:
                TextInputType.phone,

                decoration: InputDecoration(

                  prefixIcon:
                  const Icon(Icons.phone),

                  hintText:
                  "Enter Phone Number",

                  labelText: "Phone Number",

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

                obscureText: obscure1,

                decoration: InputDecoration(

                  prefixIcon:
                  const Icon(Icons.lock),

                  suffixIcon: IconButton(

                    onPressed: () {

                      setState(() {

                        obscure1 = !obscure1;
                      });
                    },

                    icon: Icon(

                      obscure1

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

              const SizedBox(height: 20),

              // ================= CONFIRM PASSWORD =================

              TextField(

                controller: confirmPassword,

                obscureText: obscure2,

                decoration: InputDecoration(

                  prefixIcon:
                  const Icon(Icons.lock),

                  suffixIcon: IconButton(

                    onPressed: () {

                      setState(() {

                        obscure2 = !obscure2;
                      });
                    },

                    icon: Icon(

                      obscure2

                          ? Icons.visibility_off

                          : Icons.visibility,
                    ),
                  ),

                  hintText:
                  "Confirm Password",

                  labelText: "Confirm Password",

                  border:
                  OutlineInputBorder(

                    borderRadius:
                    BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 35),

              // ================= SIGNUP BUTTON =================

              SizedBox(

                width: double.infinity,
                height: 55,

                child: ElevatedButton.icon(

                  onPressed: () async {
                    Navigator.pushAndRemoveUntil(
                        context, MaterialPageRoute
                      (builder: (context)=>AdminHome()),
                            (value)=>false);

                    // EMPTY CHECK
                    if(name.text.isEmpty ||
                        email.text.isEmpty ||
                        phone.text.isEmpty ||
                        password.text.isEmpty ||
                        confirmPassword.text.isEmpty){

                      ScaffoldMessenger.of(context)
                          .showSnackBar(

                        const SnackBar(
                          content:
                          Text("Please fill all fields"),
                        ),
                      );

                      return;
                    }

                    // PASSWORD CHECK
                    if(password.text !=
                        confirmPassword.text){

                      ScaffoldMessenger.of(context)
                          .showSnackBar(

                        const SnackBar(
                          content:
                          Text("Passwords do not match"),
                        ),
                      );

                      return;
                    }

                    try{

                      // CREATE ADMIN
                      UserCredential
                      userCredential =
                      await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(

                        email: email.text.trim(),

                        password:
                        password.text.trim(),
                      );

                      // USER ID
                      String uid =
                          userCredential.user!.uid;

                      // SAVE DATA
                      await FirebaseFirestore.instance
                          .collection("Admins")
                          .doc(uid)
                          .set({

                        "uid": uid,

                        "name":
                        name.text.trim(),

                        "email":
                        email.text.trim(),

                        "phone":
                        phone.text.trim(),

                        "createdAt":
                        DateTime.now(),
                      });

                      ScaffoldMessenger.of(context)
                          .showSnackBar(

                        const SnackBar(
                          content:
                          Text("Admin Created Successfully"),
                        ),
                      );

                      // CLEAR FIELDS
                      name.clear();
                      email.clear();
                      phone.clear();
                      password.clear();
                      confirmPassword.clear();

                    } catch(e){

                      ScaffoldMessenger.of(context)
                          .showSnackBar(

                        SnackBar(
                          content:
                          Text(e.toString()),
                        ),
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
                    Icons.app_registration,
                  ),

                  label: const Text(

                    "Create Admin Account",

                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ================= SECURITY TEXT =================

              const Row(

                mainAxisAlignment:
                MainAxisAlignment.center,

                children: [

                  Icon(

                    Icons.verified_user,

                    color: Colors.green,
                    size: 18,
                  ),

                  SizedBox(width: 5),

                  Text(

                    "Authorized Admin Access Only",

                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
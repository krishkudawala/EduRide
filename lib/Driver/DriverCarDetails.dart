  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:eduride/Driver/DriverHome.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:flutter/material.dart';

  class Drivercardetails extends StatefulWidget {
    const Drivercardetails({super.key});

    @override
    State<Drivercardetails> createState() => _DrivercardetailsState();
  }

  class _DrivercardetailsState extends State<Drivercardetails> {

    final _formKey = GlobalKey<FormState>();

    final TextEditingController carModel = TextEditingController();
    final TextEditingController carNumber = TextEditingController();
    final TextEditingController carColor = TextEditingController();
    final TextEditingController seats = TextEditingController();

    final dbref=FirebaseFirestore.instance.collection('cardetails');
    String vehicleType = "Car";

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Form(
              key: _formKey,

              child: Column(
                children: [

                  Image.asset(
                    "assects/logo/driverimg.png",
                    height: 300,
                  ),
                  const Text(
                    "Enter Car Details",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white
                    ),
                  ),

                  const SizedBox(height: 30),

                  TextFormField(
                    controller: carModel,
                    style: const TextStyle(
                      color: Colors.white, // User typed text
                    ),
                    decoration: InputDecoration(
                      labelText: "Car Model",
                      labelStyle: const TextStyle(
                        color: Colors.white, // Label color
                      ),
                      prefixIcon: const Icon(
                        Icons.directions_car,
                        color: Colors.white,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.lightGreenAccent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: carNumber,
                    style: TextStyle(
                      color: Colors.white
                    ),
                    decoration: InputDecoration(
                      labelText: "Car Number",
                      iconColor: Colors.white,
                      prefixIcon: const Icon(Icons.confirmation_number),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.lightGreenAccent,
                          width: 2,
                        ),
                      )
                    ),
                    validator: (value) =>
                    value!.isEmpty ? "Enter vehicle number" : null,
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: carColor,
                    style: TextStyle(
                      color: Colors.white
                    ),
                    decoration: InputDecoration(
                      labelText: "Car Color",
                      prefixIcon: const Icon(Icons.color_lens),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.lightGreenAccent,
                          width: 2,
                        ),
                      )
                    ),

                  ),

                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    value: vehicleType,
                    decoration: InputDecoration(
                      labelText: "Vehicle Type",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "Car",
                        child: Text("Car"),
                      ),
                      DropdownMenuItem(
                        value: "SUV",
                        child: Text("SUV"),
                      ),
                      DropdownMenuItem(
                        value: "Mini Van",
                        child: Text("Mini Van"),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        vehicleType = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: seats,
                    style: TextStyle(
                      color: Colors.white
                    ),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Seating Capacity",
                      prefixIcon: const Icon(Icons.event_seat),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.lightGreenAccent,
                          width: 2,
                        ),
                      )
                    ),
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          try {
                            String uid = DateTime.now().microsecondsSinceEpoch.toString();

                            await dbref.doc(uid).set({
                              "uid": uid,
                              "carModel": carModel.text.trim(),
                              "carNumber": carNumber.text.trim(),
                              "carColor": carColor.text.trim(),
                              "vehicleType": vehicleType,
                              "seats": seats.text.trim(),
                              "createdAt": FieldValue.serverTimestamp(),
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Car Details Saved"),
                              ),
                            );

                            Navigator.push(context, MaterialPageRoute(builder: (context)=>Driverhome()));

                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text(
                        "Next",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PersonalInformation extends StatefulWidget {
  const PersonalInformation({super.key});

  @override
  State<PersonalInformation> createState() =>
      _PersonalInformationState();
}

class _PersonalInformationState
    extends State<PersonalInformation> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController phoneController =
  TextEditingController();

  final TextEditingController addressController =
  TextEditingController();

  final TextEditingController cityController =
  TextEditingController();

  final TextEditingController stateController =
  TextEditingController();

  final TextEditingController genderController =
  TextEditingController();

  bool loading = false;

  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    loadInformation();
  }

  Future<void> loadInformation() async {
    if (user == null) return;

    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .get();

      if (snapshot.exists) {
        Map<String, dynamic> data =
        snapshot.data() as Map<String, dynamic>;

        phoneController.text = data["phone"] ?? "";
        addressController.text = data["address"] ?? "";
        cityController.text = data["city"] ?? "";
        stateController.text = data["state"] ?? "";
        genderController.text = data["gender"] ?? "";
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> saveInformation() async {
    if (!_formKey.currentState!.validate()) return;

    final User? currentUser = FirebaseAuth.instance.currentUser;
    String id=DateTime.now().microsecondsSinceEpoch.toString();

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User not logged in"),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(id)
          .set({
        "uid": id,
        "phone": phoneController.text.trim(),
        "address": addressController.text.trim(),
        "city": cityController.text.trim(),
        "state": stateController.text.trim(),
        "gender": genderController.text.trim(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Information Saved Successfully"),
        ),
      );

      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? "Firebase Error",
          ),
        ),
      );

      debugPrint("Firebase Error Code: ${e.code}");
      debugPrint("Firebase Error Message: ${e.message}");
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );

      debugPrint(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "Please enter $label";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    genderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Personal Information"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            children: [

              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.deepPurple,
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 25),

              buildTextField(
                controller: phoneController,
                label: "Phone Number",
                icon: Icons.phone,
                keyboardType:
                TextInputType.phone,
              ),

              buildTextField(
                controller: addressController,
                label: "Address",
                icon: Icons.home,
              ),

              buildTextField(
                controller: cityController,
                label: "City",
                icon: Icons.location_city,
              ),

              buildTextField(
                controller: stateController,
                label: "State",
                icon: Icons.map,
              ),

              buildTextField(
                controller: genderController,
                label: "Gender",
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    Colors.deepPurple,
                    foregroundColor:
                    Colors.white,
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                          15),
                    ),
                  ),
                  onPressed:
                  loading ? null : saveInformation,
                  child: loading
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                      : const Text(
                    "Save Information",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
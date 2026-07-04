import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() =>
      _ForgetPasswordState();
}

class _ForgetPasswordState
    extends State<ForgetPassword> {

  final TextEditingController email =
  TextEditingController();

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  bool loading = false;

  // RESET PASSWORD
  Future<void> resetPassword() async {

    if (email.text.trim().isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(
          content: Text(
            'Please Enter Email',
          ),
        ),
      );

      return;
    }

    setState(() {
      loading = true;
    });

    try {

      await auth.sendPasswordResetEmail(

        email: email.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text(
            'Password Reset Email Sent',
          ),

          backgroundColor: Colors.green,
        ),
      );

    } on FirebaseAuthException catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(
          content: Text(
            e.message.toString(),
          ),
        ),
      );

    } finally {

      setState(() {
        loading = false;
      });
    }
  }

  @override
  void dispose() {

    email.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'Forget Password',
        ),
      ),

      body: Padding(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            const SizedBox(height: 20),

            const Text(

              'Enter your registered email address to receive password reset link.',

              style: TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 25),

            TextFormField(

              controller: email,

              keyboardType:
              TextInputType.emailAddress,

              decoration: InputDecoration(

                hintText: 'Enter Email',

                prefixIcon:
                const Icon(Icons.email),

                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(

              width: double.infinity,
              height: 50,

              child: ElevatedButton(

                onPressed:
                loading ? null : resetPassword,

                child: loading

                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )

                    : const Text(
                  'Reset Password',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
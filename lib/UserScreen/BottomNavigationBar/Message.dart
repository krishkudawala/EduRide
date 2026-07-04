import 'package:eduride/UserScreen/payment/payment_screen.dart';
import 'package:flutter/material.dart';

class MessagePage extends StatelessWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: Colors.black12,
      ),
      body: Center(
        child: ElevatedButton(onPressed: (){
          Navigator.push(context,
              MaterialPageRoute(builder: (context) =>PaymentPage()));
          }
            , child :Text('hi')),
      ),
    );
  }
}
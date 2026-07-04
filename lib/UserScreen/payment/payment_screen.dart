import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() =>
      _PaymentPageState();
}

class _PaymentPageState
    extends State<PaymentPage> {

  late Razorpay razorpay;

  @override
  void initState() {

    super.initState();

    razorpay = Razorpay();

    // SUCCESS
    razorpay.on(
      Razorpay.EVENT_PAYMENT_SUCCESS,
      handlePaymentSuccess,
    );

    // ERROR
    razorpay.on(
      Razorpay.EVENT_PAYMENT_ERROR,
      handlePaymentError,
    );

    // EXTERNAL WALLET
    razorpay.on(
      Razorpay.EVENT_EXTERNAL_WALLET,
      handleExternalWallet,
    );
  }

  // OPEN PAYMENT
  void openPayment() {

    User? user =
        FirebaseAuth.instance.currentUser;

    var options = {

      // TEST KEY
      'key':
      'rzp_test_SsMf2KMfJMATzw',

      // AMOUNT IN PAISE
      'amount': 500 * 100,

      'name': 'EduRide',

      'description': 'Bus Pass / Ticket Payment',

      'prefill': {

        'contact': '9876543210',

        'email': user?.email,
      },

      'theme': {
        'color': '#FF9800',
      },

      'external': {
        'wallets': ['paytm']
      }
    };

    try {

      razorpay.open(options);

    } catch (e) {

      debugPrint(e.toString());
    }
  }

  // PAYMENT SUCCESS
  void handlePaymentSuccess(
      PaymentSuccessResponse response)
  async {

    User? user =
        FirebaseAuth.instance.currentUser;

    // SAVE PAYMENT
    await FirebaseFirestore.instance
        .collection("payments")
        .doc(response.paymentId)
        .set({

      "uid": user?.uid,

      "email": user?.email,


      "paymentId":
      response.paymentId,

      "orderId":
      response.orderId,



      "status":
      "Success",

      "createdAt":
      FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(

      const SnackBar(

        content: Text(
          "Payment Successful",
        ),

        backgroundColor:
        Colors.green,
      ),
    );
  }

  // PAYMENT ERROR
  void handlePaymentError(
      PaymentFailureResponse response)
  async {

    User? user =
        FirebaseAuth.instance.currentUser;

    // SAVE FAILED PAYMENT
    await FirebaseFirestore.instance
        .collection("payments")
        .add({

      "uid": user?.uid,


      "email": user?.email,


      "code": response.code,

      "message":
      response.message,

      "status":
      "Failed",

      "createdAt":
      FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(

        content: Text(

          response.message ??
              "Payment Failed",
        ),

        backgroundColor:
        Colors.red,
      ),
    );
  }

  // EXTERNAL WALLET
  void handleExternalWallet(
      ExternalWalletResponse response) {

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(

        content: Text(

          "External Wallet Selected: "
              "${response.walletName}",
        ),
      ),
    );
  }

  @override
  void dispose() {

    razorpay.clear();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
      const Color(0xffF5F5F5),

      appBar: AppBar(
        backgroundColor: Colors.blue,
        centerTitle: true,
        title: const Text(
          "EduRide Payment",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Center(

        child: Padding(

          padding:
          const EdgeInsets.all(20),

          child: Container(

            padding:
            const EdgeInsets.all(20),

            decoration: BoxDecoration(

              color: Colors.white,

              borderRadius:
              BorderRadius.circular(25),

              boxShadow: [

                BoxShadow(

                  color: Colors.grey
                      .withOpacity(0.2),

                  blurRadius: 10,

                  spreadRadius: 2,

                  offset:
                  const Offset(0, 5),
                ),
              ],
            ),

            child: Column(

              mainAxisSize:
              MainAxisSize.min,

              children: [

                // ICON
                Container(

                  height: 100,
                  width: 100,

                  decoration: BoxDecoration(

                    color: Colors.blue.shade100,

                    shape:
                    BoxShape.circle,
                  ),

                  child: const Icon(

                    Icons.account_balance_wallet,

                    size: 55,

                    color: Colors.blue,
                  ),
                ),

                const SizedBox(height: 20),

                // TITLE
                const Text(
                  "EduRide",

                  style: TextStyle(

                    fontSize: 28,

                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                // DESCRIPTION
                const Text(

                  "Complete your payment securely using Razorpay",

                  textAlign: TextAlign.center,

                  style: TextStyle(

                    fontSize: 16,

                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 25),

                // AMOUNT
                Container(

                  width: double.infinity,

                  padding:
                  const EdgeInsets.all(15),

                  decoration: BoxDecoration(

                    color:
                    Colors.orange.shade50,

                    borderRadius:
                    BorderRadius.circular(15),
                  ),

                  child: const Column(

                    children: [


                      SizedBox(height: 8),


                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // PAY BUTTON
                SizedBox(

                  width: double.infinity,

                  height: 55,

                  child: ElevatedButton(

                    onPressed: () {

                      openPayment();
                    },

                    style:
                    ElevatedButton.styleFrom(

                      backgroundColor:
                      Colors.blue,

                      shape:
                      RoundedRectangleBorder(

                        borderRadius:
                        BorderRadius.circular(15),
                      ),

                      elevation: 5,
                    ),

                    child: const Row(

                      mainAxisAlignment:
                      MainAxisAlignment.center,

                      children: [

                        Icon(

                          Icons.lock,

                          color:
                          Colors.white,
                        ),

                        SizedBox(width: 10),

                        Text(

                          "Pay Now",

                          style: TextStyle(

                            fontSize: 18,

                            fontWeight:
                            FontWeight.bold,

                            color:
                            Colors.white,
                          ),
                        ),
                      ],
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
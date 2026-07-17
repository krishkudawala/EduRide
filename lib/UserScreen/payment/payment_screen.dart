import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentPage extends StatefulWidget {
  final double amount;
  final String rideType;
  final String fromLocation;
  final String toLocation;
  final double distance;
  final String? rideId; // new

  const PaymentPage({
    super.key,
    required this.amount,
    required this.rideType,
    required this.fromLocation,
    required this.toLocation,
    required this.distance,
    this.rideId,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Razorpay razorpay;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    razorpay = Razorpay();

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWallet);
  }

  void openPayment() {
    if (_isProcessing) return;

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please login first"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    int amountInPaise = (widget.amount * 100).toInt();

    var options = {
      'key': 'rzp_test_SsMf2KMfJMATzw',
      'amount': amountInPaise,
      'name': 'EduRide',
      'description': '${widget.rideType} Ride - ${widget.fromLocation} to ${widget.toLocation}',
      'prefill': {
        'contact': '9876543210',
        'email': user.email ?? '',
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
      setState(() {
        _isProcessing = false;
      });
      debugPrint(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error opening payment: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("User not authenticated");
      }

      String paymentId = response.paymentId ?? DateTime.now().millisecondsSinceEpoch.toString();

      await FirebaseFirestore.instance
          .collection("payments")
          .doc(paymentId)
          .set({
        "uid": user.uid,
        "email": user.email ?? '',
        "paymentId": response.paymentId,
        "orderId": response.orderId,
        "signature": response.signature,
        "amount": widget.amount,
        "rideType": widget.rideType,
        "fromLocation": widget.fromLocation,
        "toLocation": widget.toLocation,
        "distance": widget.distance,
        "status": "Success",
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("payment_history")
          .doc(paymentId)
          .set({
        "paymentId": response.paymentId,
        "amount": widget.amount,
        "rideType": widget.rideType,
        "status": "Success",
        "createdAt": FieldValue.serverTimestamp(),
      });

      // ✅ FIXED – use set with merge
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set({
        "totalPayments": FieldValue.increment(1),
        "lastPaymentDate": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (widget.rideId != null) {
        await FirebaseFirestore.instance
            .collection('rides')
            .doc(widget.rideId)
            .update({
          'status': 'confirmed',
          'paymentId': response.paymentId,
          'paymentStatus': 'Success',
        });
      }

      setState(() {
        _isProcessing = false;
      });

      _showPaymentDialog(
        title: "Payment Successful! 🎉",
        message: "Your ${widget.rideType} ride payment of ₹${widget.amount.toStringAsFixed(2)} has been processed successfully.",
        isSuccess: true,
      );

    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      debugPrint("Error saving payment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Payment saved but error: $e"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
  void handlePaymentError(PaymentFailureResponse response) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
          .collection("payments")
          .add({
        "uid": user?.uid ?? 'unknown',
        "email": user?.email ?? 'unknown',
        "code": response.code,
        "message": response.message,
        "amount": widget.amount,
        "rideType": widget.rideType,
        "status": "Failed",
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (user != null) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .collection("payment_history")
            .add({
          "amount": widget.amount,
          "rideType": widget.rideType,
          "status": "Failed",
          "errorCode": response.code,
          "errorMessage": response.message,
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      setState(() {
        _isProcessing = false;
      });

      _showPaymentDialog(
        title: "Payment Failed ❌",
        message: response.message ?? "Payment failed. Please try again.",
        isSuccess: false,
      );

    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      debugPrint("Error saving failed payment: $e");
    }
  }

  void handleExternalWallet(ExternalWalletResponse response) {
    setState(() {
      _isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("External Wallet Selected: ${response.walletName}"),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showPaymentDialog({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
              size: 60,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSuccess ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (isSuccess) {
                Navigator.pop(context, true); // return success
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSuccess ? Colors.green : Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              isSuccess ? "Done" : "Try Again",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
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
      backgroundColor: const Color(0xffF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        centerTitle: true,
        elevation: 0,
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
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    size: 55,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "EduRide",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "${widget.rideType} Ride",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "${widget.fromLocation} → ${widget.toLocation}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                Text(
                  "Distance: ${widget.distance.toStringAsFixed(1)} km",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Amount:",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Ride Type:",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            widget.rideType,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total:",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "₹${widget.amount.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : openPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      disabledBackgroundColor: Colors.grey.shade400,
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Pay Now",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
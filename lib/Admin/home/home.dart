import 'package:eduride/UserScreen/FirstScreen/firstscreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  String _greeting = '';
  User? _currentUser;
  String _adminName = 'Admin';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getCurrentUser();
    _setGreeting();
    await _loadDashboardData();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
    }
  }

  Future<void> _getCurrentUser() async {
    try {
      _currentUser = _auth.currentUser;
      if (_currentUser != null) {
        final doc = await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null && data.containsKey('name')) {
            _adminName = data['name'] ?? 'Admin';
          }
        }
      }
    } catch (e) {
      print('Error getting user: $e');
    }
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      await _loadStats();
    } catch (e) {
      print('Error loading dashboard: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      // Get all collections in parallel for better performance
      final futures = await Future.wait([
        _firestore.collection('users').where('role', isEqualTo: 'student').get(),
        _firestore.collection('drivers').get(),
        _firestore.collection('buses').get(),
        _firestore.collection('rides').where('status', whereIn: ['pending', 'accepted', 'started']).get(),
        _firestore.collection('rides').where('status', whereIn: ['pending', 'accepted', 'started', 'completed', 'cancelled']).get(),
        _firestore.collection('payments').where('status', isEqualTo: 'Pending').get(),
        _firestore.collection('complaints').get(),
      ]);

      // Today's bookings and revenue
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final todayBookingsSnapshot = await _firestore
          .collection('rides')
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
          .where('createdAt', isLessThan: endOfDay)
          .get();

      final todayPaymentsSnapshot = await _firestore
          .collection('payments')
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
          .where('createdAt', isLessThan: endOfDay)
          .where('status', isEqualTo: 'Success')
          .get();

      // Calculate today's revenue
      double todayRevenue = 0;
      for (var doc in todayPaymentsSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('amount')) {
          todayRevenue += (data['amount'] ?? 0).toDouble();
        }
      }

      // Get active rides count
      final activeRides = futures[3] as QuerySnapshot<Map<String, dynamic>>;

      // Get pending complaints
      final complaints = futures[6] as QuerySnapshot<Map<String, dynamic>>;
      int pendingComplaints = 0;
      for (var doc in complaints.docs) {
        final data = doc.data();
        if (data['status'] == 'pending') {
          pendingComplaints++;
        }
      }

      setState(() {
        _stats = {
          'totalStudents': (futures[0] as QuerySnapshot<Map<String, dynamic>>).docs.length,
          'totalDrivers': (futures[1] as QuerySnapshot<Map<String, dynamic>>).docs.length,
          'totalBuses': (futures[2] as QuerySnapshot<Map<String, dynamic>>).docs.length,
          'activeRides': activeRides.docs.length,
          'todayBookings': todayBookingsSnapshot.docs.length,
          'todayRevenue': todayRevenue,
          'pendingPayments': (futures[5] as QuerySnapshot<Map<String, dynamic>>).docs.length,
          'totalComplaints': complaints.docs.length,
          'pendingComplaints': pendingComplaints,
        };
      });
    } catch (e) {
      print('Error in _loadStats: $e');
      // Set default values to avoid null errors
      setState(() {
        _stats = {
          'totalStudents': 0,
          'totalDrivers': 0,
          'totalBuses': 0,
          'activeRides': 0,
          'todayBookings': 0,
          'todayRevenue': 0.0,
          'pendingPayments': 0,
          'totalComplaints': 0,
          'pendingComplaints': 0,
        };
      });
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading dashboard...'),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 20),
              _buildStatsGrid(),
              const SizedBox(height: 20),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade700,
            Colors.blue.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.admin_panel_settings,
                  size: 30,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_greeting, $_adminName!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Welcome back! Here\'s your dashboard overview',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard(
          title: 'Students',
          value: _stats['totalStudents'] ?? 0,
          icon: Icons.person,
          color: Colors.blue,
          onTap: () {
            // Navigate to students
          },
        ),
        _buildStatCard(
          title: 'Drivers',
          value: _stats['totalDrivers'] ?? 0,
          icon: Icons.directions_bus,
          color: Colors.green,
          onTap: () {
            // Navigate to drivers
          },
        ),
        _buildStatCard(
          title: 'Buses',
          value: _stats['totalBuses'] ?? 0,
          icon: Icons.bus_alert,
          color: Colors.orange,
          onTap: () {
            // Navigate to buses
          },
        ),
        _buildStatCard(
          title: 'Active Rides',
          value: _stats['activeRides'] ?? 0,
          icon: Icons.electric_bike,
          color: Colors.purple,
          onTap: () {
            // Navigate to rides
          },
        ),
        _buildStatCard(
          title: 'Today\'s Bookings',
          value: _stats['todayBookings'] ?? 0,
          icon: Icons.book_online,
          color: Colors.teal,
          onTap: () {
            // Navigate to bookings
          },
        ),
        _buildStatCard(
          title: 'Revenue',
          value: '₹${(_stats['todayRevenue'] ?? 0).toStringAsFixed(0)}',
          icon: Icons.currency_rupee,
          color: Colors.green.shade700,
          onTap: () {
            // Navigate to payments
          },
        ),
        _buildStatCard(
          title: 'Pending Payments',
          value: _stats['pendingPayments'] ?? 0,
          icon: Icons.pending_actions,
          color: Colors.red,
          onTap: () {
            // Navigate to payments
          },
        ),
        _buildStatCard(
          title: 'Pending Complaints',
          value: _stats['pendingComplaints'] ?? 0,
          icon: Icons.warning_amber,
          color: Colors.deepOrange,
          onTap: () {
            // Navigate to complaints
          },
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required dynamic value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }



  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.push(context, MaterialPageRoute(builder: (context) =>Firstscreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
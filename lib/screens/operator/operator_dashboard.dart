import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/material_model.dart';
import '../../models/consumption_log_model.dart';
import '../../services/material_scanning_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login_screen.dart';

class OperatorDashboardScreen extends StatefulWidget {
  const OperatorDashboardScreen({Key? key}) : super(key: key);

  @override
  _OperatorDashboardScreenState createState() => _OperatorDashboardScreenState();
}

class _OperatorDashboardScreenState extends State<OperatorDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _operatorPages = [
    const OperatorHomeView(),
    const MaterialScanView(),
    const AssignedTasksView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartFab Operator Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _operatorPages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan Material',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task),
            label: 'Tasks',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

class OperatorHomeView extends StatelessWidget {
  const OperatorHomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'SmartFab Material Tracking',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Navigate to material scanning
            },
            child: const Text('Scan Material'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              // View assigned tasks
            },
            child: const Text('View Tasks'),
          ),
        ],
      ),
    );
  }
}

class MaterialScanView extends StatelessWidget {
  const MaterialScanView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          // Simulate scanning a material
          final barcode = Barcode(rawValue: 'sample-barcode');
          final material = await MaterialScanningService().scanAndFetchMaterial(barcode);

          if (material != null) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Material Found'),
                content: Text('Material Name: ${material.name}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          } else {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Material Not Found'),
                content: const Text('No material found for the scanned barcode.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        },
        child: const Text('Scan Material'),
      ),
    );
  }
}

class AssignedTasksView extends StatelessWidget {
  const AssignedTasksView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FirebaseFirestore.instance.collection('tasks').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading tasks'));
        }

        final tasks = snapshot.data?.docs ?? [];

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index].data();
            return ListTile(
              title: Text(task['title'] ?? 'No Title'),
              subtitle: Text(task['description'] ?? 'No Description'),
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsButton(context, 'Account Settings', Icons.person, () {
              // Navigate to Account Settings Page
            }),
            _buildSettingsButton(context, 'Notifications', Icons.notifications, () {
              // Navigate to Notifications Settings Page
            }),
            _buildSettingsButton(context, 'Privacy', Icons.lock, () {
              // Navigate to Privacy Settings Page
            }),
            const SizedBox(height: 20),
            _buildSettingsButton(context, 'Backup Users', Icons.backup, () async {
              await _backupFirestore(context, 'Users');
            }),
            _buildSettingsButton(context, 'Backup Admins', Icons.backup, () async {
              await _backupFirestore(context, 'Admins');
            }),
            _buildSettingsButton(context, 'Backup Courses', Icons.backup, () async {
              await _backupFirestore(context, 'Courses');
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context, String title, IconData icon, VoidCallback onPressed) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.teal),
        onTap: onPressed,
      ),
    );
  }

  Future<void> _backupFirestore(BuildContext context, String collectionName) async {
    try {
      // Step 1: Retrieve data from Firestore
      final snapshot = await FirebaseFirestore.instance.collection(collectionName).get();
      final data = snapshot.docs.map((doc) => doc.data()).toList();

      // Step 2: Convert data to JSON (or any format you prefer)
      final jsonData = data.toString();

      // Step 3: Get the directory to save the file
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/${collectionName.toLowerCase()}_backup_${DateTime.now().millisecondsSinceEpoch}.json';

      // Step 4: Save the JSON data to the file
      final file = File(path);
      await file.writeAsString(jsonData);

      // Step 5: Notify the user of success and show the file path
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$collectionName backup successful! Saved at $path'),
      ));
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$collectionName backup failed: $e'),
      ));
    }
  }
}

import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

// Import dart:html only for web
import 'dart:html' as html show Blob, Url, AnchorElement;

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

      // Step 2: Convert data to JSON
      final jsonData = jsonEncode(data);
      final fileName = '${collectionName.toLowerCase()}_backup_${DateTime.now().millisecondsSinceEpoch}.json';

      if (kIsWeb) {
        // Handle file download on web
        _downloadFileWeb(jsonData, fileName);
        _showSnackBar(context, '$collectionName backup successful! File downloaded.');
        return;
      }

      // Handle file saving on other platforms
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Select save location',
        fileName: fileName,
      );

      if (result != null) {
        final file = io.File(result);
        await file.writeAsString(jsonData);
        _showSnackBar(context, '$collectionName backup successful! Saved at $result');
      } else {
        _showSnackBar(context, 'Backup was not saved.');
      }
    } catch (e) {
      _showSnackBar(context, '$collectionName backup failed: $e');
    }
  }

  void _downloadFileWeb(String content, String fileName) {
    final blob = html.Blob([content], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

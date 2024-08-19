import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';

class UserDetailsPage extends StatelessWidget {
  final String userId;

  const UserDetailsPage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
        backgroundColor: const Color(0xFF160E30),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('Users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'User data not found.',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserInfo(Icons.person, 'Name', userData['name']),
                _buildUserInfo(Icons.email, 'Email', userData['email']),
                _buildUserInfo(Icons.card_membership, 'Student ID', userData['studentID']),
                const SizedBox(height: 20),
                _buildUserInfo(Icons.phone, 'Number', '${userData['dial']} ${userData['phone']}'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await _addContactFunctionality(
                      userData['name'],
                      '${userData['dial']} ${userData['phone']}',
                      context,
                    );
                  },
                  child: const Text('Contact'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserInfo(IconData icon, String label, String value) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(
          '$label:',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Future<void> _addContactFunctionality(String name, String phoneNumber, BuildContext context) async {
    if (await Permission.contacts.request().isGranted) {
      try {
        final newContact = Contact(
          givenName: name,
          phones: [Item(label: "mobile", value: phoneNumber)],
        );

        await ContactsService.addContact(newContact);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Contact added: $name - $phoneNumber'),
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to add contact: $e'),
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Permission to access contacts denied'),
      ));
    }
  }
}

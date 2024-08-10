import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About Etqan Center'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Etqan Center Logo
            Image.asset(
              'assets/etqan.png', // Replace with your logo path
              width: 150,
              height: 150,
            ),
            SizedBox(height: 20),
            Text(
              'Etqan Center',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Etqan Center is dedicated to providing the best educational resources and tools for students to achieve their academic goals. Our mission is to support and guide learners through a comprehensive range of courses and materials tailored to their needs.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Contact Us:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Email: support@etqan.com\nPhone: +123-456-7890\nWebsite: www.etqan.com',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class CourseDetailedPage extends StatelessWidget {
  final String courseName;
  final String courseDescription;
  final String courseImageUrl;

  const CourseDetailedPage({
    Key? key,
    required this.courseName,
    required this.courseDescription,
    required this.courseImageUrl, required String courseImage, required String imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(courseName),
        backgroundColor: Colors.blue, // Customize as needed
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border), // Wishlist icon
            onPressed: () {
              // Handle wishlist button press
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (courseImageUrl.isNotEmpty)
              Image.network(
                courseImageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 16),
            Text(
              courseName,
              style: textTheme.headlineMedium?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              courseDescription,
              style: textTheme.bodyLarge?.copyWith(fontSize: 16),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle enroll button press
                },
                child: Text('Enroll'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Customize as needed
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

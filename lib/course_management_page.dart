import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class CourseManagementPage extends StatefulWidget {
  const CourseManagementPage({Key? key}) : super(key: key);

  @override
  _CourseManagementPageState createState() => _CourseManagementPageState();
}

class _CourseManagementPageState extends State<CourseManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Management'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('Courses').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No courses available.'));
                }

                final courses = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    final imageUrl = _getImageUrl(course.id);

                    return ListTile(
                      leading: Image.network(
                        imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.error, size: 50);
                        },
                      ),
                      title: Text(course['name']),
                      subtitle: Text('Status: ${course['status']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              _showEditCourseDialog(course);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              _deleteCourse(course.id);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          FloatingActionButton(
            onPressed: _showAddCourseDialog,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  String _getImageUrl(String courseId) {
    return 'https://firebasestorage.googleapis.com/v0/b/etqan-center.appspot.com/o/courses%2F$courseId%2F$courseId.png?alt=media';
  }

  void _showAddCourseDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final _nameController = TextEditingController();
        final _descriptionController = TextEditingController();
        final _statusController = TextEditingController();
        final _durationController = TextEditingController();
        final _totalStudentsController = TextEditingController();
        File? _selectedImage;

        return AlertDialog(
          title: const Text('Add New Course'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Course Name'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: _statusController,
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              TextField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Duration'),
              ),
              TextField(
                controller: _totalStudentsController,
                decoration: const InputDecoration(labelText: 'Total Students'),
              ),
              SizedBox(height: 10),
              _selectedImage == null
                  ? const Text('No image selected.')
                  : Image.file(_selectedImage!, height: 100),
              TextButton(
                onPressed: () async {
                  final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      _selectedImage = File(pickedFile.path);
                    });
                  }
                },
                child: const Text('Select Image'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_selectedImage == null) {
                  // Handle no image selected
                  print('No image selected.');
                  return;
                }
                _addCourse(
                  _nameController.text,
                  _descriptionController.text,
                  _statusController.text,
                  _durationController.text,
                  int.tryParse(_totalStudentsController.text) ?? 0,
                  _selectedImage!,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addCourse(
      String name,
      String description,
      String status,
      String duration,
      int totalStudents,
      File imageFile,
      ) async {
    try {
      final courseId = name; // Use course name as the ID
      final newCourseRef = _firestore.collection('Courses').doc(courseId);

      // Add course data
      await newCourseRef.set({
        'name': name,
        'description': description,
        'status': status,
        'duration': duration,
        'totalStudents': totalStudents,
      });

      // Upload image
      final imageRef = _storage.ref('courses/$courseId/$courseId.png');
      final uploadTask = imageRef.putFile(imageFile);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print('Upload progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
      });

      await uploadTask.whenComplete(() => print('Image uploaded successfully!'));

      final downloadUrl = await imageRef.getDownloadURL();
      print('Image URL: $downloadUrl');
    } catch (e) {
      print('Error adding course: $e');
    }
  }

  void _showEditCourseDialog(DocumentSnapshot course) {
    showDialog(
      context: context,
      builder: (context) {
        final _nameController = TextEditingController(text: course['name']);
        final _descriptionController = TextEditingController(text: course['description']);
        final _statusController = TextEditingController(text: course['status']);
        final _durationController = TextEditingController(text: course['duration']);
        final _totalStudentsController = TextEditingController(text: course['totalStudents'].toString());
        File? _selectedImage;

        return AlertDialog(
          title: const Text('Edit Course'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Course Name'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: _statusController,
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              TextField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Duration'),
              ),
              TextField(
                controller: _totalStudentsController,
                decoration: const InputDecoration(labelText: 'Total Students'),
              ),
              SizedBox(height: 10),
              _selectedImage == null
                  ? const Text('No image selected.')
                  : Image.file(_selectedImage!, height: 100),
              TextButton(
                onPressed: () async {
                  final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      _selectedImage = File(pickedFile.path);
                    });
                  }
                },
                child: const Text('Select Image'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_selectedImage != null) {
                  _updateCourse(
                    course.id,
                    _nameController.text,
                    _descriptionController.text,
                    _statusController.text,
                    _durationController.text,
                    int.tryParse(_totalStudentsController.text) ?? 0,
                    _selectedImage!,
                  );
                } else {
                  _updateCourse(
                    course.id,
                    _nameController.text,
                    _descriptionController.text,
                    _statusController.text,
                    _durationController.text,
                    int.tryParse(_totalStudentsController.text) ?? 0,
                  );
                }
                Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateCourse(
      String courseId,
      String name,
      String description,
      String status,
      String duration,
      int totalStudents, [
        File? imageFile,
      ]) async {
    try {
      final courseRef = _firestore.collection('Courses').doc(courseId);

      // Update course data
      await courseRef.update({
        'name': name,
        'description': description,
        'status': status,
        'duration': duration,
        'totalStudents': totalStudents,
      });

      if (imageFile != null) {
        // Upload new image
        final imageRef = _storage.ref('courses/$courseId/$courseId.png');
        final uploadTask = imageRef.putFile(imageFile);

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          print('Upload progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
        });

        await uploadTask.whenComplete(() => print('Image uploaded successfully!'));
      }
    } catch (e) {
      print('Error updating course: $e');
    }
  }

  Future<void> _deleteCourse(String courseId) async {
    try {
      // Delete course document
      await _firestore.collection('Courses').doc(courseId).delete();

      // Delete course image
      final imageRef = _storage.ref('courses/$courseId/$courseId.png');
      await imageRef.delete();

      print('Course deleted successfully!');
    } catch (e) {
      print('Error deleting course: $e');
    }
  }
}

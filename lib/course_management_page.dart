import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'course_users_page.dart';
import 'user_detail_page.dart';

class CourseManagementPage extends StatefulWidget {
  const CourseManagementPage({Key? key}) : super(key: key);

  @override
  _CourseManagementPageState createState() => _CourseManagementPageState();
}

class _CourseManagementPageState extends State<CourseManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Management'),
        backgroundColor: Colors.teal,
      ),
      body: SafeArea(
        child: Column(
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
                    padding: const EdgeInsets.all(16.0),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      final imageUrl = _getImageUrl(course.id);

                      return Card(
                        elevation: 5.0,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(imageUrl),
                            backgroundColor: Colors.grey.shade200,
                            radius: 30,
                            onBackgroundImageError: (error, stackTrace) {
                              // handle image loading error
                            },
                          ),
                          title: Text(course['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold)),
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CourseUsersPage(
                                  courseId: course.id,
                                  courseName: course['name'],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FloatingActionButton(
                onPressed: _showAddCourseDialog,
                child: const Icon(Icons.add),
                backgroundColor: Colors.teal,
              ),
            ),
          ],
        ),
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
        bool _isUploading = false;
        double _uploadProgress = 0;

        return AlertDialog(
          title: const Text('Add New Course'),
          content: SingleChildScrollView(
            child: Column(
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
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                if (_selectedImage != null)
                  Column(
                    children: [
                      Image.file(_selectedImage!, height: 100, fit: BoxFit.cover),
                      if (_isUploading)
                        LinearProgressIndicator(value: _uploadProgress),
                    ],
                  )
                else
                  const Text('No image selected.'),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setState(() {
                          _selectedImage = File(pickedFile.path);
                        });
                      }
                    } catch (e) {
                      print('Error picking image: $e');
                    }
                  },
                  child: const Text('Select Image'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isEmpty ||
                    _descriptionController.text.isEmpty ||
                    _statusController.text.isEmpty ||
                    _durationController.text.isEmpty ||
                    _totalStudentsController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields.')),
                  );
                  return;
                }

                if (_selectedImage == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select an image.')),
                  );
                  return;
                }

                setState(() {
                  _isUploading = true;
                });
                await _addCourse(
                  _nameController.text,
                  _descriptionController.text,
                  _statusController.text,
                  _durationController.text,
                  int.tryParse(_totalStudentsController.text) ?? 0,
                  _selectedImage!,
                      (progress) {
                    setState(() {
                      _uploadProgress = progress;
                    });
                  },
                );
                setState(() {
                  _isUploading = false;
                });
                Navigator.of(context).pop();
                _showUploadSuccessDialog();
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
      void Function(double) onProgress,
      ) async {
    try {
      final courseId = name;
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
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes);
        onProgress(progress);
      });

      await uploadTask.whenComplete(() => print('Image uploaded successfully!'));

      final downloadUrl = await imageRef.getDownloadURL();
      print('Image URL: $downloadUrl');
    } catch (e) {
      print('Error adding course: $e');
    }
  }

  void _showUploadSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Upload Successful'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 50),
              const SizedBox(height: 10),
              const Text('The course has been added successfully.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
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

        return AlertDialog(
          title: const Text('Edit Course'),
          content: SingleChildScrollView(
            child: Column(
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
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _updateCourse(
                  course.id,
                  _nameController.text,
                  _descriptionController.text,
                  _statusController.text,
                  _durationController.text,
                  int.tryParse(_totalStudentsController.text) ?? 0,
                );
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
      int totalStudents,
      ) async {
    try {
      await _firestore.collection('Courses').doc(courseId).update({
        'name': name,
        'description': description,
        'status': status,
        'duration': duration,
        'totalStudents': totalStudents,
      });
    } catch (e) {
      print('Error updating course: $e');
    }
  }

  void _deleteCourse(String courseId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Course'),
          content: const Text('Are you sure you want to delete this course?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Delete course data
                  await _firestore.collection('Courses').doc(courseId).delete();

                  // Delete image
                  final imageRef = _storage.ref('courses/$courseId/$courseId.png');
                  await imageRef.delete();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Course deleted successfully.')),
                  );
                } catch (e) {
                  print('Error deleting course: $e');
                } finally {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

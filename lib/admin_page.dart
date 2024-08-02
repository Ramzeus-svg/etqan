import 'dart:io'; // Import dart:io for File
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  String? profilePictureUrl;
  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _courseOverviewController = TextEditingController();
  final TextEditingController _announcementController = TextEditingController();
  final TextEditingController _announcementContentController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _paymentIdController = TextEditingController();
  String? _courseImageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    loadAdminData();
  }

  Future<void> loadAdminData() async {
    String adminEmail = "admin@example.com"; // Replace with actual admin email
    var adminDoc = await FirebaseFirestore.instance.collection('Admins').doc(adminEmail).get();
    if (adminDoc.exists) {
      String profilePicturePath = adminDoc['profilePicturePath'];
      profilePictureUrl = await FirebaseStorage.instance.ref(profilePicturePath).getDownloadURL();
      setState(() {});
    }
  }

  Future<void> _pickCourseImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      String fileName = pickedFile.name;
      File file = File(pickedFile.path);
      UploadTask uploadTask = FirebaseStorage.instance.ref('course_images/$fileName').putFile(file);
      TaskSnapshot taskSnapshot = await uploadTask;
      _courseImageUrl = await taskSnapshot.ref.getDownloadURL();
    }
  }

  Future<void> _addCourse() async {
    if (_courseImageUrl != null && _courseNameController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('Courses').add({
        'name': _courseNameController.text,
        'overview': _courseOverviewController.text,
        'imageUrl': _courseImageUrl,
      });
      _courseNameController.clear();
      _courseOverviewController.clear();
      setState(() {
        _courseImageUrl = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Course added successfully')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all fields')));
    }
  }

  Future<void> _addAnnouncement() async {
    if (_announcementController.text.isNotEmpty && _announcementContentController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('Paragraphs').add({
        'Name': _announcementController.text,
        'Content': _announcementContentController.text,
      });
      _announcementController.clear();
      _announcementContentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Announcement added')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all fields')));
    }
  }

  Future<void> _updateUser(String userId) async {
    if (_userNameController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('Users').doc(userId).update({
        'name': _userNameController.text,
      });
      _userNameController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User updated successfully')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a name')));
    }
  }

  Future<void> _addGrade(String studentId) async {
    if (_gradeController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('Users').doc(studentId).update({
        'grade': _gradeController.text,
      });
      _gradeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Grade added successfully')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a grade')));
    }
  }

  Future<void> _confirmPayment(String paymentId) async {
    // Implement payment confirmation logic here
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment confirmed')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.person), text: 'Profile'),
            Tab(icon: Icon(Icons.book), text: 'Courses'),
            Tab(icon: Icon(Icons.announcement), text: 'Announcements'),
            Tab(icon: Icon(Icons.edit), text: 'Users'),
            Tab(icon: Icon(Icons.grade), text: 'Grades'),
            Tab(icon: Icon(Icons.payment), text: 'Payments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileSection(),
          _buildCoursesSection(),
          _buildAnnouncementsSection(),
          _buildUsersSection(),
          _buildGradesSection(),
          _buildPaymentsSection(),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          profilePictureUrl != null
              ? Image.network(profilePictureUrl!, width: 150, height: 150)
              : CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Admin Name', style: TextStyle(fontSize: 24)),
        ],
      ),
    );
  }

  Widget _buildCoursesSection() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(controller: _courseNameController, decoration: InputDecoration(labelText: 'Course Name')),
          TextField(controller: _courseOverviewController, decoration: InputDecoration(labelText: 'Overview')),
          SizedBox(height: 8),
          _courseImageUrl != null
              ? Image.network(_courseImageUrl!)
              : ElevatedButton(onPressed: _pickCourseImage, child: Text('Pick Image')),
          SizedBox(height: 16),
          ElevatedButton(onPressed: _addCourse, child: Text('Add Course')),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsSection() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(controller: _announcementController, decoration: InputDecoration(labelText: 'Announcement Name')),
          TextField(controller: _announcementContentController, decoration: InputDecoration(labelText: 'Content')),
          SizedBox(height: 16),
          ElevatedButton(onPressed: _addAnnouncement, child: Text('Add Announcement')),
        ],
      ),
    );
  }

  Widget _buildUsersSection() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(controller: _userNameController, decoration: InputDecoration(labelText: 'User Name')),
          SizedBox(height: 16),
          ElevatedButton(
              onPressed: () {
                // Replace with actual user ID
                String userId = 'user@example.com';
                _updateUser(userId);
              },
              child: Text('Update User')),
        ],
      ),
    );
  }

  Widget _buildGradesSection() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(controller: _gradeController, decoration: InputDecoration(labelText: 'Grade')),
          SizedBox(height: 16),
          ElevatedButton(
              onPressed: () {
                // Replace with actual student ID
                String studentId = 'student@example.com';
                _addGrade(studentId);
              },
              child: Text('Add Grade')),
        ],
      ),
    );
  }

  Widget _buildPaymentsSection() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(controller: _paymentIdController, decoration: InputDecoration(labelText: 'Payment ID')),
          SizedBox(height: 16),
          ElevatedButton(
              onPressed: () {
                String paymentId = _paymentIdController.text;
                _confirmPayment(paymentId);
              },
              child: Text('Confirm Payment')),
        ],
      ),
    );
  }
}

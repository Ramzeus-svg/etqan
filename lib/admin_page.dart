import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;
  String? profilePictureUrl;
  String? adminName;
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
    loadAdminData();
  }

  Future<void> loadAdminData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String adminEmail = user.email!;
        var adminDoc = await FirebaseFirestore.instance.collection('Admins').doc(adminEmail).get();

        if (adminDoc.exists) {
          Map<String, dynamic>? data = adminDoc.data();
          if (data != null) {
            String? profilePicturePath = data['profilePicturePath'] as String?;
            if (profilePicturePath != null && profilePicturePath.isNotEmpty) {
              profilePictureUrl = await FirebaseStorage.instance.ref(profilePicturePath).getDownloadURL();
            }

            adminName = data['name']?.split(' ')?.first ?? 'Unknown Admin';
          } else {
            print('No data found for admin email: $adminEmail');
          }
        } else {
          print('No document found for admin email: $adminEmail');
        }
      } else {
        print('No user is currently logged in.');
      }
    } catch (e) {
      print('Error loading admin data: $e');
    } finally {
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
      setState(() {});
    }
  }

  Future<void> _addCourse() async {
    String courseName = _courseNameController.text.trim();
    String courseOverview = _courseOverviewController.text.trim();

    if (courseName.isNotEmpty && courseOverview.isNotEmpty && _courseImageUrl != null) {
      await FirebaseFirestore.instance.collection('Courses').add({
        'name': courseName,
        'overview': courseOverview,
        'imageUrl': _courseImageUrl,
      });

      _courseNameController.clear();
      _courseOverviewController.clear();
      setState(() {
        _courseImageUrl = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Course added successfully!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all fields and pick an image')));
    }
  }

  Future<void> _addAnnouncement() async {
    String announcementName = _announcementController.text.trim();
    String announcementContent = _announcementContentController.text.trim();

    if (announcementName.isNotEmpty && announcementContent.isNotEmpty) {
      await FirebaseFirestore.instance.collection('Announcements').add({
        'Name': announcementName,
        'Content': announcementContent,
      });

      _announcementController.clear();
      _announcementContentController.clear();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Announcement added')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all fields')));
    }
  }

  Future<void> _updateUser(String userId) async {
    String userName = _userNameController.text.trim();

    if (userName.isNotEmpty) {
      await FirebaseFirestore.instance.collection('Users').doc(userId).update({
        'name': userName,
      });

      _userNameController.clear();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User updated successfully')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a name')));
    }
  }

  Future<void> _addGrade(String studentId) async {
    String grade = _gradeController.text.trim();

    if (grade.isNotEmpty) {
      await FirebaseFirestore.instance.collection('Users').doc(studentId).update({
        'grade': grade,
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _pages = [
      Scaffold(
        body: Padding(
          padding: EdgeInsets.all(4.0),
          child: Column(
            children: [
              // Admin Greeting and Picture
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    profilePictureUrl != null
                        ? CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(profilePictureUrl!),
                    )
                        : CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text(
                      adminName != null ? 'Hi, Dr $adminName' : 'Loading...',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2, // Number of columns
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  children: [
                    _buildIconTile(Icons.person, 'Profile', _buildProfileSection),
                    _buildIconTile(Icons.book, 'Courses', _buildCoursesSection),
                    _buildIconTile(Icons.announcement, 'Announcements', _buildAnnouncementsSection),
                    _buildIconTile(Icons.edit, 'Users', _buildUsersSection),
                    _buildIconTile(Icons.grade, 'Grades', _buildGradesSection),
                    _buildIconTile(Icons.payment, 'Payments', _buildPaymentsSection),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      Scaffold(
        body: Center(child: Text('Settings Page')),
      ),
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Main',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildIconTile(IconData icon, String title, Widget Function() page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.blue[100],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              padding: EdgeInsets.all(16),
              child: Icon(
                icon,
                size: 40,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Center(
        child: Text('Profile Section'),
      ),
    );
  }

  Widget _buildCoursesSection() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Courses'),
      ),
      body: Center(
        child: Column(
          children: [
            TextField(
              controller: _courseNameController,
              decoration: InputDecoration(labelText: 'Course Name'),
            ),
            TextField(
              controller: _courseOverviewController,
              decoration: InputDecoration(labelText: 'Course Overview'),
            ),
            ElevatedButton(
              onPressed: _pickCourseImage,
              child: Text('Pick Course Image'),
            ),
            _courseImageUrl != null
                ? Image.network(_courseImageUrl!)
                : Container(),
            ElevatedButton(
              onPressed: _addCourse,
              child: Text('Add Course'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementsSection() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Announcements'),
      ),
      body: Center(
        child: Column(
          children: [
            TextField(
              controller: _announcementController,
              decoration: InputDecoration(labelText: 'Announcement Name'),
            ),
            TextField(
              controller: _announcementContentController,
              decoration: InputDecoration(labelText: 'Announcement Content'),
            ),
            ElevatedButton(
              onPressed: _addAnnouncement,
              child: Text('Add Announcement'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersSection() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users'),
      ),
      body: Center(
        child: Column(
          children: [
            TextField(
              controller: _userNameController,
              decoration: InputDecoration(labelText: 'User Name'),
            ),
            ElevatedButton(
              onPressed: () {
                // Update user information with a specific user ID
                _updateUser('userId');
              },
              child: Text('Update User Information'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradesSection() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grades'),
      ),
      body: Center(
        child: Column(
          children: [
            TextField(
              controller: _gradeController,
              decoration: InputDecoration(labelText: 'Grade'),
            ),
            ElevatedButton(
              onPressed: () {
                // Add grade for a specific student ID
                _addGrade('studentId');
              },
              child: Text('Add Grade'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsSection() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payments'),
      ),
      body: Center(
        child: Column(
          children: [
            TextField(
              controller: _paymentIdController,
              decoration: InputDecoration(labelText: 'Payment ID'),
            ),
            ElevatedButton(
              onPressed: () {
                // Confirm payment with a specific payment ID
                _confirmPayment('paymentId');
              },
              child: Text('Confirm Payment'),
            ),
          ],
        ),
      ),
    );
  }
}

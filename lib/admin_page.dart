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

            adminName = data['name'] as String? ?? 'Unknown Admin'; // Provide default value if name is missing
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Row(
                children: [
                  profilePictureUrl != null
                      ? CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(profilePictureUrl!),
                  )
                      : CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text(
                    adminName != null ? 'Hi, Dr $adminName' : 'Loading...',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                // Navigate to settings page
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                // Implement logout functionality
              },
            ),
            ListTile(
              leading: Icon(Icons.roundabout_left),
              title: Text('About'),
              onTap: () {
                // Implement about functionality
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(4.0),
        child: GridView.count(
          crossAxisCount: 4, // Number of columns
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            _buildIconTile(Icons.person, 'Profile', _buildProfileSection),
            _buildIconTile(Icons.book, 'Courses', _buildCoursesSection),
            _buildIconTile(Icons.payment, 'Add Courses', _buildPaymentsSection),
            _buildIconTile(Icons.announcement, 'Announcements', _buildAnnouncementsSection),
            _buildIconTile(Icons.edit, 'Users', _buildUsersSection),
            _buildIconTile(Icons.grade, 'Grades', _buildGradesSection),
            _buildIconTile(Icons.payment, 'Payments', _buildPaymentsSection),
          ],
        ),
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
            Icon(icon, size: 50),
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 16)),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            profilePictureUrl != null
                ? Image.network(profilePictureUrl!, width: 150, height: 150)
                : CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(adminName != null ? adminName! : 'Loading...', style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesSection() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Courses'),
      ),
      body: Padding(
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
      ),
    );
  }

  Widget _buildAnnouncementsSection() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Announcements'),
      ),
      body: Padding(
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
      ),
    );
  }

  Widget _buildUsersSection() {
    // Implement users section UI and logic here
    return Scaffold(
      appBar: AppBar(
        title: Text('Users'),
      ),
      body: Center(
        child: Text('Users Section'),
      ),
    );
  }

  Widget _buildGradesSection() {
    // Implement grades section UI and logic here
    return Scaffold(
      appBar: AppBar(
        title: Text('Grades'),
      ),
      body: Center(
        child: Text('Grades Section'),
      ),
    );
  }

  Widget _buildPaymentsSection() {
    // Implement payments section UI and logic here
    return Scaffold(
      appBar: AppBar(
        title: Text('Payments'),
      ),
      body: Center(
        child: Text('Payments Section'),
      ),
    );
  }
}

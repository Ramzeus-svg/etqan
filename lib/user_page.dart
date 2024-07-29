import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart'; // Ensure you have this import for navigation

class UserPage extends StatefulWidget {
  final String email;

  UserPage({required this.email});

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  String userName = 'Loading...';
  String studentId = 'Loading...';
  List<CustomListItem> items = [];
  List<String> imageUrls = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeFirebase();
  }

  Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      await Future.wait([
        fetchUserData(widget.email),
        fetchDataFromFirestore(),
        fetchImagesFromStorage(),
      ]);
    } catch (e) {
      print('Error initializing Firebase: $e');
    }
  }

  Future<void> fetchUserData(String email) async {
    try {
      DocumentSnapshot documentSnapshot = await firestore
          .collection('Users')
          .doc(email.toLowerCase())
          .get();

      if (documentSnapshot.exists) {
        String name = documentSnapshot['name'] ?? '';
        String firstName = getFirstName(name);
        String studentId = documentSnapshot['studentID'] ?? '';

        setState(() {
          userName = firstName;
          this.studentId = studentId;
          isLoading = false;
        });
      } else {
        setState(() {
          userName = 'User not found';
          studentId = 'N/A';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        userName = 'Error';
        studentId = 'N/A';
        isLoading = false;
      });
    }
  }

  Future<void> fetchDataFromFirestore() async {
    try {
      QuerySnapshot querySnapshot = await firestore.collection('Paragraphs').get();
      List<CustomListItem> fetchedItems = querySnapshot.docs.map((doc) {
        return CustomListItem(
          name: doc['Name'] ?? 'Unknown',
          content: doc['Content'] ?? '',
        );
      }).toList();
      setState(() {
        items = fetchedItems;
        if (!isLoading) {
          isLoading = false;
        }
      });
    } catch (e) {
      print('Error fetching data from Firestore: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchImagesFromStorage() async {
    try {
      ListResult result = await storage.ref('images').listAll();
      List<String> urls = await Future.wait(
        result.items.map((Reference ref) async {
          String url = await ref.getDownloadURL();
          return url;
        }).toList(),
      );
      setState(() {
        imageUrls = urls;
      });
    } catch (e) {
      print('Error fetching images from Firebase Storage: $e');
      setState(() {
        imageUrls = [];
      });
    }
  }

  String getFirstName(String fullName) {
    List<String> parts = fullName.split(' ');
    return parts.isNotEmpty ? parts.first : '';
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _showOptionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
                onTap: () {
                  // Handle settings option
                  Navigator.pop(context); // Close the dialog
                },
              ),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                onTap: () {
                  Navigator.pop(context); // Close the dialog
                  _logout();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: _showOptionsDialog,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.purple,
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, $userName',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search here...',
                        border: InputBorder.none,
                        icon: Icon(Icons.search),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    childAspectRatio: 1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: [
                      _buildCategoryItem(Icons.category, 'Category'),
                      _buildCategoryItem(Icons.class_, 'Classes'),
                      _buildCategoryItem(Icons.free_breakfast, 'Free Course'),
                      _buildCategoryItem(Icons.book, 'BookStore'),
                      _buildCategoryItem(Icons.live_tv, 'Live Course'),
                      _buildCategoryItem(Icons.leaderboard, 'LeaderBoard'),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Courses', style: TextStyle(fontSize: 18)),
                      Text('See All', style: TextStyle(color: Colors.blue)),
                    ],
                  ),
                  SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    childAspectRatio: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: [
                      _buildCourseItem('Flutter', '55 Videos', 'assets/flutter_logo.png'),
                      _buildCourseItem('React Native', '55 Videos', 'assets/react_native_logo.png'),
                      _buildCourseItem('Python', '30 Videos', 'assets/python_logo.png'),
                      _buildCourseItem('Angular', '40 Videos', 'assets/angular_logo.png'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Wishlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 25,
          child: Icon(icon, size: 30),
        ),
        SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildCourseItem(String title, String subtitle, String imageUrl) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imageUrl, height: 80),
            SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 16)),
            Text(subtitle, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class CustomListItem {
  final String name;
  final String content;

  CustomListItem({required this.name, required this.content});
}

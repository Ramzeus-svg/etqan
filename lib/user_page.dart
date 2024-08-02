import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart'; // Ensure you have this import for navigation

class UserPage extends StatefulWidget {
  final String email;

  const UserPage({super.key, required this.email});

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  String userName = 'Loading...';
  String studentId = 'Loading...';
  List<CustomListItem> items = [];
  Map<String, String> courseImages = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    try {
      await Future.wait([
        fetchUserData(widget.email),
        fetchCoursesFromFirestore(),
        fetchCourseImagesFromStorage(),
      ]);
    } catch (e) {
      print('Error initializing data: $e');
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
        });
      } else {
        setState(() {
          userName = 'User not found';
          studentId = 'N/A';
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        userName = 'Error';
        studentId = 'N/A';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchCoursesFromFirestore() async {
    try {
      QuerySnapshot querySnapshot = await firestore.collection('Courses').get();
      List<CustomListItem> fetchedItems = querySnapshot.docs.map((doc) {
        return CustomListItem(
          name: doc['name'] ?? 'Unknown',
          content: '', // Assuming no content needed for courses
        );
      }).toList();
      setState(() {
        items = fetchedItems;
      });
    } catch (e) {
      print('Error fetching data from Firestore: $e');
    }
  }

  Future<void> fetchCourseImagesFromStorage() async {
    try {
      ListResult result = await storage.ref('courses').listAll();
      Map<String, String> imageUrls = {};
      for (var ref in result.prefixes) {
        // Loop through subfolders (courses)
        String courseName = ref.name; // Assuming folder name is the course name
        try {
          String courseImageUrl = await storage.ref('${ref.fullPath}/course_image.png').getDownloadURL();
          imageUrls[courseName] = courseImageUrl;
        } catch (e) {
          print('Error fetching image URL for $courseName: $e');
          // Handle cases where the image does not exist
        }
      }
      setState(() {
        courseImages = imageUrls;
      });
    } catch (e) {
      print('Error fetching images from Firebase Storage: $e');
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
      MaterialPageRoute(builder: (context) => const LoginPage()),
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
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  // Handle settings option
                  Navigator.pop(context); // Close the dialog
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
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
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: _showOptionsDialog,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async {
          await initializeData(); // Refresh data on pull
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                color: Colors.blue,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, $userName',
                      style: const TextStyle(color: Colors.white, fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const TextField(
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
                padding: const EdgeInsets.all(6),
                child: Column(
                  children: [
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      childAspectRatio: 1,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 8,
                      children: [
                        _buildCategoryItem(Icons.golf_course, 'Category'),
                        _buildCategoryItem(Icons.class_, 'Classes'),
                        _buildCategoryItem(Icons.free_breakfast, 'Free Course'),
                        _buildCategoryItem(Icons.book, 'BookStore'),
                        _buildCategoryItem(Icons.live_tv, 'Live Course'),
                        _buildCategoryItem(Icons.leaderboard, 'LeaderBoard'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Courses', style: TextStyle(fontSize: 18)),
                        Text('See All', style: TextStyle(color: Colors.blue)),
                      ],
                    ),
                    const SizedBox(height: 46),
                    GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final course = items[index];
                        final imageUrl = courseImages[course.name] ?? '';
                        return _buildCourseItem(course.name, '55 Videos', imageUrl);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
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
        currentIndex: 0, // Set this to the index of the currently selected item
        selectedItemColor: Colors.blue, // Color for the selected item
        unselectedItemColor: Colors.grey, // Color for the unselected items
        onTap: (index) {
          // Handle item tap, change state to update the selected index
        },
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
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildCourseItem(String title, String subtitle, String imageUrl) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(imageUrl, height: 80, fit: BoxFit.cover),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 16)),
            Text(subtitle, style: const TextStyle(color: Colors.grey)),
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

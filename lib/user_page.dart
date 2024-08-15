import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'login_page.dart';
import 'bottom_bar.dart';
import 'course_detailed_page.dart'; // Assuming you have this page

class UserPage extends StatefulWidget {
  final String email;

  const UserPage({super.key, required this.email});

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  late FirebaseMessaging _firebaseMessaging;

  String _userName = 'Loading...';
  String _studentId = 'Loading...';
  List<CustomListItem> _items = [];
  Map<String, String> _courseImages = {};
  bool _isLoading = true;
  int _selectedIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Initialize TabController
    _initializeData();
    _activateAppCheck();
    _initializeFirebaseMessaging();  // Initialize Firebase Messaging
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose of TabController
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchUserData(widget.email),
        _fetchCoursesFromFirestore(),
        _fetchCourseImagesFromStorage(),
      ]);
    } catch (e) {
      print('Error initializing data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _activateAppCheck() async {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.deviceCheck,
      );
    } catch (e) {
      print('Error activating Firebase App Check: $e');
    }
  }

  Future<void> _initializeFirebaseMessaging() async {
    _firebaseMessaging = FirebaseMessaging.instance;

    // Request permission for iOS devices
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Get the token for the device
    String? token = await _firebaseMessaging.getToken();
    print("Firebase Messaging Token: $token");

    // Listen for messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a message: ${message.messageId}');
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });

    // Listen for messages when the app is in the background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A message triggered app open: ${message.messageId}');
    });
  }

  Future<void> _fetchUserData(String email) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('Users').doc(email.toLowerCase()).get();

      if (doc.exists) {
        final String name = doc['name'] ?? '';
        final String studentId = doc['studentID'] ?? '';
        setState(() {
          _userName = _getFirstName(name);
          _studentId = studentId;
        });
      } else {
        setState(() {
          _userName = 'User not found';
          _studentId = 'N/A';
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _userName = 'Error';
        _studentId = 'N/A';
      });
    }
  }

  Future<void> _fetchCoursesFromFirestore({String? status}) async {
    try {
      Query query = _firestore.collection('Courses');
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      final QuerySnapshot querySnapshot = await query.get();
      final List<CustomListItem> fetchedItems = querySnapshot.docs.map((doc) {
        return CustomListItem(
          name: doc['name'] ?? 'Unknown',
          content: '', // Assuming no content needed for courses
        );
      }).toList();
      setState(() {
        _items = fetchedItems;
      });
    } catch (e) {
      print('Error fetching courses from Firestore: $e');
    }
  }

  Future<void> _fetchCourseImagesFromStorage() async {
    try {
      final QuerySnapshot courseQuerySnapshot = await _firestore.collection('Courses').get();
      final Map<String, String> imageUrls = {};

      for (var courseDoc in courseQuerySnapshot.docs) {
        final String courseName = courseDoc['name'] ?? '';
        if (courseName.isNotEmpty) {
          try {
            final String courseImagePath = 'courses/$courseName/$courseName.png';
            final String courseImageUrl = await _storage.ref(courseImagePath).getDownloadURL();
            imageUrls[courseName] = courseImageUrl;
          } catch (e) {
            print('Error fetching image URL for $courseName: $e');
            imageUrls[courseName] = 'https://example.com/placeholder.png';
          }
        }
      }

      setState(() {
        _courseImages = imageUrls;
      });
    } catch (e) {
      print('Error fetching course images: $e');
    }
  }

  String _getFirstName(String fullName) {
    return fullName.split(' ').firstWhere((part) => part.isNotEmpty, orElse: () => '');
  }

  Future<void> _logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
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
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : BottomBar(
        currentPage: _selectedIndex,
        tabController: _tabController,
        colors: [
          Colors.blue,
          Colors.red,
          Colors.green,
        ],
        unselectedColor: Colors.grey,
        barColor: Colors.white,
        end: 0.0,
        start: 10.0,
        onTap: _onItemTapped,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildMainPage(),
            _buildWishlistPage(),
            _buildProfilePage(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainPage() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTopSection(isSmallScreen),
          const SizedBox(height: 20),
          _buildCategoryButtons(isSmallScreen),
          const SizedBox(height: 20),
          _buildTrendingCoursesSection(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildWishlistPage() {
    return Center(
      child: Text('Wishlist Page', style: TextStyle(fontSize: 24)),
    );
  }

  Widget _buildProfilePage() {
    return Center(
      child: Text('Profile Page', style: TextStyle(fontSize: 24)),
    );
  }

  Widget _buildTopSection(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 20 : 40,
        vertical: isSmallScreen ? 30 : 50,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF160E30), // Purple background
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreetingAndNotificationIcon(isSmallScreen),
          const SizedBox(height: 20),
          Text(
            'Find your favorite Course here!',
            style: TextStyle(
              fontSize: isSmallScreen ? 22 : 28,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingAndNotificationIcon(bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $_userName!',
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Student ID: $_studentId',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: _showOptionsDialog,
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 30,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryButtons(bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCategoryButton('All'),
        _buildCategoryButton('Popular'),
        _buildCategoryButton('New'),
      ],
    );
  }

  Widget _buildCategoryButton(String label) {
    return ElevatedButton(
      onPressed: () {
        if (label == 'All') {
          _fetchCoursesFromFirestore();
        } else if (label == 'Popular') {
          _fetchCoursesFromFirestore(status: 'popular');
        } else if (label == 'New') {
          _fetchCoursesFromFirestore(status: 'new');
        }
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Text(label),
    );
  }

  Widget _buildTrendingCoursesSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trending Courses',
          style: TextStyle(
            fontSize: isSmallScreen ? 20 : 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: isSmallScreen ? 200 : 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              final imageUrl = _courseImages[item.name] ?? 'https://example.com/placeholder.png';
              return _buildCourseCard(item.name, imageUrl);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(String courseName, String imageUrl) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailedPage(courseName: courseName, courseDescription: '', courseImageUrl: '', courseImage: '', imageUrl: '',),
          ),
        );
      },
      child: Card(
        elevation: 5,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          children: [
            Image.network(imageUrl, height: 120, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(courseName, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'login_page.dart';
import 'bottom_bar.dart';

class UserPage extends StatefulWidget {
  final String email;

  const UserPage({super.key, required this.email});

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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

  Future<void> _fetchCoursesFromFirestore() async {
    try {
      final QuerySnapshot querySnapshot = await _firestore.collection('Courses').get();
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
              color: Colors.white,
              fontSize: isSmallScreen ? 24 : 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildSearchBar(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildGreetingAndNotificationIcon(bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: isSmallScreen ? 25 : 30,
              backgroundImage: const AssetImage('assets/avatar.png'),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $_userName!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 18 : 24,
                  ),
                ),
                Text(
                  'ID: $_studentId',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 12 : 16,
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          icon: Icon(
            Icons.notifications,
            color: Colors.white,
            size: isSmallScreen ? 30 : 35,
          ),
          onPressed: () {
            // Handle notification icon press
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isSmallScreen) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search courses...',
        hintStyle: TextStyle(
          color: Colors.white,
          fontSize: isSmallScreen ? 16 : 20,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        contentPadding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 10 : 15,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: Colors.white,
          size: isSmallScreen ? 24 : 28,
        ),
      ),
      style: TextStyle(
        color: Colors.white,
        fontSize: isSmallScreen ? 16 : 20,
      ),
    );
  }

  Widget _buildCategoryButtons(bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCategoryButton('All', Icons.grid_view, isSmallScreen),
        _buildCategoryButton('Popular', Icons.star, isSmallScreen),
        _buildCategoryButton('New', Icons.new_releases, isSmallScreen),
      ],
    );
  }

  Widget _buildCategoryButton(String label, IconData icon, bool isSmallScreen) {
    return ElevatedButton.icon(
      onPressed: () {
        // Handle category button press
      },
      icon: Icon(icon, size: isSmallScreen ? 20 : 24),
      label: Text(
        label,
        style: TextStyle(fontSize: isSmallScreen ? 16 : 20),
      ),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 10 : 15,
          horizontal: isSmallScreen ? 15 : 20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildTrendingCoursesSection(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trending Courses',
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final courseItem = _items[index];
              final courseImageUrl = _courseImages[courseItem.name] ?? '';

              return _buildCourseListItem(courseItem, courseImageUrl, isSmallScreen);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCourseListItem(CustomListItem item, String imageUrl, bool isSmallScreen) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        contentPadding: EdgeInsets.all(isSmallScreen ? 8 : 16),
        leading: imageUrl.isNotEmpty
            ? Image.network(
          imageUrl,
          width: isSmallScreen ? 50 : 80,
          height: isSmallScreen ? 50 : 80,
          fit: BoxFit.cover,
        )
            : null,
        title: Text(
          item.name,
          style: TextStyle(fontSize: isSmallScreen ? 18 : 22),
        ),
        subtitle: Text(
          item.content,
          style: TextStyle(fontSize: isSmallScreen ? 14 : 18),
        ),
        onTap: () {
          // Handle course item tap
        },
      ),
    );
  }
}

class CustomListItem {
  final String name;
  final String content;

  CustomListItem({required this.name, required this.content});
}

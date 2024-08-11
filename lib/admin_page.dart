import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'bottom_bar_admin.dart';
import 'admin_login_page.dart';

class AdminPage extends StatefulWidget {
  final String email;

  const AdminPage({super.key, required this.email});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String _userName = 'Loading...';
  String _adminId = 'Loading...';
  List<CustomListItem> _items = [];
  Map<String, String> _courseImages = {};
  bool _isLoading = true;
  int _selectedIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
    _activateAppCheck();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchAdminData(widget.email),
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

  Future<void> _fetchAdminData(String email) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('Admins').doc(email).get();

      if (doc.exists) {
        final String name = doc['name'] ?? '';
        final String adminId = doc['adminID'] ?? '';
        setState(() {
          _userName = _getFirstName(name);
          _adminId = adminId;
        });
      } else {
        print('Admin document not found for email: $email');
        setState(() {
          _userName = 'Admin not found';
          _adminId = 'N/A';
        });
      }
    } catch (e) {
      print('Error fetching admin data for email $email: $e');
      setState(() {
        _userName = 'Error';
        _adminId = 'N/A';
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
      MaterialPageRoute(builder: (context) => const AdminLoginPage()),
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
          : BottomBarAdmin(
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
            _buildAdminActionsPage(),
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

  Widget _buildAdminActionsPage() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildAdminActionsSection(isSmallScreen),
          const SizedBox(height: 20),
          _buildCourseManagementSection(isSmallScreen),
        ],
      ),
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
        color: Color(0xFF160E30),
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
            'Manage your courses here!',
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
              backgroundImage: const AssetImage('assets/etqan.png'),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, Dr.$_userName!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 18 : 24,
                  ),
                ),
                Text(
                  'ID: $_adminId',
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
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: _showOptionsDialog,
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search',
          border: InputBorder.none,
          suffixIcon: Icon(Icons.search, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildCategoryButtons(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCategoryButton('Courses', Icons.book, Colors.blue),
              _buildCategoryButton('Announcements', Icons.notifications, Colors.red),
              _buildCategoryButton('Grades', Icons.grade, Colors.green),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCategoryButton('Payments', Icons.payment, Colors.orange),
              _buildCategoryButton('Users', Icons.people, Colors.purple),
              _buildCategoryButton('Settings', Icons.settings, Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Icon(icon, size: 30, color: Colors.white),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.black)),
      ],
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
              fontSize: isSmallScreen ? 18 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
              ? const Text('No courses found.')
              : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _items.map((item) {
                return _buildCourseCard(
                  courseName: item.name,
                  imageUrl: _courseImages[item.name] ??
                      'https://example.com/placeholder.png',
                  isSmallScreen: isSmallScreen,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard({
    required String courseName,
    required String imageUrl,
    required bool isSmallScreen,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Container(
        width: isSmallScreen ? 150 : 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              blurRadius: 5,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                imageUrl,
                height: isSmallScreen ? 100 : 150,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                          : null,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                courseName,
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActionsSection(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Actions',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _buildAdminActionButton('Add Course', Icons.add, Colors.blue),
          const SizedBox(height: 10),
          _buildAdminActionButton('Edit Course', Icons.edit, Colors.green),
          const SizedBox(height: 10),
          _buildAdminActionButton('Delete Course', Icons.delete, Colors.red),
        ],
      ),
    );
  }

  Widget _buildAdminActionButton(String label, IconData icon, Color color) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  Widget _buildCourseManagementSection(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Management',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _buildCourseManagementButton('Add New Course'),
          const SizedBox(height: 10),
          _buildCourseManagementButton('Edit Existing Courses'),
        ],
      ),
    );
  }

  Widget _buildCourseManagementButton(String label) {
    return ElevatedButton(
      onPressed: () {},
      child: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
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

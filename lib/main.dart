import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

import 'firebase_notification.dart'; // Import your notification class here
import 'login_page.dart';
import 'admin_login_page.dart';
import 'register_page.dart';
import 'tour_page.dart';
import 'about_page.dart';
import 'user_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  try {
    // Initialize Firebase first
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }


    // Run the app after Firebase and notifications are initialized
    runApp(MyApp(homePage: await getInitialPage()));
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
}

Future<Widget> getInitialPage() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool rememberMe = prefs.getBool('rememberMe') ?? false;
  if (rememberMe) {
    String? email = prefs.getString('email');
    if (email != null) {
      return UserPage(email: email);
    }
  }
  return MyHomePage();
}

class MyApp extends StatelessWidget {
  final Widget homePage;

  const MyApp({super.key, required this.homePage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: homePage,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<CustomListItem> items = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchDataFromFirestore();
  }

  Future<void> fetchDataFromFirestore() async {
    try {
      final querySnapshot = await _firestore.collection('Paragraphs').get();
      setState(() {
        items = querySnapshot.docs.map((doc) {
          return CustomListItem(doc['Name'], doc['Content']);
        }).toList();
      });
    } catch (error) {
      print('Error getting documents: $error');
    }
  }

  Future<void> _showPasswordDialog() async {
    final TextEditingController passwordController = TextEditingController();
    String? adminPassword;

    try {
      DocumentSnapshot docSnapshot = await _firestore.collection('Passwords').doc('admin_password').get();
      if (docSnapshot.exists) {
        adminPassword = docSnapshot['password'];
      } else {
        throw Exception('Password document not found');
      }
    } catch (e) {
      print('Error retrieving password: $e');
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Admin Password'),
          content: TextField(
            controller: passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final String password = passwordController.text.trim();
                if (adminPassword != null && password == adminPassword) {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminLoginPage()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incorrect password')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void showContentDialog(String name, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(name),
          content: SingleChildScrollView(
            child: Text(content),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 200,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 200,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/login1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(top:40.0, left: 20.0),
                child: const Text(
                  'Hello, Guest',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'sans-serif-black',
                    fontSize: 24.0,
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height - 35.0,
                child: Column(
                  children: <Widget>[
                    Stack(
                      children: [
                        SingleChildScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: <Widget>[
                              buildCard(context, Icons.login, 'Login', LoginPage()),
                              buildCard(context, Icons.tour, 'Tour', TourPage()),
                              buildCard(context, Icons.app_registration, 'Register', RegisterPage()),
                              buildCard(context, Icons.admin_panel_settings, 'Admin', null), // Pass null for admin
                              buildCard(context, Icons.info, 'About', AboutPage()),
                            ],
                          ),
                        ),
                        if (kIsWeb) // Only show invisible buttons on web
                          Positioned.fill(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: _scrollLeft,
                                  child: Container(
                                    width: 30.0,
                                    height: double.infinity,
                                    color: Colors.transparent,
                                  ),
                                ),
                                GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: _scrollRight,
                                  child: Container(
                                    width: 30.0,
                                    height: double.infinity,
                                    color: Colors.transparent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 10.0, left: 0.0),
                      child: const Text(
                        'Announcements',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.0,
                        ),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: fetchDataFromFirestore,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 0.0),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              elevation: 5.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16.0),
                                title: Text(
                                  items[index].name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  items[index].content.length > 100
                                      ? '${items[index].content.substring(0, 100)}...'
                                      : items[index].content,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                onTap: () {
                                  showContentDialog(items[index].name, items[index].content);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCard(BuildContext context, IconData icon, String text, Widget? page) {
    double cardWidth = MediaQuery.of(context).size.width * 0.25; // Adjust card width based on screen size
    double cardHeight = cardWidth; // Keep height same as width

    return Column(
      children: [
        GestureDetector(
          onTap: page == null
              ? _showPasswordDialog
              : () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
          },
          child: Container(
            width: cardWidth,
            height: cardHeight,
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3), // changes position of shadow
                ),
              ],
            ),
            child: Icon(icon, size: 30.0, color: Colors.blue),
          ),
        ),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16.0,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class CustomListItem {
  final String name;
  final String content;

  CustomListItem(this.name, this.content);
}

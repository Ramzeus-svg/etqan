import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';
import 'admin_page.dart';
import 'register_page.dart';
import 'tour_page.dart';
import 'about_page.dart';
import 'user_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase only once
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyA9xV4MuX4_HIkNCRWy2dNOgRRfDPa8cw0",
      authDomain: "etqan-center.firebaseapp.com",
      databaseURL: "https://etqan-center-default-rtdb.europe-west1.firebasedatabase.app",
      projectId: "etqan-center",
      storageBucket: "etqan-center.appspot.com",
      messagingSenderId: "277429609000",
      appId: "1:277429609000:web:907d2bd40e028c7e104b1d",
      measurementId: "G-3HVEVDW1J3",
    ),
  );

  final initialPage = await getInitialPage();

  runApp(MyApp(homePage: initialPage));
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
      debugShowCheckedModeBanner: false,
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

  @override
  void initState() {
    super.initState();
    fetchDataFromFirestore();
  }

  void fetchDataFromFirestore() {
    _firestore.collection('Paragraphs').get().then((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        setState(() {
          items.add(CustomListItem(doc['Name'], doc['Content']));
        });
      }
    }).catchError((error) {
      print('Error getting documents: $error');
    });
  }

  void showPasswordDialog() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Admin Password'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Password'),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                if (passwordController.text == '1414') {
                  Navigator.of(context).pop();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AdminPage()));
                } else {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect password')));
                }
              },
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

  @override
  Widget build(BuildContext context) {
    // Hides the status bar and makes the app fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/logo.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(top: 1.0, left: 10.0),
                    child: const Text(
                      'Hello, Guest',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'sans-serif-black',
                        fontSize: 20.0,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: constraints.maxHeight - 30.0,
                    child: Column(
                      children: <Widget>[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: <Widget>[
                              buildCard(context, Icons.login, 'Login', LoginPage()),
                              buildCard(context, Icons.tour, 'Tour', TourPage()),
                              buildCard(context, Icons.app_registration, 'Register', RegisterPage()),
                              buildCard(context, Icons.admin_panel_settings, 'Admin', showPasswordDialog),
                              buildCard(context, Icons.info, 'About', AboutPage()),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 20.0, left: 0.0),
                          child: const Text(
                            'Announcements',
                            style: TextStyle(
                              color: Color(0xFF020255),
                              fontSize: 20.0,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 20.0),
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
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildCard(BuildContext context, IconData icon, String text, dynamic page) {
    double cardWidth = MediaQuery.of(context).size.width * 0.25; // Adjust card width based on screen size
    double cardHeight = cardWidth; // Keep height same as width

    return Column(
      children: <Widget>[
        Card(
          elevation: 15.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22.0),
          ),
          child: Container(
            width: cardWidth,
            height: cardHeight,
            margin: const EdgeInsets.all(1.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22.0),
              child: GestureDetector(
                onTap: () {
                  if (text == 'Admin') {
                    page(); // showPasswordDialog function call
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => page),
                    );
                  }
                },
                child: Icon(
                  icon,
                  size: cardWidth * 0.5, // Adjust icon size based on card width
                  color: Colors.blue, // Change the icon color if needed
                ),
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 1.0),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18.0,
            ),
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

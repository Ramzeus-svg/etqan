import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();

  String _selectedDialCode = '+20';
  bool _isRegisterButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_checkFields);
    _nameController.addListener(_checkFields);
    _passwordController.addListener(_checkFields);
    _usernameController.addListener(_checkFields);
    _phoneController.addListener(_checkFields);
    _universityController.addListener(_checkFields);
    _branchController.addListener(_checkFields);
  }

  void _checkFields() {
    setState(() {
      _isRegisterButtonEnabled = _emailController.text.isNotEmpty &&
          _nameController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty &&
          _usernameController.text.isNotEmpty &&
          _phoneController.text.isNotEmpty &&
          _universityController.text.isNotEmpty &&
          _branchController.text.isNotEmpty;
    });
  }

  Future<void> _registerUser() async {
    try {
      final UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final User? user = userCredential.user;
      if (user != null) {
        await _createUser();
      }
    } catch (e) {
      print('Exception registering user: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Registration failed: ${(e is FirebaseAuthException) ? e.message : e.toString()}'),
      ));
    }
  }

  Future<void> _createUser() async {
    final User? user = _firebaseAuth.currentUser;
    if (user != null) {
      final String userEmail = user.email!;
      final String studentID = _generateStudentID();
      final newUser = {
        'email': userEmail,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'dial': _selectedDialCode,
        'university': _universityController.text.trim(),
        'branch': _branchController.text.trim(),
        'username': _usernameController.text.trim(),
        'studentID': studentID,
        'status': 'Pending',
        'paymentstatus': 'Pending',
      };

      await _firestore.collection('Users').doc(userEmail).set(newUser);

      // Show a dialog upon successful registration
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Registration Successful'),
            content: Text('Your registration was completed successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  print('Navigating to login page...');
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  String _generateStudentID() {
    const String allowedChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final Random random = Random();
    return String.fromCharCodes(Iterable.generate(
      6,
          (_) => allowedChars.codeUnitAt(random.nextInt(allowedChars.length)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Mail',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedDialCode,
                      items: ['+20', '+966', '+44', '+33', '+49', '+81', '+86']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedDialCode = newValue!;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Country Code',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'WhatsApp Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: _universityController,
                decoration: InputDecoration(
                  labelText: 'University',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _branchController,
                decoration: InputDecoration(
                  labelText: 'Branch',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isRegisterButtonEnabled ? _registerUser : null,
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

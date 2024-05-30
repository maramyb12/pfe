import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class SignUp extends StatefulWidget {
  const SignUp({Key? key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _nameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _roleController = TextEditingController();
  final _numberController = TextEditingController();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> signUp() async {
    // Validate input fields
    if (_nameController.text.isEmpty ||
        _lastnameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _roleController.text.isEmpty ||
        _numberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please fill in all fields"),
        backgroundColor: Colors.red, // Customize the color
      ));
      return; // Stop execution if any fields are empty
    }

    // Validate email format
    if (!_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("L'adresse e-mail doit contenir un \"@\""),
        backgroundColor: Colors.red, // Customize the color
      ));
      return; // Stop execution if email format is incorrect
    }

    try {
      // Create user with email and password
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Retrieve Firebase Messaging token
      final token = await FirebaseMessaging.instance.getToken();

      // Prepare user data
      final user = <String, dynamic>{
        "uid": userCredential.user?.uid,
        "first_name": _nameController.text.trim(),
        "last_name": _lastnameController.text.trim(),
        "number": _numberController.text.trim(),
        "role": _roleController.text.trim(),
        "email": _emailController.text.trim(),
        "token": token,
      };

      // Save user data to Firestore using the UID as the document ID
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userCredential.user?.uid)
          .set(user);

      // Send password reset email for the user to set their password
      sendResetPasswordEmail(_emailController.text.trim());

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Registered Successfully"),
        backgroundColor: Colors.green, // Customize the color
      ));

      // Navigate to the list of users
      Navigator.of(context).pushReplacementNamed("ListUsers");
    } on FirebaseAuthException catch (e) {
      // Handle FirebaseAuthException
      print("Error creating user: ${e.message}");

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Registration Failed: ${e.message}"),
        backgroundColor: Colors.red, // Customize the color
      ));
    }
  }


  void sendResetPasswordEmail(String userEmail) {
    FirebaseAuth.instance.sendPasswordResetEmail(email: userEmail).then((_) {
      print('E-mail de réinitialisation envoyé avec succès à $userEmail');
    }).catchError((error) {
      print(
          'Erreur lors de l\'envoi de l\'e-mail de réinitialisation : $error');
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastnameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  OutlineInputBorder myBorders() {
    return const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(
        color: Colors.black, // Change the border color
        width: 2,
      ),
    );
  }

  OutlineInputBorder myFocusBorder() {
    return const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(
        color: Colors.deepPurple,
        width: 3,
      ),
    );
  }

  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: SizedBox(
          height: 10, // Spécifiez la hauteur souhaitée ici
          child: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
      key: _scaffoldKey,
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: SingleChildScrollView(
        child: Container(
          child: Column(
            children: [
              const SizedBox(height: 15), // Increased the spacing at the top
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: TextFormField(
                  controller: _emailController,
                  validator: emailValidator,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: const Icon(Icons.email),
                    border: myBorders(),
                    enabledBorder: myBorders(),
                    focusedBorder: myFocusBorder(),
                  ),
                ),
              ),
              Container(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: TextField(
                  controller: _nameController,
                  obscureText: false,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person),
                    labelText: "Name",
                    enabledBorder: myBorders(),
                    focusedBorder: myFocusBorder(),
                  ),
                ),
              ),
              Container(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: TextField(
                  controller: _lastnameController,
                  obscureText: false,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person),
                    labelText: "Last Name",
                    enabledBorder: myBorders(),
                    focusedBorder: myFocusBorder(),
                  ),
                ),
              ),
              Container(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: TextFormField(
                  controller: _passwordController,
                  validator: passwordValidator,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock),
                    labelText: "Password",
                    enabledBorder: myBorders(),
                    focusedBorder: myFocusBorder(),
                  ),
                ),
              ),
              Container(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: TextField(
                  controller: _roleController,
                  obscureText: false,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person),
                    labelText: "Role",
                    enabledBorder: myBorders(),
                    focusedBorder: myFocusBorder(),
                  ),
                ),
              ),
              Container(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: TextFormField(
                  controller: _numberController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone),
                    labelText: "Number",
                    enabledBorder: myBorders(),
                    focusedBorder: myFocusBorder(),
                  ),
                ),
              ),
              Container(height: 20),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: GestureDetector(
                  onTap: signUp,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 14, 10, 8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

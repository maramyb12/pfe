import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Ajout de l'import pour Firestore
import 'package:flutter_app/notification_api.dart';
import 'package:flutter_app/user_screen.dart';
import 'forgotpassword.dart'; // Assurez-vous que le fichier existe
import 'profil_screen.dart'; // Assurez-vous que le fichier existe
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  //permission notification
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (kDebugMode) {
    print('Permission granted: ${settings.authorizationStatus}');
  }

  User? user = FirebaseAuth.instance.currentUser;
  String? userUID = user?.uid;
  CollectionReference users = FirebaseFirestore.instance.collection('users');
  CollectionReference enregi = FirebaseFirestore.instance.collection('enregi');

  await FirebaseMessaging.instance.setAutoInitEnabled(true);

  if (user != null) {
    await users.doc(userUID).get().then((value) {
      if (value['role'] == 'user') {
        runApp(const isUser());
      }
      if (value['role'] == 'admin') {
        enregi.snapshots().listen((snapshot) async {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              var newCar = change.doc.data();
              String? token = await FirebaseMessaging.instance.getToken();
              if (newCar != null) {
                sendNotificationMessage(
                  userToken: token,
                  title: 'Véhicule détecté',
                  content: 'Nouveau Véhicule détecté',
                );
              }
            }
          }
        });
        runApp(const isAdmin());
      }
      print(value['role']);
    });
  } else {
    print("User is not logged in");
    runApp(const MyApp());
  }
}

class isAdmin extends StatelessWidget {
  const isAdmin({Key? key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ProfileScreen(),
    );
  }
}

class isUser extends StatelessWidget {
  const isUser({Key? key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ParkingDataPage(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 44, 167, 167),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Column(
                children: <Widget>[
                  Text(
                    "Welcome to ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontSize: 30,
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  /* Text(
                    "Parking Intellegent",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 15,
                    ),
                  )*/
                ],
              ),
              Column(
                children: <Widget>[
                  // Ajoutez le bouton de connexion
                  MaterialButton(
                    minWidth: double.infinity,
                    height: 60,
                    onPressed: () {
                      // Redirigez l'utilisateur vers la page de connexion
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                      );
                    },
                    color: Colors.black, // Set button color to black
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                          color: Color.fromARGB(255, 255, 255, 255)),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Text(
                      "Welcome",
                      style: TextStyle(
                        color: Colors
                            .white, // Ensure the text color contrasts with the black button
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool passwordObscured = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _errorMessage; // Message d'erreur

  Future<void> signIn() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (userCredential.user != null) {
          print("User UID: ${userCredential.user!.uid}");

          // Retrieve user role from Firestore
          DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

          if (userSnapshot.exists) {
            final userData = userSnapshot.data() as Map<String, dynamic>?;
            final userRole = userData?['role'] as String?;

            // Handle user role
            redirectToPage(userRole);
          }
        } else {
          print("User not authenticated");
        }
      } catch (e) {
        // Handle sign-in errors
        print("Sign-in error: $e");
        setState(() {
          _errorMessage =
              "Erreur de connexion. Veuillez vérifier vos informations.";
        });
      }
    }
  }

  void redirectToPage(String? userRole) {
    if (userRole == 'admin') {
      // Redirect user to admin page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      ); // Replace with navigation logic
    } else {
      // Redirect user to regular user page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ParkingDataPage()),
      ); // Replace with navigation logic
    }
  }

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
  }

  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer une adresse e-mail valide.';
    }
    if (!value.contains('@')) {
      return 'L\'adresse e-mail doit contenir un "@"';
    }
    return null;
  }

  String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un mot de passe.';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit avoir au moins 6 caractères.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 44, 167, 167),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pacifico',
                ),
              ),
              const Text(
                "Login to your App",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pacifico',
                ),
              ),
              const SizedBox(
                height: 44,
              ),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: "User Email",
                  //prefix: Icon(Icons.mail, color: Colors.white),
                  prefixIcon: Icon(Icons.lock, color: Colors.white),
                ),
                validator: emailValidator,
              ),
              const SizedBox(height: 26),
              TextFormField(
                controller: _passwordController,
                obscureText: passwordObscured,
                decoration: InputDecoration(
                    hintText: "User Password",
                    prefixIcon: const Icon(Icons.lock, color: Colors.white),
                    suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            passwordObscured = !passwordObscured;
                          });
                        },
                        icon: Icon(
                          passwordObscured
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white,
                        ))),
                validator: passwordValidator,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return const ForgotPasswordPage();
                            },
                          ),
                        );
                      },
                      child: const Text(
                        "Don't Remember Your Password?",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: GestureDetector(
                  onTap: signIn,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 22, 22, 22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        "Sign In",
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

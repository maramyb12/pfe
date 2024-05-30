import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Signup extends StatefulWidget {
  const Signup({Key? key}) : super(key: key);

  @override
  State<Signup> createState() => _SignUpState();
}

class _SignUpState extends State<Signup> {

  final _plateController = TextEditingController();
  final _nbController = TextEditingController();
  
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> signup() async {
    // Validate fields before attempting to save
   
    final plate = _plateController.text.trim();
    final nbString = _nbController.text.trim();
    final int? nb = int.tryParse(nbString);

    if (plate.isEmpty || nb == null) {
      _showErrorSnackBar('Please fill in all the fields.');
      return;
    }

    try {
      final plates = plate.split(',').map((e) => e.trim()).toList(); // Split and trim plate values

      final parkingData = <String, dynamic>{
        "plate": plates,
      };
      
      final nbDispo = <String, dynamic>{
        "nb": nb,
      };

      await FirebaseFirestore.instance
          .collection("parkingData")
          .doc()
          .set(parkingData);

      await FirebaseFirestore.instance
          .collection("nbDispo")
          .doc("max")
          .set(nbDispo);

      _showSuccessSnackBar('Registered Successfully!');
      Navigator.of(context).pushReplacementNamed("ListVehicule");
    } on FirebaseException catch (e) {
      _showErrorSnackBar('Registration Failed: ${e.message}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _plateController.dispose();
    _nbController.dispose();
    super.dispose();
  }

  OutlineInputBorder myBorders() {
    return const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(
        color: Colors.blue,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      key: _scaffoldKey,
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SingleChildScrollView(
        child: Container(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 25),
              ),
              Container(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: TextFormField(
                  controller: _plateController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.car_repair),
                    labelText: "Plate (comma separated if multiple)",
                    enabledBorder: myBorders(),
                    focusedBorder: myFocusBorder(),
                  ),
                ),
              ),
              Container(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: TextFormField(
                  controller: _nbController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.confirmation_number),
                    labelText: "Number Série",
                    enabledBorder: myBorders(),
                    focusedBorder: myFocusBorder(),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 25),
              ),
              Container(height: 20),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: GestureDetector(
                  onTap: signup,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 14, 10, 8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        "Save",
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

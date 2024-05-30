import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/signup_screen.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/vehicule.dart';
import 'CRUD_DATA/list_user.dart';
import 'CRUD_DATA/list_veh.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int index = 0 ;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final CollectionReference _parkingData =
      FirebaseFirestore.instance.collection("enregi");

      String sortBy = 'plate'; // Variable to track the sorting order
  TextEditingController searchController = TextEditingController(); // Controller for the search text field
  bool isSearching = false; // Variable to track if the user is currently searching
  List<DocumentSnapshot> data = []; // Initialize data as an empty list
  List<DocumentSnapshot> filteredData = []; // Initialize filteredData as an empty list
  bool barrierOpen = false; // Variable to track if the barrier is open


  Future<void> signOut() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }
  Future<int> getNbDispo(String documentId) async {
    final docRef =
        FirebaseFirestore.instance.collection('nbDispo').doc(documentId);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      return docSnap['dispo'];
    } else {
      return 0;
    }
  }
  Future<void> _showLogoutConfirmationDialog() async {
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to log out?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Logout'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the alert
                await signOut();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    
      appBar: AppBar(
        title: Text("Your Profile Page"),
        actions: [
          IconButton(
            onPressed: () {
              _showLogoutConfirmationDialog();
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      //  
     
      bottomNavigationBar: NavigationBarTheme(
        data:NavigationBarThemeData(
          indicatorColor: Colors.blue.shade100,
          labelTextStyle: MaterialStateProperty.all(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        child: NavigationBar(
          height: 55,
          backgroundColor: Color(0xFFf1f5fb),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          selectedIndex: index,
          animationDuration: Duration(seconds:1),
          onDestinationSelected: (index) =>
          setState(() => this.index = index),
        destinations: [
        NavigationDestination(
            icon: GestureDetector(
            onTap: () {
            Navigator.push(
             context,
             MaterialPageRoute(builder: (context) =>SignUp ()),
         );
        },
          child: Icon(Icons.person_add),
          ),
        label: 'User',
           ),
          NavigationDestination(
          icon: GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ListUsers()),
      );
    },
    child: Icon(Icons.menu),
  ),
           label: 'listU',
           ),
           NavigationDestination(
              icon: GestureDetector(
              onTap: () {
                Navigator.push(
                 context,
                  MaterialPageRoute(builder: (context) => Signup()),
           );
          },
             child: Icon(Icons.directions_car),
            ),
           label: 'add_veh',
           ),
           NavigationDestination(
              icon: GestureDetector(
              onTap: () {
                Navigator.push(
                 context,
                  MaterialPageRoute(builder: (context) => Listveh()),
           );
          }, 
             child: Icon(Icons.menu),
            ),
           label: 'list_ve',
           ),
           ]
           ),), // //
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text('Nombre de véhicules: '),
                        Text(
                          // Display the number of vehicles based on the search
                          isSearching
                              ? filteredData.length.toString()
                              : data.length.toString(),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        FutureBuilder<int>(
                          future: getNbDispo('dspo'),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Text('No Data Found');
                            } else {
                              return RichText(
                                text: TextSpan(
                                  style: TextStyle(color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text: 'Nombre de places disponibles: ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.normal),
                                    ),
                                    TextSpan(
                                      text: snapshot.data.toString(),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () {
                            setState(() {
                              isSearching = !isSearching; // Toggle search mode
                              if (!isSearching) {
                                searchController
                                    .clear(); // Clear the search field
                                filteredData = data; // Reset the filtered data
                              }
                            });
                          },
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.filter_list),
                          onSelected: (String value) {
                            setState(() {
                              sortBy = value;
                            });
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'plate',
                              child: Text('Trier par numéro de plaque'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'datee',
                              child: Text('Trier par date'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'etat',
                              child: Text('Trier par état (Sortie/Entrée)'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  height: isSearching
                      ? kToolbarHeight
                      : 0, // Show/hide search bar based on isSearching state
                  padding: EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Rechercher par numéro de plaque',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      // Perform search based on the entered plate number
                      setState(() {
                        // Filter data based on search
                        filteredData = data.where((item) {
                          if (item['plate'] is List) {
                            List plates = item['plate'];
                            return plates.join(', ').contains(value);
                          } else {
                            return item['plate'].toString().contains(value);
                          }
                        }).toList();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _parkingData.snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                if (streamSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else {
                  data = streamSnapshot
                      .data!.docs; // Update data with the fetched documents

                  if (sortBy == 'plate') {
                    data.sort((a, b) {
                      List platesA = a['plate'];
                      List platesB = b['plate'];
                      return platesA.join(', ').compareTo(platesB.join(', '));
                    });
                  } else if (sortBy == 'datee') {
                    data.sort((a, b) => b['datee'].compareTo(a[
                        'datee'])); // Inversion de l'ordre de comparaison pour trier par date décroissante
                  } else if (sortBy == 'etat') {
                    data.sort((a, b) => a['etat'].compareTo(b['etat']));
                  }
                  if (isSearching && filteredData.isEmpty) {
                    return Center(
                      child: Text(
                          'Aucun véhicule trouvé avec ce numéro de plaque.'),
                    );
                  }

                  return ListView(
                    children: [
                      Table(
                        border: TableBorder.all(
                          color: Colors.black,
                          style: BorderStyle.solid,
                          width: 2,
                        ),
                        children: [
                          const TableRow(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(10),
                                child: Text('Numéro de plaque'),
                              ),
                              Padding(
                                padding: EdgeInsets.all(10),
                                child: Text('Date'),
                              ),
                              Padding(
                                padding: EdgeInsets.all(10),
                                child: Text('État'),
                              ),
                            ],
                          ),
                          for (var item in isSearching ? filteredData : data)
                            TableRow(
                              children: [
                                Text(
                                  "${item['plate'][1]} تونس ${item['plate'][0]}",
                                  textDirection:
                                      TextDirection.rtl, // Right-to-left
                                ),
                                Text(item['datee'].toDate().toString(),
                                    textAlign: TextAlign.center),
                                Text(item['etat']),
                              ],
                            ),
                        ],
                      ),
                     
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

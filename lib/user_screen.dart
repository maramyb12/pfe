import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'main.dart';

class ParkingDataPage extends StatefulWidget {
  const ParkingDataPage({Key? key}) : super(key: key);

  @override
  _ParkingDataPageState createState() => _ParkingDataPageState();
}

class _ParkingDataPageState extends State<ParkingDataPage> {
  final CollectionReference _parkingData =
      FirebaseFirestore.instance.collection("enregi");

  final FirebaseAuth _auth = FirebaseAuth.instance;
  String searchQuery = '';
  String sortBy = 'plate'; // Variable to track the sorting order
  TextEditingController searchController =
      TextEditingController(); // Controller for the search text field
  bool isSearching =
      false; // Variable to track if the user is currently searching
  List<DocumentSnapshot> data = []; // Initialize data as an empty list
  List<DocumentSnapshot> filteredData =
      []; // Initialize filteredData as an empty list
  bool barrierOpen = false;
  bool barrierOpenForExit = false;
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

  
  Future<int> getNbMax(String documentId) async {
    final docRef =
        FirebaseFirestore.instance.collection('nbDispo').doc(documentId);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      return docSnap['nb'];
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
          title: const Text('Logout'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to log out?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout'),
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
  void initState() {
    super.initState();
    _initParkingDataStream();
  }

  late final StreamSubscription _parkingDataSubscription;
  bool isStreamCompleted = false;
  
  void _initParkingDataStream() {
    _parkingDataSubscription = _parkingData.snapshots().listen(
      (data) {
        List<QueryDocumentSnapshot> updatedData = data.docs;

        if (isSearching) {
          filteredData = updatedData.where((doc) {
            List plates = doc['plate'];
            return plates.any((plate) => plate.toLowerCase().contains(searchQuery.toLowerCase()));
          }).toList();
        } else {
          filteredData = updatedData;
        }

        // Check for new vehicle entries or exits
        _checkForVehicleEvents(updatedData);

        // Sort the data based on the selected sort option
        _sortData();

        // Update the UI using the StreamBuilder
        setState(() {});
      },
      onDone: () {
        // Set the flag to indicate the stream has completed
        setState(() {
          isStreamCompleted = true;
        });
        _showParkingDataStreamCompletedNotification();
      },
      onError: (error) {
        // Handle stream errors
        print('Error loading parking data: $error');
      },
    );
  }

  void _checkForVehicleEvents(List<QueryDocumentSnapshot> data) {
    for (var doc in data) {
      // Check the 'etat' field to determine if it's a vehicle entry or exit
      if (doc['etat'] == 'entry') {
        _createVehicleNotification('vehicle_entry');
      } else if (doc['etat'] == 'exit') {
        _createVehicleNotification('vehicle_exit');
      }
    }
  }

  void _createVehicleNotification(String eventType) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'basic_channel',
        title: 'Véhicule détecté',
        body: eventType == 'vehicle_entry'
            ? 'Un véhicule est entré dans le parking.'
            : 'Un véhicule est sorti du parking.',
      ),
    );
  }

  void _sortData() {
    if (sortBy == 'plate') {
      filteredData.sort((a, b) {
        List platesA = a['plate'];
        List platesB = b['plate'];
        return platesA.join(', ').compareTo(platesB.join(', '));
      });
    } else if (sortBy == 'datee') {
      filteredData.sort((a, b) => b['datee'].compareTo(a['datee']));
    } else if (sortBy == 'etat') {
      filteredData.sort((a, b) => a['etat'].compareTo(b['etat']));
    }
  }

  void _showParkingDataStreamCompletedNotification() {
    // Show a notification, e.g., using a SnackBar or a custom notification system
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Parking data stream has completed.'),
      ),
    );
  }

  @override
  void dispose() {
    _parkingDataSubscription.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Data'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              _showLogoutConfirmationDialog();
            },
            icon: const Icon(Icons.logout),
          ),
        ], // Prevent the back button in the AppBar
      ),
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
                        const Text('Nombre de véhicules: '),
                        Text(
                          // Display the number of vehicles based on the search
                          isSearching
                              ? filteredData.length.toString()
                              : data.length.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      children: [// if (snapshot.connectionState == ConnectionState.waiting) {return CircularProgressIndicator(); }
                       FutureBuilder<List<int>>(
  future: Future.wait([
    getNbDispo('dspo'),
    getNbMax('max'),
  ]),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const Text('Loading...');
    } else if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    } else {
      final nbDispo = snapshot.data![0];
      final nbMax = snapshot.data![1];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black),
              children: [
                const TextSpan(
                  text: 'Nombre de places disponibles: ',
                  style: TextStyle(fontWeight: FontWeight.normal),
                ),
                TextSpan(
                  text: nbDispo.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black),
              children: [
                const TextSpan(
                  text: 'Nombre maximum de places: ',
                  style: TextStyle(fontWeight: FontWeight.normal),
                ),
                TextSpan(
                  text: nbMax.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      );
    }
  },
),
                        
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.search),
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
                          icon: const Icon(Icons.filter_list),
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
                  duration: const Duration(milliseconds: 300),
                  height: isSearching
                      ? kToolbarHeight
                      : 0, // Show/hide search bar based on isSearching state
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
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
                  return const Center(
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
                    return const Center(
                     

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
                      Center(
                        child: ElevatedButton(
onPressed: () async {
  setState(() {
    barrierOpen = !barrierOpen;
  });

  // Update the barrier state in Firestore
  final docRef = FirebaseFirestore.instance.collection('barrierOpen').doc('entrer');
  await docRef.set({'val': barrierOpen});

  // Call the _createVehicleNotification function to trigger the notification
  _createVehicleNotification('vehicle_entry');
},
                        child: Text(
  barrierOpen ? 'Fermer la barrière' : 'Ouvrir la barrière pour entrer ',
  style: TextStyle(
    color: barrierOpen ?  Colors.green : Colors.red ,
  ),
),

                          style: ElevatedButton.styleFrom(
                            minimumSize:
                                const Size(150, 50), // Taille moyenne du bouton
                          ),
                        ),
                      ),
Container(height: 20),
Center(
  child: ElevatedButton(
 onPressed: () async {
  setState(() {
    barrierOpenForExit = !barrierOpenForExit;
  });

  // Update the barrier state in Firestore for exit
  final docRef = FirebaseFirestore.instance.collection('barrierOpen').doc('sortie');
  await docRef.set({'val': barrierOpenForExit});

  // Call the _createVehicleNotification function to trigger the notification
  _createVehicleNotification('vehicle_exit');
},
    child: Text(
      barrierOpenForExit ? 'Fermer la barrière' : 'Ouvrir la barrière pour sortir',
      style: TextStyle(
        color: barrierOpenForExit ? Colors.green : Colors.red,
      ),
    ),
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(150, 50), // Taille moyenne du bouton
    ),
  ),
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

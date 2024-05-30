import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Listveh extends StatefulWidget {
  const Listveh({Key? key}) : super(key: key);

  @override
  _listvehState createState() => _listvehState();
}

class _listvehState extends State<Listveh> {
  final CollectionReference _parkingData =
      FirebaseFirestore.instance.collection("enregi");
  final TextEditingController _etatController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _dateeController = TextEditingController();

  Future<void> _update(DocumentSnapshot? documentSnapshot) async {
    if (documentSnapshot != null) {
      _etatController.text = documentSnapshot['etat'];
      _plateController.text = documentSnapshot['plate'];
      _dateeController.text = documentSnapshot['datee'] != null
          ? (documentSnapshot['datee'] as Timestamp)
              .toDate()
              .toString()
              .substring(0, 19)
          : '';
    }

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _etatController,
                decoration: const InputDecoration(labelText: "Etat"),
              ),
              TextField(
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                controller: _plateController,
                decoration: const InputDecoration(labelText: "Plate"),
              ),
              TextField(
                keyboardType: TextInputType.datetime,
                controller: _dateeController,
                decoration: const InputDecoration(labelText: "Entry Date (yyyy-MM-dd HH:mm:ss)"),
              ),
              const SizedBox(height: 20),
             
            ],
          ),
        );
      },
    );
  }

  Future<void> _create() async {
    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _etatController,
                decoration: const InputDecoration(
                  labelText: "Etat",
                ),
              ),
              TextField(
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                controller: _plateController,
                decoration: const InputDecoration(
                  labelText: "Plate",
                ),
              ),
              const SizedBox(
                height: 20,
              ),
             
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(DocumentSnapshot documentSnapshot) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Confirm deletion"),
          content: Text("Are you sure you want to delete this veh?"),
          actions: <Widget>[
            TextButton(
              child: Text("Annuler"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Confirmer"),
              onPressed: () async {
                await _delete(documentSnapshot);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _delete(DocumentSnapshot documentSnapshot) async {
    await _parkingData.doc(documentSnapshot.id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: StreamBuilder(
        stream: _parkingData.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!streamSnapshot.hasData) {
            return Center(
              child: Text('No data available.'),
            );
          }

          return ListView.builder(
            itemCount: streamSnapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final DocumentSnapshot documentSnapshot =
                  streamSnapshot.data!.docs[index];
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(documentSnapshot['etat']),
                  subtitle: Text(documentSnapshot['plate'].toString()),
                  trailing: SizedBox(
                    width: 100,
                    child: Row(
                      children: [
                        
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _confirmDelete(documentSnapshot),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    
    );
  }
}
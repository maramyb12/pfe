import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ListUsers extends StatefulWidget {
  const ListUsers({Key? key}) : super(key: key);

  @override
  _ListUsersState createState() => _ListUsersState();
}

class _ListUsersState extends State<ListUsers> {
  final CollectionReference _users =
      FirebaseFirestore.instance.collection("users");


  final TextEditingController _numberController = TextEditingController();

  Future<void> _update(DocumentSnapshot? documentSnapshot) async {
    if (documentSnapshot != null) {
      _numberController.text = documentSnapshot["number"].toString();
      
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                controller: _numberController,
                decoration: const InputDecoration(
                  labelText: "Number",
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                child: const Text("Update"),
                onPressed: () async {
                 
                  int newNumber = int.tryParse(_numberController.text) ?? 0;

                  // Mettre à jour les données dans Firestore
                  await _users.doc(documentSnapshot?.id).update({
                    
                    "number": newNumber,
                  });

                  // Afficher un message de succès
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text("Data updated successfully."),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.green,
                    ),
                  );

                  Navigator.of(ctx).pop();
                },
              )
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
          title: const Text("Confirm deletion"),
          content: const Text("Are you sure you want to delete this user?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Annuler"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Confirmer"),
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
    await _users.doc(documentSnapshot.id).delete();
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
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: StreamBuilder(
        stream: _users.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!streamSnapshot.hasData) {
            return const Center(
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
                  title: Text(
                      "${documentSnapshot['first name']} ${documentSnapshot['last name']}"),
                  subtitle: Text(documentSnapshot['role'].toString()),
                  trailing: SizedBox(
                    width: 100,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _update(documentSnapshot),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
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

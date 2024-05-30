import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:developer' as devtools show log;


Future<bool> sendNotificationMessage({
  required String? userToken,
  required String title,
  required String content,
}) async {
  // Link firebase with the Rest API server
  final jsonCredentials =
  await rootBundle.loadString('images/pfe2-de743-f83844d37de4.json');
  final creds = auth.ServiceAccountCredentials.fromJson(jsonCredentials);

  final client = await auth.clientViaServiceAccount(
    creds,
    ['https://www.googleapis.com/auth/cloud-platform'],
  );

  // Send a POST request to the client using his Token
  const String senderId = '611538029065';
  final response = await client.post(
    Uri.parse('https://fcm.googleapis.com/v1/projects/$senderId/messages:send'),
    headers: {
      'content-type': 'application/json',
    },
    body: jsonEncode({
      'message': {
        'token': userToken,
        'notification': {'title': title, 'body': content}
      },
    }),
  );

  client.close();
  if (response.statusCode == 200) {
    return true; // Success!
  }

  devtools.log(
      'Notification Sending Error Response status: ${response.statusCode}');
  devtools.log('Notification Response body: ${response.body}');
  return false;
}


// Function to retrieve the token of the current user
Future<String?> getCurrentUserToken (String userID) async {
  try {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(userID).get();

    // Check if the document exists
    if(snapshot.exists) {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

      // Access the token field from the document
      return data['token'] as String?;
    } else {
      print('user does not exist');
      return null;
    }
  } catch (e) {
    print('error getting token: $e');
    return null;
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationPage extends StatelessWidget {
  final String? userEmail = FirebaseAuth.instance.currentUser?.email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF8DB6B4),
        title:
            const Text('Notification', style: TextStyle(color: Colors.white)),
      ),
      body: userEmail == null
          ? Center(child: Text('User not signed in'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('recipient_user_id', isEqualTo: userEmail)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  print('Firestore Query Error: ${snapshot.error}');
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No notifications'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot notification = snapshot.data!.docs[index];
                    String type = notification['type'] ?? 'No type';
                    String content = notification['content'] ?? 'No content';
                    bool read = notification['read'] ?? false;
                    Timestamp timestamp = notification['timestamp'];

                    return Card(
                      elevation: 3,
                      margin:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      color: Colors.grey[200], // Warna latar belakang abu-abu
                      child: ListTile(
                        title: Text(
                          '$type: $content',
                          style: TextStyle(fontSize: 16.0),
                        ),
                        subtitle: Text(
                          DateFormat.yMMMd()
                              .add_Hms()
                              .format(timestamp.toDate()),
                          style: TextStyle(color: Colors.grey),
                        ),
                        trailing: read
                            ? Icon(Icons.check_circle, color: Colors.green)
                            : Icon(Icons.circle),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

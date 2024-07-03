import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CommentPage extends StatefulWidget {
  final String postId;

  const CommentPage({required this.postId});

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  final TextEditingController _commentController = TextEditingController();

  Future<void> _addComment(BuildContext context) async {
    if (_commentController.text.isEmpty) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'text': _commentController.text,
      'timestamp': Timestamp.now(),
    }).then((value) {
      print('Post Commented successfully');
      // Send notification
      _sendNotification(widget.postId, 'Comment', 'User commented your post.');
    }).catchError((error) {
      print('Failed to like post: $error');
    });

    _commentController.clear();
  }

  void _sendNotification(String postId, String type, String content) async {
    DocumentSnapshot postSnapshot =
        await FirebaseFirestore.instance.collection('posts').doc(postId).get();
    String? recipientUserId = postSnapshot['username'];

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'recipient_user_id': recipientUserId,
        'timestamp': Timestamp.now(),
        'type': type,
        'content': content,
        'read': false,
      });
      print('Notification sent successfully');
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF8DB6B4),
        title: const Text('Comment', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                return ListView(
                  padding: EdgeInsets.all(8.0),
                  children: snapshot.data!.docs.map((DocumentSnapshot document) {
                    DateTime dateTime = document['timestamp'].toDate();
                    String formattedDateTime =
                        DateFormat.yMMMd().add_Hms().format(dateTime);
                    String text = document['text'];

                    return Card(
                      elevation: 3,
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      color: Colors.grey[200], // Warna latar belakang abu-abu
                      child: ListTile(
                        title: Text(
                          text,
                          style: TextStyle(fontSize: 16.0),
                        ),
                        subtitle: Text(
                          formattedDateTime,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                filled: true,
                fillColor: Colors.grey[200], // Warna latar belakang input teks
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
              ),
            ),
          ),
          SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              _addComment(context);
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 16.0), // Perbesar tombol "Add Comment"
            ),
            child: Text('Add Comment', style: TextStyle(fontSize: 16.0)),
          ),
          SizedBox(height: 16.0),
        ],
      ),
    );
  }
}

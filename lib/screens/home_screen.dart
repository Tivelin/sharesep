import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sharesep/Screens/detail_location_screen.dart';
import 'package:sharesep/Screens/notification_screen.dart';
import 'package:sharesep/Screens/post_detail_screen.dart';
import 'package:sharesep/screens/sign_in_screen.dart';
import 'package:sharesep/Screens/profile_screen.dart';
import 'package:sharesep/screens/add_post_screen.dart';
import 'package:sharesep/screens/comment_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  String _searchText = '';
  Stream<QuerySnapshot>? _querySnapshot;

  Future<bool> checkIfLiked(String postId) async {
    String? userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail != null) {
      DocumentSnapshot likeDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(userEmail)
          .get();
      return likeDoc.exists;
    }
    return false;
  }

  Future<bool> signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => SignInScreen()));
      return true;
    } catch (_) {
      return false;
    }
  }

  void _onCommentPressed(BuildContext context, String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentPage(postId: postId),
      ),
    );
  }

  Future<String?> _getUsernameFromPost(String postId) async {
    DocumentSnapshot postSnapshot =
        await FirebaseFirestore.instance.collection('posts').doc(postId).get();

    if (postSnapshot.exists) {
      Map<String, dynamic>? data = postSnapshot.data() as Map<String, dynamic>?;
      return data?['username'];
    } else {
      return null;
    }
  }

  void _onLikePressed(BuildContext context, String postId) async {
    String? userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail != null) {
      try {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .collection('likes')
            .where('user_id', isEqualTo: userEmail)
            .get();

        if (querySnapshot.docs.isEmpty) {
          await FirebaseFirestore.instance
              .collection('posts')
              .doc(postId)
              .collection('likes')
              .add({
            'user_id': userEmail,
            'timestamp': Timestamp.now(),
          });

          print('Post liked successfully');

          // Fetch the username from the post and send the notification
          String? username = await _getUsernameFromPost(postId);
          if (username != null) {
            _sendNotification(
                postId, 'Liked', 'User liked your post.', username);
          } else {
            print('Failed to fetch username');
          }
        } else {
          for (QueryDocumentSnapshot doc in querySnapshot.docs) {
            await doc.reference.delete();
          }
          print('Post unliked successfully');
        }
      } catch (error) {
        print('Error updating like status: $error');
      }
    } else {
      print('User email is null');
    }
  }

  void _sendNotification(String postId, String type, String content,
      String recipientUserId) async {
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
        title: const Text('Hello', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: () async {
              bool result = await signOut(context);
              if (result) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => SignInScreen()));
              }
            },
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
          IconButton(
            onPressed: () async {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationPage(),
                ),
              );
            },
            icon: const Icon(Icons.notifications, color: Colors.white),
          ),
          IconButton(
            onPressed: () async {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(),
                ),
              );
            },
            icon: const Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Padding ditambahkan di sini
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon:
                    Icon(Icons.search), // Ikon pencarian di sebelah kanan
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0), // Border radius
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value.toLowerCase();
                  if (_searchText == '') {
                    _querySnapshot = FirebaseFirestore.instance
                        .collection('posts')
                        .snapshots();
                  } else {
                    _querySnapshot = FirebaseFirestore.instance
                        .collection('posts')
                        .where('name', isGreaterThanOrEqualTo: _searchText)
                        .where('name',
                            isLessThanOrEqualTo: _searchText + '\uf8ff')
                        .snapshots();
                  }
                });
              },
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _querySnapshot ??
                    FirebaseFirestore.instance
                        .collection('posts')
                        .orderBy('timestamp')
                        .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No data found.'));
                  }

                  return ListView(
                    children:
                        snapshot.data!.docs.map((DocumentSnapshot document) {
                      DateTime dateTime =
                          (document['timestamp'] as Timestamp).toDate();
                      String formattedDateTime =
                          DateFormat.yMMMd().add_Hms().format(dateTime);
                      String judul = document.data().toString().contains('name')
                          ? document.get('name')
                          : 'No title';
                      String userEmail =
                          document.data().toString().contains('username')
                              ? document.get('username')
                              : 'No Username';
                      String imageUrl =
                          document.data().toString().contains('image_url')
                              ? document.get('image_url')
                              : '';
                      String text = document.data().toString().contains('text')
                          ? document.get('text')
                          : '';
                      String postId = document.id;
                      GeoPoint location = document["location"];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailPage(
                                postId: postId,
                                judul: judul,
                                userEmail: userEmail,
                                imageUrl: imageUrl,
                                text: text,
                                formattedDateTime: formattedDateTime,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                height: 200,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(imageUrl,
                                      fit: BoxFit.cover),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  userEmail,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  judul,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  text,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  formattedDateTime,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DetailLocationScreen(
                                        latitude: location.latitude,
                                        longitude: location.longitude,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                      'Latitude: ${location.latitude}, Longitude: ${location.longitude}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                          color: Colors.blue)),
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.comment),
                                    onPressed: () {
                                      _onCommentPressed(context, postId);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.favorite_border),
                                    onPressed: () {
                                      _onLikePressed(context, postId);
                                    },
                                  ),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('posts')
                                        .doc(postId)
                                        .collection('likes')
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      }

                                      int likesCount =
                                          snapshot.data?.docs.length ?? 0;

                                      return Text('$likesCount');
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.location_on),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              DetailLocationScreen(
                                            latitude: location.latitude,
                                            longitude: location.longitude,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddPostScreen()),
          );
        },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

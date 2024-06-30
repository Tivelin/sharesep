import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sharesep/screens/add_post_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sharesep/screens/sign_in_screen.dart';
import "package:intl/intl.dart";
import 'package:url_launcher/url_launcher.dart';

import 'comment_screen.dart';
import 'detail_location_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SignInScreenState signInScreenState = SignInScreenState();

  Future<bool> signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => SignInScreen()));
      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  void _onCommentPressed(BuildContext context, String postId) {
    // Navigate to the comment page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentPage(postId: postId),
      ),
    );
  }

  void _onLikePressed(BuildContext context, String postId) {
    // Save the post to the favorite page
    FirebaseFirestore.instance.collection('favorites').doc(postId).set({
      'post_id': postId,
      'timestamp': Timestamp.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () async {
              bool result = await signOut(context);
              if (result) signInScreenState.userCredential.value = '';
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp')
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              DateTime dateTime = document['timestamp'].toDate();
              String formattedDateTime =
                  DateFormat.yMMMd().add_Hms().format(dateTime);
              String userEmail = document["email"];
              String imageUrl = document["image_url"];
              String text = document["text"];
              String postId = document.id;
              GeoPoint location = document["location"];

              return Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 200,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(imageUrl, fit: BoxFit.cover),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(userEmail,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(text,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(formattedDateTime,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailLocationScreen(
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
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.comment),
                          onPressed: () {
                            _onCommentPressed(context, postId);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite_border),
                          onPressed: () {
                            _onLikePressed(context, postId);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.location_on),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailLocationScreen(
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
              );
            }).toList(),
          );
        },
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
}

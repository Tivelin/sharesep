import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sharesep/Screens/comment.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;
  final String judul;
  final String userEmail;
  final String imageUrl;
  final String text;
  final String formattedDateTime;

  PostDetailPage({
    required this.postId,
    required this.judul,
    required this.userEmail,
    required this.imageUrl,
    required this.text,
    required this.formattedDateTime,
  });

  @override
  _PostDetailPageState createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  bool _isLiked = false;
  int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    checkIfLiked();
    fetchLikesCount();
  }

  void checkIfLiked() {
    String? userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail != null) {
      FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('likes')
          .where('user_id', isEqualTo: userEmail)
          .get()
          .then((querySnapshot) {
        setState(() {
          _isLiked = querySnapshot.docs.isNotEmpty;
        });
      }).catchError((error) {
        print('Error checking if user liked post: $error');
      });
    }
  }

  void fetchLikesCount() {
    FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('likes')
        .get()
        .then((querySnapshot) {
      setState(() {
        _likesCount = querySnapshot.docs.length;
      });
    }).catchError((error) {
      print('Error fetching likes count: $error');
    });
  }

  void _onCommentPressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentPage(postId: widget.postId),
      ),
    );
  }

  void _onLikePressed() {
    String? userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail != null) {
      if (_isLiked) {
        FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('likes')
            .where('user_id', isEqualTo: userEmail)
            .get()
            .then((querySnapshot) {
          querySnapshot.docs.forEach((doc) {
            doc.reference.delete();
          });
          setState(() {
            _isLiked = false;
            _likesCount--;
          });
        }).catchError((error) {
          print('Error unliking post: $error');
        });
      } else {
        FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('likes')
            .add({
          'user_id': userEmail,
          'timestamp': Timestamp.now(),
        }).then((value) {
          setState(() {
            _isLiked = true;
            _likesCount++;
          });
          print('Post liked successfully');
        }).catchError((error) {
          print('Failed to like post: $error');
        });
      }
    } else {
      print('User email is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF8DB6B4),
        title: const Text('Post Detail', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(widget.imageUrl, fit: BoxFit.cover),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  widget.userEmail,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                widget.formattedDateTime,
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 16.0),
              Text(widget.text),
              SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.comment),
                    onPressed: () {
                      _onCommentPressed(context);
                    },
                  ),
                  IconButton(
                    icon: _isLiked
                        ? Icon(Icons.favorite)
                        : Icon(Icons.favorite_border),
                    onPressed: _onLikePressed,
                  ),
                  Text('$_likesCount'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

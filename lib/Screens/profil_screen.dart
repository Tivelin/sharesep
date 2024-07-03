import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isSignedIn = false;
  String? fullName = "";
  String userName = "";
  int likeCount = 0;
  File? _imageFile;
  String? _imageUrl;
  final ImagePicker _picker = ImagePicker();

  Future<void> _showImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Take a new photo'),
              onTap: () async {
                Navigator.of(context).pop();
                final pickedFile =
                    await _picker.pickImage(source: ImageSource.camera);
                if (pickedFile != null) {
                  setState(() {
                    _imageFile = File(pickedFile.path);
                  });
                  _uploadImageToFirestore();
                }
              },
            ),
            ListTile(
              title: Text('Choose from library'),
              onTap: () async {
                Navigator.of(context).pop();
                final pickedFile =
                    await _picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setState(() {
                    _imageFile = File(pickedFile.path);
                  });
                  _uploadImageToFirestore();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadImageToFirestore() async {
    try {
      if (_imageFile == null) return;

      Reference ref = FirebaseStorage.instance.ref().child(
          'user_profile_images/${FirebaseAuth.instance.currentUser?.uid}');
      UploadTask uploadTask = ref.putFile(_imageFile!);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);

      String downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _imageUrl = downloadUrl;
      });

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .get()
            .then((querySnapshot) {
          querySnapshot.docs.forEach((doc) {
            doc.reference.update({'profileImageUrl': _imageUrl});
          });
        });
      }

      print('Image uploaded successfully: $_imageUrl');
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  // Remaining profile page code...

  ThemeMode _themeMode = ThemeMode.system; // Default to system theme mode
  Color _backgroundColor = Colors.white;
  Color _textColor = Colors.black;

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Fetch additional user details from Firestore
        DocumentSnapshot<Map<String, dynamic>> userSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userSnapshot.exists) {
          Map<String, dynamic>? data = userSnapshot.data();
          setState(() {
            userName = user.email ?? "";
            fullName = data?['fullName'] ?? "";
            isSignedIn = true;
          });
        } else {
          print('User document does not exist.');
        }

        // Count likes from posts->likes collection
        QuerySnapshot<Map<String, dynamic>> likesSnapshot =
            await FirebaseFirestore.instance
                .collection('posts')
                .doc(user.uid)
                .collection('likes')
                .get();

        setState(() {
          likeCount = likesSnapshot.size;
        });
      } catch (e) {
        print('Error fetching user data: $e');
      }
    } else {
      print('No user is currently signed in.');
    }
  }

  void signIn() {
    setState(() {
      Navigator.pushNamed(context, '/signin');
    });
  }

  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
        _backgroundColor = Colors.black;
        _textColor = Colors.white;
      } else {
        _themeMode = ThemeMode.light;
        _backgroundColor = Colors.white;
        _textColor = Colors.black;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8DB6B4),
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background_profil.jpeg'),
              fit: BoxFit.fitWidth,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.7),
                BlendMode.darken,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              children: [
                // White overlay after the divider
                Positioned(
                  top: 270, // Adjust the position according to your layout
                  left: 0,
                  right: 0,
                  child: Container(
                    color: _backgroundColor,
                    height: 500, // Adjust the height according to your layout
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Header
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 70),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.grey, width: 2),
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 85,
                                child: Image.network(
                                  _imageUrl ??
                                      'https://example.com/default_image.jpg', // Provide a default image URL if _imageUrl is null
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            if (isSignedIn)
                              IconButton(
                                onPressed: () {
                                  _showImageSourceDialog();
                                },
                                icon: Icon(
                                  Icons.camera_alt,
                                  color: Colors.grey[50],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 4),
                    // Nama dan Username
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Nama',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            fullName ?? '',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: _textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pengguna',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            userName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: _textColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Masakan Favorit
                          Text(
                            'Masakan Favorit',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Toggle Theme Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 400,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                color: Colors.grey[300],
                                width: double.infinity,
                                height: 40,
                                child: TextButton(
                                  onPressed: signIn,
                                  child: const Text("Simpan Postingan"),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 400,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                color: Colors.grey[300],
                                width: double.infinity,
                                height: 40,
                                child: TextButton(
                                  onPressed: _toggleTheme,
                                  child: Text(
                                    _themeMode == ThemeMode.light
                                        ? 'Switch to Dark Mode'
                                        : 'Switch to Light Mode',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
<<<<<<< Updated upstream
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
=======
<<<<<<< Updated upstream
=======
import 'home_screen.dart';
>>>>>>> Stashed changes
>>>>>>> Stashed changes

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
<<<<<<< Updated upstream
  final _postTextController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  LatLng? _location;
=======
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Post'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: () async => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              ),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    final pickedFile =
                        await _picker.pickImage(source: ImageSource.camera);
                    if (pickedFile != null) {
                      setState(() {
                        _image = pickedFile;
                      });
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(color: Colors.grey),
                    width: 200,
                    height: 200,
                    child: _image != null
                        ? Image.file(File(_image!.path))
                        : Icon(
                            Icons.camera_alt,
                            color: Colors.grey[800],
                          ),
                  ),
                ),
              ],
            ),
          ),
          TextField(
            controller: _judulController,
            decoration: const InputDecoration(
              labelText: 'Judul',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _deskripsiController,
            decoration: const InputDecoration(
              labelText: 'Deskripsi',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (context) => const HomeScreen()));
                },
                child: const Text('Post')),
          ),
        ]),
      ),
    );
  }
<<<<<<< Updated upstream

  Future<void> _uploadPost() async {
    if (_image == null || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image and description are required')),
      );
      return;
    }

    String imageUrl;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('post_images')
          .child('${DateTime.now()}.jpg');
      await ref.putFile(_image!);
      imageUrl = await ref.getDownloadURL();
    } catch (e) {
      print(e);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final username = user?.email ?? 'Anonymous';

    FirebaseFirestore.instance.collection('posts').add({
      'imageUrl': imageUrl,
      'description': _descriptionController.text,
      'timestamp': Timestamp.now(),
      'username':
          username, // Hardcoded username, you can replace this with actual user data
    });

    Navigator.pop(context);
  }
>>>>>>> Stashed changes

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                await _showImageSourceDialog();
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(50),
                ),
                child: _image != null
                    ? Image.file(File(_image!.path))
                    : Icon(Icons.camera_alt),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _postTextController,
              decoration: InputDecoration(
                hintText: 'Masukkan deskripsi posting',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (_image == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select an image')),
                  );
                  return;
                }
                _location = await CurrentLocation.getCurrentLocation();
                Reference referenceRoot = FirebaseStorage.instance.ref();
                Reference referenceDirImages = referenceRoot.child("images");
                Reference referenceImagesToUpload =
                    referenceDirImages.child(_image!.path.split("/").last);
                try {
                  final uploadTask =
                      await referenceImagesToUpload.putFile(File(_image!.path));
                  final downloadUrl = await uploadTask.ref.getDownloadURL();

                  // Add Firebase Cloud Firestore functionality here
                  final CollectionReference posts =
                      FirebaseFirestore.instance.collection('posts');
                  final User? user = _auth.currentUser;
                  final String? userEmail = user?.email;
                  await posts.add({
                    'text': _postTextController.text,
                    'image_url': downloadUrl,
                    'email': userEmail,
                    'timestamp': Timestamp.now(),
                    'location':
                        GeoPoint(_location!.latitude, _location!.longitude),
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Image uploaded successfully')),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error uploading image: $e')),
                  );
                }
              },
              child: Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
<<<<<<< Updated upstream

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
                    _image = pickedFile;
                  });
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
                    _image = pickedFile;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _postTextController.dispose();
    super.dispose();
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng({required this.latitude, required this.longitude});
}

class CurrentLocation {
  static Future<LatLng> getCurrentLocation() async {
    final status = await Permission.location.status;
    if (!status.isGranted) {
      final result = await Permission.location.request();
      if (result != PermissionStatus.granted) {
        throw 'Location permission denied';
      }
    }

    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return LatLng(latitude: position.latitude, longitude: position.longitude);
    } catch (e) {
      throw 'Error getting current location: $e';
    }
  }
=======
=======
>>>>>>> Stashed changes
>>>>>>> Stashed changes
}

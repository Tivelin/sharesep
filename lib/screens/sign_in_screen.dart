import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sharesep/screens/home_screen.dart';
import 'package:sharesep/screens/sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Sign In'),
        ),
        body: Padding(
        padding: const EdgeInsets.all(16.0),
    child: SingleChildScrollView(
    child: Column(
    children: [
    const SizedBox(height: 32.0),
    TextField(
    controller: _emailController,
    decoration: const InputDecoration(
    labelText: 'Email',
    border: OutlineInputBorder(),
    ),
    ),
    const SizedBox(height: 16.0),
    TextField(
    controller: _passwordController,
    decoration: const InputDecoration(
    labelText: 'Password',
    border: OutlineInputBorder(),
    ),
    obscureText: true,
    ),
    const SizedBox(height: 16.0),
    ElevatedButton(
    onPressed: () async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
// Validasi email
    if (email.isEmpty || !isValidEmail(email)) {
    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Please enter a valid
    email')),
    );
    return;
    }
// Validasi password
    if (password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Please enter your
    password')),
    );
    return;
    }
    try {
// Lakukan sign in dengan email dan password
    await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: password,
    );
// Jika berhasil sign in, navigasi ke halaman beranda
    Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (context) => const
    HomeScreen()),
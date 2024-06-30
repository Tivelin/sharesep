import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailLocationScreen extends StatelessWidget {
  final double latitude;
  final double longitude;

  const DetailLocationScreen(
      {super.key, required this.latitude, required this.longitude});

  void _openGoogleMaps() async {
    final url = 'https://maps.google.com/maps?q=$latitude,$longitude';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Details'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Latitude: $latitude, Longitude: $longitude'),
            ElevatedButton(
              onPressed: _openGoogleMaps,
              child: const Text('Go to'),
            ),
          ],
        ),
      ),
    );
  }
}

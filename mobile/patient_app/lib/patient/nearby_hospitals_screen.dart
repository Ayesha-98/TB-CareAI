import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const primaryColor = Color(0xFF1B4D3E); // Dark green
const secondaryColor = Color(0xFFFFFFFF); // White
const bgColor = Color(0xFFFFFFFF);

class NearbyHospitalsScreen extends StatefulWidget {
  const NearbyHospitalsScreen({super.key});

  @override
  State<NearbyHospitalsScreen> createState() => _NearbyHospitalsScreenState();
}

class _NearbyHospitalsScreenState extends State<NearbyHospitalsScreen> {
  String locationMessage = 'Tap the button to find nearby TB hospitals.';
  Position? currentPosition;

  late String patientId;

  @override
  void initState() {
    super.initState();

    // ✅ Get the current Firebase user ID
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      patientId = user.uid;
    } else {
      patientId = ""; // fallback if no user logged in
      debugPrint("⚠ No Firebase user logged in!");

      WidgetsBinding.instance.addPostFrameCallback((_) {
         Navigator.pushReplacementNamed(context, '/signin');
       });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        locationMessage = 'Location services are disabled.';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          locationMessage = 'Location permission denied.';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        locationMessage = 'Location permission permanently denied.';
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      currentPosition = position;
      locationMessage =
      'Your location: (${position.latitude}, ${position.longitude})';
    });

    // ✅ Save to Firestore under patients → [UID] → geolocation → coordinates
    await FirebaseFirestore.instance
        .collection('patients')
        .doc(patientId)
        .collection('geolocation')
        .doc('coordinates')
        .set({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // ✅ Open Google Maps with location
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/tb+hospitals+near+me/@${position.latitude},${position.longitude},14z',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      setState(() {
        locationMessage = 'Could not open maps.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: secondaryColor,
        title: const Text(
          'Nearby TB Hospitals',
          style: TextStyle(color: primaryColor),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: secondaryColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_hospital, color: primaryColor, size: 60),
              const SizedBox(height: 16),
              Text(
                locationMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color:primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.location_on),
                label: const Text('Locate Nearby TB Hospitals'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _getCurrentLocation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

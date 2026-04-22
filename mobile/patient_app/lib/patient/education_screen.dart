import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

const primaryColor = Color(0xFF1B4D3E); // Dark green
const secondaryColor = Color(0xFFFFFFFF); // White
const bgColor = Color(0xFFFFFFFF);

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  final String apiKey = 'AIzaSyDRX_qgjJDwnaDMsuht-RmlFbHyimbsjpk';
  List videos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchVideos();
  }

  Future<void> fetchVideos() async {
    const String query = 'tuberculosis awareness prevention treatment';

    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=10&q=$query&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        videos = data['items'];
        isLoading = false;
      });
    } else {
      debugPrint("❌ Failed to fetch videos: ${response.statusCode}");
      setState(() => isLoading = false);
    }
  }

  void launchVideo(String videoId) async {
    final url = 'https://www.youtube.com/watch?v=$videoId';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          "Educational Content",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];
          final videoId = video['id']['videoId'];
          final title = video['snippet']['title'];
          final thumbnail = video['snippet']['thumbnails']['medium']['url'];

          return Card(
            color: secondaryColor,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(thumbnail,
                    width: 100, fit: BoxFit.cover),
              ),
              title: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: primaryColor, // Dark green title text
                ),
              ),
              trailing: const Icon(Icons.open_in_new,
                  color: primaryColor), // Dark green icon
              onTap: () => launchVideo(videoId),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

const primaryColor = Color(0xFF1B4D3E); // Dark green
const secondaryColor = Color(0xFFFFFFFF); // White
const bgColor = Color(0xFFFFFFFF); // White

class HealthTipsScreen extends StatelessWidget {
  const HealthTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📚 TB Health Tips", style: TextStyle(color: secondaryColor)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: secondaryColor),
      ),
      backgroundColor: bgColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('articles').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading articles", style: TextStyle(color: primaryColor)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          final articles = snapshot.data!.docs;

          // Group articles by section
          final Map<String, List<Map<String, String>>> groupedArticles = {};
          for (var doc in articles) {
            final data = doc.data() as Map<String, dynamic>;
            final section = data['section'] ?? 'General';
            final title = data['title'] ?? '';
            final url = data['url'] ?? '';

            if (!groupedArticles.containsKey(section)) {
              groupedArticles[section] = [];
            }

            groupedArticles[section]!.add({'title': title, 'url': url});
          }

          return ListView(
            children: groupedArticles.entries.map((entry) {
              final sectionTitle = entry.key;
              final articles = entry.value;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Card(
                  color: primaryColor.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    iconColor: secondaryColor,
                    collapsedIconColor: secondaryColor,
                    title: Text(
                      sectionTitle,
                      style: const TextStyle(color: secondaryColor, fontWeight: FontWeight.bold),
                    ),
                    children: articles.map((article) {
                      return ListTile(
                        title: Text(
                          article['title']!,
                          style: const TextStyle(color: secondaryColor),
                        ),
                        trailing: const Icon(Icons.launch, color: secondaryColor),
                        onTap: () => _launchURL(article['url']!),
                      );
                    }).toList(),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }
}

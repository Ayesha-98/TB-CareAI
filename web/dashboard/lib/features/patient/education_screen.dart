import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

// 🎨 Modern Color Scheme
const primaryColor = Color(0xFF1B4D3E); // Teal green
const secondaryColor = Color(0xFF2E7D32); // Dark green
const accentColor = Color(0xFF81C784); // Light green
const backgroundColor = Color(0xFFF8FDF9);
const cardColor = Color(0xFFFFFFFF);
const textColor = Color(0xFF333333);

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  final String apiKey = 'AIzaSyDRX_qgjJDwnaDMsuht-RmlFbHyimbsjpk';
  List videos = [];
  List articles = [];
  bool isLoading = true;
  String selectedCategory = 'All';

  final List<String> categories = [
    'All',
    'Symptoms',
    'Treatment',
    'Prevention',
    'Medication',
    'Nutrition',
    'Recovery'
  ];

  final List<Map<String, dynamic>> tbArticles = [
    {
      'title': 'Understanding Tuberculosis',
      'description': 'Learn about TB causes, transmission, and risk factors',
      'icon': Icons.info,
      'color': Colors.blue,
      'url': 'https://www.who.int/health-topics/tuberculosis'
    },
    {
      'title': 'TB Medication Guide',
      'description': 'Complete guide to TB drugs and their side effects',
      'icon': Icons.medication,
      'color': Colors.green,
      'url': 'https://www.cdc.gov/tb/topic/treatment/default.htm'
    },
    {
      'title': 'Diet for TB Patients',
      'description': 'Nutritional guidelines for faster recovery',
      'icon': Icons.restaurant,
      'color': Colors.orange,
      'url': 'https://www.tbfacts.org/diet-tuberculosis/'
    },
    {
      'title': 'Prevention Strategies',
      'description': 'How to prevent TB transmission to others',
      'icon': Icons.shield,
      'color': Colors.purple,
      'url': 'https://www.who.int/news-room/fact-sheets/detail/tuberculosis'
    },
    {
      'title': 'TB and COVID-19',
      'description': 'Understanding the impact of COVID on TB patients',
      'icon': Icons.coronavirus,
      'color': Colors.red,
      'url': 'https://www.who.int/news-room/feature-stories/detail/tb-and-covid-19'
    },
    {
      'title': 'Mental Health Support',
      'description': 'Coping strategies during TB treatment',
      'icon': Icons.psychology,
      'color': Colors.teal,
      'url': 'https://www.tballiance.org/'
    },
  ];

  @override
  void initState() {
    super.initState();
    fetchVideos();
  }

  Future<void> fetchVideos() async {
    setState(() {
      isLoading = true;
    });

    try {
      const String query = 'tuberculosis awareness prevention treatment education';
      final url = Uri.parse(
        'https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=20&q=$query&key=$apiKey',
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
    } catch (e) {
      debugPrint("❌ Error fetching videos: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  Widget _buildWebLayout() {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Web SliverAppBar
          SliverAppBar(
            expandedHeight: 220, // Reduced height since we removed categories
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor.withOpacity(0.9), secondaryColor],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 60),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.school,
                              color: primaryColor,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "TB Education Center",
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Learn about prevention, treatment, and recovery from tuberculosis",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // REMOVED: Category Filter Chips from header
                    ],
                  ),
                ),
              ),
            ),
            pinned: true,
            floating: false,
            elevation: 4,
            backgroundColor: primaryColor,
          ),

          // Main Content
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 60),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Featured Articles Section
                  Text(
                    "Featured Articles",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Comprehensive guides and resources about tuberculosis",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: tbArticles.length,
                    itemBuilder: (context, index) {
                      final article = tbArticles[index];
                      return _buildArticleCard(article);
                    },
                  ),

                  const SizedBox(height: 40),

                  // YouTube Videos Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Educational Videos",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: fetchVideos,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text("Refresh Videos"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Watch expert videos about TB care and treatment",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1.8,
                      ),
                      itemCount: videos.length,
                      itemBuilder: (context, index) {
                        return _buildVideoCard(videos[index]);
                      },
                    ),

                  const SizedBox(height: 40),

                  // Additional Resources
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.1),
                          accentColor.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Additional Resources",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "For more information and support, visit these trusted organizations:",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildResourceLink("WHO TB Portal", "https://www.who.int/tb"),
                            _buildResourceLink("CDC TB Guidelines", "https://www.cdc.gov/tb"),
                            _buildResourceLink("Stop TB Partnership", "https://www.stoptb.org"),
                            _buildResourceLink("TB Alliance", "https://www.tballiance.org"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180, // Reduced height since we removed categories
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TB Education",
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Your learning hub for tuberculosis care",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      // REMOVED: Category Chips from header
                    ],
                  ),
                ),
              ),
            ),
            pinned: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Featured Articles
                  Text(
                    "Featured Articles",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: tbArticles.length,
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 280,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: _buildArticleCard(tbArticles[index]),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Videos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Educational Videos",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      IconButton(
                        onPressed: fetchVideos,
                        icon: const Icon(Icons.refresh),
                        color: primaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: videos.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildVideoCard(videos[index]),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> article) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => launchURL(article['url']),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: article['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  article['icon'],
                  color: article['color'],
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                article['title'],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                article['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    "Read Article",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    color: primaryColor,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCard(dynamic video) {
    final videoId = video['id']['videoId'];
    final title = video['snippet']['title'];
    final channel = video['snippet']['channelTitle'];
    final thumbnail = video['snippet']['thumbnails']['medium']['url'];
    final publishedAt = video['snippet']['publishedAt'];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => launchURL('https://www.youtube.com/watch?v=$videoId'),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  Image.network(
                    thumbnail,
                    height: kIsWeb ? 180 : 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "Watch",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        channel,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(publishedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceLink(String title, String url) {
    return InkWell(
      onTap: () => launchURL(url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.open_in_new,
              color: primaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()}y ago';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()}m ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWebLayout() : _buildMobileLayout();
  }
}
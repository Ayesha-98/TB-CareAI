import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// 🎨 Modern Color Scheme
const primaryColor = Color(0xFF1B4D3E); // Teal green
const secondaryColor = Color(0xFF2E7D32); // Dark green
const accentColor = Color(0xFF81C784); // Light green
const backgroundColor = Color(0xFFF8FDF9);
const cardColor = Color(0xFFFFFFFF);
const textColor = Color(0xFF333333);
const lightTextColor = Color(0xFF666666);

class HealthTipsScreen extends StatefulWidget {
  const HealthTipsScreen({super.key});

  @override
  State<HealthTipsScreen> createState() => _HealthTipsScreenState();
}

class _HealthTipsScreenState extends State<HealthTipsScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Nutrition',
    'Medication',
    'Exercise',
    'Prevention',
    'Mental Health',
    'General Care',
    'Symptoms',
    'Recovery'
  ];

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWebLayout() : _buildMobileLayout();
  }

  Widget _buildWebLayout() {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Header Section - Now scrolls with content
          SliverAppBar(
            expandedHeight: 280,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 60),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.health_and_safety,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "TB Health & Wellness Tips",
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Expert advice and practical tips for TB prevention, treatment, and recovery",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Search and Filter Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: TextField(
                              onChanged: (value) => setState(() => _searchQuery = value),
                              decoration: InputDecoration(
                                hintText: "Search health tips, articles, guidance...",
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: primaryColor,
                                  size: 22,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 18,
                                ),
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            underline: const SizedBox(),
                            icon: Icon(Icons.expand_more, color: primaryColor, size: 24),
                            iconSize: 24,
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            elevation: 4,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            items: _categories.map((String category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            pinned: true, // Keeps the app bar visible when collapsed
            floating: false,
            elevation: 4,
          ),

          // Main Content
          SliverPadding(
            padding: const EdgeInsets.all(40),
            sliver: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('articles').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: _buildErrorState("Error loading articles"),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverToBoxAdapter(
                    child: _buildLoadingState(),
                  );
                }

                final articles = snapshot.data!.docs;
                if (articles.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _buildEmptyState(),
                  );
                }

                // Filter and group articles
                final filteredArticles = _filterArticles(articles);
                final groupedArticles = _groupArticles(filteredArticles);

                return SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 1.6,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final entry = groupedArticles.entries.elementAt(index);
                      return _buildCategoryCard(entry.key, entry.value);
                    },
                    childCount: groupedArticles.length,
                  ),
                );
              },
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
            expandedHeight: 220, // Increased height for better visibility
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.health_and_safety,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Health Tips",
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Expert guidance for TB prevention & recovery",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          onChanged: (value) => setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: "Search tips, articles...",
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            prefixIcon: Icon(Icons.search, color: primaryColor),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            pinned: true, // Keeps app bar pinned when scrolling
            floating: false,
            elevation: 4,
            stretch: true, // Allows stretching when over-scrolling
            stretchTriggerOffset: 150,
          ),
          // Category Filter Chips
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          category,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _selectedCategory == category
                                ? Colors.white
                                : textColor,
                          ),
                        ),
                        selected: _selectedCategory == category,
                        selectedColor: primaryColor,
                        backgroundColor: Colors.white,
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: _selectedCategory == category
                                ? primaryColor
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        elevation: 1,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // Articles List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('articles').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: _buildErrorState("Error loading articles"),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverToBoxAdapter(
                    child: _buildLoadingState(),
                  );
                }

                final articles = snapshot.data!.docs;
                if (articles.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _buildEmptyState(),
                  );
                }

                final filteredArticles = _filterArticles(articles);
                final groupedArticles = _groupArticles(filteredArticles);

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final entry = groupedArticles.entries.elementAt(index);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildCategoryCard(entry.key, entry.value),
                      );
                    },
                    childCount: groupedArticles.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String sectionTitle, List<Map<String, String>> articles) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      shadowColor: primaryColor.withOpacity(0.1),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getCategoryColor(sectionTitle),
                          _getCategoryColor(sectionTitle).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(sectionTitle),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sectionTitle,
                          style: TextStyle(
                            fontSize: kIsWeb ? 20 : 18,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        Text(
                          "${articles.length} articles",
                          style: TextStyle(
                            fontSize: 12,
                            color: lightTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: articles.take(3).length,
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildArticleItem(article),
                    );
                  },
                ),
              ),
              if (articles.length > 3)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showAllArticlesDialog(sectionTitle, articles),
                    icon: Icon(Icons.arrow_forward, size: 16, color: primaryColor),
                    label: Text(
                      "View all (${articles.length})",
                      style: TextStyle(
                        fontSize: 13,
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArticleItem(Map<String, String> article) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _launchURL(article['url']!),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article['title']!,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Read more →",
                      style: TextStyle(
                        fontSize: 12,
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: primaryColor,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            "Loading health tips...",
            style: TextStyle(
              fontSize: 16,
              color: lightTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.health_and_safety_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No Health Tips Available",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "We're updating our health tips collection.\nCheck back soon for expert advice!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: lightTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Oops! Something went wrong",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: lightTextColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: Icon(Icons.refresh, size: 20),
              label: Text("Try Again", style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, String>> _filterArticles(List<QueryDocumentSnapshot> articles) {
    return articles
        .map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'title': data['title']?.toString() ?? '',
        'url': data['url']?.toString() ?? '',
        'section': data['section']?.toString() ?? 'General',
      };
    })
        .where((article) {
      final matchesSearch = article['title']!
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' ||
          article['section']!.toLowerCase().contains(_selectedCategory.toLowerCase());
      return matchesSearch && matchesCategory;
    })
        .toList();
  }

  Map<String, List<Map<String, String>>> _groupArticles(List<Map<String, String>> articles) {
    final Map<String, List<Map<String, String>>> grouped = {};
    for (var article in articles) {
      final section = article['section']!;
      if (!grouped.containsKey(section)) {
        grouped[section] = [];
      }
      grouped[section]!.add(article);
    }
    return grouped;
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'nutrition': Color(0xFF4CAF50), // Green
      'medication': Color(0xFF2196F3), // Blue
      'exercise': Color(0xFFFF9800), // Orange
      'prevention': Color(0xFF9C27B0), // Purple
      'mental health': Color(0xFF0097A7), // Teal
      'symptoms': Color(0xFFF44336), // Red
      'recovery': Color(0xFFFFC107), // Amber
      'general care': Color(0xFF795548), // Brown
    };

    return colors[category.toLowerCase()] ?? primaryColor;
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'nutrition':
        return Icons.restaurant_menu;
      case 'medication':
        return Icons.medical_services;
      case 'exercise':
        return Icons.directions_run;
      case 'prevention':
        return Icons.shield;
      case 'mental health':
        return Icons.psychology;
      case 'symptoms':
        return Icons.warning_amber;
      case 'recovery':
        return Icons.healing;
      case 'general care':
        return Icons.health_and_safety;
      default:
        return Icons.article;
    }
  }

  void _showAllArticlesDialog(String sectionTitle, List<Map<String, String>> articles) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 4,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: kIsWeb ? 600 : MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dialog Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(sectionTitle),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getCategoryIcon(sectionTitle),
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          sectionTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Articles List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: articles.length,
                    itemBuilder: (context, index) {
                      final article = articles[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(sectionTitle).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.article,
                              color: _getCategoryColor(sectionTitle),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            article['title']!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: primaryColor,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _launchURL(article['url']!);
                          },
                        ),
                      );
                    },
                  ),
                ),
                // Close Button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text("Close"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not open link"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
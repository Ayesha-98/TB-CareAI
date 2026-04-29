import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ====================
// CONSTANTS & COLORS
// ====================
class AppColors {
  static const primary = Color(0xFF1B4D3E); // Teal green
  static const secondary = Color(0xFF2E7D32); // Darker green
  static const accent = Color(0xFF81C784); // Light green
  static const background = Color(0xFFF5F5F5);
  static const card = Color(0xFFFFFFFF);
  static const white = Colors.white;
  static const textDark = Colors.black87;
  static const textLight = Colors.white;
}

class AppTextStyles {
  static const titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    color: AppColors.textDark,
  );

  static const bodySmall = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );

  static const timestamp = TextStyle(
    fontSize: 10,
    color: Colors.grey,
  );
}

// ====================
// MAIN WIDGET
// ====================
class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isSending = false;
  bool _isLoadingConfig = true;

  // ✅ Google Gemini API Key (same as patient app)
  final String _geminiApiKey = "AIzaSyBrGUo35HYcks9Qm-uhNnv4HVy6DQDi1Eo";
  final String _modelName = "models/gemini-2.5-flash";

  // Default values (fallback if Firestore config fails to load)
  String _systemPrompt = "You are TB-CareAI, a medical assistant that ONLY answers questions related to tuberculosis (TB). Answer clearly and factually about TB symptoms, diagnosis, treatment, diet, cure, care, and prevention. If asked something outside TB, politely refuse.";
  String _offTopicResponse = "I can only answer questions related to tuberculosis (TB). Please ask about TB symptoms, treatment, prevention, or care.";
  List<String> _tbKeywords = [
    "tb", "tuberculosis", "cough", "x-ray", "treatment", "medicine",
    "isoniazid", "rifampicin", "symptom", "prevention", "infection",
    "lungs", "sputum", "diet", "care", "cure", "drug", "therapy",
    "diagnosis", "fever", "night sweat", "weight loss", "contagious",
    "bacteria", "latent", "active"
  ];

  final String patientId = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  void initState() {
    super.initState();
    _loadChatbotConfig();
    _loadChatHistory();
  }

  // ====================
  // DATA METHODS
  // ====================

  /// Load chatbot configuration from Firestore
  Future<void> _loadChatbotConfig() async {
    setState(() {
      _isLoadingConfig = true;
    });

    try {
      final docRef = FirebaseFirestore.instance.collection('chatbot_config').doc('settings');
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        final data = docSnap.data();

        if (data != null) {
          if (data['systemPrompt'] != null && data['systemPrompt'].toString().isNotEmpty) {
            _systemPrompt = data['systemPrompt'];
          }
          if (data['offTopicResponse'] != null && data['offTopicResponse'].toString().isNotEmpty) {
            _offTopicResponse = data['offTopicResponse'];
          }
          if (data['tbKeywords'] != null && data['tbKeywords'].toString().isNotEmpty) {
            final keywordsString = data['tbKeywords'] as String;
            _tbKeywords = keywordsString
                .split(',')
                .map((e) => e.trim().toLowerCase())
                .where((e) => e.isNotEmpty)
                .toList();
          }
          print('✅ Chatbot config loaded from Firestore');
        }
      } else {
        print('⚠️ No chatbot config found, using default values');
      }
    } catch (e) {
      print('❌ Failed to load chatbot config: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingConfig = false;
        });
      }
    }
  }

  Future<void> _loadChatHistory() async {
    if (patientId.isEmpty) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('patients')
        .doc(patientId)
        .collection('chats')
        .orderBy('timestamp')
        .get();

    setState(() {
      _messages = snapshot.docs.map((doc) => doc.data()).toList();
    });

    _scrollToBottom();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isSending) return;

    final userMessage = {
      'role': 'user',
      'content': text,
      'timestamp': Timestamp.now(),
    };

    setState(() {
      _messages.add(userMessage);
      _isSending = true;
    });

    await FirebaseFirestore.instance
        .collection('patients')
        .doc(patientId)
        .collection('chats')
        .add(userMessage);

    // Check if TB-related
    final isTBQuestion = _tbKeywords.any(
          (word) => text.toLowerCase().contains(word),
    );

    if (!isTBQuestion) {
      await _addNonTbResponse();
      return;
    }

    await _processTbQuestion(text);
  }

  Future<void> _addNonTbResponse() async {
    final botMessage = {
      'role': 'assistant',
      'content': _offTopicResponse,
      'timestamp': Timestamp.now(),
    };

    setState(() {
      _messages.add(botMessage);
      _isSending = false;
    });

    await FirebaseFirestore.instance
        .collection('patients')
        .doc(patientId)
        .collection('chats')
        .add(botMessage);

    _scrollToBottom();
  }

  Future<void> _processTbQuestion(String text) async {
    try {
      // ✅ Google Gemini API call
      final url = Uri.parse(
          "https://generativelanguage.googleapis.com/v1beta/$_modelName:generateContent?key=$_geminiApiKey"
      );

      final requestBody = {
        "contents": [
          {
            "parts": [
              {"text": "$_systemPrompt\n\nUser: $text\n\nAssistant:"}
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.6,
          "maxOutputTokens": 500,
          "topP": 0.95,
        }
      };

      print("📤 Sending request to Gemini API...");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print("📥 Response status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['candidates'][0]['content']['parts'][0]['text'];
        await _addBotResponse(reply);
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']['message'] ?? 'Unknown error';
        print("❌ API Error: $errorMessage");
        _showError("Error: $errorMessage");
      }
    } catch (e) {
      print("❌ Network Error: $e");
      _showError("Network error. Please check your connection.");
    }
  }

  Future<void> _addBotResponse(String reply) async {
    final botMessage = {
      'role': 'assistant',
      'content': reply,
      'timestamp': Timestamp.now(),
    };

    setState(() {
      _messages.add(botMessage);
      _isSending = false;
    });

    await FirebaseFirestore.instance
        .collection('patients')
        .doc(patientId)
        .collection('chats')
        .add(botMessage);

    _scrollToBottom();
  }

  void _showError(String message) {
    setState(() {
      _messages.add({
        'role': 'assistant',
        'content': message,
        'timestamp': Timestamp.now(),
      });
      _isSending = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // ====================
  // UI WIDGETS
  // ====================
  @override
  Widget build(BuildContext context) {
    if (_isLoadingConfig) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: kIsWeb ? _buildWebLayout() : _buildMobileLayout(),
    );
  }

  // ====================
  // WEB LAYOUT
  // ====================
  Widget _buildWebLayout() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, AppColors.background],
        ),
      ),
      child: Row(
        children: [
          // Side Panel
          _buildSidePanel(),

          // Chat Area
          Expanded(
            child: Column(
              children: [
                _buildWebHeader(),
                Expanded(child: _buildChatArea()),
                _buildInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanel() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.white,
                  child: Icon(
                    Icons.medical_services,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "TB Care Assistant",
                  style: AppTextStyles.titleLarge.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  "Your Personal TB Health Guide",
                  style: TextStyle(
                    color: AppColors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Tips Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "💡 Tips for Asking:",
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildTipItem("Be specific about symptoms"),
                  _buildTipItem("Ask about medication side effects"),
                  _buildTipItem("Inquire about diet during treatment"),
                  _buildTipItem("Discuss prevention methods"),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                    ),
                    child: Text(
                      "Remember: I can only answer TB-related questions for accurate medical guidance.",
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebHeader() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(Icons.chat_bubble, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Text("TB Care Chat", style: AppTextStyles.titleLarge),
          const Spacer(),
        ],
      ),
    );
  }

  // ====================
  // MOBILE LAYOUT
  // ====================
  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildMobileHeader(),
        Expanded(child: _buildChatArea()),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.chat_bubble, color: AppColors.white, size: 24),
              const SizedBox(width: 8),
              Text("TB Care Chat",
                  style: AppTextStyles.titleLarge.copyWith(color: AppColors.white)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Ask anything about TB care",
            style: TextStyle(
              fontSize: 14,
              color: AppColors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  // ====================
  // SHARED COMPONENTS
  // ====================
  Widget _buildChatArea() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.grey.shade50],
        ),
      ),
      child: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: _messages.length,
            itemBuilder: (context, index) => _buildMessage(_messages[index]),
          ),
          if (_isSending)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isUser = msg['role'] == 'user';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(isUser: false),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : Colors.grey.shade100,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg['content'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: isUser ? AppColors.white : Colors.grey.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(msg['timestamp']),
                  style: AppTextStyles.timestamp,
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _buildAvatar(isUser: true),
        ],
      ),
    );
  }

  Widget _buildAvatar({required bool isUser}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isUser ? AppColors.secondary : AppColors.accent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        isUser ? Icons.person : Icons.medical_services,
        color: AppColors.white,
        size: 18,
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: kIsWeb
          ? const EdgeInsets.all(20)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Type your TB-related question here...",
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        fontSize: kIsWeb ? 15 : 14,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: null,
                      onSubmitted: (value) {
                        _sendMessage(value.trim());
                        _controller.clear();
                      },
                    ),
                  ),
                  if (_isSending)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: AppColors.white),
              onPressed: () {
                _sendMessage(_controller.text.trim());
                _controller.clear();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.accent, size: 16),
          const SizedBox(width: 8),
          Text(text, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
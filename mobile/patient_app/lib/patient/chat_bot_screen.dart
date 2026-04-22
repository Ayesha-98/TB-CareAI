import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';

const primaryColor = Color(0xFF1B4D3E);
const secondaryColor = Color(0xFF424242);
const bgColor = Color(0xFFFFFFFF);

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

  // Google Gemini API Key
  final String _geminiApiKey = "AIzaSyBrGUo35HYcks9Qm-uhNnv4HVy6DQDi1Eo";

  // ✅ CORRECT MODEL NAME with "models/" prefix
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
      return;
    }

    // ✅ Google Gemini API with CORRECT model name
    try {
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
      print("📤 Model: $_modelName");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print("📥 Response status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['candidates'][0]['content']['parts'][0]['text'];

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

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isUser = msg['role'] == 'user';
    final content = msg['content'] ?? '';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? primaryColor.withOpacity(0.7) : secondaryColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: isUser
            ? Text(
          content,
          style: const TextStyle(fontSize: 15, color: Colors.white),
        )
            : MarkdownBody(
          data: content,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(fontSize: 15, color: Colors.white),
            h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            em: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white),
            listBullet: const TextStyle(fontSize: 15, color: Colors.white),
            blockSpacing: 4.0,
            listIndent: 16.0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: secondaryColor,
        title: const Text("🧠 TB Care ChatBot", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingConfig
          ? const Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessage(_messages[index]),
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Ask something about TB care...",
                      filled: true,
                      fillColor: secondaryColor,
                      hintStyle: const TextStyle(color: Colors.white70),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (value) {
                      _sendMessage(value.trim());
                      _controller.clear();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      _sendMessage(_controller.text.trim());
                      _controller.clear();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
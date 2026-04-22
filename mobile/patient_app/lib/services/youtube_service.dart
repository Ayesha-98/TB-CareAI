import 'dart:convert';
import 'package:http/http.dart' as http;

class YouTubeService {
  final String apiKey = 'AIzaSyDRX_qgjJDwnaDMsuht-RmlFbHyimbsjpk';
  final String channelId = 'UCWlM0e3XJv9uZ4i9nMxkB5A'; // Example: replace with TB-related channel

  Future<List<Map<String, String>>> fetchVideos() async {
    final url =
        'https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=$channelId&maxResults=10&type=video&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List items = data['items'];
      return items.map<Map<String, String>>((item) {
        return {
          'title': item['snippet']['title'],
          'thumbnail': item['snippet']['thumbnails']['high']['url'],
          'videoId': item['id']['videoId'],
        };
      }).toList();
    } else {
      throw Exception('Failed to load YouTube videos');
    }
  }
}

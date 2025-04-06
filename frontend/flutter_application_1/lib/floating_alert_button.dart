import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class FloatingAlertButton extends StatelessWidget {
  final String text; // The text (news content) to be checked by the backend
  final VoidCallback? onPressed;

  const FloatingAlertButton({
    required this.text,
    this.onPressed,  
    Key? key,  // Changed from super.key to Key? key for better compatibility
  }) : super(key: key);

  // Method to call the backend and check the news
  Future<void> checkNews(BuildContext context) async {
    final Dio dio = Dio();
    // Replace with your actual backend URL
    final String backendUrl = "http://192.168.29.41:5000/check_news";

    try {
      final response = await dio.post(
        backendUrl, 
        data: {"text": text},
        options: Options(
          headers: {"Content-Type": "application/json"},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['is_fake'] == true) {
          // Show an alert for fake news
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("⚠️ Fake News Detected: ${data['claims'][0]['text'] ?? ''}"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          // Show a notification that the news appears genuine
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ News appears to be genuine"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Network Error: ${e.toString()}"),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => checkNews(context),
      backgroundColor: Colors.redAccent,
      tooltip: 'Check for misinformation',
      child: const Icon(Icons.fact_check, color: Colors.white),
    );
  }
}
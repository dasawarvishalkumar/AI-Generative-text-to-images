import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Text-to-Image Generator',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const AiTextToImageGenerator(),
      debugShowCheckedModeBanner: false, // Hide debug banner
    );
  }
}

class AiTextToImageGenerator extends StatefulWidget {
  const AiTextToImageGenerator({super.key});

  @override
  State<AiTextToImageGenerator> createState() => _AiTextToImageGeneratorState();
}

class _AiTextToImageGeneratorState extends State<AiTextToImageGenerator> {
  final TextEditingController _queryController = TextEditingController();
  bool isGenerating = false;
  List<Uint8List> generatedImages = []; // List to store multiple images

  // Replace with your Stability AI API key
  final String apiKey = 'sk-dxCtifCogAaRFsIXc8LUMtTmANm7dKgeXVjWOp2rfmVJtmV9';

  Future<void> _generateImage(String query) async {
    if (apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
      _showError("API Key is missing or invalid.");
      return;
    }

    setState(() {
      isGenerating = true;
      generatedImages.clear(); // Clear previous images
    });

    try {
      const String engineId = 'stable-diffusion-v1-6';
      final String endpoint = 'https://api.stability.ai/v1/generation/$engineId/text-to-image';
      final Map<String, String> headers = {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };

      final Map<String, dynamic> body = {
        "text_prompts": [
          {
            "text": query,
            "weight": 1
          }
        ],
        "cfg_scale": 7,
        "height": 512,
        "width": 512,
        "samples": 4, // Generate 4 images
        "steps": 50
      };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> artifacts = data['artifacts'];

        if (artifacts.isNotEmpty) {
          setState(() {
            generatedImages = artifacts
                .map((artifact) => base64Decode(artifact['base64']))
                .toList();
          });
        } else {
          _showError("No image data received.");
        }
      } else {
        _showError("Failed: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      _showError("Error: $e");
    } finally {
      setState(() {
        isGenerating = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://trituenhantao.io/wp-content/uploads/2020/03/AI.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.6),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  "Text to Image",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _queryController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your prompt',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                isGenerating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : generatedImages.isNotEmpty
                        ? Expanded(
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, // Display 2 images per row
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: generatedImages.length,
                              itemBuilder: (context, index) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(
                                    generatedImages[index],
                                    fit: BoxFit.cover,
                                  ),
                                );
                              },
                            ),
                          )
                        : const Text(
                            'No images generated yet.',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    String query = _queryController.text.trim();
                    if (query.isNotEmpty) {
                      _generateImage(query);
                    } else {
                      _showError("Please enter a prompt!");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // Button background color
                  ),
                  child: const Text(
                    "Generate Image",
                    style: TextStyle(
                      color: Color.fromARGB(255, 36, 235, 232), // Text color
                    ),
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
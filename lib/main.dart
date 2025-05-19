import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';
import 'predictor.dart';

void main() => runApp(CleanMessyApp());

class CleanMessyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clean vs Messy Room',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: VoiceControlledHomePage(),
    );
  }
}

class VoiceControlledHomePage extends StatefulWidget {
  @override
  _VoiceControlledHomePageState createState() =>
      _VoiceControlledHomePageState();
}

class _VoiceControlledHomePageState extends State<VoiceControlledHomePage> {
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final ImagePicker _picker = ImagePicker();
  File? _image;
  String? _prediction;
  bool _isListening = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeechRecognition();
    _startIntroduction();
  }

  /// Demande et vérifie les permissions nécessaires
  Future<void> _checkPermissions() async {
    if (await Permission.microphone.isDenied) {
      await Permission.microphone.request();
    }
    if (await Permission.camera.isDenied) {
      await Permission.camera.request();
    }
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }

    print("Microphone: ${await Permission.microphone.status}");
    print("Camera: ${await Permission.camera.status}");
    print("Storage: ${await Permission.storage.status}");
  }

  /// Configure la reconnaissance vocale avec gestion des erreurs
  Future<void> _initializeSpeechRecognition() async {
    bool available = await _speechToText.initialize(
      onError: (dynamic error) {
        print("Speech recognition error: ${error.toString()}");
      },
      onStatus: (status) {
        print("Speech recognition status: $status");
      },
    );

    if (!available) {
      await _speak("Speech recognition is not available.");
    }
  }

  /// Lit un message en Text-to-Speech
  Future<void> _speak(String message) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(message);
  }

  /// Lancement de l'introduction avec écoute
  Future<void> _startIntroduction() async {
    await _speak(
        "Welcome to the Clean vs Messy Room app. Please say 'camera' to take a photo, or 'gallery' to pick a photo.");
    _startListening();
  }

  /// Lance la reconnaissance vocale avec traitement des commandes
  void _startListening() async {
    await _checkPermissions();
    if (!_isListening) {
      bool available = await _speechToText.initialize(
        onError: (dynamic error) {
          print("Speech recognition error: ${error.toString()}");
        },
        onStatus: (status) {
          print("Speech recognition status: $status");
        },
      );

      if (available) {
        setState(() => _isListening = true);

        _speechToText.listen(
          localeId: "en-US", // Changez en "fr-FR" si nécessaire
          onResult: (result) async {
            print("Raw result: ${result.recognizedWords}");
            String command = result.recognizedWords.toLowerCase();
            print("Interpreted command: $command");

            if (command.contains('camera')) {
              await _speak("Opening the camera.");
              _speechToText.stop();
              _pickImage(ImageSource.camera);
            } else if (command.contains('gallery')) {
              await _speak("Opening the gallery.");
              _speechToText.stop();
              _pickImage(ImageSource.gallery);
            } else {
              print("Unrecognized command.");
              await _speak(
                  "I didn't understand. Please say 'camera' or 'gallery'.");
            }
          },
        );
      } else {
        print("Speech recognition is not available.");
      }
    }
  }

  /// Sélectionne une image (caméra ou galerie)
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _prediction = null;
          _isLoading = true;
        });

        final result = await Predictor.predict(File(pickedFile.path));
        setState(() {
          _prediction = result;
          _isLoading = false;
        });

        if (result == "Messy Room") {
          await _speak(
              "This is a messy room. Please organize and clean up the clutter.");
        } else {
          await _speak("Great job! Your room is clean.");
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _prediction = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_image != null)
            Image.file(
              _image!,
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
            )
          else
            Lottie.asset(
              'assets/robot_background.json',
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
            ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          if (_prediction != null)
            Center(
              child: Text(
                _prediction!,
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
          if (_isListening)
            Positioned(
              bottom: 50,
              left: MediaQuery.of(context).size.width / 2 - 50,
              child: Lottie.asset(
                'assets/listening_animation.json',
                height: 100,
                width: 100,
              ),
            ),
        ],
      ),
    );
  }
}

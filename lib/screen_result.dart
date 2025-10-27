import 'dart:io';
import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    if (args == null || !args.containsKey('imagePath') || !args.containsKey('result')) {
      return Scaffold(
        appBar: AppBar(title: Text("Erreur")),
        body: Center(child: Text("Les arguments nécessaires n'ont pas été transmis.")),
      );
    }
    print("Arguments reçus : $args");


    final String imagePath = args['imagePath'];
    final String result = args['result'];

    if (!File(imagePath).existsSync()) {
      return Scaffold(
        appBar: AppBar(title: Text("Erreur")),
        body: Center(child: Text("L'image n'existe pas à ce chemin : $imagePath")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Résultat"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.file(File(imagePath)),
            SizedBox(height: 20),
            Text(
              "Résultat : $result",
              style: Theme.of(context).textTheme.displayLarge,
            ),
            SizedBox(height: 10),
            Text(
              "Détails : Cette image a été classée comme $result par l'IA.",
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, ModalRoute.withName('/'));
              },
              child: Text("Revenir à l'accueil"),
            ),
          ],
        ),
      ),
    );
  }
}

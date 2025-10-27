import 'dart:io';
import 'dart:typed_data'; // Import nécessaire pour Float32List
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class Predictor {
  static Future<Map<String, dynamic>> pickAndPredict(
      {required bool isCamera}) async {
    final picker = ImagePicker();

    // Choisir une image
    final pickedFile = await picker.pickImage(
      source: isCamera ? ImageSource.camera : ImageSource.gallery,
    );

    if (pickedFile == null) throw Exception("Aucune image sélectionnée.");

    final image = File(pickedFile.path);
    final result = await predict(image);

    return {
      'imagePath': image.path,
      'result': result,
    };
  }

  static Future<String> predict(File imageFile) async {
    // Charger le modèle TFLite
    final interpreter = await Interpreter.fromAsset('model_unquant.tflite');

    // Obtenez les informations sur l'entrée et la sortie
    final inputShape = interpreter.getInputTensor(0).shape;
    final outputShape = interpreter.getOutputTensor(0).shape;

    print('Dimensions d\'entrée du modèle : $inputShape');
    print('Dimensions de sortie du modèle : $outputShape');

    // Charger et décoder l'image
    final rawImage = img.decodeImage(imageFile.readAsBytesSync());
    if (rawImage == null) {
      throw Exception("Impossible de décoder l'image.");
    }

    // Redimensionner l'image
    final resizedImage =
        img.copyResize(rawImage, width: inputShape[1], height: inputShape[2]);

    // Préparer le tampon d'entrée
    final inputBuffer =
        Float32List(inputShape.reduce((a, b) => a * b)).reshape(inputShape);

    // Remplir le tampon d'entrée avec les pixels de l'image redimensionnée
    for (int y = 0; y < inputShape[1]; y++) {
      for (int x = 0; x < inputShape[2]; x++) {
        final pixel = resizedImage.getPixel(x, y);

        // Normalisation entre 0 et 1 (ou ajustez selon le modèle)
        inputBuffer[0][y][x][0] = img.getRed(pixel) / 255.0; // Canal R
        inputBuffer[0][y][x][1] = img.getGreen(pixel) / 255.0; // Canal G
        inputBuffer[0][y][x][2] = img.getBlue(pixel) / 255.0; // Canal B
      }
    }

    // Logs pour vérifier les données d'entrée
    print("Données d'entrée envoyées au modèle :");
    print(inputBuffer);

    // Préparer le buffer de sortie
    final outputBuffer =
        Float32List(outputShape.reduce((a, b) => a * b)).reshape(outputShape);

    // Effectuer l'inférence
    try {
      interpreter.run(inputBuffer, outputBuffer);
    } catch (e) {
      print("Erreur pendant l'inférence : $e");
      throw Exception("Erreur pendant l'inférence.");
    }

    // Fermer l'interpréteur
    interpreter.close();

    // Logs pour les probabilités de sortie
    print("Probabilités de sortie : ${outputBuffer[0]}");

    // Interpréter les résultats
    final probabilities = outputBuffer[0];
    if (probabilities.length != 2) {
      throw Exception("Le modèle a retourné un nombre inattendu de classes.");
    }

    return probabilities[1] > probabilities[0] ? 'Messy Room' : 'Clean Room';
  }
}

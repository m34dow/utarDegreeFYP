import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  final picker = ImagePicker();
  List<String> labelsList = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> loadModel(String modelPath, String labelsPath) async {
    String? res = await Tflite.loadModel(
      model: modelPath,
      labels: labelsPath,
    );
    print("Model loaded: $res");
  }

  Future<void> unloadModel() async {
    await Tflite.close();
    print("Model unloaded");
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        labelsList.clear();
      }
    });

    if (_image != null) {
      await _runModel1();
    }
  }

  Future<void> _takePicture() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        labelsList.clear();
      }
    });

    if (_image != null) {
      await _runModel1();
    }
  }

  Future<void> _runModel(String modelPath, String labelsPath) async {
    if (_image == null) {
      _showSnackBar('Please select an image first');
      return;
    }

    await loadModel(modelPath, labelsPath);

    var recognitions = await Tflite.runModelOnImage(
      path: _image!.path,
      numResults: 1,
      threshold: 0.5,
      imageMean: 0,
      imageStd: 255,
    );
    print("Recognitions: $recognitions");

    if (recognitions != null && recognitions.isNotEmpty) {
      var label = recognitions[0]['label'];
      setState(() {
        if (labelsList.isEmpty || labelsList.last != label) {
          if (labelsList.length < 2) {
            labelsList.add(label);
          } else {
            labelsList[1] = label;
          }
        }
      });
      print("Labels List: $labelsList");
    }

    await unloadModel();
  }

  Future<void> _runModel1() async {
    await _runModel("assets/MobileNetv2_type3.tflite", "assets/labels_type.txt");
  }

  Future<void> _runModel2() async {
    await _runModel("assets/MobileNetV2_condition2_2.tflite", "assets/labels_condition.txt");
  }

  void _showSnackBar(String message) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Remove any existing SnackBar before showing a new one
    scaffoldMessenger.removeCurrentSnackBar();

    // Show the new SnackBar
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 500), // Set the duration to 0.5 seconds
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pick from Gallery'),
                onTap: () {
                  _pickImage();
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Picture'),
                onTap: () {
                  _takePicture();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Apple Types & Condition Classification',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 70, 130, 180),
      ),
      backgroundColor: const Color.fromARGB(255, 234, 234, 234),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Align items to the top
          children: [
            const SizedBox(height: 50), // Add space from the top
            GestureDetector(
              onTap: _image == null ? () => _showPicker(context) : null,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 2),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 4.0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _image == null
                      ? const Center(child: Text('No image selected.', style: TextStyle(color: Colors.grey)))
                      : Image.file(
                          _image!,
                          fit: BoxFit.cover, // Fit the image within the container
                        ),
                ),
              ),
            ),
            const SizedBox(height: 15), // Add space between image and buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _image = null;
                      labelsList.clear();
                    });
                    _showSnackBar('Image removed');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 70, 130, 180),
                  ),
                  child: const Text(
                    'Remove Image',
                    style: TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _runModel2,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 70, 130, 180),
                  ),
                  child: const Text(
                    'Classify',
                    style: TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20), // Add space below buttons
            if (labelsList.length == 2) ...[
              Card(
                color: labelsList[0] != "Not Apple"
                    ? const Color.fromARGB(255, 230, 240, 255)
                    : const Color.fromARGB(255, 251, 251, 197),
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 25),
                child: ListTile(
                  leading: Image.asset(
                    labelsList[0] == "Granny Smith"
                        ? 'assets/green-apple.png'
                        : labelsList[0] != "Not Apple"
                            ? 'assets/apple.png'
                            : 'assets/apple-unknown.png',
                    width: 24,
                    height: 24,
                  ),
                  title: Text(labelsList[0], style: const TextStyle(fontSize: 20)),
                ),
              ),
              if (labelsList[0] != "Not Apple")
                Card(
                  color: labelsList[1] == "fresh"
                      ? const Color.fromARGB(255, 222, 253, 222)
                      : const Color.fromARGB(255, 252, 190, 199),
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 25),
                  child: ListTile(
                    leading: Image.asset(
                      labelsList[1] == "fresh"
                          ? 'assets/fresh.png'
                          : 'assets/rotten.png',
                      width: 24,
                      height: 24,
                    ),
                    title: Text(labelsList[1], style: const TextStyle(fontSize: 20)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

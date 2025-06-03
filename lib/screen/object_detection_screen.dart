import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:object_detection_app/utils/my_Text_stylr.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'package:object_detection_app/services/vibration_service.dart';



class ObjectDetectionScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ObjectDetectionScreen({super.key, required this.cameras});

  @override
  State<ObjectDetectionScreen> createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  late CameraController _cameraController;
  bool isCameraReady = false;
  String result = "Detecting...";
  late ImageLabeler _imageLabeler;
  bool isDetecting = false;

  late FlutterTts flutterTts;
  String? lastSpokenObject;
  bool isVibrating = false;

  Future<void> tryVibrate() async {
    if (isVibrating) return;
    isVibrating = true;
    await VibrationService.vibrateIfPossible(pattern: [0, 500, 250, 500]);
    await Future.delayed(Duration(seconds: 2)); // evita múltiples vibraciones seguidas
    isVibrating = false;
  }

  // 🔐 Lista de objetos peligrosos integrada
  final Set<String> collisionProneObjects = {
    "ambulance", "ladder", "traffic light", "cart", "backpack", "bicycle",
    "boat", "bus", "bicycle wheel", "tower", "billboard", "stairs", "traffic sign",
    "chair", "cabinetry", "suitcase", "desk", "office building", "fountain",
    "christmas tree", "studio couch", "oven", "couch", "door", "stop sign",
    "wardrobe", "tree house", "gas stove", "barrel", "treadmill", "window blind",
    "golf cart", "street light", "door handle", "bathtub", "stationary bicycle",
    "ceiling fan", "sofa bed", "bed", "fireplace", "bookcase", "refrigerator",
    "wood-burning stove", "filing cabinet", "table", "billiard table", "motorcycle",
    "bathroom cabinet", "mirror", "skyscraper", "tank", "tree", "train", "truck",
    "helicopter", "toilet", "building", "furniture", "airplane", "bench", "window",
    "closet", "lamp", "drawer", "microwave oven", "shelf", "van",
    "kitchen & dining room table", "dog bed", "cat furniture", "kitchen appliance",
    "car", "dishwasher", "wheelchair", "Wall", "wall", "pared", "room", "habitación", "Room"
  };

  // Mapa de traducciones inglés -> español
  final Map<String, String> objectTranslations = {
    "person": "persona",
    "bicycle": "bicicleta",
    "car": "carro",
    "motorcycle": "motocicleta",
    "airplane": "avión",
    "bus": "bus",
    "train": "tren",
    "truck": "camión",
    "boat": "barco",
    "traffic light": "semáforo",
    "fire hydrant": "hidrante",
    "stop sign": "señal de alto",
    "parking meter": "parquímetro",
    "bench": "banco",
    "bird": "pájaro",
    "cat": "gato",
    "dog": "perro",
    "horse": "caballo",
    "sheep": "oveja",
    "cow": "vaca",
    "elephant": "elefante",
    "bear": "oso",
    "zebra": "cebra",
    "giraffe": "jirafa",
    "backpack": "mochila",
    "umbrella": "paraguas",
    "handbag": "bolso",
    "tie": "corbata",
    "suitcase": "maleta",
    "frisbee": "frisbi",
    "skis": "esquís",
    "snowboard": "tabla de snowboard",
    "sports ball": "pelota deportiva",
    "kite": "cometa",
    "baseball bat": "bate de béisbol",
    "baseball glove": "guante de béisbol",
    "skateboard": "patineta",
    "surfboard": "tabla de surf",
    "tennis racket": "raqueta de tenis",
    "bottle": "botella",
    "wine glass": "copa de vino",
    "cup": "taza",
    "fork": "tenedor",
    "knife": "cuchillo",
    "spoon": "cuchara",
    "bowl": "tazón",
    "banana": "banana",
    "apple": "manzana",
    "sandwich": "sándwich",
    "orange": "naranja",
    "broccoli": "brócoli",
    "carrot": "zanahoria",
    "hot dog": "perro caliente",
    "pizza": "pizza",
    "donut": "donut",
    "cake": "pastel",
    "chair": "silla",
    "couch": "sofá",
    "potted plant": "planta en maceta",
    "bed": "cama",
    "dining table": "mesa de comedor",
    "toilet": "inodoro",
    "TV": "televisor",
    "laptop": "portátil",
    "mouse": "ratón",
    "remote": "control remoto",
    "keyboard": "teclado",
    "cell phone": "teléfono celular",
    "microwave": "microondas",
    "oven": "horno",
    "toaster": "tostadora",
    "sink": "fregadero",
    "refrigerator": "refrigerador",
    "book": "libro",
    "clock": "reloj",
    "vase": "florero",
    "scissors": "tijeras",
    "teddy bear": "oso de peluche",
    "hair drier": "secador de cabello",
    "toothbrush": "cepillo de dientes",
    "room": "habitación",
    "door": "puerta",
    "window": "ventana",
    "mirror": "espejo",
    "painting": "cuadro",
    "Ambulance": "Ambulancia",
    "Ladder": "Escalera",
    "Traffic light": "Semáforo",
    "Sunglasses": "Gafas de sol",
    "Cart": "Carrito",
    "Backpack": "Mochila",
    "Bicycle": "Bicicleta",
    "Home appliance": "Electrodomésticos",
    "Boat": "Barco",
    "Bus": "Autobús",
    "Bicycle wheel": "Rueda de bicicleta",
    "Tower": "Torre",
    "Billboard": "Valla publicitaria",
    "Carnivore": "Carnívoro",
    "Stairs": "Escaleras",
    "Traffic sign": "Señal de tráfico",
    "Chair": "Silla",
    "Cabinetry": "Armarios",
    "Suitcase": "Maleta",
    "Desk": "Escritorio",
    "Office building": "Edificio de oficinas",
    "Fountain": "Fuente",
    "Christmas tree": "Árbol de Navidad",
    "Studio couch": "Sofá de estudio",
    "Oven": "Horno",
    "Couch": "Sofá",
    "Door": "Puerta",
    "Scarf": "Bufanda",
    "Stop sign": "Señal de stop",
    "Wardrobe": "Armario",
    "Personal care": "Artículos de higiene personal",
    "Tree house": "Casa del árbol",
    "Gas stove": "Cocina de gas",
    "Barrel": "Barril",
    "Treadmill": "Cinta de correr",
    "Window blind": "Persiana",
    "Golf cart": "Carrito de golf",
    "Street light": "Farola",
    "Door handle": "Mango de puerta",
    "Bathtub": "Bañera",
    "Kitchen utensil": "Utensilios de cocina",
    "Stationary bicycle": "Bicicleta estática",
    "Ceiling fan": "Ventilador de techo",
    "Sofa bed": "Sofá cama",
    "Bicycle helmet": "Casco de bicicleta",
    "Bed": "Cama",
    "Fireplace": "Chimenea",
    "Kitchenware": "Utensilios de cocina",
    "Indoor rower": "Remo de interior",
    "Bookcase": "Librería",
    "Refrigerator": "Nevera",
    "Wood-burning stove": "Estufa de leña",
    "Filing cabinet": "Archivador",
    "Table": "Mesa",
    "Tableware": "Vajilla",
    "Billiard table": "Mesa de billar",
    "Motorcycle": "Motocicleta",
    "Bathroom cabinet": "Mueble de baño",
    "Bust": "Busto",
    "Mirror": "Espejo",
    "Table tennis racket": "Tenis de mesa Raqueta",
    "Kitchen knife": "Cuchillo de cocina",
    "Chest of drawers": "Cómoda",
    "Piano": "Piano",
    "Infant bed": "Cuna",
    "Cupboard": "Armario",
    "Training bench": "Banco de entrenamiento",
    "Coffee table": "Mesa de centro",
    "Skyscraper": "Rascacielos",
    "Tank": "Tanque",
    "Tree": "Árbol",
    "Train": "Tren",
    "Truck": "Camión",
    "Helicopter": "Helicóptero",
    "Toilet": "Inodoro",
    "Toilet paper": "Papel higiénico",
    "Rocket": "Cohete",
    "Wine glass": "Copa de vino",
    "Countertop": "Encimera",
    "Tablet computer": "Tablet",
    "Palm tree": "Palmera",
    "Building": "Edificio",
    "Furniture": "Muebles",
    "Airplane": "Avión",
    "Bench": "Banco",
    "Window": "Ventana",
    "Closet": "Armario",
    "Lamp": "Lámpara",
    "Vegetable": "Verdura",
    "Carrot": "Zanahoria",
    "Drawer": "Cajón",
    "Microwave oven": "Microondas",
    "Shelf": "Estante",
    "Van": "Furgoneta",
    "Wall clock": "Reloj de pared",
    "Kitchen & dining room table": "Mesa de cocina y comedor",
    "Dog bed": "Cama para perro",
    "Cat furniture": "Muebles para gato",
    "Kitchen appliance": "Electrodomésticos",
    "Glasses": "Vasos",
    "Car": "Coche",
    "Dishwasher": "Lavavajillas",
    "Wheelchair": "Silla de ruedas",
    "Wall": "pared",

  };

  // Método para traducir etiqueta
  String traducirEtiqueta(String etiqueta) {
    return objectTranslations[etiqueta.toLowerCase()] ?? etiqueta;
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeMLKit();
    _initializeTTS();
  }

  /// Initialize TTS
  void _initializeTTS() {
    flutterTts = FlutterTts();
    flutterTts.setLanguage("es-ES");
    flutterTts.setPitch(1.0);
  }

  Future<void> speakObject(String objectName) async {
    final nombreTraducido = traducirEtiqueta(objectName);
    if (nombreTraducido != lastSpokenObject) {
      lastSpokenObject = nombreTraducido;
      await flutterTts.speak(nombreTraducido);
    }
  }

  /// Initialize Camera
  Future<void> _initializeCamera() async {
    _cameraController = CameraController(
      widget.cameras[0],
      ResolutionPreset.ultraHigh,
      enableAudio: false,
    );

    await _cameraController.initialize();
    if (!mounted) return;

    setState(() {
      isCameraReady = true;
    });

    _startImageStream();
  }

  /// Initialize ML Kit
  void _initializeMLKit() {
    _imageLabeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.5),
    );
  }

  /// Start Image Stream
  void _startImageStream() {
    _cameraController.startImageStream((CameraImage image) async {
      if (isDetecting) return;
      isDetecting = true;
      await _processImage(image);
      isDetecting = false;
    });
  }

  /// Process Image
  Future<void> _processImage(CameraImage cameraImage) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File imageFile = File(filePath);

      final XFile picture = await _cameraController.takePicture();
      await picture.saveTo(imageFile.path);

      final inputImage = InputImage.fromFile(imageFile);
      final List<ImageLabel> labels = await _imageLabeler.processImage(inputImage);

      String detectedObjects =
          labels.isNotEmpty
              ? labels
                  .map((label) =>
                      "${traducirEtiqueta(label.label)} - ${(label.confidence * 100).toStringAsFixed(2)}%")
                  .join("\n")
              : "No se detectó ningún objeto";

      setState(() {
        result = detectedObjects;
      });

      if (labels.isNotEmpty) {
        String mostConfidentLabel = labels.first.label;

        // 🔔 Verifica si es un objeto de colisión
        final normalizedLabel = mostConfidentLabel.trim().toLowerCase();
        print("Etiqueta normalizada: $normalizedLabel");
        if (collisionProneObjects.contains(normalizedLabel)) {
         tryVibrate();
        }
        await speakObject(mostConfidentLabel);
      }
    } catch (e) {
      print("Error processing image: $e");
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _imageLabeler.close();
    flutterTts.stop();
    super.dispose();
  }

  MediaQueryData? mqData;
  @override
  Widget build(BuildContext context) {
    mqData = MediaQuery.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff213555),
        title: Text(
          "Detección de objetos en tiempo real",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        leading: Image.asset("assets/icons/object.png", color: Colors.blue),
      ),
      backgroundColor: Color(0xff3E5879),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Center(
              child: SizedBox(
                width: mqData!.size.width,
                child: isCameraReady
                    ? CameraPreview(_cameraController)
                    : Center(child: CircularProgressIndicator()),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                width: mqData!.size.width,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0x5af0bb78),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      "Objetos detectados",
                      style: myTextStyle18(
                        fontWeight: FontWeight.bold,
                        fontColors: Colors.orange,
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: Text(
                        result,
                        textAlign: TextAlign.start,
                        style: myTextStyle18(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:object_detection_app/screen/object_detection_screen.dart';
import 'package:object_detection_app/screen/splash_screen.dart';
import 'package:object_detection_app/utils/fall_detector.dart';


import 'package:firebase_core/firebase_core.dart';
import 'locationSharer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final cameras = await availableCameras();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp ,
    DeviceOrientation.portraitDown
  ]) ;

   // Inicia el detector de caídas
    final fallDetector = FallDetector(
      onFallDetected: (message) {
        // Aquí puedes llamar una función para enviar SMS o notificación
        print("MENSAJE: $message");
      },
    );
    fallDetector.startMonitoring();

  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return LocationSharer(
      userId: 'usuario1', 
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: SplashScreen(cameras: cameras,),
      ),
    );
  }
}

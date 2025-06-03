import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationSharer extends StatefulWidget {
  final Widget child;
  final String userId;

  const LocationSharer({Key? key, required this.child, required this.userId}) : super(key: key);

  @override
  State<LocationSharer> createState() => _LocationSharerState();
}

class _LocationSharerState extends State<LocationSharer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    print('LocationSharer iniciado');
    startSharingLocation();
  }

  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('GPS no está activado.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Permiso de ubicación denegado.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Permiso de ubicación denegado permanentemente.');
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      print('Posición obtenida: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('Error obteniendo ubicación: $e');
      return null;
    }
  }

  void startSharingLocation() {
  _timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
    Position? pos = await getCurrentLocation();

    if (pos == null) {
      print('No se pudo obtener la ubicación, se omitirá el envío.');
      return;
    }

    try {
      print('Enviando datos a Firestore...');
      await FirebaseFirestore.instance
          .collection('locations')
          .add({   // <--- Cambié .doc(widget.userId).set por .add para crear nuevo documento
        'userId': widget.userId, // guardar para poder filtrar por usuario
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Ubicación enviada: ${pos.latitude}, ${pos.longitude}');
    } catch (e) {
      print('Error enviando ubicación a Firestore: $e');
    }
  });
}


  @override
  void dispose() {
    _timer?.cancel();
    print('LocationSharer detenido');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

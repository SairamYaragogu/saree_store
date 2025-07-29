import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:saree_business/user_items.dart';
import 'package:url_launcher/url_launcher.dart';

import 'admin_panel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
        apiKey: "AIzaSyCHKx45NzD_dVGc35EmLbhh-6kM4DqIGIA",
        authDomain: "sareebusiness-b14b1.firebaseapp.com",
        projectId: "sareebusiness-b14b1",
        storageBucket: "sareebusiness-b14b1.firebasestorage.app",
        messagingSenderId: "56724650735",
        appId: "1:56724650735:web:39a9ca8175dbfb9525391a",
        measurementId: "G-KEQRE88HDS"
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saree Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.pink),
      home: UserItems(),
    );
  }
}
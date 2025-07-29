import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saree_business/user_items.dart';

class AdminPanel extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();
  final TextEditingController whatsappNumberController = TextEditingController();

  void saveSaree() async {
    final data = {
      'title': titleController.text,
      'description': descriptionController.text,
      'price': priceController.text,
      'imageUrl': imageUrlController.text,
      'whatsapp': whatsappNumberController.text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('sarees').add(data);

    titleController.clear();
    descriptionController.clear();
    priceController.clear();
    imageUrlController.clear();
    whatsappNumberController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saree added successfully!')),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    imageUrlController.dispose();
    whatsappNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Panel'), actions: [
        IconButton(
          icon: Icon(Icons.logout),
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => UserItems()));
          },
        )
      ]),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: titleController, decoration: InputDecoration(labelText: 'Title')),
            TextField(controller: descriptionController, decoration: InputDecoration(labelText: 'Description')),
            TextField(controller: priceController, decoration: InputDecoration(labelText: 'Price')),
            TextField(controller: imageUrlController, decoration: InputDecoration(labelText: 'Image URL')),
            TextField(controller: whatsappNumberController, decoration: InputDecoration(labelText: 'WhatsApp Number')),
            SizedBox(height: 20),
            ElevatedButton(onPressed: saveSaree, child: Text('Add Saree')),
          ],
        ),
      ),
    );
  }
}
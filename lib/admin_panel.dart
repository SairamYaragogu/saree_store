import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saree_business/user_items.dart';

class AdminPanel extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  bool isLoading = false;

  Future<void> pickAndUploadCSV() async {
    setState(() => isLoading = true);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result != null) {
      final fileBytes = result.files.single.bytes;

      String contents;
      if (fileBytes != null) {
        contents = utf8.decode(fileBytes);
      } else {
        final path = result.files.single.path;
        if (path == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to read file')),
          );
          setState(() => isLoading = false);
          return;
        }

        final file = File(path);
        contents = await file.readAsString();
      }

      // ✅ Step 3: Delete original collection
      await deleteAllDocumentsFromCollection('stock');

      // ✅ Step 4: Upload fresh data
      await _parseAndUploadCSV(contents);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV uploaded successfully')),
      );
    }
    setState(() => isLoading = false);
  }

  Future<void> _parseAndUploadCSV(String contents) async {
    List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter().convert(contents);

    for (int i = 1; i < rowsAsListOfValues.length; i++) {
      final row = rowsAsListOfValues[i];

      final sno = int.tryParse(row[0].toString().trim()) ?? 0;
      final category = row[1].toString().trim();
      final subcategory = row[2].toString().trim();
      final title = row[3].toString().trim();
      final description = row[4].toString().trim();
      final price = double.tryParse(row[5].toString()) ?? 0.0;

      // 🔹 Extract all image URLs from column 6 onwards
      final imageUrls = row[6]
          .toString()
          .split(',')
          .map((url) => url
            .trim()
            .replaceAll('\n', '')
            .replaceAll('\r', '')
            .replaceAll('\t', ''))
          .where((url) => url.isNotEmpty)
          .toList();

      await FirebaseFirestore.instance.collection('stock').add({
        'sno': sno,
        'category': category,
        'subcategory': subcategory,
        'title': title,
        'description': description,
        'price': price,
        'imageUrls': imageUrls,
      });
    }
  }
  Future<void> deleteAllDocumentsFromCollection(String collectionName) async {
    final collection = FirebaseFirestore.instance.collection(collectionName);
    final snapshots = await collection.get();

    final batch = FirebaseFirestore.instance.batch();

    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
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
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : ElevatedButton.icon(
          icon: Icon(Icons.upload_file),
          label: Text("Upload CSV"),
          onPressed: pickAndUploadCSV,
        ),
      ),
    );
  }
}
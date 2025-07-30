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

      // ✅ Step 1: Create latest backup
      final latestBackupName = await backupCollection('saree_items_2');

      // ✅ Step 2: Delete all old backups except the latest one
      await deleteOldBackupsExcept(latestBackupName);

      // ✅ Step 3: Delete original collection
      await deleteAllDocumentsFromCollection('saree_items_2');

      // ✅ Step 4: Upload fresh data
      await _parseAndUploadCSV(contents);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV uploaded successfully (with backup)')),
      );
    }

    setState(() => isLoading = false);
  }

  Future<void> _parseAndUploadCSV(String contents) async {
    List<List<dynamic>> rowsAsListOfValues =
    const CsvToListConverter().convert(contents);

    for (int i = 1; i < rowsAsListOfValues.length; i++) {
      final row = rowsAsListOfValues[i];

      if (row.length < 5) continue; // skip incomplete rows

      final sno = row[0].toString().trim();
      final title = row[1].toString().trim();
      final description = row[2].toString().trim();
      final price = double.tryParse(row[3].toString()) ?? 0.0;
      final imageUrl = row[4].toString().trim();

      await FirebaseFirestore.instance.collection('saree_items_2').add({
        'sno': sno,
        'title': title,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
      });
    }
  }

  Future<String> backupCollection(String collectionName) async {
    final now = DateTime.now();
    final timestamp = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour}${now.minute}${now.second}";
    final backupName = "${collectionName}_backup_$timestamp";

    final firestore = FirebaseFirestore.instance;
    final backupCollection = firestore.collection(backupName);
    final originalDocs = await firestore.collection(collectionName).get();

    final batch = firestore.batch();
    for (var doc in originalDocs.docs) {
      batch.set(backupCollection.doc(doc.id), doc.data());
    }
    await batch.commit();

    // 👉 Store backup metadata
    await firestore.collection('saree_backups_index').add({
      'name': backupName,
      'timestamp': now.toIso8601String(),
    });

    return backupName;
  }

  Future<void> deleteOldBackupsExcept(String latestBackupName) async {
    final firestore = FirebaseFirestore.instance;
    final indexSnapshot = await firestore
        .collection('saree_backups_index')
        .orderBy('timestamp', descending: true)
        .get();

    final docs = indexSnapshot.docs;

    for (int i = 1; i < docs.length; i++) {
      final backupName = docs[i]['name'];

      // Delete backup collection documents
      final backupCollection = firestore.collection(backupName);
      final backupDocs = await backupCollection.get();
      final batch = firestore.batch();

      for (var doc in backupDocs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete from index
      await firestore.collection('saree_backups_index').doc(docs[i].id).delete();
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
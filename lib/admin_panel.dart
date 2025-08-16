import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({Key? key}) : super(key: key);

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  ValueNotifier<double> progressNotifier = ValueNotifier(0);
  bool isUploading = false;

  Future<void> pickAndUploadCSV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      String contents = utf8.decode(result.files.single.bytes!);

      _showProgressDialog();

      // ✅ Step 3: Delete original collection
      await deleteAllDocumentsFromCollection('stock');

      // ✅ Step 4: Upload fresh data
      await _parseAndUploadCSV(contents);

      Navigator.pop(context); // Close progress dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV upload completed!')),
      );
    }
  }

  Future<void> _parseAndUploadCSV(String contents) async {
    List<List<dynamic>> rows = const CsvToListConverter().convert(contents);

    int totalRows = rows.length - 1; // excluding header
    int uploadedCount = 0;

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];

      final sno = int.tryParse(row[0].toString().trim()) ?? 0;
      final category = row[1].toString().trim();
      final subcategory = row[2].toString().trim();
      final title = row[3].toString().trim();
      final description = row[4].toString().trim();
      final price = double.tryParse(row[5].toString()) ?? 0.0;

      final imageUrls = row[6]
          .toString()
          .split(',')
          .map((url) => url.trim().replaceAll(RegExp(r'[\n\r\t]'), ''))
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

      uploadedCount++;
      progressNotifier.value = (uploadedCount / totalRows) * 100;

      // Give UI time to update
      await Future.delayed(const Duration(milliseconds: 50));
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
  void _showProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: ValueListenableBuilder<double>(
            valueListenable: progressNotifier,
            builder: (_, progress, __) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Uploading CSV", style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: progress / 100),
                  const SizedBox(height: 8),
                  Text("${progress.toStringAsFixed(0)}% completed"),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Center(
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  size: 60,
                  color: Colors.deepOrangeAccent,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Upload Stock CSV",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Select a CSV file to replace the existing stock list in the database.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text(
                      "Upload CSV",
                      style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.orangeAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: pickAndUploadCSV,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
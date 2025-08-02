import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saree_business/admin_login.dart';

class UserItems extends StatefulWidget {
  @override
  _UserItemsState createState() => _UserItemsState();
}

class _UserItemsState extends State<UserItems> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // 🔹 Dynamic column count based on screen width
    int crossAxisCount;
    if (screenWidth < 600) {
      crossAxisCount = 2; // Mobile
    } else if (screenWidth < 1024) {
      crossAxisCount = 3; // Small tablet / small web
    } else if (screenWidth < 1440) {
      crossAxisCount = 4; // Large screen / desktop
    } else {
      crossAxisCount = 5; // Very large desktop
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('RK Collections'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdminLogin()),
              );
            },
            child: Text(
              'Admin Login',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stock')
            .orderBy('sno', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No items available'));
          }

          final sarees = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 250, // 🔹 Max width per item
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 240, // 🔹 Fixed card height instead of aspect ratio
            ),
            itemCount: sarees.length,
            itemBuilder: (context, index) {
              final saree = sarees[index];

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                clipBehavior: Clip.hardEdge,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Product Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: saree['imageUrl'] != null &&
                          saree['imageUrl'].toString().isNotEmpty
                          ? Image.network(
                        saree['imageUrl'],
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              height: 120,
                              color: Colors.grey[300],
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image, size: 50),
                            ),
                      )
                          : Container(
                        height: 120,
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: const Icon(Icons.image, size: 50),
                      ),
                    ),

                    // 🔹 Product Info
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            saree['title'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            saree['description'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${saree['price'] ?? 'N/A'}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saree_business/admin_login.dart';
import 'package:url_launcher/url_launcher.dart';

class UserItems extends StatefulWidget {
  @override
  _UserItemsState createState() => _UserItemsState();
}

class _UserItemsState extends State<UserItems> {
  Future<void> _launchWhatsApp(String number) async {
    final Uri url = Uri.parse('https://wa.me/$number');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                color: Colors.black, // Adjust if AppBar background changes
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
            padding: EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Two items per row
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.65, // Adjust height/width ratio
            ),
            itemCount: sarees.length,
            itemBuilder: (context, index) {
              final saree = sarees[index];

              return GestureDetector(
                onTap: () {
                  // Optional: Navigate to detailed screen if required
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // 🔹 Avoid taking extra vertical space
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 Product Image
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        child: saree['imageUrl'] != null &&
                            saree['imageUrl'].toString().isNotEmpty
                            ? Image.network(
                          saree['imageUrl'],
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 140,
                            color: Colors.grey[300],
                            alignment: Alignment.center,
                            child: Icon(Icons.broken_image, size: 50),
                          ),
                        )
                            : Container(
                          height: 140,
                          color: Colors.grey[300],
                          alignment: Alignment.center,
                          child: Icon(Icons.image, size: 50),
                        ),
                      ),

                      // 🔹 Product Info
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // 🔹 Shrink wrap content
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              saree['title'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(saree['description'] ?? ''),
                            SizedBox(height: 4),
                            Text(
                              '₹${saree['price'] ?? 'N/A'}',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 6),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
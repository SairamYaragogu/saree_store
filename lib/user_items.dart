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
                color: Colors.black, // or Colors.white based on AppBar bg
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sarees')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No sarees available'));
          }

          final sarees = snapshot.data!.docs;
          return ListView.builder(
            itemCount: sarees.length,
            itemBuilder: (context, index) {
              final saree = sarees[index];
              return Card(
                margin: EdgeInsets.all(8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (saree['imageUrl'] != null && saree['imageUrl'].toString().isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          saree['imageUrl'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 200,
                            color: Colors.grey[300],
                            alignment: Alignment.center,
                            child: Icon(Icons.broken_image, size: 50),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            saree['title'] ?? '',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 6),
                          Text(saree['description'] ?? ''),
                          SizedBox(height: 6),
                          Text('₹${saree['price'] ?? 'N/A'}', style: TextStyle(color: Colors.green[700])),
                          SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () => _launchWhatsApp(saree['whatsapp']),
                            icon: Icon(Icons.chat),
                            label: Text('Chat on WhatsApp'),
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
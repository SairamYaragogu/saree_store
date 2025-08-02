import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saree_business/admin_login.dart';


class UserItems extends StatefulWidget {
  @override
  _UserItemsState createState() => _UserItemsState();
}

class _UserItemsState extends State<UserItems> with SingleTickerProviderStateMixin {
  String selectedCategory = "All";
  List<String> categories = ["All"];
  int fadeKey = 0; // 🔹 To trigger fade animation on category change

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  /// 🔹 Fetch unique categories from Firestore
  Future<void> fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('stock').get();

    final uniqueCategories = snapshot.docs
        .map((doc) => doc['category']?.toString() ?? "")
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    setState(() {
      categories = ["All", ...uniqueCategories];
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // 🔹 Dynamic column count based on screen width
    int crossAxisCount;
    if (screenWidth < 600) {
      crossAxisCount = 2; // Mobile
    } else if (screenWidth < 1024) {
      crossAxisCount = 3; // Tablet / small web
    } else if (screenWidth < 1440) {
      crossAxisCount = 4; // Large desktop
    } else {
      crossAxisCount = 5; // Very large desktop
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('RK Collections'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdminLogin()),
              );
            },
            child: const Text(
              'Admin Login',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔹 Animated Horizontal Category Chips
          Container(
            height: 60,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                      fadeKey++; // 🔹 Trigger fade animation for grid
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                          : [],
                    ),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: isSelected ? 15 : 14,
                      ),
                      child: Text(category),
                    ),
                  ),
                );
              },
            ),
          ),

          // 🔹 Items Grid with Fade Animation
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: (selectedCategory == "All")
                  ? FirebaseFirestore.instance
                  .collection('stock')
                  .orderBy('sno', descending: true)
                  .snapshots()
                  : FirebaseFirestore.instance
                  .collection('stock')
                  .where('category', isEqualTo: selectedCategory)
                  .orderBy('sno', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No items available'));
                }

                final items = snapshot.data!.docs;

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  key: ValueKey(fadeKey), // 🔹 Trigger rebuild for fade
                  child: GridView.builder(
                    key: ValueKey(selectedCategory), // 🔹 Unique key for fade effect
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 250, // 🔹 Max width per item
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 240, // 🔹 Fixed card height
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];

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
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: item['imageUrl'] != null &&
                                  item['imageUrl'].toString().isNotEmpty
                                  ? Image.network(
                                item['imageUrl'],
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                    Container(
                                      height: 120,
                                      color: Colors.grey[300],
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.broken_image,
                                          size: 50),
                                    ),
                              )
                                  : Container(
                                height: 120,
                                color: Colors.grey[300],
                                alignment: Alignment.center,
                                child:
                                const Icon(Icons.image, size: 50),
                              ),
                            ),

                            // 🔹 Product Info
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['description'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${item['price'] ?? 'N/A'}',
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
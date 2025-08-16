import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saree_business/admin_login.dart';
import 'package:saree_business/product_details.dart';


class UserItems extends StatefulWidget {
  @override
  _UserItemsState createState() => _UserItemsState();
}

class _UserItemsState extends State<UserItems> with SingleTickerProviderStateMixin {
  String selectedCategory = "All";
  String selectedSubcategory = "All";

  List<String> categories = ["All"];
  List<String> subcategories = ["All"];

  int fadeKey = 0;

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

  /// 🔹 Fetch unique subcategories for selected category
  Future<void> fetchSubcategories(String category) async {
    if (category == "All") {
      setState(() {
        subcategories = ["All"];
        selectedSubcategory = "All";
      });
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('stock')
        .where('category', isEqualTo: category)
        .get();

    final uniqueSubcategories = snapshot.docs
        .map((doc) => doc['subcategory']?.toString() ?? "")
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    setState(() {
      subcategories = ["All", ...uniqueSubcategories];
      selectedSubcategory = "All";
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

    // 🔹 Build Firestore query
    Query query = FirebaseFirestore.instance.collection('stock');
    if (selectedCategory != "All") {
      query = query.where('category', isEqualTo: selectedCategory);
    }
    if (selectedCategory != "All" && selectedSubcategory != "All") {
      query = query.where('subcategory', isEqualTo: selectedSubcategory);
    }
    query = query.orderBy('sno', descending: true);

    // 🔹 Check if any filter is applied
    bool isFilterActive = selectedCategory != "All" || selectedSubcategory != "All";

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Akki Collections'),
        centerTitle: MediaQuery.of(context).size.width > 600,
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
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔹 Category Chips with Auto-Hiding Clear Filter
          Container(
            height: 60,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: categories.length + (isFilterActive ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (isFilterActive && index == 0) {
                  // 🔹 Clear Filters chip
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = "All";
                        selectedSubcategory = "All";
                        subcategories = ["All"];
                        fadeKey++;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.clear, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Clear Filters',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final category = categories[index - (isFilterActive ? 1 : 0)];
                final isSelected = selectedCategory == category;

                return GestureDetector(
                  onTap: () async {
                    setState(() {
                      selectedCategory = category;
                      fadeKey++; // Trigger fade animation
                    });
                    await fetchSubcategories(category);
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

          // 🔹 Subcategory Chips
          if (selectedCategory != "All" && subcategories.length > 1)
            Container(
              height: 50,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: subcategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final subcategory = subcategories[index];
                  final isSelected = selectedSubcategory == subcategory;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedSubcategory = subcategory;
                        fadeKey++; // Trigger fade animation
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.green : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.4),
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
                          fontWeight: FontWeight.w500,
                          fontSize: isSelected ? 14 : 13,
                        ),
                        child: Text(subcategory),
                      ),
                    ),
                  );
                },
              ),
            ),

          // 🔹 Items Grid with Fade Animation
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
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
                  key: ValueKey(fadeKey),
                  child: GridView.builder(
                    key: ValueKey(selectedCategory + selectedSubcategory),
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 250,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 240,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final doc = items[index];
                      final item = doc.data() as Map<String, dynamic>; // Convert Firestore doc to Map

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailsScreen(product: Map<String, dynamic>.from(item)),
                            ),
                          );
                        },
                        child: Card(
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
                                child: item['imageUrls'] != null && (item['imageUrls'] as List).isNotEmpty
                                    ? Image.network(
                                  item['imageUrls'][0],
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
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
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
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
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:saree_business/image_zoom_gallery.dart';
import 'dart:html' as html;

import 'package:url_launcher/url_launcher.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({Key? key, required this.product})
      : super(key: key);

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // 🔹 Zoom Animation
  double _scale = 1.0;
  double _targetScale = 1.0;
  late AnimationController _animationController;
  late Animation<double> _animation;
  String? _adminWhatsApp;

  @override
  void initState() {
    super.initState();
    _loadAdminWhatsApp();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminWhatsApp() async {
    _adminWhatsApp = await _getAdminWhatsAppNumber();
  }

  /// 🔹 Animate double-tap zoom
  void _handleDoubleTap() {
    _targetScale = _scale == 1.0 ? 2.0 : 1.0;
    _animation = Tween<double>(begin: _scale, end: _targetScale).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.reset();
    _animationController.forward();

    _animation.addListener(() {
      setState(() {
        _scale = _animation.value;
      });
    });
  }

  Future<void> _openWhatsApp(
      BuildContext context,
      String title,
      String description,
      String price,
      String imageUrl,
      ) async {
    final adminNumber = _adminWhatsApp; // already preloaded

    if (adminNumber == null || adminNumber.isEmpty) {
      _showWhatsAppError(context);
      return;
    }

    final phone =
    adminNumber.startsWith('91') ? adminNumber : '91$adminNumber';

    final message = '''
Hi *AKKI LATEST COLLECTIONS*

I'm interested in the following product:

🛍️ Product: *$title*

📝 Description: $description

💰 Price: *$price*

🖼️ Product Image: $imageUrl
''';

    final encodedMessage = Uri.encodeComponent(message);

    final url =
        'https://api.whatsapp.com/send?phone=$phone&text=$encodedMessage';

    if (kIsWeb) {
      // ✅ iOS Safari FIX
      html.window.open(url, '_blank');
    } else {
      // ✅ Android / iOS App
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<String?> _getAdminWhatsAppNumber() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('admin')
          .get();

      if (doc.exists) {
        return doc['whatsappNumber'];
      }
    } catch (e) {
      debugPrint("Error fetching WhatsApp number: $e");
    }
    return null;
  }

  void _showWhatsAppError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('Could not open WhatsApp. Please ensure it is installed.')),
    );
  }

  /// 🔹 Main Image with pinch & animated double-tap zoom
  Widget _buildMainImage(String url) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: Container(
        color: Colors.black12,
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.deepOrangeAccent, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InteractiveViewer(
              panEnabled: true,
              scaleEnabled: true,
              minScale: 1.0,
              maxScale: 4.0,
              child: Image.network(
                url,
                fit: BoxFit.fill,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (_, __, ___) =>
                    const Center(child: Icon(Icons.broken_image, size: 50)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 Horizontal Thumbnails for Small Screens
  Widget _buildHorizontalThumbnails(List<String> imageUrls) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() => _currentIndex = index);
              _pageController.jumpToPage(index);
              _scale = 1.0; // Reset zoom on image change
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _currentIndex == index
                      ? Colors.pinkAccent
                      : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.network(
                imageUrls[index],
                width: 70,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  /// 🔹 Vertical Thumbnails for Large Screens
  Widget _buildVerticalThumbnails(List<String> imageUrls) {
    return SizedBox(
      width: 80,
      child: ListView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() => _currentIndex = index);
              _pageController.jumpToPage(index);
              _scale = 1.0; // Reset zoom on image change
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _currentIndex == index
                      ? Colors.pinkAccent
                      : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.network(
                imageUrls[index],
                width: 70,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.product['title'] ?? '';
    final description = widget.product['description'] ?? '';
    final price = widget.product['price']?.toString() ?? '0';
    final imageUrls = List<String>.from(widget.product['imageUrls'] ?? []);

    final isLargeScreen = MediaQuery.of(context).size.width > 800;

    final productDetailsSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(description,
            style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        const SizedBox(height: 16),
        Text('₹ $price',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green)),
        const SizedBox(height: 20),

        // 🔹 WhatsApp button
        ElevatedButton.icon(
          onPressed: () => _openWhatsApp(
              context, title, description, price, imageUrls[_currentIndex]),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: Image.asset(
            'assets/icons/whatsapp.png',
            height: 24,
            width: 24,
          ),
          label: const Text("Chat on WhatsApp",
              style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
        const SizedBox(height: 50),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.yellowAccent, // 🔹 Title text color
            fontSize: 18, // 🔹 Reduce text size
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF2874F0),
        elevation: 6,
        shadowColor: Colors.yellowAccent,
        iconTheme: const IconThemeData(
          color: Colors.white, // 🔹 Back arrow color
        ),
      ),
      body: isLargeScreen
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Left side (vertical thumbnails + main image)
                Expanded(
                  flex: 2,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVerticalThumbnails(imageUrls),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 400,
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: imageUrls.length,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentIndex = index;
                                    _scale = 1.0; // Reset zoom on page change
                                  });
                                },
                                itemBuilder: (context, index) {
                                  return AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 400),
                                    transitionBuilder: (child, anim) =>
                                        FadeTransition(
                                            opacity: anim, child: child),
                                    //child: _buildMainImage(imageUrls[index]),
                                    child: kIsWeb
                                        ? _buildMainImage(imageUrls[
                                            index]) // For Web (browser or mobile web)
                                        : ImageZoomGallery(
                                            imageUrls: imageUrls,
                                            initialIndex: index,
                                          ), // For Android/iOS
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 🔹 Right side (product details + WhatsApp)
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: productDetailsSection,
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Main Image
                  SizedBox(
                    height: 500,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: imageUrls.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                          _scale = 1.0; // Reset zoom on swipe
                        });
                      },
                      itemBuilder: (context, index) {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, anim) =>
                              FadeTransition(opacity: anim, child: child),
                          //child: ImageZoomGallery(imageUrls: imageUrls, initialIndex: index),
                          child: kIsWeb
                              ? _buildMainImage(imageUrls[
                                  index]) // For Web (browser or mobile web)
                              : ImageZoomGallery(
                                  imageUrls: imageUrls,
                                  initialIndex: index,
                                ), // For Android/iOS
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 5),
                  _buildHorizontalThumbnails(imageUrls),

                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: productDetailsSection,
                  ),
                ],
              ),
            ),
    );
  }
}

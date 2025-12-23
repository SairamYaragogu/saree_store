import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:saree_business/utils/app_strings.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({Key? key}) : super(key: key);

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {

  String? _adminWhatsApp;

  @override
  void initState() {
    super.initState();
    _loadAdminWhatsApp();
  }

  Future<void> _loadAdminWhatsApp() async {
    final number = await _getAdminWhatsAppNumber();

    if (!mounted) return;

    setState(() {
      _adminWhatsApp = number;
    });
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

  Future<void> _openWhatsApp(
      BuildContext context,
      ) async {
    final adminNumber = _adminWhatsApp; // already preloaded

    if (adminNumber == null || adminNumber.isEmpty) {
      _showWhatsAppError(context);
      return;
    }

    final phone =
    adminNumber.startsWith('91') ? adminNumber : '91$adminNumber';

    final encodedMessage = Uri.encodeComponent(AppStrings.CONTACTUS_AKKI);

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

  void _showWhatsAppError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
          Text('Could not open WhatsApp. Please ensure it is installed.')),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contact Us"),
        elevation: 6,
        shadowColor: Colors.yellowAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🔷 Title
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "🌸",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: Colors.green,
                      ),
                    ),
                    TextSpan(
                      text: "Akki\n",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: Colors.pink,
                      ),
                    ),
                    TextSpan(
                      text: " LATEST COLLECTIONS",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🔷 Description
              Text(
                "We’d love to hear from you! Reach out to us for product enquiries, "
                    "bulk orders, or any support related to your purchase.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 24),

              // 📞 WhatsApp
              _contactCard(
                icon: FontAwesomeIcons.whatsapp,
                iconColor: Colors.green,
                title: "WhatsApp",
                subtitle: _adminWhatsApp == null
                    ? "Loading..."
                    : "+91 $_adminWhatsApp",
                onTap: _adminWhatsApp == null
                    ? () {}
                    : () => _openWhatsApp(context),
              ),

              // 📧 Email
              _contactCard(
                icon: Icons.email_outlined,
                iconColor: Colors.redAccent,
                title: "Email",
                subtitle: AppStrings.EMAIL_AKKI,
                onTap: () => _launchUrl(
                  "mailto:${AppStrings.EMAIL_AKKI}?subject=${Uri.encodeComponent("Inquiry from Akki Latest Collections App")}&body=${Uri.encodeComponent(AppStrings.CONTACTUS_AKKI)}",
                ),
              ),

              // 📍 Location
              _contactCard(
                icon: Icons.location_on_outlined,
                iconColor: Colors.blueGrey,
                title: "Location",
                subtitle: "India",
                onTap: () {},
              ),

              const SizedBox(height: 24),

              // 🔷 Footer
              Text(
                "Our team will respond as soon as possible.\n"
                    "Thank you for choosing Akki Latest Collections.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 28),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
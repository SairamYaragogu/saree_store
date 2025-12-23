import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saree_business/utils/app_strings.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About"),
        elevation: 6,
        shadowColor: Colors.yellowAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // ⬅️ horizontal center
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

              // 🔷 About content
              Text(
                AppStrings.aboutAkki,
                textAlign: TextAlign.justify,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

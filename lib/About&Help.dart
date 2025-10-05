import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  // Replace with your actual URLs and data
  final String developerPhoto = 'assets/images/Developer.png'; // Your image in assets
  final String developerName = 'N. Lokeshraj';
  final String role = 'Final Year ECE Student';
  final String organization = 'Meenakshi Sundararajan Engineering College';
  final String location = '';

  final String phone = '';
  final String email = '';
  final String linkedInURL = '';
  final String githubURL = 'https://github.com/lokraj2004';

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('About Developer', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.deepPurple,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Current Admin: Lokeshraj N',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 6,
                color: Colors.deepPurple[100],
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    children: [const Text(
                      'Developer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),const SizedBox(height: 5),
                      CircleAvatar(
                        radius: 70, // 👈 Increase radius as needed (e.g., 60 or 70)
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: Image.asset(
                            developerPhoto,
                            width: 150, // 👈 Match to diameter (2 * radius)
                            height: 170,
                            fit: BoxFit.cover, // 👈 Ensures it fills the circle without distortion
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        developerName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        role,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,

                      ),
                      Text(
                        organization,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        location,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(thickness: 1.5),
              const SizedBox(height: 10),
              _contactTile(
                icon: Icons.phone,
                label: 'Phone',
                value: phone,
                url: 'tel:$phone',
              ),
              _contactTile(
                icon: Icons.email,
                label: 'Email',
                value: email,
                url: 'mailto:$email',
              ),
              _contactTile(
                icon: Icons.linked_camera,
                label: 'LinkedIn',
                value: linkedInURL,
                url: linkedInURL,
              ),
              _contactTile(
                icon: Icons.code,
                label: 'GitHub',
                value: githubURL,
                url: githubURL,
              ),
            ],
          ),
        )
    );
  }

  Widget _contactTile({required IconData icon, required String label, required String value, required String url}) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(label),
      subtitle: Text(value),
      onTap: () => _launchUrl(url),
    );
  }
}


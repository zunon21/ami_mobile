import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactezNousScreen extends StatelessWidget {
  const ContactezNousScreen({Key? key}) : super(key: key);

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber.replaceAll(RegExp(r'\s+'), ''));
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Impossible d’appeler $phoneNumber';
    }
  }

  void _sendEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw 'Impossible d’envoyer un email à $email';
    }
  }

  void _openMap() async {
    const url = 'https://share.google/vfCgWVfhliqPcZe6e';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Impossible d’ouvrir la carte';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFFD4A017),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Contactez Nous', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Center(
                  child: Column(
                    children: [
                      Text('AMI Côte d\'Ivoire', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF7A431D))),
                      SizedBox(height: 8),
                      Text(
                        'N\'hésitez pas à nous contacter pour toute information, partenariat ou soutien à la mission.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Nos Différents Contacts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7A431D))),
                const SizedBox(height: 12),
                _buildContactTile('Direction', '+225 07 77 10 29 62', Icons.business_center),
                _buildContactTile('Administration', '+225 07 09 65 35 25', Icons.admin_panel_settings),
                _buildContactTile('Mobilisation', '+225 07 09 00 46 21', Icons.people),
                _buildContactTile('Recherche', '+225 07 89 68 78 97', Icons.search),
                _buildContactTile('Finances', '+225 07 07 70 18 62', Icons.attach_money),
                _buildContactTile('Zone de Daloa', '+225 07 07 34 96 23', Icons.location_on),
                _buildContactTile('Zone de Bouaké', '+225 07 57 43 03 87', Icons.location_on),
                _buildContactTile('Bureau de San Pedro', '+225 07 49 93 90 86', Icons.location_on),
                const SizedBox(height: 24),
                const Text('Nos Emails', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7A431D))),
                const SizedBox(height: 12),
                _buildEmailTile('Administration', 'amicapro_ci@yahoo.fr'),
                _buildEmailTile('Mobilisation', 'amicimobilisation@gmail.com'),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _sendEmail('amicimobilisation@gmail.com'),
                    icon: const Icon(Icons.email, color: Colors.white),
                    label: const Text('Envoyer un message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A017),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Localisation du Bureau National', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7A431D))),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    onTap: _openMap,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundColor: Color(0xFF7A431D),
                            child: Icon(Icons.location_on, color: Colors.white, size: 30),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Ouvrir dans Google Maps',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7A431D)),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Bureau National de l\'AMI-CI, Abidjan',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactTile(String title, String phone, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFF3E0),
          child: Icon(icon, color: const Color(0xFF7A431D)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(phone),
        trailing: IconButton(
          icon: const Icon(Icons.phone, color: Color(0xFF7A431D)),
          onPressed: () => _makePhoneCall(phone),
        ),
      ),
    );
  }

  Widget _buildEmailTile(String title, String email) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFF3E0),
          child: Icon(Icons.email, color: const Color(0xFFD4A017)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(email),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_browser, color: Color(0xFF7A431D)),
          onPressed: () => _sendEmail(email),
        ),
      ),
    );
  }
}
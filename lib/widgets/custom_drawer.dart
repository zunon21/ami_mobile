import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/ami_cote_ivoire_screen.dart';
import '../screens/contactez_nous_screen.dart';

class CustomDrawer extends StatelessWidget {
  final VoidCallback? onAccueilTap;

  const CustomDrawer({Key? key, this.onAccueilTap}) : super(key: key);

  // ✅ Correction 1 : YouTube fonctionnel
  Future<void> _openYouTube() async {
    const url = 'https://youtube.com/@amicotedivoiretv?si=YdYCdLvGwORvYreL';
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Impossible d’ouvrir le lien';
    }
  }

  // ✅ Correction 2 : Ouvre l'app Priez le Maître si installée, sinon Play Store
  Future<void> _openPriezLeMaitre() async {
    const packageName = 'com.zunon21.priezlemaitre';
    final playStoreUrl = 'https://play.google.com/store/apps/details?id=$packageName';
    
    // Tente d'ouvrir l'application via son package (Android)
    final appUri = Uri(scheme: 'package', path: packageName);
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
    } else {
      // Sinon, ouvre le Play Store
      final storeUri = Uri.parse(playStoreUrl);
      if (await canLaunchUrl(storeUri)) {
        await launchUrl(storeUri, mode: LaunchMode.externalApplication);
      } else {
        // Dernier recours : ouvrir le navigateur
        await launchUrl(storeUri);
      }
    }
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF5D3A1A);

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      backgroundColor: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 40),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: Icon(Icons.home, color: primaryColor),
                  title: Text('Accueil', style: TextStyle(color: primaryColor)),
                  onTap: () {
                    Navigator.pop(context);
                    if (onAccueilTap != null) onAccueilTap!();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.favorite, color: primaryColor),
                  title: Text('AMI Côte d\'Ivoire', style: TextStyle(color: primaryColor)),
                  onTap: () => _navigateTo(context, const AmiCoteIvoireScreen()),
                ),
                ListTile(
                  leading: Icon(Icons.play_circle, color: primaryColor),
                  title: Text('AMI TV', style: TextStyle(color: primaryColor)),
                  onTap: () {
                    Navigator.pop(context);
                    _openYouTube();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.calendar_today, color: primaryColor),
                  title: Text('Sujet de prière', style: TextStyle(color: primaryColor)),
                  onTap: () {
                    Navigator.pop(context);
                    _openPriezLeMaitre();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.email, color: primaryColor),
                  title: Text('Contactez-Nous', style: TextStyle(color: primaryColor)),
                  onTap: () => _navigateTo(context, const ContactezNousScreen()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
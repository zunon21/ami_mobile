import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'projets_missionnaires_screen.dart';
import 'zones_departements_screen.dart';

class ChampsScreen extends StatefulWidget {
  @override
  _ChampsScreenState createState() => _ChampsScreenState();
}

class _ChampsScreenState extends State<ChampsScreen> {
  final String _baseUrl = AuthService.baseUrl;
  final String _generalProjectId = '11111111-1111-1111-1111-111111111111';

  final List<Map<String, String>> _champs = [
    {'name': 'Champs Lobi', 'image': 'assets/images/champs/lobi.png'},
    {'name': 'Champs Koulango', 'image': 'assets/images/champs/koulango.png'},
    {'name': 'Champs Lorhon', 'image': 'assets/images/champs/lorhon.png'},
    {'name': 'Champs Koyaka', 'image': 'assets/images/champs/koyaka.png'},
  ];

  void _showDonationModal({required String title}) {
    final amountController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Don pour $title', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: InputDecoration(labelText: 'Montant (FCFA)'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final amount = int.tryParse(amountController.text.trim());
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Montant invalide')));
                    return;
                  }
                  Navigator.pop(ctx);
                  final token = await AuthService.getToken();
                  if (token == null) return;
                  final response = await http.post(
                    Uri.parse('$_baseUrl/api/donations/initiate'),
                    headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
                    body: jsonEncode({
                      'project_id': _generalProjectId,
                      'amount': amount,
                      'is_anonymous': false,
                      'donation_type': 'one_time'
                    }),
                  );
                  if (response.statusCode == 200) {
                    final data = jsonDecode(response.body);
                    final checkoutUrl = data['checkout_url'];
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Paiement : $checkoutUrl')));
                  } else {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Erreur initiation paiement')));
                  }
                },
                child: Text('Procéder au paiement'),
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF5D3A1A),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5D3A1A), Color(0xFF7A4E2D)],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menu à venir'))),
        ),
        title: const Text('Champs missionnaires', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Options à venir'))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      'ACTION MISSIONNAIRE INTERAFRICAINE',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5D3A1A)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Côte d\'Ivoire',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.8, // pour que la carte soit carrée (hauteur un peu plus grande que largeur)
              children: _champs.map((champ) {
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Titre
                      Padding(
                        padding: const EdgeInsets.only(top: 12, left: 8, right: 8),
                        child: Text(
                          champ['name']!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D3A1A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Image carrée qui remplit l'espace
                      AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            champ['image']!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Bouton
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: ElevatedButton(
                          onPressed: () => _showDonationModal(title: champ['name']!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4A017),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text('Don pour ${champ['name']}'),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedItemColor: const Color(0xFFD4A017),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Champs missionnaires'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Projets missionnaires'),
          BottomNavigationBarItem(icon: Icon(Icons.location_city), label: 'Zones'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
          } else if (index == 2) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProjetsMissionnairesScreen()));
          } else if (index == 3) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ZonesDepartementsScreen()));
          }
        },
      ),
    );
  }
}
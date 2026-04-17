import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'champs_screen.dart';
import 'projets_missionnaires_screen.dart';

class ZonesDepartementsScreen extends StatefulWidget {
  @override
  _ZonesDepartementsScreenState createState() => _ZonesDepartementsScreenState();
}

class _ZonesDepartementsScreenState extends State<ZonesDepartementsScreen> {
  final String _baseUrl = AuthService.baseUrl;
  final String _generalProjectId = '11111111-1111-1111-1111-111111111111';

  // Liste des zones (noms et chemins d'images)
  final List<Map<String, String>> _zones = [
    {'name': 'Zone de Daloa', 'image': 'assets/images/Zones/daloa.png'},
    {'name': 'Zone de Bouaké', 'image': 'assets/images/Zones/bouake.png'},
    {'name': 'Bureau de San-Pedro', 'image': 'assets/images/Zones/sanpedro.png'},
  ];

  // Liste des départements (noms et chemins d'images)
  final List<Map<String, String>> _departements = [
    {'name': 'Direction', 'image': 'assets/images/Départements/direction.png'},
    {'name': 'Administration', 'image': 'assets/images/Départements/administration.png'},
    {'name': 'Mobilisation', 'image': 'assets/images/Départements/mobilisation.png'},
    {'name': 'Recherche', 'image': 'assets/images/Départements/recherche.png'},
    {'name': 'Finance', 'image': 'assets/images/Départements/finance.png'},
    {'name': 'Formation IIFM', 'image': 'assets/images/Départements/formation.png'},
    {'name': 'Media', 'image': 'assets/images/Départements/media.png'},
    {'name': 'Bien-être et Social', 'image': 'assets/images/Départements/bienetre.png'},
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

  Widget _buildSection(String title, List<Map<String, String>> items) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFFD4A017),
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Container(
          width: 60,
          height: 2.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFD4A017), Color(0xFFF57C00)]),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: items.length,
          itemBuilder: (ctx, index) {
            final item = items[index];
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, left: 8, right: 8),
                    child: Text(
                      item['name']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D3A1A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        item['image']!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: ElevatedButton(
                      onPressed: () => _showDonationModal(title: item['name']!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4A017),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text('Don pour ${item['name']}'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
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
        title: const Text('Zones et départements', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
            _buildSection('Les Zones', _zones),
            _buildSection('Les Départements', _departements),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
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
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ChampsScreen()));
          } else if (index == 2) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProjetsMissionnairesScreen()));
          }
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'champs_screen.dart';
import 'zones_departements_screen.dart';

class ProjetsMissionnairesScreen extends StatefulWidget {
  @override
  _ProjetsMissionnairesScreenState createState() => _ProjetsMissionnairesScreenState();
}

class _ProjetsMissionnairesScreenState extends State<ProjetsMissionnairesScreen> {
  List<dynamic> _projects = [];
  bool _isLoading = true;
  String _error = '';
  final String _baseUrl = AuthService.baseUrl;

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    final token = await AuthService.getToken();
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/projects'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _projects = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Erreur chargement projets';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur de connexion';
        _isLoading = false;
      });
    }
  }

  void _showDonationModal({required String projectId, required String projectName}) {
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
              Text('Don pour $projectName', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                      'project_id': projectId,
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

  void _showProjectDetails(Map<String, dynamic> project) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(project['name']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (project['image_url'] != null)
                Image.network(project['image_url'], height: 150, fit: BoxFit.cover),
              SizedBox(height: 12),
              Text(project['description'] ?? 'Aucune description'),
              SizedBox(height: 12),
              Text('Objectif : ${project['target_amount']} FCFA', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Fermer')),
        ],
      ),
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
        title: const Text('Projets missionnaires', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error.isNotEmpty)
              Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _projects.length,
                itemBuilder: (ctx, i) {
                  final p = _projects[i];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Image en arrière-plan
                          if (p['image_url'] != null)
                            Image.network(
                              p['image_url'],
                              fit: BoxFit.cover,
                            )
                          else
                            Container(color: Colors.grey[200]),
                          // Dégradé sombre en bas
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                                ),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    p['name'],
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    p['description'] ?? '',
                                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${p['target_amount']} FCFA',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD4A017)),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton(
                                        onPressed: () => _showProjectDetails(p),
                                        style: TextButton.styleFrom(foregroundColor: Colors.white),
                                        child: const Text('Plus d\'infos', style: TextStyle(fontSize: 11)),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => _showDonationModal(projectId: p['id'], projectName: p['name']),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFD4A017),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        ),
                                        child: const Text('Faire un don', style: TextStyle(fontSize: 11)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
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
          } else if (index == 3) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ZonesDepartementsScreen()));
          }
        },
      ),
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import '../services/commitment_service.dart';
import 'champs_screen.dart';
import 'projets_missionnaires_screen.dart';
import 'zones_departements_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _projects = [];
  bool _isLoading = true;
  String _error = '';
  String _fullName = '';
  Map<String, dynamic>? _commitment;
  Timer? _commitmentTimer;
  bool _isModalOpen = false;

  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final String _baseUrl = AuthService.baseUrl;
  final String _commitmentProjectId = '1979cd55-803d-4654-adac-409fa328b937';

  @override
  void initState() {
    super.initState();
    _loadData();
    _startCommitmentTimer();
    _initBlinkAnimation();
  }

  void _initBlinkAnimation() {
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.4).animate(_blinkController);
  }

  @override
  void dispose() {
    _commitmentTimer?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  void _startCommitmentTimer() {
    _commitmentTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _checkAndShowCommitmentModal();
    });
  }

  Future<void> _checkAndShowCommitmentModal() async {
    if (_commitment == null && !_isModalOpen && mounted) {
      _showCommitmentModal();
    }
  }

  Future<void> _loadData() async {
    await _fetchUserInfo();
    await _fetchCommitment();
    await _fetchProjects();
  }

  Future<void> _fetchUserInfo() async {
    final user = await AuthService.getUserInfo();
    if (user != null && user['full_name'] != null) {
      setState(() {
        _fullName = user['full_name'];
      });
    } else {
      setState(() {
        _fullName = 'Partenaire';
      });
    }
  }

  Future<void> _fetchCommitment() async {
    final commitment = await CommitmentService.getCommitment();
    setState(() {
      _commitment = commitment;
    });
  }

  Future<void> _fetchProjects() async {
    final token = await AuthService.getToken();
    if (token == null) {
      _logout();
      return;
    }
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
      } else if (response.statusCode == 401) {
        _logout();
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

  void _logout() async {
    await AuthService.deleteToken();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showCommitmentModal({bool isEditing = false}) {
    if (_isModalOpen) return;
    _isModalOpen = true;

    if (isEditing && _commitment != null) {
      _amountController.text = _commitment!['amount'].toString();
      _dayController.text = _commitment!['day_of_month'].toString();
      _reasonController.text = _commitment!['reason'] ?? '';
    } else {
      _amountController.clear();
      _dayController.clear();
      _reasonController.clear();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isEditing ? 'Modifier mon engagement' : 'Mon engagement mensuel'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Montant (FCFA)'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12),
              TextField(
                controller: _dayController,
                decoration: InputDecoration(labelText: 'Jour du mois (1-31)'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12),
              TextField(
                controller: _reasonController,
                decoration: InputDecoration(labelText: 'Raison (optionnel)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _isModalOpen = false;
              },
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(_amountController.text.trim());
                final day = int.tryParse(_dayController.text.trim());
                if (amount == null || amount <= 0 || day == null || day < 1 || day > 31) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Montant ou jour invalide')));
                  return;
                }
                final success = await CommitmentService.saveCommitment(
                  amount: amount,
                  dayOfMonth: day,
                  reason: _reasonController.text.trim(),
                );
                Navigator.pop(ctx);
                _isModalOpen = false;
                if (success) {
                  await _fetchCommitment();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Engagement enregistré')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de l\'enregistrement')));
                }
              },
              child: Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  void _showDonationModal({
    bool isGeneral = false,
    bool isMissionary = false,
    bool isAnonymous = false,
    String? projectId,
    String? projectName,
    double? presetAmount,
  }) {
    final amountController = TextEditingController(text: presetAmount?.toString() ?? '');
    final missionaryNameController = TextEditingController();
    String finalProjectId;
    String finalTitle;

    if (projectId != null) {
      finalProjectId = projectId;
      finalTitle = projectName != null ? 'Don pour $projectName' : 'Faire un don';
    } else if (isGeneral) {
      finalProjectId = '11111111-1111-1111-1111-111111111111';
      finalTitle = 'Don général à la mission';
    } else if (isMissionary) {
      finalProjectId = '11111111-1111-1111-1111-111111111111';
      finalTitle = 'Soutenir un missionnaire';
    } else {
      finalProjectId = _commitmentProjectId;
      finalTitle = 'Faire un don';
    }

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
              Text(finalTitle, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              if (isMissionary) ...[
                TextField(
                  controller: missionaryNameController,
                  decoration: InputDecoration(labelText: 'Nom et prénom du missionnaire (optionnel)'),
                ),
                SizedBox(height: 12),
              ],
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
                      'project_id': finalProjectId,
                      'amount': amount,
                      'is_anonymous': isAnonymous,
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

  Widget _buildSectionTitle(String title, {bool withBorder = true}) {
    Widget textWidget = Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFFD4A017),
        letterSpacing: 0.5,
      ),
      textAlign: TextAlign.center,
    );
    if (withBorder) {
      textWidget = Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFF5D3A1A), width: 2),
          borderRadius: BorderRadius.circular(30),
          color: Colors.white.withOpacity(0.1),
        ),
        child: textWidget,
      );
    }
    return Column(
      children: [
        textWidget,
        const SizedBox(height: 6),
        Container(
          width: 60,
          height: 2.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFD4A017), Color(0xFFF57C00)]),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
    required IconData icon,
    bool blink = false,
  }) {
    Widget button = OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Color(0xFFD4A017)),
      label: Text(label, style: TextStyle(color: Color(0xFFD4A017), fontWeight: FontWeight.w500)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Color(0xFFD4A017), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      ),
    );
    if (blink) {
      button = FadeTransition(
        opacity: _blinkAnimation,
        child: button,
      );
    }
    return button;
  }

  Widget _buildCommitmentCard() {
    if (_commitment == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Aucun engagement mensuel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _showCommitmentModal(),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4A017)),
                child: const Text('Ajouter un engagement'),
              ),
            ],
          ),
        ),
      );
    }
    final rawAmount = _commitment!['amount'];
    final double amountValue = double.tryParse(rawAmount.toString()) ?? 0.0;
    final day = _commitment!['day_of_month'];
    final reason = _commitment!['reason'];
    final now = DateTime.now();
    int currentMonth = now.month;
    int currentYear = now.year;
    int nextMonth = currentMonth + 1;
    int nextYear = currentYear;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear += 1;
    }
    final monthNames = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    final nextMonthName = monthNames[nextMonth - 1];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Mon engagement mensuel',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5D3A1A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text('Montant : $amountValue FCFA', style: TextStyle(fontSize: 16)),
            Text('Jour : $day du mois', style: TextStyle(fontSize: 16)),
            if (reason != null && reason.isNotEmpty) Text('Raison : $reason', style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _blinkAnimation,
              child: ElevatedButton(
                onPressed: () {
                  _showDonationModal(
                    projectId: _commitmentProjectId,
                    projectName: 'Engagement mensuel',
                    presetAmount: amountValue,
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4A017)),
                child: Text('Honorer votre engagement du mois de $nextMonthName'),
              ),
            ),
            const SizedBox(height: 8),
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFFD4A017)),
              onPressed: () => _showCommitmentModal(isEditing: true),
            ),
          ],
        ),
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
        title: const Text('Accueil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Options à venir'))),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD4A017), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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

              _buildSectionTitle('Partenaire De L\'AMI'),
              const SizedBox(height: 8),
              Text(
                _fullName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              _buildCommitmentCard(),
              const SizedBox(height: 24),

              _buildSectionTitle('Cliquez pour soutenir l\'AMI'),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton(
                      label: 'Don anonyme',
                      onTap: () => _showDonationModal(isGeneral: true, isAnonymous: true),
                      icon: Icons.visibility_off,
                      blink: true,
                    ),
                    const SizedBox(width: 12),
                    _buildActionButton(
                      label: 'Soutenir un missionnaire',
                      onTap: () => _showDonationModal(isMissionary: true),
                      icon: Icons.people,
                      blink: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              _buildSectionTitle('Les Projets Missionnaires'),
              const SizedBox(height: 20),

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
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Image en arrière-plan (remplit tout le cadre)
                            if (p['image_url'] != null && p['image_url'].toString().isNotEmpty)
                              Image.network(
                                p['image_url'],
                                fit: BoxFit.cover,
                              )
                            else
                              Container(color: Colors.grey[200]),
                            // Dégradé sombre en bas pour améliorer la lisibilité du texte
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
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
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ChampsScreen()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ProjetsMissionnairesScreen()));
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ZonesDepartementsScreen()));
          } else if (index != 0) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Page en construction')));
          }
        },
      ),
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import '../services/commitment_service.dart';
import 'service_list_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _fullName = '';
  Map<String, dynamic>? _commitment;
  List<dynamic> _recurringDonations = [];
  List<dynamic> _serviceCommitments = [];
  bool _isLoading = true;
  bool _isModalOpen = false;
  bool _isSubmittingMission = false;
  final String _baseUrl = AuthService.baseUrl;
  final String _generalProjectId = '11111111-1111-1111-1111-111111111111';

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  String _selectedPeriodicity = 'mensuel';

  final List<String> _periodicities = ['mensuel', 'bimestriel', 'trimestriel', 'semestriel', 'annuel'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _fetchUserInfo();
    await _fetchCommitment();
    await _fetchRecurringDonations();
    await _fetchServiceCommitments();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchUserInfo() async {
    final user = await AuthService.getUserInfo();
    if (user != null && user['full_name'] != null) {
      setState(() => _fullName = user['full_name']);
    } else {
      setState(() => _fullName = 'Partenaire');
    }
  }

  Future<void> _fetchCommitment() async {
    final commitment = await CommitmentService.getCommitment();
    setState(() => _commitment = commitment);
  }

  Future<void> _fetchRecurringDonations() async {
    final token = await AuthService.getToken();
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/donations'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> all = jsonDecode(response.body);
        setState(() {
          _recurringDonations = all.where((d) => d['donation_type'] == 'recurring').toList();
        });
      }
    } catch (e) {
      print('Erreur récupération dons récurrents : $e');
    }
  }

  Future<void> _fetchServiceCommitments() async {
    final token = await AuthService.getToken();
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/auth/service-commitments'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _serviceCommitments = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print('Erreur récupération engagements de service : $e');
    }
  }

  void _showCommitmentModal({bool isEditing = false}) {
    if (_isModalOpen) return;
    _isModalOpen = true;

    if (isEditing && _commitment != null) {
      _amountController.text = _commitment!['amount'].toString();
      _dayController.text = _commitment!['day_of_month'].toString();
      _selectedPeriodicity = _commitment!['periodicity'] ?? 'mensuel';
    } else {
      _amountController.clear();
      _dayController.clear();
      _selectedPeriodicity = 'mensuel';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Modifier le fonctionnement de l\'AMI' : 'Fonctionnement de l\'AMI'),
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
                  DropdownButtonFormField<String>(
                    value: _selectedPeriodicity,
                    decoration: InputDecoration(labelText: 'Périodicité'),
                    items: _periodicities.map((String period) {
                      return DropdownMenuItem<String>(
                        value: period,
                        child: Text(period),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setStateDialog(() {
                        _selectedPeriodicity = newValue!;
                      });
                    },
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
                      periodicity: _selectedPeriodicity,
                      reason: null,
                    );
                    Navigator.pop(ctx);
                    _isModalOpen = false;
                    if (success) {
                      await _fetchCommitment();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fonctionnement de l\'AMI enregistré')));
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
      },
    );
  }

  // Paiement direct (offrande missionnaire)
  Future<void> _makeDirectDonation(String title, double amount, String reason) async {
    final token = await AuthService.getToken();
    if (token == null) return;
    final response = await http.post(
      Uri.parse('$_baseUrl/api/donations/initiate'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({
        'project_id': _generalProjectId,
        'amount': amount.toInt(),
        'is_anonymous': false,
        'donation_type': 'one_time'
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final checkoutUrl = data['checkout_url'];
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Paiement : $checkoutUrl')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur initiation paiement')));
    }
  }

  void _showOffrandeMissionnaireModal() {
    final TextEditingController amountCtrl = TextEditingController();
    final TextEditingController reasonCtrl = TextEditingController();
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
              const Text('Offrande Missionnaire', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF5D3A1A))),
              const SizedBox(height: 8),
              const Text('Soutenez l’œuvre de Dieu par un don immédiat', style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                decoration: const InputDecoration(labelText: 'Montant (FCFA)', prefixIcon: Icon(Icons.money)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'Raison (optionnel)', prefixIcon: Icon(Icons.edit)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final amount = int.tryParse(amountCtrl.text.trim());
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Montant invalide')));
                    return;
                  }
                  final reason = reasonCtrl.text.trim();
                  Navigator.pop(ctx);
                  await _makeDirectDonation('Offrande missionnaire', amount.toDouble(), reason);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4A017),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Procéder au paiement', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showDonationModal({required String title, required String projectId, double? presetAmount}) {
    final amountController = TextEditingController(text: presetAmount?.toString() ?? '');
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

  // Formulaire d'engagement pour un missionnaire avec protection IDENTIQUE à ServiceListScreen
  void _showMissionnaireModal() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController dayController = TextEditingController();
    final TextEditingController missionaryNameController = TextEditingController();
    String selectedPeriodicity = 'mensuel';
    final List<String> periodicities = ['mensuel', 'bimestriel', 'trimestriel', 'semestriel', 'annuel'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Soutenir un missionnaire',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF5D3A1A)),
                  ),
                  const SizedBox(height: 8),
                  const Text('Engagez-vous à soutenir financièrement un missionnaire', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Montant (FCFA)', prefixIcon: Icon(Icons.money)),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dayController,
                    decoration: const InputDecoration(labelText: 'Jour du mois (1-31)', prefixIcon: Icon(Icons.calendar_today)),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: missionaryNameController,
                    decoration: const InputDecoration(labelText: 'Nom et Prénoms du missionnaire', prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedPeriodicity,
                    decoration: const InputDecoration(labelText: 'Périodicité'),
                    items: periodicities.map((String period) {
                      return DropdownMenuItem<String>(
                        value: period,
                        child: Text(period),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setStateModal(() {
                        selectedPeriodicity = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSubmittingMission ? null : () => _saveMissionCommitment(
                      ctx,
                      amountController,
                      dayController,
                      missionaryNameController,
                      selectedPeriodicity,
                    ),
                    child: _isSubmittingMission
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Enregistrer l\'engagement', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Fonction séparée comme dans ServiceListScreen
  Future<void> _saveMissionCommitment(
    BuildContext ctx,
    TextEditingController amountController,
    TextEditingController dayController,
    TextEditingController missionaryNameController,
    String periodicity,
  ) async {
    if (_isSubmittingMission) return;
    final amount = int.tryParse(amountController.text.trim());
    final day = int.tryParse(dayController.text.trim());
    final name = missionaryNameController.text.trim();

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Montant invalide')));
      return;
    }
    if (day == null || day < 1 || day > 31) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Jour invalide (1-31)')));
      return;
    }
    if (name.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Veuillez saisir le nom du missionnaire')));
      return;
    }

    setState(() => _isSubmittingMission = true);
    final token = await AuthService.getToken();
    if (token == null) {
      setState(() => _isSubmittingMission = false);
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/service-commitments'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'service_name': 'Missionnaire',
          'item_name': name,
          'amount': amount,
          'day_of_month': day,
          'periodicity': periodicity,
          'reason': null,
        }),
      );
      if (response.statusCode == 201) {
        Navigator.pop(ctx);
        await _fetchServiceCommitments();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Engagement missionnaire enregistré')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de l\'enregistrement')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur réseau')));
    } finally {
      if (mounted) setState(() => _isSubmittingMission = false);
    }
  }

  void _navigateToService(String service) async {
    List<String> items = [];
    switch (service) {
      case 'Missionnaire':
        _showMissionnaireModal();
        return;
      case 'Champs':
        items = ['Koyaka', 'Koulango', 'Lobi', 'Lorhon', 'Tous les Champs'];
        break;
      case 'Projets':
        items = ['Siege de l’AMI', 'Bâtiment Noé', 'Bâtiment 5 Pains et 2 Poissons'];
        break;
      case 'Activités':
        items = ['ECOMIN', 'RHEMA', 'VSD dans Sa présence', 'Priez le Maître', 'Levez les yeux', 'La classe de disciples', 'L’école de mariage ECOMA'];
        break;
      case 'Zones':
        items = ['Zone de Daloa', 'Zone de Bouake'];
        break;
      case 'Départements':
        items = ['Administration', 'Recherche', 'Finance', 'Mobilisation', 'Media'];
        break;
      case 'Social':
        items = ['Santé', 'Scolarité des Enfants de missionnaires', 'Retrait'];
        break;
      case 'IIFM':
        items = ['scolarité des étudiants', 'infrastructures', 'Fonctionnement'];
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Page $service en construction')));
        return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ServiceListScreen(title: service, items: items)),
    );
    await _fetchServiceCommitments();
    setState(() {});
  }

  void _honorServiceCommitment(Map<String, dynamic> commitment) {
    _showDonationModal(
      title: commitment['item_name'],
      projectId: _generalProjectId,
      presetAmount: (commitment['amount'] as num).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: const Color(0xFFD4A017),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text(
              '« Que votre lumière brille devant les hommes » — Matthieu 5:16',
              style: TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Logo et identité
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
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      child: Column(
                        children: [
                          const Text(
                            'ACTION MISSIONNAIRE INTERAFRICAINE',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5D3A1A)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Côte d\'Ivoire',
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Profil partenaire
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person, color: Color(0xFFD4A017)),
                          const SizedBox(width: 8),
                          Text(_fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bouton Offrande Missionnaire (design unique)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: InkWell(
                      onTap: _showOffrandeMissionnaireModal,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD4A017), Color(0xFFF57C00), Color(0xFFFF8F00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4A017).withOpacity(0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.volunteer_activism, color: Colors.white, size: 28),
                            const SizedBox(width: 12),
                            const Text(
                              'Offrande Missionnaire',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_forward, color: Color(0xFFD4A017), size: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Fonctionnement de l'AMI
                  _buildCommitmentCard(),
                  const SizedBox(height: 24),

                  // Grille des services (modifiée : titre, icônes, disposition 2 lignes de 4)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Text('Nos besoins', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5D3A1A))),
                          const SizedBox(height: 12),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 4, // 4 colonnes pour 2 lignes de 4
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            children: [
                              // Première ligne : Missionnaire, Champs, Projets, Activités
                              _buildServiceCircle('Missionnaire', Icons.people, const Color(0xFFFFCDD2)),
                              _buildServiceCircle('Champs', Icons.church, const Color(0xFFC8E6C9)),
                              _buildServiceCircle('Projets', Icons.work, const Color(0xFFBBDEFB)),
                              _buildServiceCircle('Activités', Icons.event, const Color(0xFFFFF9C4)),
                              // Deuxième ligne : Zones, Départements, IIFM, Social
                              _buildServiceCircle('Zones', Icons.location_on, const Color(0xFFE1BEE7)),
                              _buildServiceCircle('Départements', Icons.apartment, const Color(0xFFB2EBF2)),
                              _buildServiceCircle('IIFM', Icons.school, const Color(0xFFFFCDD2)),
                              _buildServiceCircle('Social', Icons.volunteer_activism, const Color(0xFFC8E6C9)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Historique des engagements
                  const Text(
                    'Historique des engagements',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5D3A1A)),
                  ),
                  const SizedBox(height: 8),
                  _recurringDonations.isEmpty && _serviceCommitments.isEmpty
                      ? const Card(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('Aucun engagement honoré pour le moment'),
                          ),
                        )
                      : Column(
                          children: [
                            if (_recurringDonations.isNotEmpty) ...[
                              const Text('Dons récurrents', style: TextStyle(fontWeight: FontWeight.bold)),
                              ..._recurringDonations.map((d) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text('${d['amount']} FCFA'),
                                  subtitle: Text('Date : ${DateTime.parse(d['createdAt']).toLocal().toString().substring(0, 16)}'),
                                  trailing: Chip(label: Text(d['status'])),
                                ),
                              )).toList(),
                            ],
                            if (_serviceCommitments.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Text('Engagements en attente', style: TextStyle(fontWeight: FontWeight.bold)),
                              ..._serviceCommitments.map((c) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text('${c['item_name']} : ${c['amount']} FCFA'),
                                  subtitle: Text('Jour ${c['day_of_month']} - ${c['periodicity']}'),
                                  trailing: ElevatedButton(
                                    onPressed: () => _honorServiceCommitment(c),
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4A017)),
                                    child: const Text('Honorer'),
                                  ),
                                ),
                              )).toList(),
                            ],
                          ],
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildServiceCircle(String title, IconData icon, Color bgColor) {
    return InkWell(
      onTap: () => _navigateToService(title),
      borderRadius: BorderRadius.circular(60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 30, color: const Color(0xFF5D3A1A)),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF5D3A1A)),
          ),
        ],
      ),
    );
  }

  Widget _buildCommitmentCard() {
    if (_commitment == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              const Text('Fonctionnement de l\'AMI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
    final periodicity = _commitment!['periodicity'] ?? 'mensuel';
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text('Fonctionnement de l\'AMI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5D3A1A))),
            const SizedBox(height: 8),
            Text('Montant : $amountValue FCFA', style: const TextStyle(fontSize: 16)),
            Text('Jour : $day du mois', style: const TextStyle(fontSize: 16)),
            Text('Périodicité : $periodicity', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _showCommitmentModal(isEditing: true),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4A017)),
                  child: const Text('Modifier'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _showDonationModal(
                    title: 'Fonctionnement de l\'AMI',
                    projectId: _generalProjectId,
                    presetAmount: amountValue,
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4A017)),
                  child: const Text('Honorer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
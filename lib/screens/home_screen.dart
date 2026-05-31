import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:app_settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/commitment_service.dart';
import '../services/payment_service.dart';
import 'service_list_screen.dart';
import '../widgets/custom_drawer.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _fullName = '';
  Map<String, dynamic>? _commitment;
  List<dynamic> _recurringDonations = [];
  List<dynamic> _serviceCommitments = [];
  List<dynamic> _paymentHistory = [];
  bool _isLoading = true;
  bool _isModalOpen = false;
  bool _isSubmittingMission = false;
  final String _baseUrl = AuthService.baseUrl;
  final String _generalProjectId = '11111111-1111-1111-1111-111111111111';

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  String _selectedPeriodicity = 'Mensuel';

  final List<String> _periodicities = ['Mensuel', 'Bimensuel', 'Trimestriel', 'Semestriel', 'Annuel', 'Ponctuel'];

  // Moyens de paiement
  String _selectedPaymentMethod = 'wave';
  final List<String> _paymentMethods = ['wave', 'orange', 'mtn', 'moov', 'djamo'];

  // Couleurs pour les méthodes de paiement
  Color _getPaymentMethodColor(String method) {
    switch (method) {
      case 'wave': return const Color(0xFF00B2FF);
      case 'orange': return const Color(0xFFFF5C00);
      case 'mtn': return const Color(0xFFF4A300);
      case 'moov': return const Color(0xFF00A651);
      default: return const Color(0xFF5D3A1A);
    }
  }

  Widget _getPaymentMethodWidget(String method) {
    return Text(
      _getPaymentMethodLabel(method),
      style: TextStyle(
        color: _getPaymentMethodColor(method),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'wave': return 'WAVE';
      case 'orange': return 'ORANGE';
      case 'mtn': return 'MTN';
      case 'moov': return 'MOOV';
      case 'djamo': return 'CARTES BANCAIRES';
      default: return method.toUpperCase();
    }
  }

  String _mapPeriodicityToBackend(String periodicity) {
    switch (periodicity.toLowerCase()) {
      case 'bimensuel': return 'bimestriel';
      case 'ponctuel': return 'ponctuel';
      default: return periodicity.toLowerCase();
    }
  }

  String _capitalizePeriodicity(String periodicity) {
    if (periodicity.isEmpty) return 'Mensuel';
    final lower = periodicity.toLowerCase();
    if (lower == 'bimestriel') return 'Bimensuel';
    if (lower == 'ponctuel') return 'Ponctuel';
    return periodicity[0].toUpperCase() + periodicity.substring(1).toLowerCase();
  }

  @override
  void initState() {
    super.initState();
    _loadCachedData();   // Charge immédiatement le cache (affichage instantané)
    _loadData();         // En arrière-plan, récupère les données à jour
  }

  // --------------------- GESTION DU CACHE ---------------------
  Future<void> _cacheData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fullName', _fullName);
    if (_commitment != null) {
      await prefs.setString('commitment', jsonEncode(_commitment));
    } else {
      await prefs.remove('commitment');
    }
    await prefs.setString('recurringDonations', jsonEncode(_recurringDonations));
    await prefs.setString('serviceCommitments', jsonEncode(_serviceCommitments));
    await prefs.setString('paymentHistory', jsonEncode(_paymentHistory));
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasCache = false;

    if (prefs.containsKey('fullName')) {
      setState(() {
        _fullName = prefs.getString('fullName')!;
        hasCache = true;
      });
    }
    if (prefs.containsKey('commitment')) {
      final data = prefs.getString('commitment');
      if (data != null) {
        setState(() {
          _commitment = jsonDecode(data);
          hasCache = true;
        });
      }
    }
    if (prefs.containsKey('recurringDonations')) {
      final data = prefs.getString('recurringDonations');
      if (data != null) {
        setState(() {
          _recurringDonations = jsonDecode(data);
          hasCache = true;
        });
      }
    }
    if (prefs.containsKey('serviceCommitments')) {
      final data = prefs.getString('serviceCommitments');
      if (data != null) {
        setState(() {
          _serviceCommitments = jsonDecode(data);
          hasCache = true;
        });
      }
    }
    if (prefs.containsKey('paymentHistory')) {
      final data = prefs.getString('paymentHistory');
      if (data != null) {
        setState(() {
          _paymentHistory = jsonDecode(data);
          hasCache = true;
        });
      }
    }
    if (hasCache) {
      setState(() => _isLoading = false);
    }
  }

  // --------------------- CHARGEMENT DEPUIS LE SERVEUR ---------------------
  Future<void> _loadData() async {
    await _fetchUserInfo();
    await _fetchCommitment();
    await _fetchRecurringDonations();
    await _fetchServiceCommitments();
    await _fetchPaymentHistory();
    await _cacheData();                    // Mise à jour du cache
    if (mounted && _isLoading) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserInfo() async {
    final user = await AuthService.getUserInfo();
    if (user != null && user['full_name'] != null && user['full_name'].toString().isNotEmpty) {
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
        Uri.parse('$_baseUrl/api/donations/my-donations'),
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

  Future<void> _fetchPaymentHistory() async {
    final token = await AuthService.getToken();
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/donations/my-donations'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> all = jsonDecode(response.body);
        final successful = all.where((d) => d['status'] == 'success').toList();
        successful.sort((a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));
        setState(() {
          _paymentHistory = successful;
        });
      }
    } catch (e) {
      print('Erreur récupération historique des paiements : $e');
    }
  }

  // --------------------- REÇU DE PAIEMENT (design élégant) ---------------------
  void _showPaymentReceipt() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Reçu de paiement',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5D3A1A)),
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF0E5D8)),
                  Expanded(
                    child: _paymentHistory.isEmpty
                        ? const Center(child: Text('Aucun paiement effectué', style: TextStyle(color: Colors.grey, fontSize: 16)))
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _paymentHistory.length,
                            itemBuilder: (ctx, index) {
                              final payment = _paymentHistory[index];
                              final DateTime dateTime = DateTime.parse(payment['createdAt']);
                              final String formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
                              final String formattedTime = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                              final String title = payment['description'] ?? 'Don AMI';
                              final double amount = () {
                                final value = payment['amount'];
                                if (value is int) return value.toDouble();
                                if (value is double) return value;
                                if (value is String) return double.tryParse(value) ?? 0.0;
                                return 0.0;
                              }();
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 4))],
                                  border: Border.all(color: Color(0xFFFCE4B2), width: 1),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF4A2E1B))),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(colors: [Color(0xFFD4A017), Color(0xFFF57C00)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                            child: Text('${amount.toStringAsFixed(0)} FCFA', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today, size: 14, color: Color(0xFFA88B6F)),
                                          const SizedBox(width: 6),
                                          Text(formattedDate, style: const TextStyle(fontSize: 12, color: Color(0xFFA88B6F))),
                                          const SizedBox(width: 16),
                                          const Icon(Icons.access_time, size: 14, color: Color(0xFFA88B6F)),
                                          const SizedBox(width: 6),
                                          Text(formattedTime, style: const TextStyle(fontSize: 12, color: Color(0xFFA88B6F))),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --------------------- MODALES DE DON (toutes inchangées sauf ajout de _cacheData après mise à jour) ---------------------
  void _showStructureDonationModal() {
    final TextEditingController orgNameController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    final TextEditingController destinationController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();
    String localPaymentMethod = _selectedPaymentMethod;
    bool isPaying = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            int currentAmount = 0;
            int totalWithFees = 0;
            void updateTotal() {
              currentAmount = int.tryParse(amountController.text) ?? 0;
              totalWithFees = PaymentService.calculateTotalWithFees(currentAmount);
            }
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Structures et Organisations',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF5D3A1A)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Faites parvenir les dons de votre structure, organisme ou cellule à l’AMI Côte d’Ivoire',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: orgNameController,
                    decoration: const InputDecoration(labelText: 'Nom de l’organisation', prefixIcon: Icon(Icons.business)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Montant versé (FCFA)', prefixIcon: Icon(Icons.money)),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => setStateModal(() => updateTotal()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: destinationController,
                    decoration: const InputDecoration(labelText: 'Destinations des fonds', prefixIcon: Icon(Icons.place)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(labelText: 'Motifs du don', prefixIcon: Icon(Icons.edit)),
                  ),
                  const SizedBox(height: 12),
                  if (currentAmount > 0) ...[
                    Text('Frais (1,5%) : ${(currentAmount * 0.015).round()} FCFA'),
                    const SizedBox(height: 4),
                    Text('Total à payer : $totalWithFees FCFA', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                  ],
                  DropdownButtonFormField<String>(
                    value: localPaymentMethod,
                    decoration: const InputDecoration(labelText: 'Moyen de paiement', prefixIcon: Icon(Icons.payment)),
                    items: _paymentMethods.map((method) => DropdownMenuItem(
                      value: method,
                      child: _getPaymentMethodWidget(method),
                    )).toList(),
                    onChanged: (value) {
                      setStateModal(() {
                        localPaymentMethod = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isPaying
                        ? null
                        : () async {
                            setStateModal(() => isPaying = true);
                            final String orgName = orgNameController.text.trim();
                            final int? amount = int.tryParse(amountController.text.trim());
                            if (orgName.isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Veuillez saisir le nom de l’organisation')));
                              setStateModal(() => isPaying = false);
                              return;
                            }
                            if (amount == null || amount <= 0) {
                              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Montant invalide')));
                              setStateModal(() => isPaying = false);
                              return;
                            }
                            final total = PaymentService.calculateTotalWithFees(amount);
                            final extraData = {
                              'organizationName': orgName,
                              'destination': destinationController.text.trim(),
                              'reason': reasonController.text.trim(),
                            };
                            final success = await PaymentService.initiatePayment(
                              total,
                              _generalProjectId,
                              localPaymentMethod,
                              description: 'Structures et Organisations',
                              extraData: extraData,
                            );
                            Navigator.pop(ctx);
                            if (success) {
                              await Future.delayed(Duration(seconds: 2));
                              await _fetchPaymentHistory();
                              await _cacheData();   // Mise à jour du cache
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paiement réussi ! Redirection...')));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de l’initiation du paiement')));
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A017),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: isPaying
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Procéder au paiement', style: TextStyle(fontSize: 16)),
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

  void _showCommitmentModal({bool isEditing = false}) {
    if (_isModalOpen) return;
    _isModalOpen = true;

    if (isEditing && _commitment != null) {
      _amountController.text = _commitment!['amount'].toString();
      _dayController.text = _commitment!['day_of_month'].toString();
      String rawPeriod = _commitment!['periodicity'] ?? 'mensuel';
      _selectedPeriodicity = _capitalizePeriodicity(rawPeriod);
    } else {
      _amountController.clear();
      _dayController.clear();
      _selectedPeriodicity = 'Mensuel';
    }

    String localPaymentMethod = _selectedPaymentMethod;
    bool isPaying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            bool isDonPonctuel = (_selectedPeriodicity == 'Ponctuel');
            int currentAmount = 0;
            int totalWithFees = 0;
            void updateTotal() {
              currentAmount = int.tryParse(_amountController.text) ?? 0;
              totalWithFees = PaymentService.calculateTotalWithFees(currentAmount);
            }
            return AlertDialog(
              title: Text(isEditing ? 'Modifier le fonctionnement de l\'AMI' : 'Fonctionnement de l\'AMI'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _amountController,
                    decoration: InputDecoration(labelText: 'Montant (FCFA)'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => setStateDialog(() => updateTotal()),
                  ),
                  const SizedBox(height: 12),
                  if (!isDonPonctuel)
                    TextField(
                      controller: _dayController,
                      decoration: InputDecoration(labelText: 'Jour du mois (1-31)'),
                      keyboardType: TextInputType.number,
                    ),
                  const SizedBox(height: 12),
                  if (isDonPonctuel && currentAmount > 0) ...[
                    Text('Frais (1,5%) : ${(currentAmount * 0.015).round()} FCFA'),
                    const SizedBox(height: 4),
                    Text('Total à payer : $totalWithFees FCFA', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                  ],
                  DropdownButtonFormField<String>(
                    value: _selectedPeriodicity,
                    decoration: InputDecoration(labelText: 'Périodicité'),
                    items: _periodicities.map((period) {
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
                  if (isDonPonctuel) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: localPaymentMethod,
                      decoration: const InputDecoration(labelText: 'Moyen de paiement', prefixIcon: Icon(Icons.payment)),
                      items: _paymentMethods.map((method) => DropdownMenuItem(
                        value: method,
                        child: _getPaymentMethodWidget(method),
                      )).toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          localPaymentMethod = value!;
                        });
                      },
                    ),
                  ],
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
                  onPressed: isPaying
                      ? null
                      : () async {
                          if (isDonPonctuel) {
                            setStateDialog(() => isPaying = true);
                            final amount = double.tryParse(_amountController.text.trim());
                            if (amount == null || amount <= 0) {
                              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Montant invalide')));
                              setStateDialog(() => isPaying = false);
                              return;
                            }
                            final total = PaymentService.calculateTotalWithFees(amount.toInt());
                            final success = await PaymentService.initiatePayment(
                              total,
                              _generalProjectId,
                              localPaymentMethod,
                              description: 'Fonctionnement de l\'AMI',
                            );
                            Navigator.pop(ctx);
                            _isModalOpen = false;
                            if (success) {
                              await Future.delayed(Duration(seconds: 2));
                              await _fetchPaymentHistory();
                              await _cacheData();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paiement réussi ! Redirection...')));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur initiation paiement')));
                            }
                          } else {
                            final amount = double.tryParse(_amountController.text.trim());
                            final day = int.tryParse(_dayController.text.trim());
                            if (amount == null || amount <= 0 || day == null || day < 1 || day > 31) {
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Montant ou jour invalide')));
                              return;
                            }
                            final success = await CommitmentService.saveCommitment(
                              amount: amount,
                              dayOfMonth: day,
                              periodicity: _mapPeriodicityToBackend(_selectedPeriodicity),
                              reason: null,
                            );
                            Navigator.pop(ctx);
                            _isModalOpen = false;
                            if (success) {
                              await _fetchCommitment();
                              await _cacheData();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fonctionnement de l\'AMI enregistré')));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de l\'enregistrement')));
                            }
                          }
                        },
                  child: isPaying
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isDonPonctuel ? 'Procéder au paiement' : 'Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDonationModal({required String title, required String projectId, double? presetAmount}) {
    final amountController = TextEditingController(text: (presetAmount ?? 0).toString());
    String localPaymentMethod = _selectedPaymentMethod;
    bool isPaying = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            int currentAmount = 0;
            int totalWithFees = 0;
            void updateTotal() {
              currentAmount = int.tryParse(amountController.text) ?? 0;
              totalWithFees = PaymentService.calculateTotalWithFees(currentAmount);
            }
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
                    onChanged: (val) => setStateModal(() => updateTotal()),
                  ),
                  const SizedBox(height: 12),
                  if (currentAmount > 0) ...[
                    Text('Frais (1,5%) : ${(currentAmount * 0.015).round()} FCFA'),
                    const SizedBox(height: 4),
                    Text('Total à payer : $totalWithFees FCFA', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                  ],
                  DropdownButtonFormField<String>(
                    value: localPaymentMethod,
                    decoration: const InputDecoration(labelText: 'Moyen de paiement', prefixIcon: Icon(Icons.payment)),
                    items: _paymentMethods.map((method) => DropdownMenuItem(
                      value: method,
                      child: _getPaymentMethodWidget(method),
                    )).toList(),
                    onChanged: (value) {
                      setStateModal(() {
                        localPaymentMethod = value!;
                      });
                    },
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isPaying
                        ? null
                        : () async {
                            setStateModal(() => isPaying = true);
                            final amount = int.tryParse(amountController.text.trim());
                            if (amount == null || amount <= 0) {
                              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Montant invalide')));
                              setStateModal(() => isPaying = false);
                              return;
                            }
                            final total = PaymentService.calculateTotalWithFees(amount);
                            final success = await PaymentService.initiatePayment(
                              total,
                              projectId,
                              localPaymentMethod,
                              description: title,
                            );
                            Navigator.pop(ctx);
                            if (success) {
                              await Future.delayed(Duration(seconds: 2));
                              await _fetchPaymentHistory();
                              await _cacheData();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paiement réussi ! Redirection...')));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur paiement')));
                            }
                          },
                    child: isPaying
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Procéder au paiement'),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showMissionnaireModal() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController dayController = TextEditingController();
    final TextEditingController missionaryNameController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();
    String selectedPeriodicity = 'Mensuel';
    final List<String> periodicities = ['Mensuel', 'Bimensuel', 'Trimestriel', 'Semestriel', 'Annuel', 'Ponctuel'];
    String localPaymentMethod = _selectedPaymentMethod;
    bool isPaying = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            bool isDonPonctuel = (selectedPeriodicity == 'Ponctuel');
            int currentAmount = 0;
            int totalWithFees = 0;
            void updateTotal() {
              currentAmount = int.tryParse(amountController.text) ?? 0;
              totalWithFees = PaymentService.calculateTotalWithFees(currentAmount);
            }
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
                  const Text('Soutenir un missionnaire', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF5D3A1A))),
                  const SizedBox(height: 8),
                  const Text('Engagez-vous à soutenir financièrement un missionnaire', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Montant (FCFA)', prefixIcon: Icon(Icons.money)),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => setStateModal(() => updateTotal()),
                  ),
                  const SizedBox(height: 12),
                  if (!isDonPonctuel)
                    Column(children: [
                      TextField(controller: dayController, decoration: const InputDecoration(labelText: 'Jour du mois (1-31)', prefixIcon: Icon(Icons.calendar_today)), keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                    ]),
                  TextField(controller: missionaryNameController, decoration: const InputDecoration(labelText: 'Nom et Prénoms du missionnaire', prefixIcon: Icon(Icons.person))),
                  const SizedBox(height: 12),
                  TextField(controller: reasonController, decoration: const InputDecoration(labelText: 'Motifs du don', prefixIcon: Icon(Icons.edit))),
                  const SizedBox(height: 12),
                  if (isDonPonctuel && currentAmount > 0) ...[
                    Text('Frais (1,5%) : ${(currentAmount * 0.015).round()} FCFA'),
                    const SizedBox(height: 4),
                    Text('Total à payer : $totalWithFees FCFA', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                  ],
                  DropdownButtonFormField<String>(
                    value: selectedPeriodicity,
                    decoration: const InputDecoration(labelText: 'Périodicité'),
                    items: periodicities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (newValue) => setStateModal(() => selectedPeriodicity = newValue!),
                  ),
                  if (isDonPonctuel) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: localPaymentMethod,
                      decoration: const InputDecoration(labelText: 'Moyen de paiement', prefixIcon: Icon(Icons.payment)),
                      items: _paymentMethods.map((method) => DropdownMenuItem(
                        value: method,
                        child: _getPaymentMethodWidget(method),
                      )).toList(),
                      onChanged: (value) {
                        setStateModal(() {
                          localPaymentMethod = value!;
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSubmittingMission || isPaying
                        ? null
                        : () async {
                            setStateModal(() => isPaying = true);
                            await _saveMissionCommitment(
                              ctx,
                              amountController,
                              dayController,
                              missionaryNameController,
                              reasonController,
                              selectedPeriodicity,
                              isDonPonctuel,
                              localPaymentMethod,
                              setStateModal,
                            );
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4A017), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                    child: isPaying
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isDonPonctuel ? 'Procéder au paiement' : 'Enregistrer l\'engagement', style: const TextStyle(fontSize: 16)),
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

  Future<void> _saveMissionCommitment(
    BuildContext ctx,
    TextEditingController amountController,
    TextEditingController dayController,
    TextEditingController missionaryNameController,
    TextEditingController reasonController,
    String periodicity,
    bool isDonPonctuel,
    String paymentMethod,
    StateSetter setModalState,
  ) async {
    if (_isSubmittingMission) return;
    setState(() => _isSubmittingMission = true);
    final amount = int.tryParse(amountController.text.trim());
    final name = missionaryNameController.text.trim();
    final motive = reasonController.text.trim();
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Montant invalide')));
      setState(() => _isSubmittingMission = false);
      setModalState(() {});
      return;
    }
    if (name.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Veuillez saisir le nom du missionnaire')));
      setState(() => _isSubmittingMission = false);
      setModalState(() {});
      return;
    }
    try {
      if (isDonPonctuel) {
        final total = PaymentService.calculateTotalWithFees(amount);
        final extraData = motive.isNotEmpty ? {'reason': motive} : null;
        final success = await PaymentService.initiatePayment(
          total,
          _generalProjectId,
          paymentMethod,
          description: 'Missionnaire - $name',
          extraData: extraData,
        );
        Navigator.pop(ctx);
        if (success) {
          await Future.delayed(Duration(seconds: 2));
          await _fetchPaymentHistory();
          await _cacheData();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paiement réussi ! Redirection...')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur initiation paiement')));
        }
      } else {
        final day = int.tryParse(dayController.text.trim());
        if (day == null || day < 1 || day > 31) {
          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Jour invalide (1-31)')));
          setState(() => _isSubmittingMission = false);
          setModalState(() {});
          return;
        }
        final token = await AuthService.getToken();
        if (token == null) {
          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Utilisateur non connecté')));
          setState(() => _isSubmittingMission = false);
          setModalState(() {});
          return;
        }
        final response = await http.post(
          Uri.parse('$_baseUrl/api/auth/service-commitments'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode({
            'service_name': 'Missionnaire',
            'item_name': name,
            'amount': amount,
            'day_of_month': day,
            'periodicity': _mapPeriodicityToBackend(periodicity),
            'reason': motive.isNotEmpty ? motive : null,
          }),
        );
        Navigator.pop(ctx);
        if (response.statusCode == 201) {
          await _fetchServiceCommitments();
          await _cacheData();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Engagement missionnaire enregistré')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de l\'enregistrement')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur réseau')));
      if (!isDonPonctuel) setState(() => _isSubmittingMission = false);
    } finally {
      if (mounted) setState(() => _isSubmittingMission = false);
    }
    setModalState(() {});
  }

  Future<void> _deleteCommitment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Supprimer votre engagement mensuel ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirm != true) return;
    final token = await AuthService.getToken();
    if (token == null) return;
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/auth/commitment'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      await _fetchCommitment();
      await _cacheData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Engagement supprimé')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur suppression')));
    }
  }

  Future<void> _editServiceCommitment(Map<String, dynamic> commitment) async {
    final TextEditingController amountController = TextEditingController(text: commitment['amount'].toString());
    final TextEditingController dayController = TextEditingController(text: commitment['day_of_month'].toString());
    String storedPeriodicity = commitment['periodicity'] ?? 'mensuel';
    String selectedPeriodicity;
    if (storedPeriodicity.toLowerCase() == 'ponctuel') {
      selectedPeriodicity = 'Ponctuel';
    } else if (storedPeriodicity.toLowerCase() == 'bimestriel') {
      selectedPeriodicity = 'Bimensuel';
    } else {
      selectedPeriodicity = storedPeriodicity.isNotEmpty ? storedPeriodicity[0].toUpperCase() + storedPeriodicity.substring(1).toLowerCase() : 'Mensuel';
    }
    final List<String> periodicities = ['Mensuel', 'Bimensuel', 'Trimestriel', 'Semestriel', 'Annuel', 'Ponctuel'];
    
    final isMissionnaire = (commitment['service_name'] == 'Missionnaire');
    final TextEditingController nameController = TextEditingController(text: isMissionnaire ? (commitment['item_name'] ?? '') : '');
    final TextEditingController motiveController = TextEditingController(text: commitment['reason'] ?? '');
    final TextEditingController reasonController = TextEditingController(text: isMissionnaire ? '' : (commitment['reason'] ?? ''));
    final itemName = commitment['item_name'];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            bool isDonPonctuel = (selectedPeriodicity == 'Ponctuel');
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Modifier l\'engagement',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Align(alignment: Alignment.centerLeft, child: Text('${commitment['service_name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    const SizedBox(height: 4),
                    Align(alignment: Alignment.centerLeft, child: Text(isMissionnaire ? 'Soutenir un missionnaire' : itemName, style: const TextStyle(fontStyle: FontStyle.italic))),
                    const SizedBox(height: 16),
                    TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Montant (FCFA)'), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    if (!isDonPonctuel) TextField(controller: dayController, decoration: const InputDecoration(labelText: 'Jour du mois (1-31)'), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    if (isMissionnaire) ...[
                      TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nom et Prénoms du missionnaire')),
                      const SizedBox(height: 12),
                      TextField(controller: motiveController, decoration: const InputDecoration(labelText: 'Motifs du don')),
                      const SizedBox(height: 12),
                    ] else ...[
                      TextField(controller: reasonController, decoration: const InputDecoration(labelText: 'Objet du don')),
                      const SizedBox(height: 12),
                    ],
                    DropdownButtonFormField<String>(
                      value: selectedPeriodicity,
                      decoration: const InputDecoration(labelText: 'Périodicité'),
                      items: periodicities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: (v) => setStateModal(() => selectedPeriodicity = v!),
                    ),
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerLeft, child: Text('Date d\'enregistrement : ${_formatDate(commitment['createdAt'])}', style: const TextStyle(fontSize: 12, color: Colors.grey))),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            final newAmount = double.tryParse(amountController.text.trim())?.toInt();
                            if (newAmount == null || newAmount <= 0) {
                              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Montant invalide')));
                              return;
                            }
                            final newDay = isDonPonctuel ? null : int.tryParse(dayController.text.trim());
                            if (!isDonPonctuel && (newDay == null || newDay < 1 || newDay > 31)) {
                              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Jour invalide (1-31)')));
                              return;
                            }
                            final token = await AuthService.getToken();
                            if (token == null) return;
                            final body = <String, dynamic>{
                              'amount': newAmount,
                              'day_of_month': newDay,
                              'periodicity': _mapPeriodicityToBackend(selectedPeriodicity),
                            };
                            if (isMissionnaire) {
                              final newName = nameController.text.trim();
                              if (newName.isNotEmpty) body['item_name'] = newName;
                              final newMotive = motiveController.text.trim();
                              if (newMotive.isNotEmpty) body['reason'] = newMotive;
                            } else {
                              final newReason = reasonController.text.trim();
                              if (newReason.isNotEmpty) body['reason'] = newReason;
                            }
                            final response = await http.put(
                              Uri.parse('$_baseUrl/api/auth/service-commitments/${commitment['id']}'),
                              headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
                              body: jsonEncode(body),
                            );
                            Navigator.pop(ctx);
                            if (response.statusCode == 200) {
                              await _fetchServiceCommitments();
                              await _cacheData();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Engagement modifié')));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur modification')));
                            }
                          },
                          child: const Text('Enregistrer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(dynamic dateTime) {
    if (dateTime == null) return 'Date inconnue';
    try {
      final DateTime dt = DateTime.parse(dateTime);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return dateTime.toString();
    }
  }

  Future<void> _deleteServiceCommitment(Map<String, dynamic> commitment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Supprimer l\'engagement pour ${commitment['item_name']} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirm != true) return;
    final token = await AuthService.getToken();
    if (token == null) return;
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/auth/service-commitments/${commitment['id']}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      await _fetchServiceCommitments();
      await _cacheData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Engagement supprimé')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur suppression')));
    }
  }

  Future<void> _honorServiceCommitment(Map<String, dynamic> commitment) async {
    final double amountValue = double.tryParse(commitment['amount'].toString()) ?? 0;
    final TextEditingController amountCtrl = TextEditingController(text: amountValue.toString());
    String localPaymentMethod = _selectedPaymentMethod;
    bool isPaying = false;
    final String description = '${commitment['service_name']} - ${commitment['item_name']}';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            int currentAmount = 0;
            int totalWithFees = 0;
            void updateTotal() {
              currentAmount = int.tryParse(amountCtrl.text) ?? 0;
              totalWithFees = PaymentService.calculateTotalWithFees(currentAmount);
            }
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Honorer l\'engagement',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountCtrl,
                      decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => setStateDialog(() => updateTotal()),
                    ),
                    const SizedBox(height: 12),
                    if (currentAmount > 0) ...[
                      Text('Frais (1,5%) : ${(currentAmount * 0.015).round()} FCFA'),
                      const SizedBox(height: 4),
                      Text('Total à payer : $totalWithFees FCFA', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                    ],
                    DropdownButtonFormField<String>(
                      value: localPaymentMethod,
                      decoration: const InputDecoration(labelText: 'Moyen de paiement', prefixIcon: Icon(Icons.payment)),
                      items: _paymentMethods.map((method) => DropdownMenuItem(
                        value: method,
                        child: _getPaymentMethodWidget(method),
                      )).toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          localPaymentMethod = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: isPaying
                              ? null
                              : () async {
                                  setStateDialog(() => isPaying = true);
                                  final double amountDouble = double.tryParse(amountCtrl.text.trim()) ?? 0;
                                  final int newAmount = amountDouble.toInt();
                                  if (newAmount <= 0) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Montant invalide')));
                                    setStateDialog(() => isPaying = false);
                                    return;
                                  }
                                  final total = PaymentService.calculateTotalWithFees(newAmount);
                                  final success = await PaymentService.initiatePayment(
                                    total,
                                    _generalProjectId,
                                    localPaymentMethod,
                                    description: description,
                                  );
                                  if (!mounted) return;
                                  Navigator.pop(ctx);
                                  if (success) {
                                    await Future.delayed(Duration(seconds: 2));
                                    await _fetchPaymentHistory();
                                    await _cacheData();
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paiement réussi ! Redirection...')));
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de l’initiation du paiement')));
                                  }
                                },
                          child: isPaying
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Payer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToService(String service) async {
    switch (service) {
      case 'Missionnaire': _showMissionnaireModal(); return;
      case 'Champs':
      case 'Projets':
      case 'Départements':
      case 'IIFM':
      case 'Zones':
      case 'Activités':
      case 'Social':
      case 'Équipements':
        await Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceListScreen(categoryName: service)));
        await _fetchServiceCommitments();
        setState(() {});
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Page $service en construction')));
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: const Color(0xFFD4A017),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Accueil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => AppSettings.openAppSettings(),
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
      drawer: const CustomDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFD4A017), width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))]),
                          child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.asset('assets/images/logo.png', fit: BoxFit.cover)),
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
                              const Text('ACTION MISSIONNAIRE INTERAFRICAINE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5D3A1A)), textAlign: TextAlign.center),
                              const SizedBox(height: 4),
                              Text('Côte d\'Ivoire', style: TextStyle(fontSize: 12, color: Colors.grey[700]), textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.person, color: Color(0xFFD4A017)), const SizedBox(width: 8), Text(_fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildCommitmentCard(),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              const Text('Les divers engagements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5D3A1A))),
                              const SizedBox(height: 16),
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 3,
                                childAspectRatio: 1.2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 24,
                                children: [
                                  _buildServiceCircle('Champs', Icons.church, const Color(0xFFC8E6C9)),
                                  _buildServiceCircle('Missionnaire', Icons.people, const Color(0xFFFFCDD2)),
                                  _buildServiceCircle('Projets', Icons.work, const Color(0xFFBBDEFB)),
                                  _buildServiceCircle('Départements', Icons.apartment, const Color(0xFFB2EBF2)),
                                  _buildServiceCircle('IIFM', Icons.school, const Color(0xFFFFCDD2)),
                                  _buildServiceCircle('Zones', Icons.location_on, const Color(0xFFE1BEE7)),
                                  _buildServiceCircle('Activités', Icons.event, const Color(0xFFFFF9C4)),
                                  _buildServiceCircle('Social', Icons.volunteer_activism, const Color(0xFFC8E6C9)),
                                  _buildServiceCircle('Équipements', Icons.inventory, const Color(0xFFE0E0E0)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              const Text('Structures et Organisations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5D3A1A))),
                              const SizedBox(height: 8),
                              const Text('Faites parvenir les dons de votre structure, organisme ou cellule à l’AMI Côte d’Ivoire', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _showStructureDonationModal,
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4A017), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  child: Text('Effectuer un don', style: TextStyle(fontSize: 16)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Historique des engagements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5D3A1A))),
                      const SizedBox(height: 12),
                      _recurringDonations.isEmpty && _serviceCommitments.isEmpty
                          ? const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('Aucun engagement honoré pour le moment')))
                          : Column(
                              children: [
                                if (_recurringDonations.isNotEmpty) ...[
                                  const Text('Dons récurrents', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  ..._recurringDonations.map((d) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(title: Text('${d['amount']} FCFA'), subtitle: Text('${_formatDate(d['createdAt'])} - ${d['status']}'), trailing: Chip(label: Text(d['status']))),
                                  )),
                                ],
                                if (_serviceCommitments.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Text('Engagements en attente', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  ..._serviceCommitments.map((c) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Center(
                                          child: Column(
                                            children: [
                                              Text(
                                                '${c['service_name']} - ${c['item_name']}',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 4),
                                              Text('Montant : ${c['amount']} FCFA', textAlign: TextAlign.center),
                                              Text('Jour : ${c['day_of_month'] ?? '-'}', textAlign: TextAlign.center),
                                              if (c['reason'] != null && c['reason'].isNotEmpty)
                                                Text('Objet : ${c['reason']}', textAlign: TextAlign.center),
                                              Text('Périodicité : ${c['periodicity']}', textAlign: TextAlign.center),
                                              Text('Date : ${_formatDate(c['createdAt'])}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              OutlinedButton(onPressed: () => _editServiceCommitment(c), child: const Text('Modifier')),
                                              const SizedBox(width: 12),
                                              ElevatedButton(
                                                onPressed: () => _honorServiceCommitment(c),
                                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4A017)),
                                                child: const Text('Honorer'),
                                              ),
                                              const SizedBox(width: 12),
                                              OutlinedButton(onPressed: () => _deleteServiceCommitment(c), style: OutlinedButton.styleFrom(foregroundColor: Colors.red), child: const Text('Supprimer')),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                                ],
                              ],
                            ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton.icon(
                          onPressed: _showPaymentReceipt,
                          icon: const Icon(Icons.receipt_long),
                          label: const Text('Reçu de paiement', style: TextStyle(fontSize: 18)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4A017), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
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
          Container(width: 60, height: 60, decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]), child: Icon(icon, size: 30, color: const Color(0xFF5D3A1A))),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF5D3A1A)), textAlign: TextAlign.center, softWrap: false, overflow: TextOverflow.visible),
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
              ElevatedButton(onPressed: () => _showCommitmentModal(), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4A017)), child: const Text('Ajouter un engagement')),
            ],
          ),
        ),
      );
    }
    final rawAmount = _commitment!['amount'];
    final double amountValue = double.tryParse(rawAmount.toString()) ?? 0.0;
    final day = _commitment!['day_of_month'];
    final periodicity = _commitment!['periodicity'] ?? 'Mensuel';
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
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              decoration: const InputDecoration(labelText: 'Moyen de paiement', prefixIcon: Icon(Icons.payment)),
              items: _paymentMethods.map((method) => DropdownMenuItem(
                value: method,
                child: _getPaymentMethodWidget(method),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => _showCommitmentModal(isEditing: true),
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                  child: const Text('Modifier'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    final TextEditingController amountCtrl = TextEditingController(text: amountValue.toString());
                    final String localMethod = _selectedPaymentMethod;
                    bool isPaying = false;
                    await showDialog(
                      context: context,
                      builder: (ctx2) => AlertDialog(
                        title: const Text('Honorer l\'engagement'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: amountCtrl,
                              decoration: InputDecoration(labelText: 'Montant (FCFA)'),
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                // Recalculer le total si nécessaire (optionnel)
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: localMethod,
                              decoration: const InputDecoration(labelText: 'Moyen de paiement', prefixIcon: Icon(Icons.payment)),
                              items: _paymentMethods.map((method) => DropdownMenuItem(
                                value: method,
                                child: _getPaymentMethodWidget(method),
                              )).toList(),
                              onChanged: (value) {},
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('Annuler')),
                          StatefulBuilder(
                            builder: (context, setStateBtn) {
                              return ElevatedButton(
                                onPressed: isPaying
                                    ? null
                                    : () async {
                                        setStateBtn(() => isPaying = true);
                                        final double amountDouble = double.tryParse(amountCtrl.text.trim()) ?? 0;
                                        final int newAmount = amountDouble.toInt();
                                        if (newAmount <= 0) {
                                          ScaffoldMessenger.of(ctx2).showSnackBar(const SnackBar(content: Text('Montant invalide')));
                                          setStateBtn(() => isPaying = false);
                                          return;
                                        }
                                        final total = PaymentService.calculateTotalWithFees(newAmount);
                                        final success = await PaymentService.initiatePayment(
                                          total,
                                          _generalProjectId,
                                          localMethod,
                                          description: 'Fonctionnement de l\'AMI',
                                        );
                                        Navigator.pop(ctx2);
                                        if (success) {
                                          await Future.delayed(Duration(seconds: 2));
                                          await _fetchPaymentHistory();
                                          await _cacheData();
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paiement réussi ! Redirection...')));
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur paiement')));
                                        }
                                      },
                                child: isPaying
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Text('Payer'),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4A017)),
                  child: const Text('Honorer'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _deleteCommitment,
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Supprimer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
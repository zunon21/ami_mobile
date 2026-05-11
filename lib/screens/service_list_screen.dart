import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

class ServiceListScreen extends StatefulWidget {
  final String categoryName; // ex: 'Champs', 'Projets', etc.

  const ServiceListScreen({Key? key, required this.categoryName}) : super(key: key);

  @override
  _ServiceListScreenState createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _items = [];
  List<String> _filteredItems = [];

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  String _selectedPeriodicity = 'Mensuel';
  bool _isLoading = false;

  TextEditingController? _reasonController;
  String? _selectedEcominType;
  final List<String> _ecominTypes = ['Adolescents', 'Benjamins', 'Adultes'];

  final List<String> _periodicities = ['Mensuel', 'Bimensuel', 'Trimestriel', 'Semestriel', 'Annuel', 'Ponctuel'];

  String _mapPeriodicityToBackend(String periodicity) {
    switch (periodicity.toLowerCase()) {
      case 'bimensuel': return 'bimestriel';
      default: return periodicity.toLowerCase();
    }
  }

  // Fonction de normalisation (minuscules, suppression des accents)
  String _normalize(String s) {
    return s.toLowerCase()
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .trim();
  }

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  // Récupération des items pour la catégorie depuis l'API
  Future<void> _fetchItems() async {
    final token = await AuthService.getToken();
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/service-items/categories'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> categories = jsonDecode(response.body);
        final normalizedTarget = _normalize(widget.categoryName);
        final category = categories.firstWhere(
          (cat) => _normalize(cat['name']) == normalizedTarget,
          orElse: () => null,
        );
        if (category != null && category['items'] != null) {
          final List<dynamic> itemsJson = category['items'];
          final List<String> itemsList = itemsJson.map((item) => item['name'] as String).toList();
          setState(() {
            _items = itemsList;
            _filteredItems = itemsList;
          });
        }
      }
    } catch (e) {
      print('Erreur chargement items: $e');
    }
  }

  // Rafraîchissement manuel (pull-to-refresh)
  Future<void> _onRefresh() async {
    await _fetchItems();
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = _items
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _saveCommitment(String itemName, {String? reasonValue, String? ecominType}) async {
    if (_isLoading) return;

    final amount = double.tryParse(_amountController.text.trim());
    final isDonPonctuel = (_selectedPeriodicity == 'Ponctuel');

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Montant invalide')));
      return;
    }

    setState(() => _isLoading = true);
    final token = await AuthService.getToken();
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      if (isDonPonctuel) {
        final response = await http.post(
          Uri.parse('${AuthService.baseUrl}/api/donations/initiate'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode({
            'project_id': '11111111-1111-1111-1111-111111111111',
            'amount': amount.toInt(),
            'is_anonymous': false,
            'donation_type': 'one_time'
          }),
        );
        Navigator.pop(context);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final checkoutUrl = data['checkout_url'];
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Paiement : $checkoutUrl')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur initiation paiement')));
        }
      } else {
        final day = int.tryParse(_dayController.text.trim());
        if (day == null || day < 1 || day > 31) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jour invalide (1-31)')));
          setState(() => _isLoading = false);
          return;
        }

        final Map<String, dynamic> body = {
          'service_name': widget.categoryName,
          'item_name': itemName,
          'amount': amount,
          'day_of_month': day,
          'periodicity': _mapPeriodicityToBackend(_selectedPeriodicity),
        };

        String combinedReason = '';
        if (widget.categoryName == 'Activités' && itemName == 'ECOMIN' && ecominType != null && ecominType.isNotEmpty) {
          combinedReason = 'Ecomin : $ecominType';
          if (reasonValue != null && reasonValue.isNotEmpty) {
            combinedReason += ' - $reasonValue';
          }
        } else {
          combinedReason = reasonValue ?? '';
        }
        if (combinedReason.isNotEmpty) {
          body['reason'] = combinedReason;
        }

        final response = await http.post(
          Uri.parse('${AuthService.baseUrl}/api/auth/service-commitments'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode(body),
        );
        Navigator.pop(context);
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Engagement enregistré')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de l\'enregistrement')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCommitmentModal(String itemName) {
    _amountController.clear();
    _dayController.clear();
    _selectedPeriodicity = 'Mensuel';
    _reasonController?.dispose();
    _reasonController = null;
    _selectedEcominType = null;

    String modalTitle = 'Engagement pour $itemName';
    if (itemName == 'Levez les yeux') {
      modalTitle = 'Engagement pour le magazine levez les yeux';
    } else if (itemName == 'Priez le Maître') {
      modalTitle = 'Engagement pour le calendrier de prière prier le maître';
    }

    _reasonController = TextEditingController();

    final bool isEcomin = (widget.categoryName == 'Activités' && itemName == 'ECOMIN');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool isDonPonctuel = (_selectedPeriodicity == 'Ponctuel');
            return AlertDialog(
              title: Text(modalTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  if (!isDonPonctuel)
                    TextField(
                      controller: _dayController,
                      decoration: const InputDecoration(labelText: 'Jour du mois (1-31)'),
                      keyboardType: TextInputType.number,
                    ),
                  if (isEcomin) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedEcominType,
                      decoration: const InputDecoration(labelText: 'Quel Ecomin ?', prefixIcon: Icon(Icons.group)),
                      items: _ecominTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setModalState(() => _selectedEcominType = v),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reasonController!,
                    decoration: const InputDecoration(labelText: 'Motifs du don', prefixIcon: Icon(Icons.edit)), // (optionnel) retiré
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedPeriodicity,
                    decoration: const InputDecoration(labelText: 'Périodicité'),
                    items: _periodicities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (v) => setModalState(() => _selectedPeriodicity = v!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _saveCommitment(
                            itemName,
                            reasonValue: _reasonController?.text.trim(),
                            ecominType: _selectedEcominType,
                          ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(isDonPonctuel ? 'Procéder au paiement' : 'Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String? headerTitle;
    if (widget.categoryName == 'Champs') {
      headerTitle = 'Engagez vous à soutenir un champ';
    } else if (widget.categoryName == 'Projets') {
      headerTitle = 'Engagez vous à soutenir un Projet';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: const Color(0xFFD4A017),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.categoryName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (headerTitle != null) ...[
                Text(
                  headerTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5D3A1A)),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Chercher par nom',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: _filterItems,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _filteredItems.isEmpty
                    ? const Center(child: Text('Aucun élément trouvé'))
                    : ListView.builder(
                        itemCount: _filteredItems.length,
                        itemBuilder: (ctx, index) {
                          final item = _filteredItems[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.folder, color: Color(0xFFD4A017)),
                              title: Text(item),
                              trailing: const Icon(Icons.add_circle_outline, color: Color(0xFFD4A017)),
                              onTap: () => _showCommitmentModal(item),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

class ServiceListScreen extends StatefulWidget {
  final String title;
  final List<String> items;

  const ServiceListScreen({Key? key, required this.title, required this.items}) : super(key: key);

  @override
  _ServiceListScreenState createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredItems = [];

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  String _selectedPeriodicity = 'Mensuel';
  bool _isLoading = false;

  // Contrôleurs pour les champs optionnels (seront créés dynamiquement)
  TextEditingController? _extraController;

  final List<String> _periodicities = ['Mensuel', 'Bimensuel', 'Trimestriel', 'Semestriel', 'Annuel', 'Ponctuel'];

  // Fonction utilitaire : convertit la périodicité affichée en valeur backend
  // CORRECTION : "Bimensuel" -> "bimestriel" (car backend n'accepte pas "bimensuel")
  String _mapPeriodicityToBackend(String periodicity) {
    switch (periodicity.toLowerCase()) {
      case 'bimensuel': return 'bimestriel';
      default: return periodicity.toLowerCase();
    }
  }

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = widget.items
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _saveCommitment(String itemName, {String? extraReason}) async {
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
          'service_name': widget.title,
          'item_name': itemName,
          'amount': amount,
          'day_of_month': day,
          'periodicity': _mapPeriodicityToBackend(_selectedPeriodicity),
        };
        if (extraReason != null && extraReason.isNotEmpty) {
          body['reason'] = extraReason;
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
    _extraController?.dispose();
    _extraController = null;

    String modalTitle = 'Engagement pour $itemName';
    if (itemName == 'Levez les yeux') {
      modalTitle = 'Engagement pour le magazine levez les yeux';
    } else if (itemName == 'Priez le Maître') {
      modalTitle = 'Engagement pour le calendrier de prière prier le maître';
    }

    String? extraLabel;
    if (widget.title == 'IIFM') {
      if (itemName == 'Fonctionnement') {
        extraLabel = 'Précisez l\'objet exact du fonctionnement de IIFM (optionnel)';
      } else if (itemName == 'infrastructures') {
        extraLabel = 'Indiquez l\'infrastructure de IIFM (optionnel)';
      }
    } else if (widget.title == 'Zones') {
      if (itemName == 'Zone de Bouaké') {
        extraLabel = 'Indiquez l\'objet du don à la zone de Bouaké (optionnel)';
      } else if (itemName == 'Zone de Daloa') {
        extraLabel = 'Indiquez l\'objet du don à la zone de Daloa (optionnel)';
      }
    } else if (widget.title == 'Équipements') {
      if (itemName == 'Achat matériel divers') {
        extraLabel = 'Précisez le matériel (optionnel)';
      }
    }

    if (extraLabel != null) {
      _extraController = TextEditingController();
    }

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
                  if (extraLabel != null) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _extraController!,
                      decoration: InputDecoration(labelText: extraLabel),
                    ),
                  ],
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
                      : () => _saveCommitment(itemName, extraReason: _extraController?.text.trim()),
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
    if (widget.title == 'Champs') {
      headerTitle = 'Engagez vous à soutenir un champ';
    } else if (widget.title == 'Projets') {
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
        title: Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
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
    );
  }
}
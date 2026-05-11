import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({Key? key}) : super(key: key);

  @override
  _HistoriqueScreenState createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  List<dynamic> _commitments = [];
  bool _isLoading = true;
  String? _error;

  // Récupérer les engagements (service + mensuel)
  Future<void> _fetchCommitments() async {
    final token = await AuthService.getToken();
    if (token == null) {
      setState(() {
        _error = "Non authentifié";
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/auth/service-commitments'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _commitments = jsonDecode(response.body);
          _error = null;
        });
      } else {
        setState(() {
          _error = "Erreur chargement engagements";
        });
      }
    } catch (e) {
      setState(() {
        _error = "Erreur réseau : $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Supprimer un engagement
  Future<void> _deleteCommitment(String id) async {
    final token = await AuthService.getToken();
    if (token == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Voulez-vous vraiment supprimer cet engagement ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Oui')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/api/auth/service-commitments/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        _fetchCommitments(); // rafraîchir
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Engagement supprimé')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur suppression')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  // Modifier un engagement (via un formulaire simple)
  Future<void> _editCommitment(dynamic commitment) async {
    // On utilise un formulaire simple pour modifier le montant et le jour
    final TextEditingController amountCtrl = TextEditingController(text: commitment['amount'].toString());
    final TextEditingController dayCtrl = TextEditingController(text: commitment['day_of_month'].toString());
    String periodicity = commitment['periodicity'];
    final List<String> periodicities = ['mensuel', 'bimestriel', 'trimestriel', 'semestriel', 'annuel', 'ponctuel'];

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier l\'engagement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: dayCtrl,
              decoration: const InputDecoration(labelText: 'Jour du mois (1-31)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: periodicity,
              decoration: const InputDecoration(labelText: 'Périodicité'),
              items: periodicities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => periodicity = v!,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer')),
        ],
      ),
    );

    if (result != true) return;

    final amount = double.tryParse(amountCtrl.text);
    final day = int.tryParse(dayCtrl.text);
    if (amount == null || day == null || day < 1 || day > 31) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Montant ou jour invalide')));
      return;
    }

    final token = await AuthService.getToken();
    if (token == null) return;

    try {
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/api/auth/service-commitments/${commitment['id']}'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'amount': amount,
          'day_of_month': day,
          'periodicity': periodicity,
          'item_name': commitment['item_name'],
          'reason': commitment['reason'] ?? '',
        }),
      );
      if (response.statusCode == 200) {
        _fetchCommitments();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Engagement modifié')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur modification')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCommitments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes engagements'),
        backgroundColor: const Color(0xFFD4A017),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCommitments,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _commitments.isEmpty
                    ? const Center(child: Text('Aucun engagement pour le moment'))
                    : ListView.builder(
                        itemCount: _commitments.length,
                        itemBuilder: (ctx, index) {
                          final c = _commitments[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text('${c['item_name']} - ${c['amount']} FCFA'),
                              subtitle: Text('Jour ${c['day_of_month']} - ${c['periodicity']}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _editCommitment(c),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteCommitment(c['id']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
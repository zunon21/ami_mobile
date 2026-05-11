import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

class EngagementForm extends StatefulWidget {
  final String serviceName;
  final String itemName;
  final Map<String, dynamic>? existingCommitment;

  const EngagementForm({
    Key? key,
    required this.serviceName,
    required this.itemName,
    this.existingCommitment,
  }) : super(key: key);

  @override
  _EngagementFormState createState() => _EngagementFormState();
}

class _EngagementFormState extends State<EngagementForm> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  String _periodicity = 'mensuel';
  final List<String> _periodicities = ['mensuel', 'bimestriel', 'trimestriel', 'semestriel', 'annuel', 'ponctuel'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingCommitment != null) {
      _amountController.text = widget.existingCommitment!['amount'].toString();
      _dayController.text = widget.existingCommitment!['day_of_month'].toString();
      _periodicity = widget.existingCommitment!['periodicity'] ?? 'mensuel';
      _reasonController.text = widget.existingCommitment!['reason'] ?? '';
    }
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    final day = int.tryParse(_dayController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Montant invalide')));
      return;
    }
    final isDonPonctuel = _periodicity == 'ponctuel';
    if (!isDonPonctuel && (day == null || day < 1 || day > 31)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jour invalide (1-31)')));
      return;
    }

    setState(() => _isLoading = true);
    final token = await AuthService.getToken();
    if (token == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Non authentifié')));
      return;
    }

    final body = {
      'service_name': widget.serviceName,
      'item_name': widget.itemName,
      'amount': amount,
      'day_of_month': isDonPonctuel ? 1 : day,
      'periodicity': _periodicity,
      'reason': _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
    };

    final url = widget.existingCommitment == null
        ? '${AuthService.baseUrl}/api/auth/service-commitments'
        : '${AuthService.baseUrl}/api/auth/service-commitments/${widget.existingCommitment!['id']}';

    final method = widget.existingCommitment == null ? 'post' : 'put';

    try {
      http.Response response;
      if (method == 'post') {
        response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode(body),
        );
      } else {
        response = await http.put(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode(body),
        );
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.existingCommitment == null ? 'Engagement enregistré' : 'Engagement modifié')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de l\'enregistrement')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDonPonctuel = _periodicity == 'ponctuel';
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingCommitment == null ? 'Nouvel engagement' : 'Modifier engagement'),
        backgroundColor: const Color(0xFFD4A017),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _periodicity,
              decoration: const InputDecoration(labelText: 'Périodicité'),
              items: _periodicities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => setState(() => _periodicity = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: 'Motifs du don (optionnel)'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4A017)),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(widget.existingCommitment == null ? 'Enregistrer' : 'Mettre à jour'),
            ),
          ],
        ),
      ),
    );
  }
}
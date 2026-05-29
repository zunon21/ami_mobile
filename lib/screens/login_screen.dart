import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();
  final TextEditingController _churchController = TextEditingController();
  String? _selectedGender;

  String _step = 'phone';
  bool _isLoading = false;
  String _status = '';
  String _tempToken = '';
  String _tempPhone = '';

  // FocusNode pour le champ Nom (correction clavier)
  final FocusNode _nameFocusNode = FocusNode();

  final List<Map<String, String>> _countries = [
    {'name': 'Côte d’Ivoire', 'code': '+225'},
    {'name': 'France', 'code': '+33'},
    {'name': 'Sénégal', 'code': '+221'},
    {'name': 'Mali', 'code': '+223'},
    {'name': 'Burkina Faso', 'code': '+226'},
    {'name': 'Bénin', 'code': '+229'},
    {'name': 'Togo', 'code': '+228'},
    {'name': 'Niger', 'code': '+227'},
    {'name': 'Guinée', 'code': '+224'},
    {'name': 'Ghana', 'code': '+233'},
    {'name': 'Nigeria', 'code': '+234'},
    {'name': 'Canada', 'code': '+1'},
    {'name': 'États-Unis', 'code': '+1'},
    {'name': 'Belgique', 'code': '+32'},
    {'name': 'Suisse', 'code': '+41'},
  ];
  String _selectedCountryCode = '+225';

  Future<void> _requestOtp() async {
    String rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) {
      setState(() => _status = 'Veuillez saisir votre numéro');
      return;
    }
    rawPhone = rawPhone.replaceAll(RegExp(r'\s+'), '');
    final fullPhone = _selectedCountryCode + rawPhone;

    setState(() { _isLoading = true; _status = ''; });
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/api/auth/request-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': fullPhone}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final code = data['code'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Votre code OTP : $code'),
            duration: Duration(seconds: 10),
            backgroundColor: Colors.green,
          ),
        );
        setState(() { _step = 'otp'; _tempPhone = fullPhone; _status = 'Code envoyé (consultez le message ci-dessous)'; });
      } else {
        setState(() => _status = 'Erreur envoi code');
      }
    } catch (e) {
      print('Erreur détaillée : $e');
      setState(() => _status = 'Erreur connexion: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) { setState(() => _status = 'Entrez le code'); return; }
    setState(() { _isLoading = true; _status = ''; });
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': _tempPhone, 'code': code}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final needsName = data['needs_name'] ?? false;
        if (needsName) {
          setState(() { _step = 'name'; _tempToken = token; });
          // FORCER LA RÉINITIALISATION DU CLAVIER POUR LE CHAMP NOM
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _nameFocusNode.unfocus();
            Future.delayed(Duration(milliseconds: 100), () {
              if (mounted) _nameFocusNode.requestFocus();
            });
          });
        } else {
          await AuthService.saveToken(token);
          setState(() => _status = 'Connexion réussie');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen()),
          );
        }
      } else {
        setState(() => _status = 'Code invalide ou expiré');
      }
    } catch (e) {
      setState(() => _status = 'Erreur vérification');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeProfile() async {
    final fullName = _nameController.text.trim();
    final firstName = _firstNameController.text.trim();
    final gender = _selectedGender;
    final age = int.tryParse(_ageController.text.trim());
    final city = _cityController.text.trim();
    final profession = _professionController.text.trim();
    final church = _churchController.text.trim();

    if (fullName.isEmpty || firstName.isEmpty || gender == null || age == null || city.isEmpty || profession.isEmpty || church.isEmpty) {
      setState(() => _status = 'Veuillez remplir tous les champs');
      return;
    }

    setState(() { _isLoading = true; _status = ''; });
    try {
      await http.put(
        Uri.parse('${AuthService.baseUrl}/api/auth/update-name'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_tempToken',
        },
        body: jsonEncode({'name': fullName}),
      );
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/api/auth/complete-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_tempToken',
        },
        body: jsonEncode({
          'first_name': firstName,
          'gender': gender,
          'age': age,
          'city': city,
          'profession': profession,
          'church_org': church,
        }),
      );
      if (response.statusCode == 200) {
        await AuthService.saveToken(_tempToken);
        setState(() => _status = 'Profil enregistré !');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      } else {
        setState(() => _status = 'Erreur enregistrement profil');
      }
    } catch (e) {
      setState(() => _status = 'Erreur connexion');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', height: 80),
              const SizedBox(height: 16),
              if (_step == 'phone') ...[
                Text('Bienvenue sur PARTENAIRE DE L\'AMI', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C1A0C))),
                const SizedBox(height: 12),
                Text('Entrez votre numéro de téléphone', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCountryCode,
                      isExpanded: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      items: _countries.map((country) => DropdownMenuItem(value: country['code'], child: Text('${country['name']} (${country['code']})'))).toList(),
                      onChanged: (value) => setState(() => _selectedCountryCode = value!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(controller: _phoneController, decoration: InputDecoration(labelText: 'Numéro', prefixIcon: Icon(Icons.phone, color: const Color(0xFFD4A017)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), keyboardType: TextInputType.phone),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _isLoading ? null : _requestOtp, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4A017), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Continuer', style: TextStyle(fontSize: 16))),
              ] else if (_step == 'otp') ...[
                Text('Vérification', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C1A0C))),
                const SizedBox(height: 12),
                Text('Un code a été envoyé à $_tempPhone', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 32),
                TextField(controller: _otpController, decoration: InputDecoration(labelText: 'Code à 6 chiffres', prefixIcon: Icon(Icons.lock, color: const Color(0xFFD4A017)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), keyboardType: TextInputType.number),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _isLoading ? null : _verifyOtp, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4A017), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Vérifier', style: TextStyle(fontSize: 16))),
              ] else if (_step == 'name') ...[
                Text('Complétez votre profil', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C1A0C))),
                const SizedBox(height: 12),
                Text('Quelques informations supplémentaires', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  decoration: InputDecoration(labelText: 'Nom', prefixIcon: Icon(Icons.person, color: const Color(0xFFD4A017)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _firstNameController,
                  decoration: InputDecoration(labelText: 'Prénoms', prefixIcon: Icon(Icons.person_outline, color: const Color(0xFFD4A017)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(labelText: 'Sexe', prefixIcon: Icon(Icons.wc, color: const Color(0xFFD4A017)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: ['Homme', 'Femme'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _selectedGender = v),
                ),
                const SizedBox(height: 16),
                TextField(controller: _ageController, decoration: InputDecoration(labelText: 'Âge', prefixIcon: Icon(Icons.cake, color: const Color(0xFFD4A017)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                TextField(controller: _cityController, decoration: InputDecoration(labelText: 'Ville de résidence', prefixIcon: Icon(Icons.location_city, color: const Color(0xFFD4A017)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 16),
                TextField(controller: _professionController, decoration: InputDecoration(labelText: 'Profession', prefixIcon: Icon(Icons.work, color: const Color(0xFFD4A017)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 16),
                TextField(controller: _churchController, decoration: InputDecoration(labelText: 'Église / organisation', prefixIcon: Icon(Icons.church, color: const Color(0xFFD4A017)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _isLoading ? null : _completeProfile, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4A017), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Terminer', style: TextStyle(fontSize: 16))),
              ],
              const SizedBox(height: 32),
              Text(_status, style: TextStyle(color: _status.contains('réussie') ? Colors.green : Colors.red)),
              const SizedBox(height: 16),
              Text.rich(TextSpan(text: 'En vous inscrivant, vous acceptez notre ', style: TextStyle(color: Colors.grey[600], fontSize: 12), children: [TextSpan(text: 'Politique de confidentialité', style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)), const TextSpan(text: ' et nos '), TextSpan(text: 'Conditions d\'utilisation', style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline))])),
            ],
          ),
        ),
      ),
    );
  }
}
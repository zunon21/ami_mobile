import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'auth_service.dart';

class PaymentService {
  static Future<bool> initiatePayment(
    int amount,
    String projectId,
    String paymentMethod, {
    String? description,
    Map<String, dynamic>? extraData, // ← nouveau paramètre
  }) async {
    final token = await AuthService.getToken();
    if (token == null) return false;

    try {
      final Map<String, dynamic> body = {
        'amount': amount,
        'project_id': projectId,
        'is_anonymous': false,
        'paymentMethod': paymentMethod,
      };
      if (description != null) {
        body['description'] = description;
      }
      if (extraData != null && extraData.isNotEmpty) {
        body['extra_data'] = extraData;
      }

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/api/donations/initiate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final checkoutUrl = data['checkout_url'];
        if (checkoutUrl != null && await canLaunchUrl(Uri.parse(checkoutUrl))) {
          await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication);
          return true;
        }
      } else {
        print('Erreur HTTP ${response.statusCode}: ${response.body}');
      }
      return false;
    } catch (e) {
      print('Erreur paiement: $e');
      return false;
    }
  }
}
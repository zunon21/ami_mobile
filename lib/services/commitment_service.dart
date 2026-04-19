import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

class CommitmentService {
  static Future<Map<String, dynamic>?> getCommitment() async {
    final token = await AuthService.getToken();
    if (token == null) return null;
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/auth/commitment'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        return null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> saveCommitment({
    required double amount,
    required int dayOfMonth,
    required String periodicity,
    String? reason,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) return false;
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/api/auth/commitment'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'amount': amount,
          'day_of_month': dayOfMonth,
          'periodicity': periodicity,
          'reason': reason,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
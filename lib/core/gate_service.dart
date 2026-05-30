import 'dart:convert';
import '../setup/app_config.dart';
import '../data/gate_response.dart';
import 'net_client.dart';
import 'vault_service.dart';

class GateService {
  final VaultService _vault;

  GateService(this._vault);

  Future<GateResponse> fetchRemote(Map<String, dynamic> body) async {
    if (AppConfig.apiEndpoint.isEmpty) {
      return GateResponse.error('Endpoint not set');
    }

    try {
      final uri = Uri.parse(AppConfig.apiEndpoint);
      final response = await appNetClient
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final result = GateResponse.fromJson(json);

        if (result.ok && result.url != null) {
          await _vault.setSavedUrl(result.url!);
          if (result.expires != null) {
            await _vault.setUrlExpires(result.expires!);
          }
        }

        return result;
      } else {
        return GateResponse.error('HTTP ${response.statusCode}');
      }
    } catch (e) {
      return GateResponse.error(e.toString());
    }
  }

  Future<String?> getContentUrl() async {
    return _vault.getSavedUrl();
  }
}

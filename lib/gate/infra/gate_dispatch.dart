import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/gate_config.dart';
import '../models/gate_reply.dart';
import 'secure_agent.dart';
import 'session_vault.dart';

/// Posts an install/launch payload to the remote gate endpoint and
/// caches the returned destination URL. Returns [GateReply.declined]
/// when the endpoint is not yet configured so callers fall back to the
/// game flow without crashing.
class GateDispatch {
  final SessionVault _vault;

  GateDispatch(this._vault);

  Future<GateReply> send(Map<String, dynamic> body) async {
    final endpoint = GateConfig.configEndpoint;
    debugPrint('[STK.GD] send → endpoint="$endpoint"');
    if (endpoint.isEmpty) {
      debugPrint('[STK.GD] endpoint not configured — declined');
      return GateReply.declined('endpoint_missing');
    }
    try {
      final uri = Uri.parse(endpoint);
      debugPrint('[STK.GD] POST $uri  body=${jsonEncode(body)}');
      final resp = await secureAgent
          .post(uri,
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode(body))
          .timeout(const Duration(seconds: 8));

      debugPrint('[STK.GD] HTTP ${resp.statusCode}');
      final preview = resp.body.length > 500
          ? '${resp.body.substring(0, 500)}…'
          : resp.body;
      debugPrint('[STK.GD] body=$preview');

      if (resp.statusCode != 200) {
        return GateReply.declined('http_${resp.statusCode}');
      }
      final decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic>) {
        return GateReply.declined('bad_json');
      }
      final reply = GateReply.fromMap(decoded);
      debugPrint('[STK.GD] reply granted=${reply.granted} dest=${reply.destination}');
      if (reply.granted && reply.destination != null) {
        await _vault.writeSavedUrl(reply.destination!);
        if (reply.expiresAt != null) {
          await _vault.writeSavedTtl(reply.expiresAt!);
        }
      }
      return reply;
    } catch (err, st) {
      debugPrint('[STK.GD] error: $err\n$st');
      return GateReply.declined(err.toString());
    }
  }
}

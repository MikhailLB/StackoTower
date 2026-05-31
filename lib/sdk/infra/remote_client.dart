import 'dart:convert';
import '../config/remote_config.dart';
import '../models/wire.dart';
import 'app_client.dart';
import 'data_store.dart';

class RemoteClient {
  final DataStore _store;

  RemoteClient(this._store);

  Future<RemoteReply> send(Map<String, dynamic> body) async {
    final endpoint = RemoteConfig.endpoint;
    if (endpoint.isEmpty) return RemoteReply.declined('endpoint_missing');
    try {
      final uri = Uri.parse(endpoint);
      final resp = await appClient
          .post(uri,
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode(body))
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode != 200) {
        return RemoteReply.declined('http_${resp.statusCode}');
      }
      final decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic>) {
        return RemoteReply.declined('bad_json');
      }
      final reply = RemoteReply.fromMap(decoded);
      if (reply.granted && reply.destination != null) {
        await _store.writeSavedUrl(reply.destination!);
        if (reply.expiresAt != null) {
          await _store.writeSavedTtl(reply.expiresAt!);
        }
      }
      return reply;
    } catch (err) {
      return RemoteReply.declined(err.toString());
    }
  }
}

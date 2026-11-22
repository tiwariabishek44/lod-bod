import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/load_post.dart';

/// One device-local draft per signed-in user, independent of shipment mode.
class LocalLoadDraftStore {
  LocalLoadDraftStore(this.preferences, this.ownerId);
  final SharedPreferences preferences;
  final String ownerId;
  String get _key => 'loadboard.load_draft.v1.$ownerId';
  String get _migrationKey => '$_key.migrated';

  Future<LoadPost?> read() async {
    // Preserve drafts saved by earlier versions of the mock repository.
    if (!(preferences.getBool(_migrationKey) ?? false)) {
      final legacy = preferences.getString('loadboard.shipments.v2.$ownerId');
      if (legacy != null && preferences.getString(_key) == null) {
        final state = jsonDecode(legacy) as Map;
        final draft = state['draft'];
        if (draft != null &&
            !await preferences.setString(_key, jsonEncode(draft))) {
          throw StateError('Could not migrate your saved draft.');
        }
      }
      if (!await preferences.setBool(_migrationKey, true)) {
        throw StateError('Could not finish preparing draft storage.');
      }
    }
    final data = preferences.getString(_key);
    return data == null
        ? null
        : LoadPost.fromJson(Map<String, dynamic>.from(jsonDecode(data) as Map));
  }

  Future<LoadPost> save(LoadPost post) async {
    // Mark migration complete before replacing a legacy draft.
    await read();
    final saved = post.copyWith(
      status: LoadPostStatus.draft,
      updatedAt: DateTime.now(),
    );
    if (!await preferences.setString(_key, jsonEncode(saved.toJson()))) {
      throw StateError('Could not save the draft on this device.');
    }
    return saved;
  }

  Future<void> removeIfMatching(String id) async {
    final saved = await read();
    if (saved?.id == id && !await preferences.remove(_key)) {
      throw StateError('Could not remove the posted draft.');
    }
  }
}

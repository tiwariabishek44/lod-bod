import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/load_catalog_repository.dart';
import '../data/repositories/local_load_draft_store.dart';
import '../data/repositories/shipment_repository.dart';
import '../domain/models/load_post.dart';
import 'shipment_providers.dart';

/// Coordinates form data operations independently of navigation and dialogs.
/// Drafts remain on this device in both application modes.
final postLoadControllerProvider = Provider<PostLoadController>((ref) {
  return PostLoadController(
    catalogs: ref.watch(loadCatalogRepositoryProvider),
    drafts: ref.watch(localLoadDraftStoreProvider),
    submit: ref.read(shipmentWorkflowProvider.notifier).submit,
    refresh: ref.read(shipmentWorkflowProvider.notifier).refresh,
  );
});

class PostLoadController {
  PostLoadController({
    required this.catalogs,
    required this.drafts,
    required this.submit,
    required this.refresh,
  });

  final LoadCatalogRepository catalogs;
  final LocalLoadDraftStore drafts;
  final Future<LoadPostSubmission> Function(LoadPost) submit;
  final Future<void> Function() refresh;

  Future<LoadCatalog> loadCatalog() => catalogs.fetch();
  Future<String> saveContact(String name, String phone) =>
      catalogs.saveContact(name, phone);
  Future<LoadPost?> readDraft() => drafts.read();
  Future<LoadPost> saveDraft(LoadPost post) => drafts.save(post);
  Future<void> removeDraftIfMatching(String id) => drafts.removeIfMatching(id);
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../library/application/providers/library_providers.dart';
import '../../data/repositories/local_image_object_repository.dart';
import '../../data/storage/web_image_data_store.dart';
import '../../domain/repositories/image_object_repository.dart';

final webImageDataStoreProvider = Provider<WebImageDataStore>((ref) {
  return WebImageDataStore();
});

final imageObjectRepositoryProvider = Provider<ImageObjectRepository>((ref) {
  return LocalImageObjectRepository(
    store: ref.watch(keyValueStoreProvider),
    imageDataStore: ref.watch(webImageDataStoreProvider),
  );
});

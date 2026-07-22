// Copy all content into text_providers.dart.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../library/application/providers/library_providers.dart';
import '../../data/repositories/local_text_object_repository.dart';
import '../../domain/repositories/text_object_repository.dart';

final textObjectRepositoryProvider = Provider<TextObjectRepository>((ref) {
  return LocalTextObjectRepository(store: ref.watch(keyValueStoreProvider));
});

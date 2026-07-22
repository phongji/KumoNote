import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../library/application/providers/library_providers.dart';
import '../../data/repositories/local_ink_repository.dart';
import '../../domain/entities/ink_stroke.dart';
import '../../domain/repositories/ink_repository.dart';

final inkRepositoryProvider = Provider<InkRepository>((ref) {
  final store = ref.watch(keyValueStoreProvider);

  return LocalInkRepository(store: store);
});

final inkStrokeListProvider = FutureProvider.family<List<InkStroke>, String>((
  ref,
  pageId,
) {
  return ref.watch(inkRepositoryProvider).getStrokes(pageId);
});

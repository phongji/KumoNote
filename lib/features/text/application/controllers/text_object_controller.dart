import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/text_object.dart';
import '../../domain/repositories/text_object_repository.dart';
import '../providers/text_providers.dart';

final textObjectControllerProvider =
    AsyncNotifierProvider.family<
      TextObjectController,
      List<TextObject>,
      String
    >(TextObjectController.new);

final class TextObjectController extends AsyncNotifier<List<TextObject>> {
  TextObjectController(this._pageId);

  final String _pageId;
  final Uuid _uuid = const Uuid();

  TextObjectRepository get _repository {
    return ref.read(textObjectRepositoryProvider);
  }

  @override
  Future<List<TextObject>> build() {
    return _repository.getObjectsForPage(_pageId);
  }

  Future<void> createText({
    required double x,
    required double y,
    required String languageCode,
    String initialText = '',
  }) async {
    final current = state.asData?.value ?? const <TextObject>[];
    final now = DateTime.now().toUtc();
    final object = TextObject(
      id: _uuid.v4(),
      pageId: _pageId,
      plainText: initialText,
      fontFamilyToken: 'systemSans',
      fontSize: 18,
      weight: 400,
      alignment: TextObjectAlignment.left,
      colorValue: 0xFF303330,
      lineHeight: 1.45,
      languageCode: languageCode,
      bounds: TextObjectBounds(x: x, y: y, width: 240, height: 88),
      createdAt: now,
      updatedAt: now,
      version: 1,
      zIndex: now.microsecondsSinceEpoch,
    );

    state = AsyncData([...current, object]);
    await _saveOrRestore(previous: current, object: object);
  }

  Future<void> editText({
    required String objectId,
    required String plainText,
  }) async {
    await _updateObject(
      objectId,
      (object) =>
          object.edit(newPlainText: plainText, now: DateTime.now().toUtc()),
    );
  }

  Future<void> moveText({
    required String objectId,
    required double deltaX,
    required double deltaY,
  }) async {
    await _updateObject(
      objectId,
      (object) => object.move(
        deltaX: deltaX,
        deltaY: deltaY,
        now: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> resizeText({
    required String objectId,
    required double width,
    required double height,
  }) async {
    await _updateObject(
      objectId,
      (object) => object.resize(
        width: width,
        height: height,
        now: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> rotateText({
    required String objectId,
    required double angleRadians,
  }) async {
    await _updateObject(
      objectId,
      (object) => object.rotate(
        angleRadians: angleRadians,
        now: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> restyleText({
    required String objectId,
    required String fontFamilyToken,
    required double fontSize,
    required int weight,
    required TextObjectAlignment alignment,
    required int colorValue,
    required double lineHeight,
  }) async {
    await _updateObject(
      objectId,
      (object) => object.restyle(
        fontFamilyToken: fontFamilyToken,
        fontSize: fontSize,
        weight: weight,
        alignment: alignment,
        colorValue: colorValue,
        lineHeight: lineHeight,
        now: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> reorderText({
    required String objectId,
    required int zIndex,
  }) async {
    await _updateObject(
      objectId,
      (object) =>
          object.reorder(newZIndex: zIndex, now: DateTime.now().toUtc()),
    );
  }

  Future<void> deleteText(String objectId) async {
    final current = state.asData?.value ?? const <TextObject>[];
    final updated = current.where((object) => object.id != objectId).toList();

    state = AsyncData(updated);

    try {
      await _repository.delete(objectId);
    } catch (error, stackTrace) {
      state = AsyncData(current);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.getObjectsForPage(_pageId),
    );
  }

  Future<void> _updateObject(
    String objectId,
    TextObject Function(TextObject object) update,
  ) async {
    final current = state.asData?.value ?? const <TextObject>[];
    final index = current.indexWhere((object) => object.id == objectId);

    if (index == -1) {
      return;
    }

    final updatedObject = update(current[index]);
    final updated = [...current]..[index] = updatedObject;

    state = AsyncData(updated);
    await _saveOrRestore(previous: current, object: updatedObject);
  }

  Future<void> _saveOrRestore({
    required List<TextObject> previous,
    required TextObject object,
  }) async {
    try {
      await _repository.save(object);
    } catch (error, stackTrace) {
      state = AsyncData(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

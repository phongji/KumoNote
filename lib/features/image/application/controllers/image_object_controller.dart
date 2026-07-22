// Copy all content into image_object_controller.dart (automatic z-index v6).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/image_object.dart';
import '../providers/image_providers.dart';

final imageObjectControllerProvider =
    AsyncNotifierProvider.family<
      ImageObjectController,
      List<ImageObject>,
      String
    >(ImageObjectController.new);

final class ImageObjectController extends AsyncNotifier<List<ImageObject>> {
  ImageObjectController(this._pageId);

  static const double _defaultWidth = 320;
  static const double _maximumInitialHeight = 420;

  final String _pageId;
  final Uuid _uuid = const Uuid();

  @override
  Future<List<ImageObject>> build() {
    return ref.read(imageObjectRepositoryProvider).getByPageId(_pageId);
  }

  Future<void> createImage({
    required String originalPath,
    required String checksum,
    required double sourceWidth,
    required double sourceHeight,
    required double pageWidth,
    required double pageHeight,
    String? previewPath,
    String? thumbnailPath,
    bool isOwnedFile = true,
  }) async {
    if (sourceWidth <= 0 || sourceHeight <= 0) {
      throw ArgumentError('Image dimensions must be greater than zero.');
    }

    final current = state.requireValue;
    final aspectRatio = sourceWidth / sourceHeight;
    var width = _defaultWidth.clamp(80, pageWidth * 0.8).toDouble();
    var height = width / aspectRatio;

    if (height > _maximumInitialHeight || height > pageHeight * 0.8) {
      height = _maximumInitialHeight.clamp(80, pageHeight * 0.8).toDouble();
      width = height * aspectRatio;
    }

    final now = DateTime.now().toUtc();
    final object = ImageObject(
      id: _uuid.v4(),
      pageId: _pageId,
      originalPath: originalPath,
      previewPath: previewPath,
      thumbnailPath: thumbnailPath,
      checksum: checksum,
      bounds: ImageObjectBounds(
        x: (pageWidth - width) / 2,
        y: (pageHeight - height) / 2,
        width: width,
        height: height,
      ),
      isOwnedFile: isOwnedFile,
      createdAt: now,
      updatedAt: now,
      version: 1,
      zIndex: now.microsecondsSinceEpoch,
    );

    await _saveChange(
      updatedObjects: [...current, object],
      changedObject: object,
      errorMessage: 'Unable to add the image.',
    );
  }

  Future<void> moveImage({
    required String objectId,
    required double deltaX,
    required double deltaY,
  }) async {
    await _transformObject(
      objectId: objectId,
      transform: (object) {
        return object.transform(
          newBounds: object.bounds.move(deltaX: deltaX, deltaY: deltaY),
          now: DateTime.now().toUtc(),
        );
      },
      errorMessage: 'Unable to move the image.',
    );
  }

  void previewMoveImage({
    required String objectId,
    required double deltaX,
    required double deltaY,
  }) {
    _previewTransform(
      objectId: objectId,
      transform: (object) {
        return object.transform(
          newBounds: object.bounds.move(deltaX: deltaX, deltaY: deltaY),
          now: DateTime.now().toUtc(),
        );
      },
    );
  }

  Future<void> resizeImage({
    required String objectId,
    required double width,
    required double height,
  }) async {
    await _transformObject(
      objectId: objectId,
      transform: (object) {
        return object.transform(
          newBounds: object.bounds.resize(newWidth: width, newHeight: height),
          now: DateTime.now().toUtc(),
        );
      },
      errorMessage: 'Unable to resize the image.',
    );
  }

  void previewResizeImage({
    required String objectId,
    required double width,
    required double height,
  }) {
    _previewTransform(
      objectId: objectId,
      transform: (object) {
        return object.transform(
          newBounds: object.bounds.resize(newWidth: width, newHeight: height),
          now: DateTime.now().toUtc(),
        );
      },
    );
  }

  Future<void> rotateImage({
    required String objectId,
    required double rotation,
  }) async {
    await _transformObject(
      objectId: objectId,
      transform: (object) {
        return object.transform(
          newBounds: object.bounds.copyWith(rotation: rotation),
          now: DateTime.now().toUtc(),
        );
      },
      errorMessage: 'Unable to rotate the image.',
    );
  }

  void previewRotateImage({
    required String objectId,
    required double rotation,
  }) {
    _previewTransform(
      objectId: objectId,
      transform: (object) {
        return object.transform(
          newBounds: object.bounds.copyWith(rotation: rotation),
          now: DateTime.now().toUtc(),
        );
      },
    );
  }

  Future<void> commitImageTransform(String objectId) async {
    final current = state.requireValue;
    final index = current.indexWhere((object) => object.id == objectId);

    if (index == -1) {
      throw StateError('Image object was not found.');
    }

    await ref.read(imageObjectRepositoryProvider).save(current[index]);
  }

  Future<void> setOpacity({
    required String objectId,
    required double opacity,
  }) async {
    await _transformObject(
      objectId: objectId,
      transform: (object) {
        return object.updateAppearance(
          newOpacity: opacity,
          now: DateTime.now().toUtc(),
        );
      },
      errorMessage: 'Unable to update the image.',
    );
  }

  Future<void> reorderImage({
    required String objectId,
    required int zIndex,
  }) async {
    await _transformObject(
      objectId: objectId,
      transform: (object) {
        return object.reorder(newZIndex: zIndex, now: DateTime.now().toUtc());
      },
      errorMessage: 'Unable to reorder the image.',
    );
  }

  Future<void> setCrop({
    required String objectId,
    required ImageCrop crop,
  }) async {
    await _transformObject(
      objectId: objectId,
      transform: (object) {
        final oldCropWidth = object.crop.right - object.crop.left;
        final oldCropHeight = object.crop.bottom - object.crop.top;
        final newCropWidth = crop.right - crop.left;
        final newCropHeight = crop.bottom - crop.top;

        final horizontalOffset =
            object.bounds.width *
            ((crop.left - object.crop.left) / oldCropWidth);
        final verticalOffset =
            object.bounds.height *
            ((crop.top - object.crop.top) / oldCropHeight);

        final newWidth = object.bounds.width * (newCropWidth / oldCropWidth);
        final newHeight =
            object.bounds.height * (newCropHeight / oldCropHeight);

        final appearance = object.updateAppearance(
          newCrop: crop,
          now: DateTime.now().toUtc(),
        );

        return appearance.transform(
          newBounds: appearance.bounds.copyWith(
            x: appearance.bounds.x + horizontalOffset,
            y: appearance.bounds.y + verticalOffset,
            width: newWidth,
            height: newHeight,
          ),
          now: DateTime.now().toUtc(),
        );
      },
      errorMessage: 'Unable to crop the image.',
    );
  }

  Future<void> duplicateImage(String objectId) async {
    final current = state.requireValue;
    final originalIndex = current.indexWhere((object) => object.id == objectId);

    if (originalIndex == -1) {
      throw StateError('Image object was not found.');
    }

    final original = current[originalIndex];
    final now = DateTime.now().toUtc();
    final duplicate = ImageObject(
      id: _uuid.v4(),
      pageId: original.pageId,
      originalPath: original.originalPath,
      previewPath: original.previewPath,
      thumbnailPath: original.thumbnailPath,
      checksum: original.checksum,
      bounds: original.bounds.move(deltaX: 24, deltaY: 24),
      crop: original.crop,
      opacity: original.opacity,
      isOwnedFile: original.isOwnedFile,
      createdAt: now,
      updatedAt: now,
      version: 1,
      zIndex: now.microsecondsSinceEpoch,
    );

    await _saveChange(
      updatedObjects: [...current, duplicate],
      changedObject: duplicate,
      errorMessage: 'Unable to copy the image.',
    );
  }

  Future<void> deleteImage(String objectId) async {
    final current = state.requireValue;
    final updatedObjects = current
        .where((object) => object.id != objectId)
        .toList(growable: false);

    state = AsyncData(updatedObjects);

    try {
      await ref.read(imageObjectRepositoryProvider).delete(objectId);
    } catch (error, stackTrace) {
      state = AsyncData(current);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(imageObjectRepositoryProvider).getByPageId(_pageId),
    );
  }

  Future<void> _transformObject({
    required String objectId,
    required ImageObject Function(ImageObject object) transform,
    required String errorMessage,
  }) async {
    final current = state.requireValue;
    final index = current.indexWhere((object) => object.id == objectId);

    if (index == -1) {
      throw StateError('Image object was not found.');
    }

    final changedObject = transform(current[index]);
    final updatedObjects = [...current]..[index] = changedObject;

    await _saveChange(
      updatedObjects: updatedObjects,
      changedObject: changedObject,
      errorMessage: errorMessage,
    );
  }

  void _previewTransform({
    required String objectId,
    required ImageObject Function(ImageObject object) transform,
  }) {
    final current = state.requireValue;
    final index = current.indexWhere((object) => object.id == objectId);

    if (index == -1) {
      return;
    }

    final updatedObjects = [...current]..[index] = transform(current[index]);
    state = AsyncData(updatedObjects);
  }

  Future<void> _saveChange({
    required List<ImageObject> updatedObjects,
    required ImageObject changedObject,
    required String errorMessage,
  }) async {
    final previous = state.requireValue;
    state = AsyncData(updatedObjects);

    try {
      await ref.read(imageObjectRepositoryProvider).save(changedObject);
    } catch (error, stackTrace) {
      state = AsyncData(previous);
      Error.throwWithStackTrace(StateError(errorMessage), stackTrace);
    }
  }
}

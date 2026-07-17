import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:UzhavuSei/theme/app_theme.dart';

class BorrowImageItem {
  final File? localFile;
  final String? remoteUrl;

  BorrowImageItem({this.localFile, this.remoteUrl});

  bool get isLocal => localFile != null;
  String get path => isLocal ? localFile!.path : remoteUrl!;
}

/// Helper class to optimize images in background isolates
class ImageOptimizer {
  static Future<File> optimize(File file) async {
    final tempDir = await getTemporaryDirectory();
    final params = {
      'inputPath': file.path,
      'tempDirPath': tempDir.path,
    };
    final String outputPath = await compute(_optimizeTask, params);
    return File(outputPath);
  }

  static Future<String> _optimizeTask(Map<String, String> params) async {
    final inputPath = params['inputPath']!;
    final tempDirPath = params['tempDirPath']!;

    final file = File(inputPath);
    final bytes = await file.readAsBytes();
    final decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) {
      throw Exception('Unable to optimize this image.');
    }

    img.Image resizedImage = decodedImage;
    // Resize if dimensions exceed 1920x1080 (maintaining aspect ratio)
    if (decodedImage.width > 1920 || decodedImage.height > 1080) {
      final double aspectRatio = decodedImage.width / decodedImage.height;
      if (aspectRatio > (1920 / 1080)) {
        resizedImage = img.copyResize(decodedImage, width: 1920);
      } else {
        resizedImage = img.copyResize(decodedImage, height: 1080);
      }
    }

    // Multi-stage compression to hit target size (300 KB to 800 KB, absolute max 2 MB)
    int quality = 85;
    List<int> jpgBytes = img.encodeJpg(resizedImage, quality: quality);

    // If still larger than 2MB, compress with lower quality down to 20
    while (jpgBytes.length > 2 * 1024 * 1024 && quality > 20) {
      quality -= 15;
      if (quality < 20) quality = 20;
      jpgBytes = img.encodeJpg(resizedImage, quality: quality);
    }

    // If still larger than 800KB but below 2MB, check if we can reduce to target range if quality remains high
    if (jpgBytes.length > 800 * 1024 && quality > 50) {
      int targetQuality = quality - 15;
      final targetJpgBytes = img.encodeJpg(resizedImage, quality: targetQuality);
      if (targetJpgBytes.length <= 2 * 1024 * 1024) {
        jpgBytes = targetJpgBytes;
      }
    }

    // Save to temp path
    final outputPath = '$tempDirPath/opt_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(jpgBytes);
    return outputPath;
  }
}

class BorrowImagePicker extends StatefulWidget {
  const BorrowImagePicker({
    super.key,
    required this.initialImages,
    required this.onImagesChanged,
    this.maxImages = 10,
  });

  final List<BorrowImageItem> initialImages;
  final ValueChanged<List<BorrowImageItem>> onImagesChanged;
  final int maxImages;

  @override
  State<BorrowImagePicker> createState() => _BorrowImagePickerState();
}

class _BorrowImagePickerState extends State<BorrowImagePicker> {
  final List<BorrowImageItem> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _optimizing = false;

  @override
  void initState() {
    super.initState();
    _images.addAll(widget.initialImages);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final img = await _picker.pickImage(source: ImageSource.camera);
        if (img != null) {
          await _processAndAddImage(File(img.path));
        }
      } else {
        final imgs = await _picker.pickMultiImage();
        if (imgs.isNotEmpty) {
          final countToTake = widget.maxImages - _images.length;
          final listToProcess = imgs.take(countToTake).toList();
          for (final img in listToProcess) {
            await _processAndAddImage(File(img.path));
          }
        }
      }
    } catch (e) {
      _showError('Failed to access device camera or gallery. Please check permissions.');
    }
  }

  Future<void> _processAndAddImage(File file) async {
    // 1. Validation (File extension only)
    final ext = file.path.split('.').last.toLowerCase();
    if (ext != 'jpg' && ext != 'jpeg' && ext != 'png') {
      _showError('Unsupported file type. Please upload JPG, JPEG, or PNG.');
      return;
    }

    // 2. Crop Image to 16:9
    final cropped = await ImageCropper().cropImage(
      sourcePath: file.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image (16:9)',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          aspectRatioPresets: [CropAspectRatioPreset.ratio16x9],
          initAspectRatio: CropAspectRatioPreset.ratio16x9,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Image (16:9)',
          aspectRatioPresets: [CropAspectRatioPreset.ratio16x9],
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (cropped == null) {
      // Crop cancelled by user
      return;
    }

    // 3. Optimize image in background
    setState(() {
      _optimizing = true;
    });

    try {
      final optimizedFile = await ImageOptimizer.optimize(File(cropped.path));
      
      // Double check file size after optimization
      if (optimizedFile.lengthSync() > 2 * 1024 * 1024) {
        _showError('Unable to optimize this image below 2 MB. Please choose another photo.');
        return;
      }

      setState(() {
        _images.add(BorrowImageItem(localFile: optimizedFile));
      });
      widget.onImagesChanged(_images);
    } catch (e) {
      _showError('Unable to optimize this image. Please choose another photo.');
    } finally {
      setState(() {
        _optimizing = false;
      });
    }
  }

  void _removeImage(int index) async {
    if (_images.length == 1) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Cover Photo?'),
          content: const Text('Listing requires at least one image. Deleting this will require you to add another.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() {
      _images.removeAt(index);
    });
    widget.onImagesChanged(_images);
  }

  void _showSourceBottomSheet() {
    if (_images.length >= widget.maxImages) {
      _showError('Maximum ${widget.maxImages} images allowed.');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Photos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.grey),
                title: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Listing Images',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEBEFF0)),
              ),
              child: _images.isEmpty
                  ? GestureDetector(
                      onTap: _showSourceBottomSheet,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 36),
                            SizedBox(height: 8),
                            Text(
                              'Upload Images (16:9 crop)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        // Horizontal scroll list of images
                        Expanded(
                          child: ReorderableListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            itemCount: _images.length,
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (oldIndex < newIndex) {
                                  newIndex -= 1;
                                }
                                final item = _images.removeAt(oldIndex);
                                _images.insert(newIndex, item);
                              });
                              widget.onImagesChanged(_images);
                            },
                            itemBuilder: (ctx, index) {
                              final img = _images[index];
                              return Card(
                                key: ValueKey(img.path + index.toString()),
                                margin: const EdgeInsets.only(right: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  children: [
                                    // Thumbnail Image
                                    img.isLocal
                                        ? Image.file(
                                            img.localFile!,
                                            width: 160,
                                            height: 120,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.network(
                                            img.remoteUrl!,
                                            width: 160,
                                            height: 120,
                                            fit: BoxFit.cover,
                                          ),

                                    // Cover Badge for index 0
                                    if (index == 0)
                                      Positioned(
                                        left: 8,
                                        bottom: 8,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          child: const Text(
                                            'Cover',
                                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),

                                    // Drag indicator / overlay hints
                                    Positioned(
                                      left: 8,
                                      top: 8,
                                      child: Icon(
                                        Icons.drag_indicator,
                                        color: Colors.white.withOpacity(0.8),
                                        size: 20,
                                      ),
                                    ),

                                    // Remove Button
                                    Positioned(
                                      right: 4,
                                      top: 4,
                                      child: GestureDetector(
                                        onTap: () => _removeImage(index),
                                        child: CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.black.withOpacity(0.6),
                                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        // Add Button at the end of the scroll list
                        if (_images.length < widget.maxImages)
                          Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: GestureDetector(
                              onTap: _showSourceBottomSheet,
                              child: Container(
                                width: 80,
                                height: 116,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add, color: AppColors.primary, size: 24),
                                    SizedBox(height: 4),
                                    Text(
                                      'Add More',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            if (_optimizing)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 12),
                        Text(
                          'Optimizing image...',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

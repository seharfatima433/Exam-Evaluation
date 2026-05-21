import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

final _sb = Supabase.instance.client;
const _bucket = 'nsct-materials';

enum NsctFileType { pdf, image, office, other }

NsctFileType detectType(String fileName) {
  final ext = fileName.split('.').last.toLowerCase();
  if (ext == 'pdf') return NsctFileType.pdf;
  if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) return NsctFileType.image;
  if (['pptx', 'ppt', 'docx', 'doc', 'xlsx', 'xls'].contains(ext)) return NsctFileType.office;
  return NsctFileType.other;
}

class NsctFile {
  final String name;
  final String publicUrl;
  final NsctFileType type;
  final int? sizeBytes;

  NsctFile({
    required this.name,
    required this.publicUrl,
    required this.type,
    this.sizeBytes,
  });

  String get sizeLabel {
    if (sizeBytes == null) return '';
    if (sizeBytes! < 1024) return '${sizeBytes}B';
    if (sizeBytes! < 1024 * 1024) return '${(sizeBytes! / 1024).toStringAsFixed(1)}KB';
    return '${(sizeBytes! / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  IconData get icon {
    switch (type) {
      case NsctFileType.pdf:    return Icons.picture_as_pdf_rounded;
      case NsctFileType.image:  return Icons.image_rounded;
      case NsctFileType.office: return Icons.description_rounded;
      case NsctFileType.other:  return Icons.insert_drive_file_rounded;
    }
  }

  Color get iconColor {
    switch (type) {
      case NsctFileType.pdf:    return const Color(0xFFB71C1C);
      case NsctFileType.image:  return const Color(0xFF00897B);
      case NsctFileType.office: return const Color(0xFF1565C0);
      case NsctFileType.other:  return const Color(0xFF6A1B9A);
    }
  }
}

class NsctStorageService {
  // Bucket structure (confirmed via screenshot):
  // nsct-materials / networks   / pdf-guide / file.pdf
  //                            / notes     / file.pdf
  //                            / mcqs      / file.pdf
  // Path = "$subjectFolder/$resourceType"
  static Future<List<NsctFile>> listFiles({
    required String subjectFolder,
    required String resourceType,
  }) async {
    final path = '$subjectFolder/$resourceType';
    try {
      debugPrint('NsctStorage: listing → $path');
      final objects = await _sb.storage.from(_bucket).list(path: path);
      debugPrint('NsctStorage: ${objects.length} objects returned');

      final files = objects.where((o) =>
      o.name.isNotEmpty &&
          o.name != '.emptyFolderPlaceholder' &&
          o.name != '.keep' &&
          o.name.contains('.'),
      ).toList();

      if (files.isEmpty) {
        debugPrint('NsctStorage: ❌ no files at $path');
        return [];
      }

      final result = files.map((o) {
        final filePath = '$path/${o.name}';
        final url = _sb.storage.from(_bucket).getPublicUrl(filePath);
        debugPrint('NsctStorage: ✅ ${o.name}');
        return NsctFile(
          name: o.name,
          publicUrl: url,
          type: detectType(o.name),
          sizeBytes: o.metadata?['size'] as int?,
        );
      }).toList();

      debugPrint('NsctStorage: ✅ ${result.length} files at $path');
      return result;
    } catch (e) {
      debugPrint('NsctStorage: error at $path → $e');
      return [];
    }
  }

  static Future<String?> uploadFile({
    required String subjectFolder,
    required String resourceType,
    required String fileName,
    required List<int> bytes,
  }) async {
    try {
      final path = '$subjectFolder/$resourceType/$fileName';
      await _sb.storage.from(_bucket).uploadBinary(
        path,
        Uint8List.fromList(bytes),
        fileOptions: const FileOptions(upsert: true),
      );
      return _sb.storage.from(_bucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('NsctStorage uploadFile error: $e');
      return null;
    }
  }

  static Future<bool> deleteFile({
    required String subjectFolder,
    required String resourceType,
    required String fileName,
  }) async {
    try {
      await _sb.storage.from(_bucket).remove(['$subjectFolder/$resourceType/$fileName']);
      return true;
    } catch (e) {
      debugPrint('NsctStorage deleteFile error: $e');
      return false;
    }
  }

  static Future<void> openFile(BuildContext context, NsctFile file) async {
    switch (file.type) {
      case NsctFileType.pdf:
        await _openPdf(context, file);
        break;
      case NsctFileType.image:
        _openImage(context, file);
        break;
      case NsctFileType.office:
      case NsctFileType.other:
        await _openInBrowser(file.publicUrl);
        break;
    }
  }

  // ✅ messenger pehle capture karo — async gap se pehle
  static Future<void> _openPdf(BuildContext context, NsctFile file) async {
    final messenger = ScaffoldMessenger.of(context);
    _snack(messenger, 'PDF is downloading...');
    try {
      final dir = await getTemporaryDirectory();
      final localPath = '${dir.path}/${file.name}';
      if (!await File(localPath).exists()) {
        await Dio().download(file.publicUrl, localPath);
      }
      await OpenFilex.open(localPath);
    } catch (e) {
      _snack(messenger, 'File can not open $e');
    }
  }

  static void _openImage(BuildContext context, NsctFile file) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => _ImageViewerScreen(file: file)));
  }

  static Future<void> _openInBrowser(String url) async {
    final uri = Uri.parse(
        'https://docs.google.com/viewer?url=${Uri.encodeComponent(url)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static void _snack(ScaffoldMessengerState messenger, String msg) {
    messenger.showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }
}

class _ImageViewerScreen extends StatelessWidget {
  final NsctFile file;
  const _ImageViewerScreen({required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(file.name,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            file.publicUrl,
            fit: BoxFit.contain,
            loadingBuilder: (ctx, child, progress) {
              if (progress == null) return child;
              return const CircularProgressIndicator(color: Colors.white);
            },
            errorBuilder: (ctx, err, stack) => const Icon(
                Icons.broken_image_rounded, color: Colors.white54, size: 64),
          ),
        ),
      ),
    );
  }
}
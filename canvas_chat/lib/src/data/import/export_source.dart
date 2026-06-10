import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Read-only view over a ChatGPT export, whether it is an extracted folder
/// or a `.zip` archive. File names are relative to the export root
/// (e.g. `export_manifest.json`, `conversations-000.json`, `file-….dat`).
abstract class ExportSource {
  /// Whether [name] exists in the export.
  bool exists(String name);

  /// Reads [name] as UTF-8 text.
  Future<String> readString(String name);

  /// Reads [name] as raw bytes.
  Future<Uint8List> readBytes(String name);

  /// Copies [name] to [destPath], creating parent directories as needed.
  Future<void> copyTo(String name, String destPath);

  /// Releases any underlying resources.
  Future<void> close();

  /// Opens [path] as either a folder or a zip export.
  static Future<ExportSource> open(String path) async {
    if (FileSystemEntity.isDirectorySync(path)) {
      return DirectoryExportSource(Directory(path));
    }
    return ZipExportSource.open(File(path));
  }
}

/// Export that has already been extracted to a folder.
class DirectoryExportSource implements ExportSource {
  DirectoryExportSource(this.root);

  final Directory root;

  File _file(String name) => File('${root.path}${Platform.pathSeparator}$name');

  @override
  bool exists(String name) => _file(name).existsSync();

  @override
  Future<String> readString(String name) => _file(name).readAsString();

  @override
  Future<Uint8List> readBytes(String name) => _file(name).readAsBytes();

  @override
  Future<void> copyTo(String name, String destPath) async {
    final dest = File(destPath);
    await dest.parent.create(recursive: true);
    await _file(name).copy(destPath);
  }

  @override
  Future<void> close() async {}
}

/// Export still packed in the official `.zip`.
///
/// Handles archives whose entries either sit at the root or share a single
/// top-level directory (both layouts occur in the wild).
class ZipExportSource implements ExportSource {
  ZipExportSource._(this._archive, this._byName);

  final Archive _archive;
  final Map<String, ArchiveFile> _byName;

  static Future<ZipExportSource> open(File zipFile) async {
    final archive = ZipDecoder().decodeBytes(await zipFile.readAsBytes());
    final byName = <String, ArchiveFile>{};
    for (final entry in archive.files) {
      if (!entry.isFile) continue;
      byName[_normalize(entry.name)] = entry;
    }
    return ZipExportSource._(archive, byName);
  }

  /// Strips a single shared top-level directory, if any, lazily per lookup:
  /// exact name first, then `<prefix>/<name>`.
  static String _normalize(String name) =>
      name.replaceAll('\\', '/').replaceFirst(RegExp(r'^\./'), '');

  ArchiveFile? _find(String name) {
    final exact = _byName[name];
    if (exact != null) return exact;
    // Fall back to a match under one directory level (zip-with-folder).
    ArchiveFile? found;
    for (final entry in _byName.entries) {
      final key = entry.key;
      if (key.endsWith('/$name') &&
          !key.substring(0, key.length - name.length - 1).contains('/')) {
        if (found != null) return null; // ambiguous
        found = entry.value;
      }
    }
    return found;
  }

  @override
  bool exists(String name) => _find(name) != null;

  @override
  Future<String> readString(String name) async =>
      utf8.decode(await readBytes(name));

  @override
  Future<Uint8List> readBytes(String name) async {
    final entry = _find(name);
    if (entry == null) {
      throw FileSystemException('Not found in zip', name);
    }
    return entry.readBytes() ?? Uint8List(0);
  }

  @override
  Future<void> copyTo(String name, String destPath) async {
    final dest = File(destPath);
    await dest.parent.create(recursive: true);
    await dest.writeAsBytes(await readBytes(name));
  }

  @override
  Future<void> close() async {
    await _archive.clear();
  }
}

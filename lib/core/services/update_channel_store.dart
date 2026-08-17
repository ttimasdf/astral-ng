import 'dart:io';

import 'package:astral/core/states/update_state.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class UpdateChannelStore {
  const UpdateChannelStore._();

  static const _fileName = 'update-channel.txt';

  static Future<File> _file() async {
    final directory = await getApplicationSupportDirectory();
    return File(path.join(directory.path, _fileName));
  }

  static Future<UpdateChannel?> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final value = (await file.readAsString()).trim();
      return UpdateChannel.parseStorage(value);
    } on FileSystemException {
      return null;
    }
  }

  static Future<void> write(UpdateChannel channel) async {
    final file = await _file();
    await file.writeAsString('${channel.name}\n', flush: true);
  }
}

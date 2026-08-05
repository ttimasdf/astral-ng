import 'dart:io';

import 'package:astral/core/models/all_settings.dart';
import 'package:astral/core/models/net_config.dart';
import 'package:astral/core/models/room.dart';
import 'package:astral/core/models/server_mod.dart';
import 'package:astral/core/models/magic_wall_model.dart';
import 'package:astral/core/database/dao/all_settings_dao.dart';
import 'package:astral/core/database/dao/net_config_dao.dart';
import 'package:astral/core/database/dao/room_dao.dart';
import 'package:astral/core/database/dao/server_dao.dart';
import 'package:astral/core/database/dao/magic_wall_dao.dart';
import 'package:isar_community/isar.dart';
import 'package:astral/core/models/theme_settings.dart';
import 'package:astral/core/database/dao/theme_settings_dao.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  late Isar isar;
  late ThemeSettingsDao themeSettings;
  late NetConfigDao netConfig;
  late RoomDao rooms;
  late AllSettingsDao allSettings;
  late ServerDao servers;
  late MagicWallDao magicWall;
  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    final supportDirectory = await getApplicationSupportDirectory();
    final databaseDirectory = Directory(p.join(supportDirectory.path, 'db'));
    await databaseDirectory.create(recursive: true);
    isar = await Isar.open([
      ThemeSettingsSchema,
      NetConfigSchema,
      RoomSchema,
      AllSettingsSchema,
      ServerModSchema,
      MagicWallRuleModelSchema,
      MagicWallGroupModelSchema,
      MagicWallEventLogModelSchema,
    ], directory: databaseDirectory.path);
    themeSettings = ThemeSettingsDao(isar);
    netConfig = NetConfigDao(isar);
    rooms = RoomDao(isar);
    allSettings = AllSettingsDao(isar);
    servers = ServerDao(isar);
    magicWall = MagicWallDao(isar);

    await rooms.init();
    await servers.init();
    _initialized = true;
  }
}

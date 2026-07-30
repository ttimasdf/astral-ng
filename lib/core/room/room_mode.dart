import 'package:astral/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

/// Presentation names for the two ways a room gets its EasyTier credentials.
class RoomMode {
  const RoomMode._();

  /// Simple mode generates private credentials; advanced mode accepts them.
  static String label(bool usesGeneratedCredentials) =>
      usesGeneratedCredentials
          ? LocaleKeys.room_mode_simple.tr()
          : LocaleKeys.room_mode_advanced.tr();
}

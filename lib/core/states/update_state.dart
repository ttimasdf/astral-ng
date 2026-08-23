import 'package:signals_flutter/signals_flutter.dart';

enum UpdateChannel {
  stable,
  beta,
  alpha;

  static UpdateChannel? parseStorage(String? value) {
    for (final channel in UpdateChannel.values) {
      if (channel.name == value) return channel;
    }
    return null;
  }

  static UpdateChannel fromStorage(
    String? value, {
    required bool legacyReceiveBetaUpdates,
  }) {
    return parseStorage(value) ??
        (legacyReceiveBetaUpdates ? UpdateChannel.beta : UpdateChannel.stable);
  }
}

/// Update preferences and runtime state.
class UpdateState {
  final channel = signal(UpdateChannel.stable);
  final automaticUpdateChecks = signal(true);

  void setChannel(UpdateChannel value) {
    channel.value = value;
  }

  void selectChannel(UpdateChannel value) {
    channel.value = value;
    if (value != UpdateChannel.stable) {
      automaticUpdateChecks.value = true;
    }
  }

  void setAutomaticUpdateChecks(bool value) {
    automaticUpdateChecks.value = value;
  }
}

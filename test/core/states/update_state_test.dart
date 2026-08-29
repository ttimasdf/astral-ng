import 'package:enmesh/core/states/update_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('migrates the legacy beta preference when no channel is stored', () {
    expect(
      UpdateChannel.fromStorage(null, legacyReceiveBetaUpdates: false),
      UpdateChannel.stable,
    );
    expect(
      UpdateChannel.fromStorage(null, legacyReceiveBetaUpdates: true),
      UpdateChannel.beta,
    );
    expect(
      UpdateChannel.fromStorage('alpha', legacyReceiveBetaUpdates: false),
      UpdateChannel.alpha,
    );
  });

  test('preview selection enables checks without forcing them permanently', () {
    final state = UpdateState();
    state.setAutomaticUpdateChecks(false);

    state.selectChannel(UpdateChannel.beta);
    expect(state.channel.value, UpdateChannel.beta);
    expect(state.automaticUpdateChecks.value, isTrue);

    state.setAutomaticUpdateChecks(false);
    expect(state.automaticUpdateChecks.value, isFalse);

    state.selectChannel(UpdateChannel.alpha);
    expect(state.automaticUpdateChecks.value, isTrue);
  });
}

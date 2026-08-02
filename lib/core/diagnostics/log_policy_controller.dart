import 'package:flutter/foundation.dart';
import 'package:astral/core/diagnostics/log_policy.dart';

final class LogPolicyController extends ValueNotifier<LogPolicy> {
  LogPolicyController(super.value);

  void replace(LogPolicy policy) {
    value = policy;
  }
}

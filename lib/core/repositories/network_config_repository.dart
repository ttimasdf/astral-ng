import 'package:enmesh/core/database/app_data.dart';
import 'package:enmesh/core/models/net_config.dart';

/// 网络配置持久化（单例 [NetConfig]）
class NetworkConfigRepository {
  final AppDatabase _db;

  NetworkConfigRepository(this._db);

  Future<NetConfig> get() => _db.netConfig.get();

  Future<void> update(void Function(NetConfig config) mutate) =>
      _db.netConfig.update(mutate);

  Future<bool> getPreferEnmeshAdapter() async =>
      (await _db.allSettings.get()).preferEnmeshAdapter;

  Future<void> setPreferEnmeshAdapter(bool value) =>
      _db.allSettings.update((s) => s.preferEnmeshAdapter = value);
}

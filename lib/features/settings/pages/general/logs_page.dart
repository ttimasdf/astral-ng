import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:astral/core/diagnostics/diagnostic_formatter.dart';
import 'package:astral/core/diagnostics/diagnostic_modules.dart';
import 'package:astral/core/diagnostics/diagnostic_record.dart';
import 'package:astral/core/diagnostics/diagnostics_runtime.dart';
import 'package:astral/core/diagnostics/log_policy.dart';
import 'package:astral/core/diagnostics/log_severity.dart';
import 'package:astral/core/diagnostics/support_bundle.dart';
import 'package:astral/core/ui/app_snack_bars.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key, this.initialErrorId});

  final String? initialErrorId;

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _eventCodeController = TextEditingController();
  final TextEditingController _sessionController = TextEditingController();
  final TextEditingController _operationController = TextEditingController();
  final TextEditingController _attemptController = TextEditingController();
  late final TextEditingController _errorController;
  LogSeverity? _minimumLevel;
  String? _module;
  String? _origin;
  bool _paused = false;
  bool _autoScroll = true;
  List<DiagnosticRecord>? _pausedRecords;

  DiagnosticsRuntime get _diagnostics => Diagnostics.runtime;

  @override
  void initState() {
    super.initState();
    _errorController = TextEditingController(text: widget.initialErrorId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _eventCodeController.dispose();
    _sessionController.dispose();
    _operationController.dispose();
    _attemptController.dispose();
    _errorController.dispose();
    super.dispose();
  }

  List<DiagnosticRecord> _filter(List<DiagnosticRecord> records) {
    final query = _searchController.text.trim().toLowerCase();
    return records
        .where((record) {
          if (_minimumLevel != null &&
              record.level.index < _minimumLevel!.index) {
            return false;
          }
          if (_module != null && !record.module.startsWith(_module!)) {
            return false;
          }
          if (_origin != null && record.origin != _origin) return false;
          if (!_matches(record.eventCode, _eventCodeController.text)) {
            return false;
          }
          if (!_matches(record.sessionId, _sessionController.text)) {
            return false;
          }
          if (!_matches(record.operationId, _operationController.text)) {
            return false;
          }
          if (!_matches(record.connectionAttemptId, _attemptController.text)) {
            return false;
          }
          if (!_matches(record.errorId, _errorController.text)) return false;
          if (query.isEmpty) return true;
          return record.message.toLowerCase().contains(query) ||
              record.eventCode.toLowerCase().contains(query) ||
              record.module.toLowerCase().contains(query) ||
              record.fields.toString().toLowerCase().contains(query) ||
              (record.errorMessage?.toLowerCase().contains(query) ?? false) ||
              (record.errorId?.toLowerCase().contains(query) ?? false);
        })
        .toList(growable: false);
  }

  bool _matches(String? value, String query) {
    final normalized = query.trim().toLowerCase();
    return normalized.isEmpty ||
        (value?.toLowerCase().contains(normalized) ?? false);
  }

  int get _advancedFilterCount =>
      [
        _origin,
        _eventCodeController.text,
        _sessionController.text,
        _operationController.text,
        _attemptController.text,
        _errorController.text,
      ].where((value) => value != null && value.trim().isNotEmpty).length;

  Future<void> _copyRecords(List<DiagnosticRecord> records) async {
    if (records.isEmpty) {
      AppSnackBars.info(context, '提示', '暂无日志可复制');
      return;
    }
    final text = records.map(_formatRecordWithDetails).join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    AppSnackBars.success(context, '复制成功', '已复制 ${records.length} 条日志到剪贴板');
  }

  Future<void> _copySupportBundle(List<DiagnosticRecord> records) async {
    final approved = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('复制支持包'),
            content: const Text(
              '支持包包含已脱敏的诊断记录、会话、版本、平台、日志策略和接收器状态。'
              '其中仍可能包含网络标识符，请在分享前检查内容。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('复制'),
              ),
            ],
          ),
    );
    if (approved != true || !mounted) return;
    final bundle = SupportBundle.encode(
      diagnostics: _diagnostics,
      records: records,
    );
    await Clipboard.setData(ClipboardData(text: bundle));
    Diagnostics.logger(DiagnosticModules.logging).info(
      'support-bundle.copied',
      'Redacted support bundle copied',
      fields: {'record_count': records.length},
    );
    if (!mounted) return;
    AppSnackBars.success(context, '复制成功', '支持包已复制到剪贴板');
  }

  String _formatRecordWithDetails(DiagnosticRecord record) {
    final details = DiagnosticFormatter.details(record);
    return details.isEmpty
        ? DiagnosticFormatter.console(record)
        : '${DiagnosticFormatter.console(record)}\n$details';
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _togglePaused(List<DiagnosticRecord> current) {
    setState(() {
      _paused = !_paused;
      _pausedRecords = _paused ? List.unmodifiable(current) : null;
    });
  }

  void _showAdvancedFilters(List<DiagnosticRecord> records) {
    final origins =
        records.map((record) => record.origin).toSet().toList()..sort();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => _AdvancedFilterSheet(
            origins: origins,
            origin: _origin,
            eventCodeController: _eventCodeController,
            sessionController: _sessionController,
            operationController: _operationController,
            attemptController: _attemptController,
            errorController: _errorController,
            onChanged: (origin) => setState(() => _origin = origin),
            onClear: () {
              setState(() {
                _origin = null;
                _eventCodeController.clear();
                _sessionController.clear();
                _operationController.clear();
                _attemptController.clear();
                _errorController.clear();
              });
            },
          ),
    );
  }

  void _showPolicySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _LogPolicySheet(diagnostics: _diagnostics),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Hero(
          tag: 'logs_hero',
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text('诊断日志'),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: '复制脱敏支持包',
            onPressed: () => _copySupportBundle(_diagnostics.store.value),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: '日志模块设置',
            onPressed: _showPolicySheet,
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: '清空内存日志',
            onPressed: _confirmClear,
          ),
        ],
      ),
      body: ValueListenableBuilder<List<DiagnosticRecord>>(
        valueListenable: _diagnostics.store,
        builder: (context, liveRecords, _) {
          final source = _pausedRecords ?? liveRecords;
          final records = _filter(source);
          final modules =
              liveRecords.map((record) => record.module).toSet().toList()
                ..sort();
          final suppressedCount = liveRecords
              .where(
                (record) => record.eventCode == 'logging.records.suppressed',
              )
              .fold<int>(
                0,
                (total, record) =>
                    total + ((record.fields['count'] as num?)?.toInt() ?? 0),
              );
          if (_autoScroll && !_paused) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(
                  _scrollController.position.maxScrollExtent,
                );
              }
            });
          }

          return Column(
            children: [
              _FilterBar(
                searchController: _searchController,
                minimumLevel: _minimumLevel,
                module: _module,
                modules: modules,
                paused: _paused,
                visibleCount: records.length,
                totalCount: source.length,
                onSearchChanged: (_) => setState(() {}),
                onLevelChanged:
                    (value) => setState(() => _minimumLevel = value),
                onModuleChanged: (value) => setState(() => _module = value),
                autoScroll: _autoScroll,
                advancedFilterCount: _advancedFilterCount,
                suppressedCount: suppressedCount,
                evictedCount: _diagnostics.store.evictedRecords,
                onPause: () => _togglePaused(liveRecords),
                onAutoScroll: () => setState(() => _autoScroll = !_autoScroll),
                onAdvancedFilters: () => _showAdvancedFilters(liveRecords),
                onCopy: () => _copyRecords(records),
              ),
              Expanded(
                child:
                    records.isEmpty
                        ? const _EmptyLogs()
                        : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 88),
                          itemCount: records.length,
                          itemBuilder:
                              (context, index) => _DiagnosticRecordCard(
                                record: records[index],
                                onCopy: () => _copyRecords([records[index]]),
                              ),
                        ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scrollToBottom,
        tooltip: '滚动到底部',
        heroTag: 'logs_fab',
        child: const Icon(Icons.keyboard_arrow_down),
      ),
    );
  }

  void _confirmClear() {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认清空'),
            content: const Text('仅清空当前内存中的诊断日志，持久化文件不会被删除。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  _diagnostics.store.clear();
                  setState(() => _pausedRecords = null);
                  Navigator.pop(context);
                  AppSnackBars.success(context, '已清空', '内存日志已清空');
                },
                child: const Text('确定'),
              ),
            ],
          ),
    );
  }
}

final class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.searchController,
    required this.minimumLevel,
    required this.module,
    required this.modules,
    required this.paused,
    required this.autoScroll,
    required this.advancedFilterCount,
    required this.suppressedCount,
    required this.evictedCount,
    required this.visibleCount,
    required this.totalCount,
    required this.onSearchChanged,
    required this.onLevelChanged,
    required this.onModuleChanged,
    required this.onPause,
    required this.onAutoScroll,
    required this.onAdvancedFilters,
    required this.onCopy,
  });

  final TextEditingController searchController;
  final LogSeverity? minimumLevel;
  final String? module;
  final List<String> modules;
  final bool paused;
  final bool autoScroll;
  final int advancedFilterCount;
  final int suppressedCount;
  final int evictedCount;
  final int visibleCount;
  final int totalCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<LogSeverity?> onLevelChanged;
  final ValueChanged<String?> onModuleChanged;
  final VoidCallback onPause;
  final VoidCallback onAutoScroll;
  final VoidCallback onAdvancedFilters;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.search),
              hintText: '搜索消息、事件、模块、错误 ID…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<LogSeverity?>(
                  initialValue: minimumLevel,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: '最低级别',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('全部')),
                    ...LogSeverity.values.map(
                      (level) => DropdownMenuItem(
                        value: level,
                        child: Text(level.name.toUpperCase()),
                      ),
                    ),
                  ],
                  onChanged: onLevelChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: module,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: '模块',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('全部模块')),
                    ...modules.map(
                      (name) => DropdownMenuItem(
                        value: name,
                        child: Text(
                          name.replaceFirst('astral.', ''),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: onModuleChanged,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onPause,
                  tooltip: paused ? '恢复实时更新' : '暂停实时更新',
                  icon: Icon(paused ? Icons.play_arrow : Icons.pause),
                ),
                IconButton(
                  onPressed: onAutoScroll,
                  tooltip: autoScroll ? '关闭自动滚动' : '开启自动滚动',
                  icon: Icon(
                    Icons.vertical_align_bottom,
                    color:
                        autoScroll
                            ? Theme.of(context).colorScheme.primary
                            : null,
                  ),
                ),
                IconButton(
                  onPressed: onAdvancedFilters,
                  tooltip: '关联和来源筛选',
                  icon:
                      advancedFilterCount == 0
                          ? const Icon(Icons.filter_list)
                          : Badge.count(
                            count: advancedFilterCount,
                            child: const Icon(Icons.filter_list),
                          ),
                ),
                IconButton(
                  onPressed: onCopy,
                  tooltip: '复制当前筛选结果',
                  icon: const Icon(Icons.copy_all),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$visibleCount / $totalCount 条${paused ? ' · 已暂停' : ''}'
              '${suppressedCount > 0 ? ' · 抑制 $suppressedCount' : ''}'
              '${evictedCount > 0 ? ' · 内存淘汰 $evictedCount' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

final class _AdvancedFilterSheet extends StatefulWidget {
  const _AdvancedFilterSheet({
    required this.origins,
    required this.origin,
    required this.eventCodeController,
    required this.sessionController,
    required this.operationController,
    required this.attemptController,
    required this.errorController,
    required this.onChanged,
    required this.onClear,
  });

  final List<String> origins;
  final String? origin;
  final TextEditingController eventCodeController;
  final TextEditingController sessionController;
  final TextEditingController operationController;
  final TextEditingController attemptController;
  final TextEditingController errorController;
  final ValueChanged<String?> onChanged;
  final VoidCallback onClear;

  @override
  State<_AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

final class _AdvancedFilterSheetState extends State<_AdvancedFilterSheet> {
  String? _origin;

  @override
  void initState() {
    super.initState();
    _origin = widget.origin;
  }

  void _textChanged(String _) => widget.onChanged(_origin);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text('关联和来源筛选', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _origin,
              decoration: const InputDecoration(
                labelText: '来源',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('全部来源')),
                ...widget.origins.map(
                  (origin) =>
                      DropdownMenuItem(value: origin, child: Text(origin)),
                ),
              ],
              onChanged: (origin) {
                setState(() => _origin = origin);
                widget.onChanged(origin);
              },
            ),
            const SizedBox(height: 12),
            _filterField('事件代码', widget.eventCodeController),
            _filterField('会话 ID', widget.sessionController),
            _filterField('操作 ID', widget.operationController),
            _filterField('连接尝试 ID', widget.attemptController),
            _filterField('错误 ID', widget.errorController),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() => _origin = null);
                    widget.onClear();
                  },
                  child: const Text('清除筛选'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('完成'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        onChanged: _textChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

final class _DiagnosticRecordCard extends StatelessWidget {
  const _DiagnosticRecordCard({required this.record, required this.onCopy});

  final DiagnosticRecord record;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final color = switch (record.level) {
      LogSeverity.trace => Colors.grey,
      LogSeverity.debug => Colors.blueGrey,
      LogSeverity.info => Colors.blue,
      LogSeverity.warning => Colors.orange,
      LogSeverity.error || LogSeverity.fatal => Colors.red,
    };
    final icon = switch (record.level) {
      LogSeverity.trace || LogSeverity.debug => Icons.code,
      LogSeverity.info => Icons.info_outline,
      LogSeverity.warning => Icons.warning_amber_outlined,
      LogSeverity.error || LogSeverity.fatal => Icons.error_outline,
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ExpansionTile(
        leading: Icon(icon, color: color, size: 20),
        title: Text(
          '${record.level.token}  ${record.module.replaceFirst('astral.', '')}  '
          '${record.eventCode}',
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            color: color,
            fontWeight: record.isError ? FontWeight.w700 : null,
          ),
        ),
        subtitle: Text(record.message),
        trailing: IconButton(
          icon: const Icon(Icons.copy, size: 16),
          tooltip: '复制此条日志',
          onPressed: onCopy,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            DiagnosticFormatter.console(record),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
          if (record.errorMessage != null) ...[
            const SizedBox(height: 8),
            SelectableText(
              record.errorMessage!,
              style: TextStyle(color: color, fontFamily: 'monospace'),
            ),
          ],
          if (record.stackTrace != null) ...[
            const SizedBox(height: 8),
            SelectableText(
              record.stackTrace!,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

final class _EmptyLogs extends StatelessWidget {
  const _EmptyLogs();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('暂无匹配的诊断日志', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

final class _LogPolicySheet extends StatelessWidget {
  const _LogPolicySheet({required this.diagnostics});

  final DiagnosticsRuntime diagnostics;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder:
            (context, controller) => ValueListenableBuilder<LogPolicy>(
              valueListenable: diagnostics.policy,
              builder:
                  (context, policy, _) => ListView(
                    controller: controller,
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        '日志策略',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text('当前：${policy.name} · 配置立即应用于所有 Dart 模块'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed:
                                () => diagnostics.policy.replace(
                                  LogPolicy.productionDefaults(),
                                ),
                            child: const Text('Production'),
                          ),
                          OutlinedButton(
                            onPressed:
                                () => diagnostics.policy.replace(
                                  LogPolicy.debugDefaults(),
                                ),
                            child: const Text('Debug'),
                          ),
                          FilledButton(
                            onPressed:
                                () => diagnostics.policy.startDiagnosticSession(
                                  moduleLevels: const {
                                    DiagnosticModules.connection:
                                        LogSeverity.trace,
                                    DiagnosticModules.vpn: LogSeverity.trace,
                                    DiagnosticModules.easyTier:
                                        LogSeverity.debug,
                                    DiagnosticModules.easyTierTunnel:
                                        LogSeverity.warning,
                                  },
                                ),
                            child: const Text('15 分钟连接诊断'),
                          ),
                          if (diagnostics.policy.isDiagnosticSession)
                            TextButton(
                              onPressed:
                                  diagnostics.policy.stopDiagnosticSession,
                              child: const Text('停止诊断会话'),
                            ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final header = SupportBundle.encode(
                                diagnostics: diagnostics,
                                records: const [],
                              );
                              await Clipboard.setData(
                                ClipboardData(text: header),
                              );
                              if (!context.mounted) return;
                              AppSnackBars.success(
                                context,
                                '复制成功',
                                '会话、策略和接收器状态已复制',
                              );
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('复制会话/策略'),
                          ),
                        ],
                      ),
                      const Divider(height: 28),
                      const Text('模块级别（同时应用到控制台、内存和文件）'),
                      const SizedBox(height: 8),
                      ...DiagnosticModules.all.map((module) {
                        final effective = policy.minimumLevel(
                          module,
                          DiagnosticDestination.console,
                        );
                        return ListTile(
                          dense: true,
                          title: Text(module.replaceFirst('astral.', '')),
                          subtitle: Text('有效级别：${effective?.name ?? 'off'}'),
                          trailing: DropdownButton<LogSeverity?>(
                            value: effective,
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('OFF'),
                              ),
                              ...LogSeverity.values.map(
                                (level) => DropdownMenuItem(
                                  value: level,
                                  child: Text(level.token),
                                ),
                              ),
                            ],
                            onChanged:
                                (level) => diagnostics.policy.setModuleLevel(
                                  module,
                                  level,
                                ),
                          ),
                        );
                      }),
                      const Divider(height: 28),
                      Text(
                        '接收器状态',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ...diagnostics.sinkHealth.entries.map(
                        (entry) => ListTile(
                          dense: true,
                          leading: Icon(
                            entry.value['healthy'] == false ||
                                    entry.value['failed'] == true
                                ? Icons.error_outline
                                : Icons.check_circle_outline,
                          ),
                          title: Text(entry.key),
                          subtitle: Text(
                            entry.value.entries
                                .map((item) => '${item.key}=${item.value}')
                                .join(' · '),
                          ),
                        ),
                      ),
                      const Divider(height: 28),
                      Text(
                        '选择正确的排查工具',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• 状态转换与失败：本页结构化日志\n'
                        '• 数据包：tcpdump / Wireshark\n'
                        '• 路由、TUN、VPN：系统 IP/route 工具或 Android dumpsys\n'
                        '• EasyTier 连接与拓扑：房间拓扑和运行状态 API\n'
                        '• UI 卡顿与内存：Flutter DevTools Performance / Memory\n'
                        '• Android 服务重启：adb logcat 与系统服务诊断\n\n'
                        '错误和致命错误始终保留在紧急控制台和内存中。'
                        '复制内容可能包含网络标识符，请在分享前检查。',
                      ),
                    ],
                  ),
            ),
      ),
    );
  }
}

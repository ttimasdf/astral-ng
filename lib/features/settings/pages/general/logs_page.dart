import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:astral/core/diagnostics/diagnostic_formatter.dart';
import 'package:astral/core/diagnostics/diagnostic_modules.dart';
import 'package:astral/core/diagnostics/diagnostic_record.dart';
import 'package:astral/core/diagnostics/diagnostics_runtime.dart';
import 'package:astral/core/diagnostics/log_policy.dart';
import 'package:astral/core/diagnostics/log_severity.dart';
import 'package:astral/core/ui/app_snack_bars.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  LogSeverity? _minimumLevel;
  String? _module;
  bool _paused = false;
  List<DiagnosticRecord>? _pausedRecords;

  DiagnosticsRuntime get _diagnostics => Diagnostics.runtime;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
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
                onPause: () => _togglePaused(liveRecords),
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
    required this.visibleCount,
    required this.totalCount,
    required this.onSearchChanged,
    required this.onLevelChanged,
    required this.onModuleChanged,
    required this.onPause,
    required this.onCopy,
  });

  final TextEditingController searchController;
  final LogSeverity? minimumLevel;
  final String? module;
  final List<String> modules;
  final bool paused;
  final int visibleCount;
  final int totalCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<LogSeverity?> onLevelChanged;
  final ValueChanged<String?> onModuleChanged;
  final VoidCallback onPause;
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
              IconButton(
                onPressed: onPause,
                tooltip: paused ? '恢复实时更新' : '暂停实时更新',
                icon: Icon(paused ? Icons.play_arrow : Icons.pause),
              ),
              IconButton(
                onPressed: onCopy,
                tooltip: '复制当前筛选结果',
                icon: const Icon(Icons.copy_all),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$visibleCount / $totalCount 条${paused ? ' · 已暂停' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
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
                      const SizedBox(height: 16),
                      const Text(
                        '错误和致命错误始终保留在紧急控制台和内存中。'
                        '高频数据包排查请使用 tcpdump/Wireshark。',
                      ),
                    ],
                  ),
            ),
      ),
    );
  }
}

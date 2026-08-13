import 'package:astral/features/rooms/pages/room_page.dart';
import 'package:astral/features/rooms/utils/random_name.dart';
import 'package:astral/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Future<void> showAddRoomDialog(BuildContext context) async {
  bool simpleMode = true;
  String? name = RandomName();
  String? roomName;
  String? roomPassword;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('添加房间'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: TextEditingController(text: name),
                  decoration: const InputDecoration(labelText: '房间名称'),
                  // 当文本字段内容改变时，同步更新外部 'name' 变量
                  onChanged: (value) => name = value,
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    LocaleKeys.room_mode.tr(),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                RadioGroup<bool>(
                  groupValue: simpleMode,
                  onChanged: (value) => setState(() => simpleMode = value!),
                  child: Column(
                    children: [
                      RadioListTile<bool>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(LocaleKeys.room_mode_simple.tr()),
                        subtitle: Text(LocaleKeys.room_mode_simple_desc.tr()),
                        value: true,
                      ),
                      RadioListTile<bool>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(LocaleKeys.room_mode_advanced.tr()),
                        subtitle: Text(LocaleKeys.room_mode_advanced_desc.tr()),
                        value: false,
                      ),
                    ],
                  ),
                ),

                if (!simpleMode) ...[
                  TextField(
                    decoration: const InputDecoration(labelText: '房间号'),
                    onChanged: (value) => roomName = value,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(labelText: '房间密码'),
                    onChanged: (value) => roomPassword = value,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  addRoomForMode(
                    simpleMode,
                    name ?? RandomName(),
                    roomName ?? "",
                    roomPassword ?? "",
                  );
                  Navigator.of(context).pop();
                },
                child: const Text('确定'),
              ),
            ],
          );
        },
      );
    },
  );
}

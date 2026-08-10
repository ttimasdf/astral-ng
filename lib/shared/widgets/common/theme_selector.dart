import 'package:astral/core/services/service_manager.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

void showThemeColorPicker(BuildContext context) {
  final currentColor = ServiceManager().themeState.themeColor.value;
  var previewColor = currentColor;

  showDialog<void>(
    context: context,
    builder:
        (context) => StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: Text('select_theme_color'.tr()),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BlockPicker(
                        pickerColor: previewColor,
                        onColorChanged: (color) {
                          setState(() => previewColor = color);
                          ServiceManager().theme.updateThemeColor(color);
                        },
                        availableColors: const [
                          Colors.red,
                          Colors.pink,
                          Colors.purple,
                          Colors.deepPurple,
                          Colors.indigo,
                          Colors.blue,
                          Colors.lightBlue,
                          Colors.cyan,
                          Colors.teal,
                          Colors.green,
                          Colors.lightGreen,
                          Colors.lime,
                          Colors.yellow,
                          Colors.amber,
                          Colors.orange,
                          Colors.deepOrange,
                          Colors.brown,
                          Colors.grey,
                          Colors.blueGrey,
                        ],
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.color_lens),
                        label: Text('custom_color'.tr()),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showAdvancedColorPicker(context, previewColor);
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      ServiceManager().theme.updateThemeColor(currentColor);
                      Navigator.of(context).pop();
                    },
                    child: Text('cancel'.tr()),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('confirm'.tr()),
                  ),
                ],
              ),
        ),
  );
}

void _showAdvancedColorPicker(BuildContext context, Color initialColor) {
  var pickerColor = initialColor;
  final currentColor = ServiceManager().themeState.themeColor.value;

  showDialog<void>(
    context: context,
    builder:
        (context) => StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: Text('custom_color'.tr()),
                content: SingleChildScrollView(
                  child: ColorPicker(
                    pickerColor: pickerColor,
                    onColorChanged: (color) {
                      setState(() => pickerColor = color);
                      ServiceManager().theme.updateThemeColor(color);
                    },
                    pickerAreaHeightPercent: 0.8,
                    enableAlpha: false,
                    displayThumbColor: true,
                    paletteType: PaletteType.hsvWithHue,
                    pickerAreaBorderRadius: const BorderRadius.all(
                      Radius.circular(10),
                    ),
                    labelTypes: const [ColorLabelType.rgb, ColorLabelType.hex],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      ServiceManager().theme.updateThemeColor(currentColor);
                      Navigator.of(context).pop();
                    },
                    child: Text('cancel'.tr()),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('confirm'.tr()),
                  ),
                ],
              ),
        ),
  );
}

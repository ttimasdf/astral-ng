import 'package:enmesh/features/rooms/widgets/nat_visual_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes exact NAT values into the six shared families', () {
    const light = ColorScheme.light();
    expect(
      NatVisualStyle.resolve('OpenInternet', light).family,
      NatFamily.public,
    );
    expect(NatVisualStyle.resolve('NoPat', light).family, NatFamily.public);
    expect(
      NatVisualStyle.resolve('FullCone', light).family,
      NatFamily.fullCone,
    );
    expect(
      NatVisualStyle.resolve('Restricted', light).family,
      NatFamily.restricted,
    );
    expect(
      NatVisualStyle.resolve('PortRestricted', light).family,
      NatFamily.portRestricted,
    );
    expect(
      NatVisualStyle.resolve('SymmetricEasyInc', light).family,
      NatFamily.symmetric,
    );
    expect(
      NatVisualStyle.resolve('unexpected', light).family,
      NatFamily.unknown,
    );
  });

  test('light and dark styles maintain distinct contrast-safe foregrounds', () {
    final light = NatVisualStyle.resolve(
      'Restricted',
      const ColorScheme.light(),
    );
    final dark = NatVisualStyle.resolve('Restricted', const ColorScheme.dark());

    expect(light.foreground, isNot(dark.foreground));
    expect(light.border.a, greaterThan(0));
    expect(light.background.a, greaterThan(0));
  });

  test('all legend families have a style and label', () {
    final scheme = const ColorScheme.light();
    for (final family in NatVisualStyle.legendFamilies) {
      final style = NatVisualStyle.forFamily(family, scheme);
      expect(style.labelKey, isNotEmpty);
      expect(style.icon, isNotNull);
      expect(style.border.a, greaterThan(0));
    }
  });
}

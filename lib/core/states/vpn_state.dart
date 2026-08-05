import 'package:signals_flutter/signals_flutter.dart';

/// Android VPN 路由状态
class VpnState {
  final androidVpnRoutes = signal<List<String>>([]);

  void setAndroidVpnRoutes(List<String> routes) {
    androidVpnRoutes.value = routes;
  }

  void addAndroidVpnRoute(String route) {
    androidVpnRoutes.value = [...androidVpnRoutes.value, route];
  }

  void removeAndroidVpnRoute(int index) {
    final routes = List<String>.from(androidVpnRoutes.value);
    if (index >= 0 && index < routes.length) {
      routes.removeAt(index);
      androidVpnRoutes.value = routes;
    }
  }
}

class BlockedServers {
  static const List<String> blockedUrls = [
  ];

  static bool isBlocked(String url) {
    return blockedUrls.contains(url);
  }

  static bool hasBlockedEnabledServer(List<dynamic> servers) {
    return servers.any(
      (server) => server.enable == true && isBlocked(server.url),
    );
  }
}

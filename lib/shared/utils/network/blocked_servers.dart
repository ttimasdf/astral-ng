class BlockedServers {
  static const List<String> blockedUrls = [
  ];

  static bool isBlocked(String url) {
    return blockedUrls.contains(url);
  }
}

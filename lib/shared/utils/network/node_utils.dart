import 'package:astral/src/rust/api/simple.dart';

/// Returns whether an identity represents an EasyTier public relay server.
bool isServerIdentity(String hostname, String ipv4) {
  return hostname.startsWith('PublicServer_') || ipv4 == '0.0.0.0';
}

/// Returns whether [node] represents an EasyTier public relay server.
bool isServerNode(KVNodeInfo node) =>
    isServerIdentity(node.hostname, node.ipv4);

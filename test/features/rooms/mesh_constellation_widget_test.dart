import 'package:astral/features/rooms/widgets/mesh_constellation.dart';
import 'package:astral/shared/utils/network/mesh_peer_identity.dart';
import 'package:astral/src/rust/api/simple.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart' as gv;

void main() {
  testWidgets('route layout follows canvas orientation and route depth', (
    tester,
  ) async {
    final nodes = [
      _node(1, 'Local', '10.1.0.1', 0),
      _node(2, 'Relay', '10.1.0.2', 1),
      _node(
        3,
        'Forwarded',
        '10.1.0.3',
        2,
        hops: const [
          NodeHopStats(
            peerId: 2,
            targetIp: '10.1.0.2',
            latencyMs: 12,
            packetLoss: 0,
            nodeName: 'Relay',
          ),
        ],
      ),
    ];

    tester.view.physicalSize = const Size(1200, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(home: MeshConstellation(nodes: nodes, localIp: '10.1.0.1')),
    );
    await tester.pumpAndSettle();
    final desktopLocal = tester.getCenter(
      find.byKey(const ValueKey('ip_10.1.0.1')),
    );
    final desktopRelay = tester.getCenter(
      find.byKey(const ValueKey('ip_10.1.0.2')),
    );
    final desktopForwarded = tester.getCenter(
      find.byKey(const ValueKey('ip_10.1.0.3')),
    );
    expect(
      (desktopRelay.dx - desktopLocal.dx).abs(),
      greaterThan((desktopRelay.dy - desktopLocal.dy).abs()),
    );
    expect(
      (desktopForwarded.dx - desktopLocal.dx).abs(),
      greaterThan((desktopRelay.dx - desktopLocal.dx).abs()),
    );

    tester.view.physicalSize = const Size(390, 700);
    await tester.pumpWidget(
      MaterialApp(home: MeshConstellation(nodes: nodes, localIp: '10.1.0.1')),
    );
    expect(
      tester.widget<gv.GraphView>(find.byType(gv.GraphView)).animated,
      isFalse,
    );
    await tester.pumpAndSettle();
    final mobileLocal = tester.getCenter(
      find.byKey(const ValueKey('ip_10.1.0.1')),
    );
    final mobileRelay = tester.getCenter(
      find.byKey(const ValueKey('ip_10.1.0.2')),
    );
    final mobileForwarded = tester.getCenter(
      find.byKey(const ValueKey('ip_10.1.0.3')),
    );
    expect(
      (mobileRelay.dy - mobileLocal.dy).abs(),
      greaterThan((mobileRelay.dx - mobileLocal.dx).abs()),
    );
    expect(
      (mobileForwarded.dy - mobileLocal.dy).abs(),
      greaterThan((mobileRelay.dy - mobileLocal.dy).abs()),
    );
  });

  testWidgets(
    'constellation renders tappable peers without a parent scaffold',
    (tester) async {
      final nodes = [
        _node(1, 'Local', '10.1.0.1', 0),
        _node(2, 'Peer', '10.1.0.2', 1),
        _node(3, 'PublicServer_Relay', '0.0.0.0', 1),
        _node(
          4,
          'Forwarded target',
          '10.1.0.4',
          2,
          hops: const [
            NodeHopStats(
              peerId: 2,
              targetIp: '10.1.0.2',
              latencyMs: 12,
              packetLoss: 0,
              nodeName: 'Peer',
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(home: MeshConstellation(nodes: nodes, localIp: '10.1.0.1')),
      );
      await tester.pump();

      expect(find.byType(GestureDetector), findsWidgets);
      expect(find.byIcon(Icons.my_location_rounded), findsNothing);
      expect(
        find.text(MeshPeerIdentity.emojiFor(username: 'Local', ip: '10.1.0.1')),
        findsOneWidget,
      );
      expect(
        find.text(MeshPeerIdentity.emojiFor(username: 'Peer', ip: '10.1.0.2')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.dns_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pointer hover does not remove the graph nodes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MeshConstellation(
          nodes: [
            _node(1, 'Local', '10.1.0.1', 0),
            _node(2, 'Peer', '10.1.0.2', 1),
          ],
          localIp: '10.1.0.1',
        ),
      ),
    );
    await tester.pumpAndSettle();
    final emoji = MeshPeerIdentity.emojiFor(username: 'Peer', ip: '10.1.0.2');
    expect(find.text(emoji), findsOneWidget);

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(pointer.removePointer);
    await pointer.addPointer(location: tester.getCenter(find.text(emoji)));
    await tester.pump();

    expect(find.text(emoji), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('metric refresh keeps the settled graph element', (tester) async {
    final nodes = ValueNotifier<List<KVNodeInfo>>([
      _node(1, 'Local', '10.1.0.1', 0),
      _node(2, 'Peer', '10.1.0.2', 1),
    ]);
    addTearDown(nodes.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<List<KVNodeInfo>>(
          valueListenable: nodes,
          builder:
              (context, value, _) =>
                  MeshConstellation(nodes: value, localIp: '10.1.0.1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final graphElement = tester.element(find.byType(gv.GraphView));

    nodes.value = [
      _node(1, 'Local', '10.1.0.1', 0),
      _node(2, 'Peer', '10.1.0.2', 1, latency: 88),
    ];
    await tester.pump();

    expect(tester.element(find.byType(gv.GraphView)), same(graphElement));
  });

  testWidgets('pan and zoom stay within Astral bounds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MeshConstellation(
          nodes: [
            _node(1, 'Local', '10.1.0.1', 0),
            _node(2, 'Peer', '10.1.0.2', 1),
          ],
          localIp: '10.1.0.1',
        ),
      ),
    );
    await tester.pump();

    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(find.byType(Tooltip), findsNothing);
    expect(find.byType(InkWell), findsNothing);
    expect(viewer.minScale, .55);
    expect(viewer.maxScale, 1.8);
    expect(viewer.boundaryMargin, EdgeInsets.zero);
  });

  testWidgets('detail values align and scroll in a short viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MeshConstellation(
          nodes: [
            _node(1, 'Local', '10.1.0.1', 0),
            _node(2, 'PublicServer_Relay', '0.0.0.0', 1),
            _node(3, 'Peer', '10.1.0.3', 1, nat: 'Restricted'),
          ],
          localIp: '10.1.0.1',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byKey(const ValueKey('ip_10.1.0.3')));
    await tester.pumpAndSettle();

    final values = ['10.1.0.3', '12 ms', '0.0%', 'udp4'];
    final leftEdges = [
      for (final value in values) tester.getTopLeft(find.text(value)).dx,
    ];

    for (final leftEdge in leftEdges.skip(1)) {
      expect(leftEdge, moreOrLessEquals(leftEdges.first, epsilon: .1));
    }
    expect(find.text('0.0.0.0'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

KVNodeInfo _node(
  int peerId,
  String name,
  String ip,
  int cost, {
  List<NodeHopStats> hops = const [],
  String nat = '',
  double latency = 12,
}) => KVNodeInfo(
  peerId: peerId,
  hostname: name,
  ipv4: ip,
  latencyMs: latency,
  nat: nat,
  hops: hops,
  lossRate: 0,
  connections: const [],
  tunnelProto: 'udp',
  connType: '',
  rxBytes: BigInt.zero,
  txBytes: BigInt.zero,
  version: '',
  cost: cost,
  proxyCidrs: const [],
);

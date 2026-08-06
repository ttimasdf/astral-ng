import 'package:astral/core/models/room.dart';
import 'package:astral/core/room/room_share_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('share codes preserve Simple room mode', () {
    final room = Room(
      name: 'Simple room',
      simpleMode: true,
      roomName: 'generated-room',
      password: 'generated-password',
      messageKey: 'message-key',
    );

    final decoded = RoomShareCodec.decodeRoom(RoomShareCodec.encodeRoom(room));

    expect(decoded, isNotNull);
    expect(decoded!.simpleMode, isTrue);
    expect(decoded.roomName, room.roomName);
  });

  test('share codes preserve Advanced room mode', () {
    final room = Room(
      name: 'Advanced room',
      simpleMode: false,
      roomName: 'shared-room',
      password: 'shared-password',
    );

    final decoded = RoomShareCodec.decodeRoom(RoomShareCodec.encodeRoom(room));

    expect(decoded, isNotNull);
    expect(decoded!.simpleMode, isFalse);
    expect(decoded.roomName, room.roomName);
  });
}

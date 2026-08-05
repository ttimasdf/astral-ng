// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'all_settings.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAllSettingsCollection on Isar {
  IsarCollection<AllSettings> get allSettings => this.collection();
}

const AllSettingsSchema = CollectionSchema(
  name: r'AllSettings',
  id: 7675443445704401613,
  properties: {
    r'androidVpnRoutes': PropertySchema(
      id: 0,
      name: r'androidVpnRoutes',
      type: IsarType.stringList,
    ),
    r'automaticUpdateChecks': PropertySchema(
      id: 1,
      name: r'automaticUpdateChecks',
      type: IsarType.bool,
    ),
    r'closeToTray': PropertySchema(
      id: 2,
      name: r'closeToTray',
      type: IsarType.bool,
    ),
    r'compactPeerCards': PropertySchema(
      id: 3,
      name: r'compactPeerCards',
      type: IsarType.bool,
    ),
    r'connectAfterLaunch': PropertySchema(
      id: 4,
      name: r'connectAfterLaunch',
      type: IsarType.bool,
    ),
    r'connectionNotificationEnabled': PropertySchema(
      id: 5,
      name: r'connectionNotificationEnabled',
      type: IsarType.bool,
    ),
    r'connectionRetryLimit': PropertySchema(
      id: 6,
      name: r'connectionRetryLimit',
      type: IsarType.long,
    ),
    r'latestAvailableVersion': PropertySchema(
      id: 7,
      name: r'latestAvailableVersion',
      type: IsarType.string,
    ),
    r'launchAtLogin': PropertySchema(
      id: 8,
      name: r'launchAtLogin',
      type: IsarType.bool,
    ),
    r'launchToTray': PropertySchema(
      id: 9,
      name: r'launchToTray',
      type: IsarType.bool,
    ),
    r'peerDisplayMode': PropertySchema(
      id: 10,
      name: r'peerDisplayMode',
      type: IsarType.long,
    ),
    r'peerListeners': PropertySchema(
      id: 11,
      name: r'peerListeners',
      type: IsarType.stringList,
    ),
    r'peerName': PropertySchema(
      id: 12,
      name: r'peerName',
      type: IsarType.string,
    ),
    r'peerSortOption': PropertySchema(
      id: 13,
      name: r'peerSortOption',
      type: IsarType.long,
    ),
    r'peerSortOrder': PropertySchema(
      id: 14,
      name: r'peerSortOrder',
      type: IsarType.long,
    ),
    r'preferAstralAdapter': PropertySchema(
      id: 15,
      name: r'preferAstralAdapter',
      type: IsarType.bool,
    ),
    r'receiveBetaUpdates': PropertySchema(
      id: 16,
      name: r'receiveBetaUpdates',
      type: IsarType.bool,
    ),
    r'reduceTopologyAnimations': PropertySchema(
      id: 17,
      name: r'reduceTopologyAnimations',
      type: IsarType.bool,
    ),
    r'retryFailedConnections': PropertySchema(
      id: 18,
      name: r'retryFailedConnections',
      type: IsarType.bool,
    ),
    r'selectedRoomId': PropertySchema(
      id: 19,
      name: r'selectedRoomId',
      type: IsarType.long,
    ),
    r'updateDownloadSource': PropertySchema(
      id: 20,
      name: r'updateDownloadSource',
      type: IsarType.string,
    ),
  },

  estimateSize: _allSettingsEstimateSize,
  serialize: _allSettingsSerialize,
  deserialize: _allSettingsDeserialize,
  deserializeProp: _allSettingsDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _allSettingsGetId,
  getLinks: _allSettingsGetLinks,
  attach: _allSettingsAttach,
  version: '3.3.0',
);

int _allSettingsEstimateSize(
  AllSettings object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.androidVpnRoutes.length * 3;
  {
    for (var i = 0; i < object.androidVpnRoutes.length; i++) {
      final value = object.androidVpnRoutes[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.latestAvailableVersion;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final list = object.peerListeners;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += value.length * 3;
        }
      }
    }
  }
  {
    final value = object.peerName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.updateDownloadSource.length * 3;
  return bytesCount;
}

void _allSettingsSerialize(
  AllSettings object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.androidVpnRoutes);
  writer.writeBool(offsets[1], object.automaticUpdateChecks);
  writer.writeBool(offsets[2], object.closeToTray);
  writer.writeBool(offsets[3], object.compactPeerCards);
  writer.writeBool(offsets[4], object.connectAfterLaunch);
  writer.writeBool(offsets[5], object.connectionNotificationEnabled);
  writer.writeLong(offsets[6], object.connectionRetryLimit);
  writer.writeString(offsets[7], object.latestAvailableVersion);
  writer.writeBool(offsets[8], object.launchAtLogin);
  writer.writeBool(offsets[9], object.launchToTray);
  writer.writeLong(offsets[10], object.peerDisplayMode);
  writer.writeStringList(offsets[11], object.peerListeners);
  writer.writeString(offsets[12], object.peerName);
  writer.writeLong(offsets[13], object.peerSortOption);
  writer.writeLong(offsets[14], object.peerSortOrder);
  writer.writeBool(offsets[15], object.preferAstralAdapter);
  writer.writeBool(offsets[16], object.receiveBetaUpdates);
  writer.writeBool(offsets[17], object.reduceTopologyAnimations);
  writer.writeBool(offsets[18], object.retryFailedConnections);
  writer.writeLong(offsets[19], object.selectedRoomId);
  writer.writeString(offsets[20], object.updateDownloadSource);
}

AllSettings _allSettingsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AllSettings();
  object.androidVpnRoutes = reader.readStringList(offsets[0]) ?? [];
  object.automaticUpdateChecks = reader.readBool(offsets[1]);
  object.closeToTray = reader.readBool(offsets[2]);
  object.compactPeerCards = reader.readBool(offsets[3]);
  object.connectAfterLaunch = reader.readBool(offsets[4]);
  object.connectionNotificationEnabled = reader.readBool(offsets[5]);
  object.connectionRetryLimit = reader.readLong(offsets[6]);
  object.id = id;
  object.latestAvailableVersion = reader.readStringOrNull(offsets[7]);
  object.launchAtLogin = reader.readBool(offsets[8]);
  object.launchToTray = reader.readBool(offsets[9]);
  object.peerDisplayMode = reader.readLong(offsets[10]);
  object.peerListeners = reader.readStringList(offsets[11]);
  object.peerName = reader.readStringOrNull(offsets[12]);
  object.peerSortOption = reader.readLong(offsets[13]);
  object.peerSortOrder = reader.readLong(offsets[14]);
  object.preferAstralAdapter = reader.readBool(offsets[15]);
  object.receiveBetaUpdates = reader.readBool(offsets[16]);
  object.reduceTopologyAnimations = reader.readBool(offsets[17]);
  object.retryFailedConnections = reader.readBool(offsets[18]);
  object.selectedRoomId = reader.readLongOrNull(offsets[19]);
  object.updateDownloadSource = reader.readString(offsets[20]);
  return object;
}

P _allSettingsDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringList(offset) ?? []) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readStringList(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readLong(offset)) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    case 15:
      return (reader.readBool(offset)) as P;
    case 16:
      return (reader.readBool(offset)) as P;
    case 17:
      return (reader.readBool(offset)) as P;
    case 18:
      return (reader.readBool(offset)) as P;
    case 19:
      return (reader.readLongOrNull(offset)) as P;
    case 20:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _allSettingsGetId(AllSettings object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _allSettingsGetLinks(AllSettings object) {
  return [];
}

void _allSettingsAttach(
  IsarCollection<dynamic> col,
  Id id,
  AllSettings object,
) {
  object.id = id;
}

extension AllSettingsQueryWhereSort
    on QueryBuilder<AllSettings, AllSettings, QWhere> {
  QueryBuilder<AllSettings, AllSettings, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AllSettingsQueryWhere
    on QueryBuilder<AllSettings, AllSettings, QWhereClause> {
  QueryBuilder<AllSettings, AllSettings, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension AllSettingsQueryFilter
    on QueryBuilder<AllSettings, AllSettings, QFilterCondition> {
  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  androidVpnRoutesElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'androidVpnRoutes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  androidVpnRoutesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'androidVpnRoutes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  androidVpnRoutesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'androidVpnRoutes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  androidVpnRoutesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'androidVpnRoutes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  androidVpnRoutesElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'androidVpnRoutes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  androidVpnRoutesElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'androidVpnRoutes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  androidVpnRoutesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'androidVpnRoutes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  androidVpnRoutesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'androidVpnRoutes',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  androidVpnRoutesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'androidVpnRoutes', value: ''),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  androidVpnRoutesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'androidVpnRoutes', value: ''),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  androidVpnRoutesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'androidVpnRoutes', length, true, length, true);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  androidVpnRoutesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'androidVpnRoutes', 0, true, 0, true);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  androidVpnRoutesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'androidVpnRoutes', 0, false, 999999, true);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  androidVpnRoutesLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'androidVpnRoutes', 0, true, length, include);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  androidVpnRoutesLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'androidVpnRoutes',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  androidVpnRoutesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'androidVpnRoutes',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  automaticUpdateChecksEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'automaticUpdateChecks',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  closeToTrayEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'closeToTray', value: value),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  compactPeerCardsEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'compactPeerCards', value: value),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  connectAfterLaunchEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'connectAfterLaunch', value: value),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  connectionNotificationEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'connectionNotificationEnabled',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  connectionRetryLimitEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'connectionRetryLimit',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  connectionRetryLimitGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'connectionRetryLimit',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  connectionRetryLimitLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'connectionRetryLimit',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  connectionRetryLimitBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'connectionRetryLimit',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  latestAvailableVersionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'latestAvailableVersion'),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  latestAvailableVersionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'latestAvailableVersion'),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  latestAvailableVersionEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'latestAvailableVersion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  latestAvailableVersionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'latestAvailableVersion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  latestAvailableVersionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'latestAvailableVersion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  latestAvailableVersionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'latestAvailableVersion',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  latestAvailableVersionStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'latestAvailableVersion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  latestAvailableVersionEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'latestAvailableVersion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  latestAvailableVersionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'latestAvailableVersion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  latestAvailableVersionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'latestAvailableVersion',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  latestAvailableVersionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'latestAvailableVersion', value: ''),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  latestAvailableVersionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'latestAvailableVersion',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  launchAtLoginEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'launchAtLogin', value: value),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  launchToTrayEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'launchToTray', value: value),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerDisplayModeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'peerDisplayMode', value: value),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerDisplayModeGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'peerDisplayMode',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerDisplayModeLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'peerDisplayMode',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerDisplayModeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'peerDisplayMode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerListenersIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'peerListeners'),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerListenersIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'peerListeners'),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerListenersElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'peerListeners',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerListenersElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'peerListeners',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerListenersElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'peerListeners',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerListenersElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'peerListeners',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerListenersElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'peerListeners',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerListenersElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'peerListeners',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerListenersElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'peerListeners',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerListenersElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'peerListeners',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerListenersElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'peerListeners', value: ''),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerListenersElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'peerListeners', value: ''),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerListenersLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'peerListeners', length, true, length, true);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerListenersIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'peerListeners', 0, true, 0, true);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerListenersIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'peerListeners', 0, false, 999999, true);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerListenersLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'peerListeners', 0, true, length, include);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerListenersLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'peerListeners', length, include, 999999, true);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerListenersLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'peerListeners',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'peerName'),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'peerName'),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition> peerNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'peerName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'peerName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'peerName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition> peerNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'peerName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'peerName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'peerName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'peerName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition> peerNameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'peerName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'peerName', value: ''),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'peerName', value: ''),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerSortOptionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'peerSortOption', value: value),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerSortOptionGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'peerSortOption',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerSortOptionLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'peerSortOption',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerSortOptionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'peerSortOption',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerSortOrderEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'peerSortOrder', value: value),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerSortOrderGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'peerSortOrder',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerSortOrderLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'peerSortOrder',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  peerSortOrderBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'peerSortOrder',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  preferAstralAdapterEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'preferAstralAdapter', value: value),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  receiveBetaUpdatesEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'receiveBetaUpdates', value: value),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  reduceTopologyAnimationsEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'reduceTopologyAnimations',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  retryFailedConnectionsEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'retryFailedConnections',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  selectedRoomIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'selectedRoomId'),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  selectedRoomIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'selectedRoomId'),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  selectedRoomIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'selectedRoomId', value: value),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  selectedRoomIdGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'selectedRoomId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  selectedRoomIdLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'selectedRoomId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  selectedRoomIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'selectedRoomId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  updateDownloadSourceEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'updateDownloadSource',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  updateDownloadSourceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updateDownloadSource',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  updateDownloadSourceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updateDownloadSource',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  updateDownloadSourceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updateDownloadSource',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  updateDownloadSourceStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'updateDownloadSource',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  updateDownloadSourceEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'updateDownloadSource',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  updateDownloadSourceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'updateDownloadSource',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  updateDownloadSourceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'updateDownloadSource',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  updateDownloadSourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updateDownloadSource', value: ''),
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterFilterCondition>
  updateDownloadSourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'updateDownloadSource',
          value: '',
        ),
      );
    });
  }
}

extension AllSettingsQueryObject
    on QueryBuilder<AllSettings, AllSettings, QFilterCondition> {}

extension AllSettingsQueryLinks
    on QueryBuilder<AllSettings, AllSettings, QFilterCondition> {}

extension AllSettingsQuerySortBy
    on QueryBuilder<AllSettings, AllSettings, QSortBy> {
  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByAutomaticUpdateChecks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'automaticUpdateChecks', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByAutomaticUpdateChecksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'automaticUpdateChecks', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy> sortByCloseToTray() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closeToTray', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy> sortByCloseToTrayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closeToTray', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByCompactPeerCards() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'compactPeerCards', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByCompactPeerCardsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'compactPeerCards', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByConnectAfterLaunch() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectAfterLaunch', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByConnectAfterLaunchDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectAfterLaunch', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByConnectionNotificationEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectionNotificationEnabled', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByConnectionNotificationEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectionNotificationEnabled', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByConnectionRetryLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectionRetryLimit', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByConnectionRetryLimitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectionRetryLimit', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByLatestAvailableVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestAvailableVersion', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByLatestAvailableVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestAvailableVersion', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy> sortByLaunchAtLogin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'launchAtLogin', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByLaunchAtLoginDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'launchAtLogin', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy> sortByLaunchToTray() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'launchToTray', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByLaunchToTrayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'launchToTray', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy> sortByPeerDisplayMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerDisplayMode', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByPeerDisplayModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerDisplayMode', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy> sortByPeerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerName', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy> sortByPeerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerName', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy> sortByPeerSortOption() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerSortOption', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByPeerSortOptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerSortOption', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy> sortByPeerSortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerSortOrder', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByPeerSortOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerSortOrder', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByPreferAstralAdapter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferAstralAdapter', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByPreferAstralAdapterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferAstralAdapter', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByReceiveBetaUpdates() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiveBetaUpdates', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByReceiveBetaUpdatesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiveBetaUpdates', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByReduceTopologyAnimations() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reduceTopologyAnimations', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByReduceTopologyAnimationsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reduceTopologyAnimations', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByRetryFailedConnections() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryFailedConnections', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByRetryFailedConnectionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryFailedConnections', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy> sortBySelectedRoomId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedRoomId', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortBySelectedRoomIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedRoomId', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByUpdateDownloadSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updateDownloadSource', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  sortByUpdateDownloadSourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updateDownloadSource', Sort.desc);
    });
  }
}

extension AllSettingsQuerySortThenBy
    on QueryBuilder<AllSettings, AllSettings, QSortThenBy> {
  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByAutomaticUpdateChecks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'automaticUpdateChecks', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByAutomaticUpdateChecksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'automaticUpdateChecks', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy> thenByCloseToTray() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closeToTray', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy> thenByCloseToTrayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closeToTray', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByCompactPeerCards() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'compactPeerCards', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByCompactPeerCardsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'compactPeerCards', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByConnectAfterLaunch() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectAfterLaunch', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByConnectAfterLaunchDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectAfterLaunch', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByConnectionNotificationEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectionNotificationEnabled', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByConnectionNotificationEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectionNotificationEnabled', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByConnectionRetryLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectionRetryLimit', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByConnectionRetryLimitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectionRetryLimit', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByLatestAvailableVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestAvailableVersion', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByLatestAvailableVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestAvailableVersion', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy> thenByLaunchAtLogin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'launchAtLogin', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByLaunchAtLoginDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'launchAtLogin', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy> thenByLaunchToTray() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'launchToTray', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByLaunchToTrayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'launchToTray', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy> thenByPeerDisplayMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerDisplayMode', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByPeerDisplayModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerDisplayMode', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy> thenByPeerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerName', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy> thenByPeerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerName', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy> thenByPeerSortOption() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerSortOption', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByPeerSortOptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerSortOption', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy> thenByPeerSortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerSortOrder', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByPeerSortOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerSortOrder', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByPreferAstralAdapter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferAstralAdapter', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByPreferAstralAdapterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferAstralAdapter', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByReceiveBetaUpdates() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiveBetaUpdates', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByReceiveBetaUpdatesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiveBetaUpdates', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByReduceTopologyAnimations() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reduceTopologyAnimations', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByReduceTopologyAnimationsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reduceTopologyAnimations', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByRetryFailedConnections() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryFailedConnections', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByRetryFailedConnectionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryFailedConnections', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy> thenBySelectedRoomId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedRoomId', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenBySelectedRoomIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedRoomId', Sort.desc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByUpdateDownloadSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updateDownloadSource', Sort.asc);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QAfterSortBy>
  thenByUpdateDownloadSourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updateDownloadSource', Sort.desc);
    });
  }
}

extension AllSettingsQueryWhereDistinct
    on QueryBuilder<AllSettings, AllSettings, QDistinct> {
  QueryBuilder<AllSettings, AllSettings, QDistinct>
  distinctByAndroidVpnRoutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'androidVpnRoutes');
    });
  }

  QueryBuilder<AllSettings, AllSettings, QDistinct>
  distinctByAutomaticUpdateChecks() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'automaticUpdateChecks');
    });
  }

  QueryBuilder<AllSettings, AllSettings, QDistinct> distinctByCloseToTray() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'closeToTray');
    });
  }

  QueryBuilder<AllSettings, AllSettings, QDistinct>
  distinctByCompactPeerCards() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'compactPeerCards');
    });
  }

  QueryBuilder<AllSettings, AllSettings, QDistinct>
  distinctByConnectAfterLaunch() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'connectAfterLaunch');
    });
  }

  QueryBuilder<AllSettings, AllSettings, QDistinct>
  distinctByConnectionNotificationEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'connectionNotificationEnabled');
    });
  }

  QueryBuilder<AllSettings, AllSettings, QDistinct>
  distinctByConnectionRetryLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'connectionRetryLimit');
    });
  }

  QueryBuilder<AllSettings, AllSettings, QDistinct>
  distinctByLatestAvailableVersion({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'latestAvailableVersion',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<AllSettings, AllSettings, QDistinct> distinctByLaunchAtLogin() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'launchAtLogin');
    });
  }

  QueryBuilder<AllSettings, AllSettings, QDistinct> distinctByLaunchToTray() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'launchToTray');
    });
  }

  QueryBuilder<AllSettings, AllSettings, QDistinct>
  distinctByPeerDisplayMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'peerDisplayMode');
    });
  }

  QueryBuilder<AllSettings, AllSettings, QDistinct> distinctByPeerListeners() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'peerListeners');
    });
  }

  QueryBuilder<AllSettings, AllSettings, QDistinct> distinctByPeerName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'peerName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AllSettings, AllSettings, QDistinct> distinctByPeerSortOption() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'peerSortOption');
    });
  }

  QueryBuilder<AllSettings, AllSettings, QDistinct> distinctByPeerSortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'peerSortOrder');
    });
  }

  QueryBuilder<AllSettings, AllSettings, QDistinct>
  distinctByPreferAstralAdapter() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'preferAstralAdapter');
    });
  }

  QueryBuilder<AllSettings, AllSettings, QDistinct>
  distinctByReceiveBetaUpdates() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'receiveBetaUpdates');
    });
  }

  QueryBuilder<AllSettings, AllSettings, QDistinct>
  distinctByReduceTopologyAnimations() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reduceTopologyAnimations');
    });
  }

  QueryBuilder<AllSettings, AllSettings, QDistinct>
  distinctByRetryFailedConnections() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'retryFailedConnections');
    });
  }

  QueryBuilder<AllSettings, AllSettings, QDistinct> distinctBySelectedRoomId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'selectedRoomId');
    });
  }

  QueryBuilder<AllSettings, AllSettings, QDistinct>
  distinctByUpdateDownloadSource({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'updateDownloadSource',
        caseSensitive: caseSensitive,
      );
    });
  }
}

extension AllSettingsQueryProperty
    on QueryBuilder<AllSettings, AllSettings, QQueryProperty> {
  QueryBuilder<AllSettings, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AllSettings, List<String>, QQueryOperations>
  androidVpnRoutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'androidVpnRoutes');
    });
  }

  QueryBuilder<AllSettings, bool, QQueryOperations>
  automaticUpdateChecksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'automaticUpdateChecks');
    });
  }

  QueryBuilder<AllSettings, bool, QQueryOperations> closeToTrayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'closeToTray');
    });
  }

  QueryBuilder<AllSettings, bool, QQueryOperations> compactPeerCardsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'compactPeerCards');
    });
  }

  QueryBuilder<AllSettings, bool, QQueryOperations>
  connectAfterLaunchProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'connectAfterLaunch');
    });
  }

  QueryBuilder<AllSettings, bool, QQueryOperations>
  connectionNotificationEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'connectionNotificationEnabled');
    });
  }

  QueryBuilder<AllSettings, int, QQueryOperations>
  connectionRetryLimitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'connectionRetryLimit');
    });
  }

  QueryBuilder<AllSettings, String?, QQueryOperations>
  latestAvailableVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'latestAvailableVersion');
    });
  }

  QueryBuilder<AllSettings, bool, QQueryOperations> launchAtLoginProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'launchAtLogin');
    });
  }

  QueryBuilder<AllSettings, bool, QQueryOperations> launchToTrayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'launchToTray');
    });
  }

  QueryBuilder<AllSettings, int, QQueryOperations> peerDisplayModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'peerDisplayMode');
    });
  }

  QueryBuilder<AllSettings, List<String>?, QQueryOperations>
  peerListenersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'peerListeners');
    });
  }

  QueryBuilder<AllSettings, String?, QQueryOperations> peerNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'peerName');
    });
  }

  QueryBuilder<AllSettings, int, QQueryOperations> peerSortOptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'peerSortOption');
    });
  }

  QueryBuilder<AllSettings, int, QQueryOperations> peerSortOrderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'peerSortOrder');
    });
  }

  QueryBuilder<AllSettings, bool, QQueryOperations>
  preferAstralAdapterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'preferAstralAdapter');
    });
  }

  QueryBuilder<AllSettings, bool, QQueryOperations>
  receiveBetaUpdatesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'receiveBetaUpdates');
    });
  }

  QueryBuilder<AllSettings, bool, QQueryOperations>
  reduceTopologyAnimationsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reduceTopologyAnimations');
    });
  }

  QueryBuilder<AllSettings, bool, QQueryOperations>
  retryFailedConnectionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'retryFailedConnections');
    });
  }

  QueryBuilder<AllSettings, int?, QQueryOperations> selectedRoomIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'selectedRoomId');
    });
  }

  QueryBuilder<AllSettings, String, QQueryOperations>
  updateDownloadSourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updateDownloadSource');
    });
  }
}

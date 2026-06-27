// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $RunsTable extends Runs with TableInfo<$RunsTable, RunRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceMMeta = const VerificationMeta(
    'distanceM',
  );
  @override
  late final GeneratedColumn<double> distanceM = GeneratedColumn<double>(
    'distance_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _durationSMeta = const VerificationMeta(
    'durationS',
  );
  @override
  late final GeneratedColumn<int> durationS = GeneratedColumn<int>(
    'duration_s',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _avgPaceSPerKmMeta = const VerificationMeta(
    'avgPaceSPerKm',
  );
  @override
  late final GeneratedColumn<double> avgPaceSPerKm = GeneratedColumn<double>(
    'avg_pace_s_per_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _caloriesEstMeta = const VerificationMeta(
    'caloriesEst',
  );
  @override
  late final GeneratedColumn<double> caloriesEst = GeneratedColumn<double>(
    'calories_est',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAt,
    endedAt,
    distanceM,
    durationS,
    avgPaceSPerKm,
    caloriesEst,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<RunRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('distance_m')) {
      context.handle(
        _distanceMMeta,
        distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta),
      );
    }
    if (data.containsKey('duration_s')) {
      context.handle(
        _durationSMeta,
        durationS.isAcceptableOrUnknown(data['duration_s']!, _durationSMeta),
      );
    }
    if (data.containsKey('avg_pace_s_per_km')) {
      context.handle(
        _avgPaceSPerKmMeta,
        avgPaceSPerKm.isAcceptableOrUnknown(
          data['avg_pace_s_per_km']!,
          _avgPaceSPerKmMeta,
        ),
      );
    }
    if (data.containsKey('calories_est')) {
      context.handle(
        _caloriesEstMeta,
        caloriesEst.isAcceptableOrUnknown(
          data['calories_est']!,
          _caloriesEstMeta,
        ),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RunRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RunRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      distanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_m'],
      )!,
      durationS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_s'],
      )!,
      avgPaceSPerKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_pace_s_per_km'],
      )!,
      caloriesEst: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calories_est'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $RunsTable createAlias(String alias) {
    return $RunsTable(attachedDatabase, alias);
  }
}

class RunRow extends DataClass implements Insertable<RunRow> {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double distanceM;
  final int durationS;
  final double avgPaceSPerKm;
  final double caloriesEst;
  final bool synced;
  const RunRow({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.distanceM,
    required this.durationS,
    required this.avgPaceSPerKm,
    required this.caloriesEst,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['distance_m'] = Variable<double>(distanceM);
    map['duration_s'] = Variable<int>(durationS);
    map['avg_pace_s_per_km'] = Variable<double>(avgPaceSPerKm);
    map['calories_est'] = Variable<double>(caloriesEst);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  RunsCompanion toCompanion(bool nullToAbsent) {
    return RunsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      distanceM: Value(distanceM),
      durationS: Value(durationS),
      avgPaceSPerKm: Value(avgPaceSPerKm),
      caloriesEst: Value(caloriesEst),
      synced: Value(synced),
    );
  }

  factory RunRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RunRow(
      id: serializer.fromJson<String>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      distanceM: serializer.fromJson<double>(json['distanceM']),
      durationS: serializer.fromJson<int>(json['durationS']),
      avgPaceSPerKm: serializer.fromJson<double>(json['avgPaceSPerKm']),
      caloriesEst: serializer.fromJson<double>(json['caloriesEst']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'distanceM': serializer.toJson<double>(distanceM),
      'durationS': serializer.toJson<int>(durationS),
      'avgPaceSPerKm': serializer.toJson<double>(avgPaceSPerKm),
      'caloriesEst': serializer.toJson<double>(caloriesEst),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  RunRow copyWith({
    String? id,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    double? distanceM,
    int? durationS,
    double? avgPaceSPerKm,
    double? caloriesEst,
    bool? synced,
  }) => RunRow(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    distanceM: distanceM ?? this.distanceM,
    durationS: durationS ?? this.durationS,
    avgPaceSPerKm: avgPaceSPerKm ?? this.avgPaceSPerKm,
    caloriesEst: caloriesEst ?? this.caloriesEst,
    synced: synced ?? this.synced,
  );
  RunRow copyWithCompanion(RunsCompanion data) {
    return RunRow(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
      durationS: data.durationS.present ? data.durationS.value : this.durationS,
      avgPaceSPerKm: data.avgPaceSPerKm.present
          ? data.avgPaceSPerKm.value
          : this.avgPaceSPerKm,
      caloriesEst: data.caloriesEst.present
          ? data.caloriesEst.value
          : this.caloriesEst,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RunRow(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('distanceM: $distanceM, ')
          ..write('durationS: $durationS, ')
          ..write('avgPaceSPerKm: $avgPaceSPerKm, ')
          ..write('caloriesEst: $caloriesEst, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startedAt,
    endedAt,
    distanceM,
    durationS,
    avgPaceSPerKm,
    caloriesEst,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RunRow &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.distanceM == this.distanceM &&
          other.durationS == this.durationS &&
          other.avgPaceSPerKm == this.avgPaceSPerKm &&
          other.caloriesEst == this.caloriesEst &&
          other.synced == this.synced);
}

class RunsCompanion extends UpdateCompanion<RunRow> {
  final Value<String> id;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<double> distanceM;
  final Value<int> durationS;
  final Value<double> avgPaceSPerKm;
  final Value<double> caloriesEst;
  final Value<bool> synced;
  final Value<int> rowid;
  const RunsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.durationS = const Value.absent(),
    this.avgPaceSPerKm = const Value.absent(),
    this.caloriesEst = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RunsCompanion.insert({
    required String id,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.durationS = const Value.absent(),
    this.avgPaceSPerKm = const Value.absent(),
    this.caloriesEst = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startedAt = Value(startedAt);
  static Insertable<RunRow> custom({
    Expression<String>? id,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<double>? distanceM,
    Expression<int>? durationS,
    Expression<double>? avgPaceSPerKm,
    Expression<double>? caloriesEst,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (distanceM != null) 'distance_m': distanceM,
      if (durationS != null) 'duration_s': durationS,
      if (avgPaceSPerKm != null) 'avg_pace_s_per_km': avgPaceSPerKm,
      if (caloriesEst != null) 'calories_est': caloriesEst,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RunsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<double>? distanceM,
    Value<int>? durationS,
    Value<double>? avgPaceSPerKm,
    Value<double>? caloriesEst,
    Value<bool>? synced,
    Value<int>? rowid,
  }) {
    return RunsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      distanceM: distanceM ?? this.distanceM,
      durationS: durationS ?? this.durationS,
      avgPaceSPerKm: avgPaceSPerKm ?? this.avgPaceSPerKm,
      caloriesEst: caloriesEst ?? this.caloriesEst,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<double>(distanceM.value);
    }
    if (durationS.present) {
      map['duration_s'] = Variable<int>(durationS.value);
    }
    if (avgPaceSPerKm.present) {
      map['avg_pace_s_per_km'] = Variable<double>(avgPaceSPerKm.value);
    }
    if (caloriesEst.present) {
      map['calories_est'] = Variable<double>(caloriesEst.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RunsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('distanceM: $distanceM, ')
          ..write('durationS: $durationS, ')
          ..write('avgPaceSPerKm: $avgPaceSPerKm, ')
          ..write('caloriesEst: $caloriesEst, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RunPointsTable extends RunPoints
    with TableInfo<$RunPointsTable, RunPointRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RunPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elevationMeta = const VerificationMeta(
    'elevation',
  );
  @override
  late final GeneratedColumn<double> elevation = GeneratedColumn<double>(
    'elevation',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
    'speed',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accuracyMeta = const VerificationMeta(
    'accuracy',
  );
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
    'accuracy',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    runId,
    lat,
    lng,
    elevation,
    timestamp,
    speed,
    accuracy,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'run_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<RunPointRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('elevation')) {
      context.handle(
        _elevationMeta,
        elevation.isAcceptableOrUnknown(data['elevation']!, _elevationMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('speed')) {
      context.handle(
        _speedMeta,
        speed.isAcceptableOrUnknown(data['speed']!, _speedMeta),
      );
    }
    if (data.containsKey('accuracy')) {
      context.handle(
        _accuracyMeta,
        accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RunPointRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RunPointRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      elevation: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}elevation'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      speed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed'],
      ),
      accuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy'],
      ),
    );
  }

  @override
  $RunPointsTable createAlias(String alias) {
    return $RunPointsTable(attachedDatabase, alias);
  }
}

class RunPointRow extends DataClass implements Insertable<RunPointRow> {
  final int id;
  final String runId;
  final double lat;
  final double lng;
  final double? elevation;
  final DateTime timestamp;
  final double? speed;
  final double? accuracy;
  const RunPointRow({
    required this.id,
    required this.runId,
    required this.lat,
    required this.lng,
    this.elevation,
    required this.timestamp,
    this.speed,
    this.accuracy,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['run_id'] = Variable<String>(runId);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    if (!nullToAbsent || elevation != null) {
      map['elevation'] = Variable<double>(elevation);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || speed != null) {
      map['speed'] = Variable<double>(speed);
    }
    if (!nullToAbsent || accuracy != null) {
      map['accuracy'] = Variable<double>(accuracy);
    }
    return map;
  }

  RunPointsCompanion toCompanion(bool nullToAbsent) {
    return RunPointsCompanion(
      id: Value(id),
      runId: Value(runId),
      lat: Value(lat),
      lng: Value(lng),
      elevation: elevation == null && nullToAbsent
          ? const Value.absent()
          : Value(elevation),
      timestamp: Value(timestamp),
      speed: speed == null && nullToAbsent
          ? const Value.absent()
          : Value(speed),
      accuracy: accuracy == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracy),
    );
  }

  factory RunPointRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RunPointRow(
      id: serializer.fromJson<int>(json['id']),
      runId: serializer.fromJson<String>(json['runId']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      elevation: serializer.fromJson<double?>(json['elevation']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      speed: serializer.fromJson<double?>(json['speed']),
      accuracy: serializer.fromJson<double?>(json['accuracy']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'runId': serializer.toJson<String>(runId),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'elevation': serializer.toJson<double?>(elevation),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'speed': serializer.toJson<double?>(speed),
      'accuracy': serializer.toJson<double?>(accuracy),
    };
  }

  RunPointRow copyWith({
    int? id,
    String? runId,
    double? lat,
    double? lng,
    Value<double?> elevation = const Value.absent(),
    DateTime? timestamp,
    Value<double?> speed = const Value.absent(),
    Value<double?> accuracy = const Value.absent(),
  }) => RunPointRow(
    id: id ?? this.id,
    runId: runId ?? this.runId,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    elevation: elevation.present ? elevation.value : this.elevation,
    timestamp: timestamp ?? this.timestamp,
    speed: speed.present ? speed.value : this.speed,
    accuracy: accuracy.present ? accuracy.value : this.accuracy,
  );
  RunPointRow copyWithCompanion(RunPointsCompanion data) {
    return RunPointRow(
      id: data.id.present ? data.id.value : this.id,
      runId: data.runId.present ? data.runId.value : this.runId,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      elevation: data.elevation.present ? data.elevation.value : this.elevation,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      speed: data.speed.present ? data.speed.value : this.speed,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RunPointRow(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('elevation: $elevation, ')
          ..write('timestamp: $timestamp, ')
          ..write('speed: $speed, ')
          ..write('accuracy: $accuracy')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, runId, lat, lng, elevation, timestamp, speed, accuracy);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RunPointRow &&
          other.id == this.id &&
          other.runId == this.runId &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.elevation == this.elevation &&
          other.timestamp == this.timestamp &&
          other.speed == this.speed &&
          other.accuracy == this.accuracy);
}

class RunPointsCompanion extends UpdateCompanion<RunPointRow> {
  final Value<int> id;
  final Value<String> runId;
  final Value<double> lat;
  final Value<double> lng;
  final Value<double?> elevation;
  final Value<DateTime> timestamp;
  final Value<double?> speed;
  final Value<double?> accuracy;
  const RunPointsCompanion({
    this.id = const Value.absent(),
    this.runId = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.elevation = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.speed = const Value.absent(),
    this.accuracy = const Value.absent(),
  });
  RunPointsCompanion.insert({
    this.id = const Value.absent(),
    required String runId,
    required double lat,
    required double lng,
    this.elevation = const Value.absent(),
    required DateTime timestamp,
    this.speed = const Value.absent(),
    this.accuracy = const Value.absent(),
  }) : runId = Value(runId),
       lat = Value(lat),
       lng = Value(lng),
       timestamp = Value(timestamp);
  static Insertable<RunPointRow> custom({
    Expression<int>? id,
    Expression<String>? runId,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<double>? elevation,
    Expression<DateTime>? timestamp,
    Expression<double>? speed,
    Expression<double>? accuracy,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (runId != null) 'run_id': runId,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (elevation != null) 'elevation': elevation,
      if (timestamp != null) 'timestamp': timestamp,
      if (speed != null) 'speed': speed,
      if (accuracy != null) 'accuracy': accuracy,
    });
  }

  RunPointsCompanion copyWith({
    Value<int>? id,
    Value<String>? runId,
    Value<double>? lat,
    Value<double>? lng,
    Value<double?>? elevation,
    Value<DateTime>? timestamp,
    Value<double?>? speed,
    Value<double?>? accuracy,
  }) {
    return RunPointsCompanion(
      id: id ?? this.id,
      runId: runId ?? this.runId,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      elevation: elevation ?? this.elevation,
      timestamp: timestamp ?? this.timestamp,
      speed: speed ?? this.speed,
      accuracy: accuracy ?? this.accuracy,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (elevation.present) {
      map['elevation'] = Variable<double>(elevation.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RunPointsCompanion(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('elevation: $elevation, ')
          ..write('timestamp: $timestamp, ')
          ..write('speed: $speed, ')
          ..write('accuracy: $accuracy')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(70.0),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('km'),
  );
  static const VerificationMeta _onboardingSeenMeta = const VerificationMeta(
    'onboardingSeen',
  );
  @override
  late final GeneratedColumn<bool> onboardingSeen = GeneratedColumn<bool>(
    'onboarding_seen',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_seen" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('system'),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notificationsEnabledMeta =
      const VerificationMeta('notificationsEnabled');
  @override
  late final GeneratedColumn<bool> notificationsEnabled = GeneratedColumn<bool>(
    'notifications_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notifications_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _runReminderEnabledMeta =
      const VerificationMeta('runReminderEnabled');
  @override
  late final GeneratedColumn<bool> runReminderEnabled = GeneratedColumn<bool>(
    'run_reminder_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("run_reminder_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _runReminderDaysMeta = const VerificationMeta(
    'runReminderDays',
  );
  @override
  late final GeneratedColumn<String> runReminderDays = GeneratedColumn<String>(
    'run_reminder_days',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _runReminderTimeMinMeta =
      const VerificationMeta('runReminderTimeMin');
  @override
  late final GeneratedColumn<int> runReminderTimeMin = GeneratedColumn<int>(
    'run_reminder_time_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(420),
  );
  static const VerificationMeta _streakAlertsMeta = const VerificationMeta(
    'streakAlerts',
  );
  @override
  late final GeneratedColumn<bool> streakAlerts = GeneratedColumn<bool>(
    'streak_alerts',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("streak_alerts" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _weeklyGoalAlertsMeta = const VerificationMeta(
    'weeklyGoalAlerts',
  );
  @override
  late final GeneratedColumn<bool> weeklyGoalAlerts = GeneratedColumn<bool>(
    'weekly_goal_alerts',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("weekly_goal_alerts" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _goalAchievedAlertsMeta =
      const VerificationMeta('goalAchievedAlerts');
  @override
  late final GeneratedColumn<bool> goalAchievedAlerts = GeneratedColumn<bool>(
    'goal_achieved_alerts',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("goal_achieved_alerts" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _comebackAlertsMeta = const VerificationMeta(
    'comebackAlerts',
  );
  @override
  late final GeneratedColumn<bool> comebackAlerts = GeneratedColumn<bool>(
    'comeback_alerts',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("comeback_alerts" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _quietHoursStartMinMeta =
      const VerificationMeta('quietHoursStartMin');
  @override
  late final GeneratedColumn<int> quietHoursStartMin = GeneratedColumn<int>(
    'quiet_hours_start_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1260),
  );
  static const VerificationMeta _quietHoursEndMinMeta = const VerificationMeta(
    'quietHoursEndMin',
  );
  @override
  late final GeneratedColumn<int> quietHoursEndMin = GeneratedColumn<int>(
    'quiet_hours_end_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(480),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    weightKg,
    unit,
    onboardingSeen,
    themeMode,
    displayName,
    notificationsEnabled,
    runReminderEnabled,
    runReminderDays,
    runReminderTimeMin,
    streakAlerts,
    weeklyGoalAlerts,
    goalAchievedAlerts,
    comebackAlerts,
    quietHoursStartMin,
    quietHoursEndMin,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('onboarding_seen')) {
      context.handle(
        _onboardingSeenMeta,
        onboardingSeen.isAcceptableOrUnknown(
          data['onboarding_seen']!,
          _onboardingSeenMeta,
        ),
      );
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('notifications_enabled')) {
      context.handle(
        _notificationsEnabledMeta,
        notificationsEnabled.isAcceptableOrUnknown(
          data['notifications_enabled']!,
          _notificationsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('run_reminder_enabled')) {
      context.handle(
        _runReminderEnabledMeta,
        runReminderEnabled.isAcceptableOrUnknown(
          data['run_reminder_enabled']!,
          _runReminderEnabledMeta,
        ),
      );
    }
    if (data.containsKey('run_reminder_days')) {
      context.handle(
        _runReminderDaysMeta,
        runReminderDays.isAcceptableOrUnknown(
          data['run_reminder_days']!,
          _runReminderDaysMeta,
        ),
      );
    }
    if (data.containsKey('run_reminder_time_min')) {
      context.handle(
        _runReminderTimeMinMeta,
        runReminderTimeMin.isAcceptableOrUnknown(
          data['run_reminder_time_min']!,
          _runReminderTimeMinMeta,
        ),
      );
    }
    if (data.containsKey('streak_alerts')) {
      context.handle(
        _streakAlertsMeta,
        streakAlerts.isAcceptableOrUnknown(
          data['streak_alerts']!,
          _streakAlertsMeta,
        ),
      );
    }
    if (data.containsKey('weekly_goal_alerts')) {
      context.handle(
        _weeklyGoalAlertsMeta,
        weeklyGoalAlerts.isAcceptableOrUnknown(
          data['weekly_goal_alerts']!,
          _weeklyGoalAlertsMeta,
        ),
      );
    }
    if (data.containsKey('goal_achieved_alerts')) {
      context.handle(
        _goalAchievedAlertsMeta,
        goalAchievedAlerts.isAcceptableOrUnknown(
          data['goal_achieved_alerts']!,
          _goalAchievedAlertsMeta,
        ),
      );
    }
    if (data.containsKey('comeback_alerts')) {
      context.handle(
        _comebackAlertsMeta,
        comebackAlerts.isAcceptableOrUnknown(
          data['comeback_alerts']!,
          _comebackAlertsMeta,
        ),
      );
    }
    if (data.containsKey('quiet_hours_start_min')) {
      context.handle(
        _quietHoursStartMinMeta,
        quietHoursStartMin.isAcceptableOrUnknown(
          data['quiet_hours_start_min']!,
          _quietHoursStartMinMeta,
        ),
      );
    }
    if (data.containsKey('quiet_hours_end_min')) {
      context.handle(
        _quietHoursEndMinMeta,
        quietHoursEndMin.isAcceptableOrUnknown(
          data['quiet_hours_end_min']!,
          _quietHoursEndMinMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      onboardingSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_seen'],
      )!,
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      notificationsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notifications_enabled'],
      )!,
      runReminderEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}run_reminder_enabled'],
      )!,
      runReminderDays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_reminder_days'],
      )!,
      runReminderTimeMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}run_reminder_time_min'],
      )!,
      streakAlerts: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}streak_alerts'],
      )!,
      weeklyGoalAlerts: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}weekly_goal_alerts'],
      )!,
      goalAchievedAlerts: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}goal_achieved_alerts'],
      )!,
      comebackAlerts: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}comeback_alerts'],
      )!,
      quietHoursStartMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quiet_hours_start_min'],
      )!,
      quietHoursEndMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quiet_hours_end_min'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final int id;
  final double weightKg;
  final String unit;
  final bool onboardingSeen;
  final String themeMode;
  final String? displayName;
  final bool notificationsEnabled;
  final bool runReminderEnabled;
  final String runReminderDays;
  final int runReminderTimeMin;
  final bool streakAlerts;
  final bool weeklyGoalAlerts;
  final bool goalAchievedAlerts;
  final bool comebackAlerts;
  final int quietHoursStartMin;
  final int quietHoursEndMin;
  const Setting({
    required this.id,
    required this.weightKg,
    required this.unit,
    required this.onboardingSeen,
    required this.themeMode,
    this.displayName,
    required this.notificationsEnabled,
    required this.runReminderEnabled,
    required this.runReminderDays,
    required this.runReminderTimeMin,
    required this.streakAlerts,
    required this.weeklyGoalAlerts,
    required this.goalAchievedAlerts,
    required this.comebackAlerts,
    required this.quietHoursStartMin,
    required this.quietHoursEndMin,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['weight_kg'] = Variable<double>(weightKg);
    map['unit'] = Variable<String>(unit);
    map['onboarding_seen'] = Variable<bool>(onboardingSeen);
    map['theme_mode'] = Variable<String>(themeMode);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    map['notifications_enabled'] = Variable<bool>(notificationsEnabled);
    map['run_reminder_enabled'] = Variable<bool>(runReminderEnabled);
    map['run_reminder_days'] = Variable<String>(runReminderDays);
    map['run_reminder_time_min'] = Variable<int>(runReminderTimeMin);
    map['streak_alerts'] = Variable<bool>(streakAlerts);
    map['weekly_goal_alerts'] = Variable<bool>(weeklyGoalAlerts);
    map['goal_achieved_alerts'] = Variable<bool>(goalAchievedAlerts);
    map['comeback_alerts'] = Variable<bool>(comebackAlerts);
    map['quiet_hours_start_min'] = Variable<int>(quietHoursStartMin);
    map['quiet_hours_end_min'] = Variable<int>(quietHoursEndMin);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      weightKg: Value(weightKg),
      unit: Value(unit),
      onboardingSeen: Value(onboardingSeen),
      themeMode: Value(themeMode),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      notificationsEnabled: Value(notificationsEnabled),
      runReminderEnabled: Value(runReminderEnabled),
      runReminderDays: Value(runReminderDays),
      runReminderTimeMin: Value(runReminderTimeMin),
      streakAlerts: Value(streakAlerts),
      weeklyGoalAlerts: Value(weeklyGoalAlerts),
      goalAchievedAlerts: Value(goalAchievedAlerts),
      comebackAlerts: Value(comebackAlerts),
      quietHoursStartMin: Value(quietHoursStartMin),
      quietHoursEndMin: Value(quietHoursEndMin),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      id: serializer.fromJson<int>(json['id']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      unit: serializer.fromJson<String>(json['unit']),
      onboardingSeen: serializer.fromJson<bool>(json['onboardingSeen']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      notificationsEnabled: serializer.fromJson<bool>(
        json['notificationsEnabled'],
      ),
      runReminderEnabled: serializer.fromJson<bool>(json['runReminderEnabled']),
      runReminderDays: serializer.fromJson<String>(json['runReminderDays']),
      runReminderTimeMin: serializer.fromJson<int>(json['runReminderTimeMin']),
      streakAlerts: serializer.fromJson<bool>(json['streakAlerts']),
      weeklyGoalAlerts: serializer.fromJson<bool>(json['weeklyGoalAlerts']),
      goalAchievedAlerts: serializer.fromJson<bool>(json['goalAchievedAlerts']),
      comebackAlerts: serializer.fromJson<bool>(json['comebackAlerts']),
      quietHoursStartMin: serializer.fromJson<int>(json['quietHoursStartMin']),
      quietHoursEndMin: serializer.fromJson<int>(json['quietHoursEndMin']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'weightKg': serializer.toJson<double>(weightKg),
      'unit': serializer.toJson<String>(unit),
      'onboardingSeen': serializer.toJson<bool>(onboardingSeen),
      'themeMode': serializer.toJson<String>(themeMode),
      'displayName': serializer.toJson<String?>(displayName),
      'notificationsEnabled': serializer.toJson<bool>(notificationsEnabled),
      'runReminderEnabled': serializer.toJson<bool>(runReminderEnabled),
      'runReminderDays': serializer.toJson<String>(runReminderDays),
      'runReminderTimeMin': serializer.toJson<int>(runReminderTimeMin),
      'streakAlerts': serializer.toJson<bool>(streakAlerts),
      'weeklyGoalAlerts': serializer.toJson<bool>(weeklyGoalAlerts),
      'goalAchievedAlerts': serializer.toJson<bool>(goalAchievedAlerts),
      'comebackAlerts': serializer.toJson<bool>(comebackAlerts),
      'quietHoursStartMin': serializer.toJson<int>(quietHoursStartMin),
      'quietHoursEndMin': serializer.toJson<int>(quietHoursEndMin),
    };
  }

  Setting copyWith({
    int? id,
    double? weightKg,
    String? unit,
    bool? onboardingSeen,
    String? themeMode,
    Value<String?> displayName = const Value.absent(),
    bool? notificationsEnabled,
    bool? runReminderEnabled,
    String? runReminderDays,
    int? runReminderTimeMin,
    bool? streakAlerts,
    bool? weeklyGoalAlerts,
    bool? goalAchievedAlerts,
    bool? comebackAlerts,
    int? quietHoursStartMin,
    int? quietHoursEndMin,
  }) => Setting(
    id: id ?? this.id,
    weightKg: weightKg ?? this.weightKg,
    unit: unit ?? this.unit,
    onboardingSeen: onboardingSeen ?? this.onboardingSeen,
    themeMode: themeMode ?? this.themeMode,
    displayName: displayName.present ? displayName.value : this.displayName,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    runReminderEnabled: runReminderEnabled ?? this.runReminderEnabled,
    runReminderDays: runReminderDays ?? this.runReminderDays,
    runReminderTimeMin: runReminderTimeMin ?? this.runReminderTimeMin,
    streakAlerts: streakAlerts ?? this.streakAlerts,
    weeklyGoalAlerts: weeklyGoalAlerts ?? this.weeklyGoalAlerts,
    goalAchievedAlerts: goalAchievedAlerts ?? this.goalAchievedAlerts,
    comebackAlerts: comebackAlerts ?? this.comebackAlerts,
    quietHoursStartMin: quietHoursStartMin ?? this.quietHoursStartMin,
    quietHoursEndMin: quietHoursEndMin ?? this.quietHoursEndMin,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      id: data.id.present ? data.id.value : this.id,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      unit: data.unit.present ? data.unit.value : this.unit,
      onboardingSeen: data.onboardingSeen.present
          ? data.onboardingSeen.value
          : this.onboardingSeen,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      notificationsEnabled: data.notificationsEnabled.present
          ? data.notificationsEnabled.value
          : this.notificationsEnabled,
      runReminderEnabled: data.runReminderEnabled.present
          ? data.runReminderEnabled.value
          : this.runReminderEnabled,
      runReminderDays: data.runReminderDays.present
          ? data.runReminderDays.value
          : this.runReminderDays,
      runReminderTimeMin: data.runReminderTimeMin.present
          ? data.runReminderTimeMin.value
          : this.runReminderTimeMin,
      streakAlerts: data.streakAlerts.present
          ? data.streakAlerts.value
          : this.streakAlerts,
      weeklyGoalAlerts: data.weeklyGoalAlerts.present
          ? data.weeklyGoalAlerts.value
          : this.weeklyGoalAlerts,
      goalAchievedAlerts: data.goalAchievedAlerts.present
          ? data.goalAchievedAlerts.value
          : this.goalAchievedAlerts,
      comebackAlerts: data.comebackAlerts.present
          ? data.comebackAlerts.value
          : this.comebackAlerts,
      quietHoursStartMin: data.quietHoursStartMin.present
          ? data.quietHoursStartMin.value
          : this.quietHoursStartMin,
      quietHoursEndMin: data.quietHoursEndMin.present
          ? data.quietHoursEndMin.value
          : this.quietHoursEndMin,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('id: $id, ')
          ..write('weightKg: $weightKg, ')
          ..write('unit: $unit, ')
          ..write('onboardingSeen: $onboardingSeen, ')
          ..write('themeMode: $themeMode, ')
          ..write('displayName: $displayName, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('runReminderEnabled: $runReminderEnabled, ')
          ..write('runReminderDays: $runReminderDays, ')
          ..write('runReminderTimeMin: $runReminderTimeMin, ')
          ..write('streakAlerts: $streakAlerts, ')
          ..write('weeklyGoalAlerts: $weeklyGoalAlerts, ')
          ..write('goalAchievedAlerts: $goalAchievedAlerts, ')
          ..write('comebackAlerts: $comebackAlerts, ')
          ..write('quietHoursStartMin: $quietHoursStartMin, ')
          ..write('quietHoursEndMin: $quietHoursEndMin')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    weightKg,
    unit,
    onboardingSeen,
    themeMode,
    displayName,
    notificationsEnabled,
    runReminderEnabled,
    runReminderDays,
    runReminderTimeMin,
    streakAlerts,
    weeklyGoalAlerts,
    goalAchievedAlerts,
    comebackAlerts,
    quietHoursStartMin,
    quietHoursEndMin,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.id == this.id &&
          other.weightKg == this.weightKg &&
          other.unit == this.unit &&
          other.onboardingSeen == this.onboardingSeen &&
          other.themeMode == this.themeMode &&
          other.displayName == this.displayName &&
          other.notificationsEnabled == this.notificationsEnabled &&
          other.runReminderEnabled == this.runReminderEnabled &&
          other.runReminderDays == this.runReminderDays &&
          other.runReminderTimeMin == this.runReminderTimeMin &&
          other.streakAlerts == this.streakAlerts &&
          other.weeklyGoalAlerts == this.weeklyGoalAlerts &&
          other.goalAchievedAlerts == this.goalAchievedAlerts &&
          other.comebackAlerts == this.comebackAlerts &&
          other.quietHoursStartMin == this.quietHoursStartMin &&
          other.quietHoursEndMin == this.quietHoursEndMin);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<int> id;
  final Value<double> weightKg;
  final Value<String> unit;
  final Value<bool> onboardingSeen;
  final Value<String> themeMode;
  final Value<String?> displayName;
  final Value<bool> notificationsEnabled;
  final Value<bool> runReminderEnabled;
  final Value<String> runReminderDays;
  final Value<int> runReminderTimeMin;
  final Value<bool> streakAlerts;
  final Value<bool> weeklyGoalAlerts;
  final Value<bool> goalAchievedAlerts;
  final Value<bool> comebackAlerts;
  final Value<int> quietHoursStartMin;
  final Value<int> quietHoursEndMin;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.unit = const Value.absent(),
    this.onboardingSeen = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.displayName = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.runReminderEnabled = const Value.absent(),
    this.runReminderDays = const Value.absent(),
    this.runReminderTimeMin = const Value.absent(),
    this.streakAlerts = const Value.absent(),
    this.weeklyGoalAlerts = const Value.absent(),
    this.goalAchievedAlerts = const Value.absent(),
    this.comebackAlerts = const Value.absent(),
    this.quietHoursStartMin = const Value.absent(),
    this.quietHoursEndMin = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.unit = const Value.absent(),
    this.onboardingSeen = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.displayName = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.runReminderEnabled = const Value.absent(),
    this.runReminderDays = const Value.absent(),
    this.runReminderTimeMin = const Value.absent(),
    this.streakAlerts = const Value.absent(),
    this.weeklyGoalAlerts = const Value.absent(),
    this.goalAchievedAlerts = const Value.absent(),
    this.comebackAlerts = const Value.absent(),
    this.quietHoursStartMin = const Value.absent(),
    this.quietHoursEndMin = const Value.absent(),
  });
  static Insertable<Setting> custom({
    Expression<int>? id,
    Expression<double>? weightKg,
    Expression<String>? unit,
    Expression<bool>? onboardingSeen,
    Expression<String>? themeMode,
    Expression<String>? displayName,
    Expression<bool>? notificationsEnabled,
    Expression<bool>? runReminderEnabled,
    Expression<String>? runReminderDays,
    Expression<int>? runReminderTimeMin,
    Expression<bool>? streakAlerts,
    Expression<bool>? weeklyGoalAlerts,
    Expression<bool>? goalAchievedAlerts,
    Expression<bool>? comebackAlerts,
    Expression<int>? quietHoursStartMin,
    Expression<int>? quietHoursEndMin,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (weightKg != null) 'weight_kg': weightKg,
      if (unit != null) 'unit': unit,
      if (onboardingSeen != null) 'onboarding_seen': onboardingSeen,
      if (themeMode != null) 'theme_mode': themeMode,
      if (displayName != null) 'display_name': displayName,
      if (notificationsEnabled != null)
        'notifications_enabled': notificationsEnabled,
      if (runReminderEnabled != null)
        'run_reminder_enabled': runReminderEnabled,
      if (runReminderDays != null) 'run_reminder_days': runReminderDays,
      if (runReminderTimeMin != null)
        'run_reminder_time_min': runReminderTimeMin,
      if (streakAlerts != null) 'streak_alerts': streakAlerts,
      if (weeklyGoalAlerts != null) 'weekly_goal_alerts': weeklyGoalAlerts,
      if (goalAchievedAlerts != null)
        'goal_achieved_alerts': goalAchievedAlerts,
      if (comebackAlerts != null) 'comeback_alerts': comebackAlerts,
      if (quietHoursStartMin != null)
        'quiet_hours_start_min': quietHoursStartMin,
      if (quietHoursEndMin != null) 'quiet_hours_end_min': quietHoursEndMin,
    });
  }

  SettingsCompanion copyWith({
    Value<int>? id,
    Value<double>? weightKg,
    Value<String>? unit,
    Value<bool>? onboardingSeen,
    Value<String>? themeMode,
    Value<String?>? displayName,
    Value<bool>? notificationsEnabled,
    Value<bool>? runReminderEnabled,
    Value<String>? runReminderDays,
    Value<int>? runReminderTimeMin,
    Value<bool>? streakAlerts,
    Value<bool>? weeklyGoalAlerts,
    Value<bool>? goalAchievedAlerts,
    Value<bool>? comebackAlerts,
    Value<int>? quietHoursStartMin,
    Value<int>? quietHoursEndMin,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      weightKg: weightKg ?? this.weightKg,
      unit: unit ?? this.unit,
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
      themeMode: themeMode ?? this.themeMode,
      displayName: displayName ?? this.displayName,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      runReminderEnabled: runReminderEnabled ?? this.runReminderEnabled,
      runReminderDays: runReminderDays ?? this.runReminderDays,
      runReminderTimeMin: runReminderTimeMin ?? this.runReminderTimeMin,
      streakAlerts: streakAlerts ?? this.streakAlerts,
      weeklyGoalAlerts: weeklyGoalAlerts ?? this.weeklyGoalAlerts,
      goalAchievedAlerts: goalAchievedAlerts ?? this.goalAchievedAlerts,
      comebackAlerts: comebackAlerts ?? this.comebackAlerts,
      quietHoursStartMin: quietHoursStartMin ?? this.quietHoursStartMin,
      quietHoursEndMin: quietHoursEndMin ?? this.quietHoursEndMin,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (onboardingSeen.present) {
      map['onboarding_seen'] = Variable<bool>(onboardingSeen.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (notificationsEnabled.present) {
      map['notifications_enabled'] = Variable<bool>(notificationsEnabled.value);
    }
    if (runReminderEnabled.present) {
      map['run_reminder_enabled'] = Variable<bool>(runReminderEnabled.value);
    }
    if (runReminderDays.present) {
      map['run_reminder_days'] = Variable<String>(runReminderDays.value);
    }
    if (runReminderTimeMin.present) {
      map['run_reminder_time_min'] = Variable<int>(runReminderTimeMin.value);
    }
    if (streakAlerts.present) {
      map['streak_alerts'] = Variable<bool>(streakAlerts.value);
    }
    if (weeklyGoalAlerts.present) {
      map['weekly_goal_alerts'] = Variable<bool>(weeklyGoalAlerts.value);
    }
    if (goalAchievedAlerts.present) {
      map['goal_achieved_alerts'] = Variable<bool>(goalAchievedAlerts.value);
    }
    if (comebackAlerts.present) {
      map['comeback_alerts'] = Variable<bool>(comebackAlerts.value);
    }
    if (quietHoursStartMin.present) {
      map['quiet_hours_start_min'] = Variable<int>(quietHoursStartMin.value);
    }
    if (quietHoursEndMin.present) {
      map['quiet_hours_end_min'] = Variable<int>(quietHoursEndMin.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('weightKg: $weightKg, ')
          ..write('unit: $unit, ')
          ..write('onboardingSeen: $onboardingSeen, ')
          ..write('themeMode: $themeMode, ')
          ..write('displayName: $displayName, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('runReminderEnabled: $runReminderEnabled, ')
          ..write('runReminderDays: $runReminderDays, ')
          ..write('runReminderTimeMin: $runReminderTimeMin, ')
          ..write('streakAlerts: $streakAlerts, ')
          ..write('weeklyGoalAlerts: $weeklyGoalAlerts, ')
          ..write('goalAchievedAlerts: $goalAchievedAlerts, ')
          ..write('comebackAlerts: $comebackAlerts, ')
          ..write('quietHoursStartMin: $quietHoursStartMin, ')
          ..write('quietHoursEndMin: $quietHoursEndMin')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, GoalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metricMeta = const VerificationMeta('metric');
  @override
  late final GeneratedColumn<String> metric = GeneratedColumn<String>(
    'metric',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetValueMeta = const VerificationMeta(
    'targetValue',
  );
  @override
  late final GeneratedColumn<double> targetValue = GeneratedColumn<double>(
    'target_value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodMeta = const VerificationMeta('period');
  @override
  late final GeneratedColumn<String> period = GeneratedColumn<String>(
    'period',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('weekly'),
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    metric,
    targetValue,
    period,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<GoalRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('metric')) {
      context.handle(
        _metricMeta,
        metric.isAcceptableOrUnknown(data['metric']!, _metricMeta),
      );
    } else if (isInserting) {
      context.missing(_metricMeta);
    }
    if (data.containsKey('target_value')) {
      context.handle(
        _targetValueMeta,
        targetValue.isAcceptableOrUnknown(
          data['target_value']!,
          _targetValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetValueMeta);
    }
    if (data.containsKey('period')) {
      context.handle(
        _periodMeta,
        period.isAcceptableOrUnknown(data['period']!, _periodMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      metric: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metric'],
      )!,
      targetValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_value'],
      )!,
      period: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class GoalRow extends DataClass implements Insertable<GoalRow> {
  final String id;
  final String metric;
  final double targetValue;
  final String period;
  final bool synced;
  const GoalRow({
    required this.id,
    required this.metric,
    required this.targetValue,
    required this.period,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['metric'] = Variable<String>(metric);
    map['target_value'] = Variable<double>(targetValue);
    map['period'] = Variable<String>(period);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      metric: Value(metric),
      targetValue: Value(targetValue),
      period: Value(period),
      synced: Value(synced),
    );
  }

  factory GoalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalRow(
      id: serializer.fromJson<String>(json['id']),
      metric: serializer.fromJson<String>(json['metric']),
      targetValue: serializer.fromJson<double>(json['targetValue']),
      period: serializer.fromJson<String>(json['period']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'metric': serializer.toJson<String>(metric),
      'targetValue': serializer.toJson<double>(targetValue),
      'period': serializer.toJson<String>(period),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  GoalRow copyWith({
    String? id,
    String? metric,
    double? targetValue,
    String? period,
    bool? synced,
  }) => GoalRow(
    id: id ?? this.id,
    metric: metric ?? this.metric,
    targetValue: targetValue ?? this.targetValue,
    period: period ?? this.period,
    synced: synced ?? this.synced,
  );
  GoalRow copyWithCompanion(GoalsCompanion data) {
    return GoalRow(
      id: data.id.present ? data.id.value : this.id,
      metric: data.metric.present ? data.metric.value : this.metric,
      targetValue: data.targetValue.present
          ? data.targetValue.value
          : this.targetValue,
      period: data.period.present ? data.period.value : this.period,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalRow(')
          ..write('id: $id, ')
          ..write('metric: $metric, ')
          ..write('targetValue: $targetValue, ')
          ..write('period: $period, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, metric, targetValue, period, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalRow &&
          other.id == this.id &&
          other.metric == this.metric &&
          other.targetValue == this.targetValue &&
          other.period == this.period &&
          other.synced == this.synced);
}

class GoalsCompanion extends UpdateCompanion<GoalRow> {
  final Value<String> id;
  final Value<String> metric;
  final Value<double> targetValue;
  final Value<String> period;
  final Value<bool> synced;
  final Value<int> rowid;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.metric = const Value.absent(),
    this.targetValue = const Value.absent(),
    this.period = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsCompanion.insert({
    required String id,
    required String metric,
    required double targetValue,
    this.period = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       metric = Value(metric),
       targetValue = Value(targetValue);
  static Insertable<GoalRow> custom({
    Expression<String>? id,
    Expression<String>? metric,
    Expression<double>? targetValue,
    Expression<String>? period,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (metric != null) 'metric': metric,
      if (targetValue != null) 'target_value': targetValue,
      if (period != null) 'period': period,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsCompanion copyWith({
    Value<String>? id,
    Value<String>? metric,
    Value<double>? targetValue,
    Value<String>? period,
    Value<bool>? synced,
    Value<int>? rowid,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      metric: metric ?? this.metric,
      targetValue: targetValue ?? this.targetValue,
      period: period ?? this.period,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (metric.present) {
      map['metric'] = Variable<String>(metric.value);
    }
    if (targetValue.present) {
      map['target_value'] = Variable<double>(targetValue.value);
    }
    if (period.present) {
      map['period'] = Variable<String>(period.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('metric: $metric, ')
          ..write('targetValue: $targetValue, ')
          ..write('period: $period, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RunsTable runs = $RunsTable(this);
  late final $RunPointsTable runPoints = $RunPointsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final RunDao runDao = RunDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  late final GoalDao goalDao = GoalDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    runs,
    runPoints,
    settings,
    goals,
  ];
}

typedef $$RunsTableCreateCompanionBuilder =
    RunsCompanion Function({
      required String id,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<double> distanceM,
      Value<int> durationS,
      Value<double> avgPaceSPerKm,
      Value<double> caloriesEst,
      Value<bool> synced,
      Value<int> rowid,
    });
typedef $$RunsTableUpdateCompanionBuilder =
    RunsCompanion Function({
      Value<String> id,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<double> distanceM,
      Value<int> durationS,
      Value<double> avgPaceSPerKm,
      Value<double> caloriesEst,
      Value<bool> synced,
      Value<int> rowid,
    });

class $$RunsTableFilterComposer extends Composer<_$AppDatabase, $RunsTable> {
  $$RunsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationS => $composableBuilder(
    column: $table.durationS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgPaceSPerKm => $composableBuilder(
    column: $table.avgPaceSPerKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get caloriesEst => $composableBuilder(
    column: $table.caloriesEst,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RunsTableOrderingComposer extends Composer<_$AppDatabase, $RunsTable> {
  $$RunsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationS => $composableBuilder(
    column: $table.durationS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgPaceSPerKm => $composableBuilder(
    column: $table.avgPaceSPerKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get caloriesEst => $composableBuilder(
    column: $table.caloriesEst,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RunsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RunsTable> {
  $$RunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<double> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => column);

  GeneratedColumn<int> get durationS =>
      $composableBuilder(column: $table.durationS, builder: (column) => column);

  GeneratedColumn<double> get avgPaceSPerKm => $composableBuilder(
    column: $table.avgPaceSPerKm,
    builder: (column) => column,
  );

  GeneratedColumn<double> get caloriesEst => $composableBuilder(
    column: $table.caloriesEst,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$RunsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RunsTable,
          RunRow,
          $$RunsTableFilterComposer,
          $$RunsTableOrderingComposer,
          $$RunsTableAnnotationComposer,
          $$RunsTableCreateCompanionBuilder,
          $$RunsTableUpdateCompanionBuilder,
          (RunRow, BaseReferences<_$AppDatabase, $RunsTable, RunRow>),
          RunRow,
          PrefetchHooks Function()
        > {
  $$RunsTableTableManager(_$AppDatabase db, $RunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<double> distanceM = const Value.absent(),
                Value<int> durationS = const Value.absent(),
                Value<double> avgPaceSPerKm = const Value.absent(),
                Value<double> caloriesEst = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RunsCompanion(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                distanceM: distanceM,
                durationS: durationS,
                avgPaceSPerKm: avgPaceSPerKm,
                caloriesEst: caloriesEst,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<double> distanceM = const Value.absent(),
                Value<int> durationS = const Value.absent(),
                Value<double> avgPaceSPerKm = const Value.absent(),
                Value<double> caloriesEst = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RunsCompanion.insert(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                distanceM: distanceM,
                durationS: durationS,
                avgPaceSPerKm: avgPaceSPerKm,
                caloriesEst: caloriesEst,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RunsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RunsTable,
      RunRow,
      $$RunsTableFilterComposer,
      $$RunsTableOrderingComposer,
      $$RunsTableAnnotationComposer,
      $$RunsTableCreateCompanionBuilder,
      $$RunsTableUpdateCompanionBuilder,
      (RunRow, BaseReferences<_$AppDatabase, $RunsTable, RunRow>),
      RunRow,
      PrefetchHooks Function()
    >;
typedef $$RunPointsTableCreateCompanionBuilder =
    RunPointsCompanion Function({
      Value<int> id,
      required String runId,
      required double lat,
      required double lng,
      Value<double?> elevation,
      required DateTime timestamp,
      Value<double?> speed,
      Value<double?> accuracy,
    });
typedef $$RunPointsTableUpdateCompanionBuilder =
    RunPointsCompanion Function({
      Value<int> id,
      Value<String> runId,
      Value<double> lat,
      Value<double> lng,
      Value<double?> elevation,
      Value<DateTime> timestamp,
      Value<double?> speed,
      Value<double?> accuracy,
    });

class $$RunPointsTableFilterComposer
    extends Composer<_$AppDatabase, $RunPointsTable> {
  $$RunPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get elevation => $composableBuilder(
    column: $table.elevation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RunPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $RunPointsTable> {
  $$RunPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get elevation => $composableBuilder(
    column: $table.elevation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RunPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RunPointsTable> {
  $$RunPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get runId =>
      $composableBuilder(column: $table.runId, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<double> get elevation =>
      $composableBuilder(column: $table.elevation, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  GeneratedColumn<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);
}

class $$RunPointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RunPointsTable,
          RunPointRow,
          $$RunPointsTableFilterComposer,
          $$RunPointsTableOrderingComposer,
          $$RunPointsTableAnnotationComposer,
          $$RunPointsTableCreateCompanionBuilder,
          $$RunPointsTableUpdateCompanionBuilder,
          (
            RunPointRow,
            BaseReferences<_$AppDatabase, $RunPointsTable, RunPointRow>,
          ),
          RunPointRow,
          PrefetchHooks Function()
        > {
  $$RunPointsTableTableManager(_$AppDatabase db, $RunPointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RunPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RunPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RunPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> runId = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lng = const Value.absent(),
                Value<double?> elevation = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<double?> speed = const Value.absent(),
                Value<double?> accuracy = const Value.absent(),
              }) => RunPointsCompanion(
                id: id,
                runId: runId,
                lat: lat,
                lng: lng,
                elevation: elevation,
                timestamp: timestamp,
                speed: speed,
                accuracy: accuracy,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String runId,
                required double lat,
                required double lng,
                Value<double?> elevation = const Value.absent(),
                required DateTime timestamp,
                Value<double?> speed = const Value.absent(),
                Value<double?> accuracy = const Value.absent(),
              }) => RunPointsCompanion.insert(
                id: id,
                runId: runId,
                lat: lat,
                lng: lng,
                elevation: elevation,
                timestamp: timestamp,
                speed: speed,
                accuracy: accuracy,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RunPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RunPointsTable,
      RunPointRow,
      $$RunPointsTableFilterComposer,
      $$RunPointsTableOrderingComposer,
      $$RunPointsTableAnnotationComposer,
      $$RunPointsTableCreateCompanionBuilder,
      $$RunPointsTableUpdateCompanionBuilder,
      (
        RunPointRow,
        BaseReferences<_$AppDatabase, $RunPointsTable, RunPointRow>,
      ),
      RunPointRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      Value<int> id,
      Value<double> weightKg,
      Value<String> unit,
      Value<bool> onboardingSeen,
      Value<String> themeMode,
      Value<String?> displayName,
      Value<bool> notificationsEnabled,
      Value<bool> runReminderEnabled,
      Value<String> runReminderDays,
      Value<int> runReminderTimeMin,
      Value<bool> streakAlerts,
      Value<bool> weeklyGoalAlerts,
      Value<bool> goalAchievedAlerts,
      Value<bool> comebackAlerts,
      Value<int> quietHoursStartMin,
      Value<int> quietHoursEndMin,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<int> id,
      Value<double> weightKg,
      Value<String> unit,
      Value<bool> onboardingSeen,
      Value<String> themeMode,
      Value<String?> displayName,
      Value<bool> notificationsEnabled,
      Value<bool> runReminderEnabled,
      Value<String> runReminderDays,
      Value<int> runReminderTimeMin,
      Value<bool> streakAlerts,
      Value<bool> weeklyGoalAlerts,
      Value<bool> goalAchievedAlerts,
      Value<bool> comebackAlerts,
      Value<int> quietHoursStartMin,
      Value<int> quietHoursEndMin,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onboardingSeen => $composableBuilder(
    column: $table.onboardingSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get runReminderEnabled => $composableBuilder(
    column: $table.runReminderEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get runReminderDays => $composableBuilder(
    column: $table.runReminderDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get runReminderTimeMin => $composableBuilder(
    column: $table.runReminderTimeMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get streakAlerts => $composableBuilder(
    column: $table.streakAlerts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get weeklyGoalAlerts => $composableBuilder(
    column: $table.weeklyGoalAlerts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get goalAchievedAlerts => $composableBuilder(
    column: $table.goalAchievedAlerts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get comebackAlerts => $composableBuilder(
    column: $table.comebackAlerts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quietHoursStartMin => $composableBuilder(
    column: $table.quietHoursStartMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quietHoursEndMin => $composableBuilder(
    column: $table.quietHoursEndMin,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onboardingSeen => $composableBuilder(
    column: $table.onboardingSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get runReminderEnabled => $composableBuilder(
    column: $table.runReminderEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get runReminderDays => $composableBuilder(
    column: $table.runReminderDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get runReminderTimeMin => $composableBuilder(
    column: $table.runReminderTimeMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get streakAlerts => $composableBuilder(
    column: $table.streakAlerts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get weeklyGoalAlerts => $composableBuilder(
    column: $table.weeklyGoalAlerts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get goalAchievedAlerts => $composableBuilder(
    column: $table.goalAchievedAlerts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get comebackAlerts => $composableBuilder(
    column: $table.comebackAlerts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quietHoursStartMin => $composableBuilder(
    column: $table.quietHoursStartMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quietHoursEndMin => $composableBuilder(
    column: $table.quietHoursEndMin,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get onboardingSeen => $composableBuilder(
    column: $table.onboardingSeen,
    builder: (column) => column,
  );

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get runReminderEnabled => $composableBuilder(
    column: $table.runReminderEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get runReminderDays => $composableBuilder(
    column: $table.runReminderDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get runReminderTimeMin => $composableBuilder(
    column: $table.runReminderTimeMin,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get streakAlerts => $composableBuilder(
    column: $table.streakAlerts,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get weeklyGoalAlerts => $composableBuilder(
    column: $table.weeklyGoalAlerts,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get goalAchievedAlerts => $composableBuilder(
    column: $table.goalAchievedAlerts,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get comebackAlerts => $composableBuilder(
    column: $table.comebackAlerts,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quietHoursStartMin => $composableBuilder(
    column: $table.quietHoursStartMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quietHoursEndMin => $composableBuilder(
    column: $table.quietHoursEndMin,
    builder: (column) => column,
  );
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<bool> onboardingSeen = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<bool> notificationsEnabled = const Value.absent(),
                Value<bool> runReminderEnabled = const Value.absent(),
                Value<String> runReminderDays = const Value.absent(),
                Value<int> runReminderTimeMin = const Value.absent(),
                Value<bool> streakAlerts = const Value.absent(),
                Value<bool> weeklyGoalAlerts = const Value.absent(),
                Value<bool> goalAchievedAlerts = const Value.absent(),
                Value<bool> comebackAlerts = const Value.absent(),
                Value<int> quietHoursStartMin = const Value.absent(),
                Value<int> quietHoursEndMin = const Value.absent(),
              }) => SettingsCompanion(
                id: id,
                weightKg: weightKg,
                unit: unit,
                onboardingSeen: onboardingSeen,
                themeMode: themeMode,
                displayName: displayName,
                notificationsEnabled: notificationsEnabled,
                runReminderEnabled: runReminderEnabled,
                runReminderDays: runReminderDays,
                runReminderTimeMin: runReminderTimeMin,
                streakAlerts: streakAlerts,
                weeklyGoalAlerts: weeklyGoalAlerts,
                goalAchievedAlerts: goalAchievedAlerts,
                comebackAlerts: comebackAlerts,
                quietHoursStartMin: quietHoursStartMin,
                quietHoursEndMin: quietHoursEndMin,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<bool> onboardingSeen = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<bool> notificationsEnabled = const Value.absent(),
                Value<bool> runReminderEnabled = const Value.absent(),
                Value<String> runReminderDays = const Value.absent(),
                Value<int> runReminderTimeMin = const Value.absent(),
                Value<bool> streakAlerts = const Value.absent(),
                Value<bool> weeklyGoalAlerts = const Value.absent(),
                Value<bool> goalAchievedAlerts = const Value.absent(),
                Value<bool> comebackAlerts = const Value.absent(),
                Value<int> quietHoursStartMin = const Value.absent(),
                Value<int> quietHoursEndMin = const Value.absent(),
              }) => SettingsCompanion.insert(
                id: id,
                weightKg: weightKg,
                unit: unit,
                onboardingSeen: onboardingSeen,
                themeMode: themeMode,
                displayName: displayName,
                notificationsEnabled: notificationsEnabled,
                runReminderEnabled: runReminderEnabled,
                runReminderDays: runReminderDays,
                runReminderTimeMin: runReminderTimeMin,
                streakAlerts: streakAlerts,
                weeklyGoalAlerts: weeklyGoalAlerts,
                goalAchievedAlerts: goalAchievedAlerts,
                comebackAlerts: comebackAlerts,
                quietHoursStartMin: quietHoursStartMin,
                quietHoursEndMin: quietHoursEndMin,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$GoalsTableCreateCompanionBuilder =
    GoalsCompanion Function({
      required String id,
      required String metric,
      required double targetValue,
      Value<String> period,
      Value<bool> synced,
      Value<int> rowid,
    });
typedef $$GoalsTableUpdateCompanionBuilder =
    GoalsCompanion Function({
      Value<String> id,
      Value<String> metric,
      Value<double> targetValue,
      Value<String> period,
      Value<bool> synced,
      Value<int> rowid,
    });

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metric => $composableBuilder(
    column: $table.metric,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetValue => $composableBuilder(
    column: $table.targetValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metric => $composableBuilder(
    column: $table.metric,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetValue => $composableBuilder(
    column: $table.targetValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get metric =>
      $composableBuilder(column: $table.metric, builder: (column) => column);

  GeneratedColumn<double> get targetValue => $composableBuilder(
    column: $table.targetValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get period =>
      $composableBuilder(column: $table.period, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$GoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalsTable,
          GoalRow,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (GoalRow, BaseReferences<_$AppDatabase, $GoalsTable, GoalRow>),
          GoalRow,
          PrefetchHooks Function()
        > {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> metric = const Value.absent(),
                Value<double> targetValue = const Value.absent(),
                Value<String> period = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                metric: metric,
                targetValue: targetValue,
                period: period,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String metric,
                required double targetValue,
                Value<String> period = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion.insert(
                id: id,
                metric: metric,
                targetValue: targetValue,
                period: period,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalsTable,
      GoalRow,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (GoalRow, BaseReferences<_$AppDatabase, $GoalsTable, GoalRow>),
      GoalRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RunsTableTableManager get runs => $$RunsTableTableManager(_db, _db.runs);
  $$RunPointsTableTableManager get runPoints =>
      $$RunPointsTableTableManager(_db, _db.runPoints);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_dao.dart';

// ignore_for_file: type=lint
mixin _$RunDaoMixin on DatabaseAccessor<AppDatabase> {
  $RunsTable get runs => attachedDatabase.runs;
  $RunPointsTable get runPoints => attachedDatabase.runPoints;
  RunDaoManager get managers => RunDaoManager(this);
}

class RunDaoManager {
  final _$RunDaoMixin _db;
  RunDaoManager(this._db);
  $$RunsTableTableManager get runs =>
      $$RunsTableTableManager(_db.attachedDatabase, _db.runs);
  $$RunPointsTableTableManager get runPoints =>
      $$RunPointsTableTableManager(_db.attachedDatabase, _db.runPoints);
}

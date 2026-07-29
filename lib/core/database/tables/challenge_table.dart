import 'package:drift/drift.dart';

class Challenges extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get type => text()();
  IntColumn get durationDays => integer()();
  TextColumn get startDate => text()();
  TextColumn get createdBy => text().nullable()();
  IntColumn get participants => integer().withDefault(const Constant(0))();
  @override Set<Column> get primaryKey => {id};
}

class ChallengeParticipants extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get challengeId => text().references(Challenges, #id)();
  TextColumn get userName => text()();
  TextColumn get joinedDate => text()();
  IntColumn get progress => integer().withDefault(const Constant(0))();
  Set<Column> get uniqueKey => {challengeId, userName};
}

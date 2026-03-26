// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_behavior.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppBehaviorSnapshotAdapter extends TypeAdapter<AppBehaviorSnapshot> {
  @override
  final int typeId = 4;

  @override
  AppBehaviorSnapshot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppBehaviorSnapshot(
      packageName: fields[0] as String,
      recordedAt: fields[1] as DateTime,
      cpuUsage: fields[2] as double,
      ramUsageMb: fields[3] as double,
      networkTrafficMb: fields[4] as double,
      wakeLocksCount: fields[5] as int,
      suspicionScore: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AppBehaviorSnapshot obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.packageName)
      ..writeByte(1)
      ..write(obj.recordedAt)
      ..writeByte(2)
      ..write(obj.cpuUsage)
      ..writeByte(3)
      ..write(obj.ramUsageMb)
      ..writeByte(4)
      ..write(obj.networkTrafficMb)
      ..writeByte(5)
      ..write(obj.wakeLocksCount)
      ..writeByte(6)
      ..write(obj.suspicionScore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppBehaviorSnapshotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

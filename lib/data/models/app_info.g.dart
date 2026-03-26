// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppInfoAdapter extends TypeAdapter<AppInfo> {
  @override
  final int typeId = 0;

  @override
  AppInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppInfo(
      packageName: fields[0] as String,
      displayName: fields[1] as String,
      iconBase64: fields[2] as String?,
      permissions: (fields[3] as List).cast<String>(),
      cpuUsage: fields[4] as double,
      ramUsageMb: fields[5] as double,
      wakeLocksCount: fields[6] as int,
      hasAccessibilityService: fields[7] as bool,
      startsOnBoot: fields[8] as bool,
      networkTrafficMb: fields[9] as double,
      connectsToDatacenter: fields[10] as bool,
      suspicionScore: fields[11] as int,
      lastSeen: fields[12] as DateTime,
      versionName: fields[13] as String?,
      isSystemApp: fields[14] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppInfo obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.packageName)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.iconBase64)
      ..writeByte(3)
      ..write(obj.permissions)
      ..writeByte(4)
      ..write(obj.cpuUsage)
      ..writeByte(5)
      ..write(obj.ramUsageMb)
      ..writeByte(6)
      ..write(obj.wakeLocksCount)
      ..writeByte(7)
      ..write(obj.hasAccessibilityService)
      ..writeByte(8)
      ..write(obj.startsOnBoot)
      ..writeByte(9)
      ..write(obj.networkTrafficMb)
      ..writeByte(10)
      ..write(obj.connectsToDatacenter)
      ..writeByte(11)
      ..write(obj.suspicionScore)
      ..writeByte(12)
      ..write(obj.lastSeen)
      ..writeByte(13)
      ..write(obj.versionName)
      ..writeByte(14)
      ..write(obj.isSystemApp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

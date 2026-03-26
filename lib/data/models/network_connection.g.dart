// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_connection.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NetworkConnectionAdapter extends TypeAdapter<NetworkConnection> {
  @override
  final int typeId = 1;

  @override
  NetworkConnection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NetworkConnection(
      remoteIp: fields[0] as String,
      hostname: fields[1] as String,
      port: fields[2] as int,
      protocol: fields[3] as String,
      country: fields[4] as String?,
      countryCode: fields[5] as String?,
      provider: fields[6] as String?,
      isKnownDatacenter: fields[7] as bool,
      trafficKbps: fields[8] as double,
      suspicionScore: fields[9] as int,
      flags: (fields[10] as List).cast<String>(),
      firstSeen: fields[11] as DateTime,
      lastSeen: fields[12] as DateTime,
      relatedApp: fields[13] as String?,
      latitude: fields[14] as double?,
      longitude: fields[15] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, NetworkConnection obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.remoteIp)
      ..writeByte(1)
      ..write(obj.hostname)
      ..writeByte(2)
      ..write(obj.port)
      ..writeByte(3)
      ..write(obj.protocol)
      ..writeByte(4)
      ..write(obj.country)
      ..writeByte(5)
      ..write(obj.countryCode)
      ..writeByte(6)
      ..write(obj.provider)
      ..writeByte(7)
      ..write(obj.isKnownDatacenter)
      ..writeByte(8)
      ..write(obj.trafficKbps)
      ..writeByte(9)
      ..write(obj.suspicionScore)
      ..writeByte(10)
      ..write(obj.flags)
      ..writeByte(11)
      ..write(obj.firstSeen)
      ..writeByte(12)
      ..write(obj.lastSeen)
      ..writeByte(13)
      ..write(obj.relatedApp)
      ..writeByte(14)
      ..write(obj.latitude)
      ..writeByte(15)
      ..write(obj.longitude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkConnectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

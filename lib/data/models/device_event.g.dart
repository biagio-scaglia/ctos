// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeviceEventTypeAdapter extends TypeAdapter<DeviceEventType> {
  @override
  final int typeId = 2;

  @override
  DeviceEventType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DeviceEventType.cameraAccess;
      case 1:
        return DeviceEventType.microphoneAccess;
      case 2:
        return DeviceEventType.locationAccess;
      case 3:
        return DeviceEventType.networkSpike;
      case 4:
        return DeviceEventType.wakeLock;
      case 5:
        return DeviceEventType.appAutoStart;
      case 6:
        return DeviceEventType.permissionGranted;
      case 7:
        return DeviceEventType.permissionRevoked;
      case 8:
        return DeviceEventType.suspiciousProcess;
      case 9:
        return DeviceEventType.batteryDrain;
      case 10:
        return DeviceEventType.vpnDetected;
      case 11:
        return DeviceEventType.vpnDisconnected;
      case 12:
        return DeviceEventType.accessibilityEnabled;
      case 13:
        return DeviceEventType.unusualNetworkConnection;
      case 14:
        return DeviceEventType.highCpuUsage;
      default:
        return DeviceEventType.suspiciousProcess;
    }
  }

  @override
  void write(BinaryWriter writer, DeviceEventType obj) {
    switch (obj) {
      case DeviceEventType.cameraAccess:
        writer.writeByte(0);
        break;
      case DeviceEventType.microphoneAccess:
        writer.writeByte(1);
        break;
      case DeviceEventType.locationAccess:
        writer.writeByte(2);
        break;
      case DeviceEventType.networkSpike:
        writer.writeByte(3);
        break;
      case DeviceEventType.wakeLock:
        writer.writeByte(4);
        break;
      case DeviceEventType.appAutoStart:
        writer.writeByte(5);
        break;
      case DeviceEventType.permissionGranted:
        writer.writeByte(6);
        break;
      case DeviceEventType.permissionRevoked:
        writer.writeByte(7);
        break;
      case DeviceEventType.suspiciousProcess:
        writer.writeByte(8);
        break;
      case DeviceEventType.batteryDrain:
        writer.writeByte(9);
        break;
      case DeviceEventType.vpnDetected:
        writer.writeByte(10);
        break;
      case DeviceEventType.vpnDisconnected:
        writer.writeByte(11);
        break;
      case DeviceEventType.accessibilityEnabled:
        writer.writeByte(12);
        break;
      case DeviceEventType.unusualNetworkConnection:
        writer.writeByte(13);
        break;
      case DeviceEventType.highCpuUsage:
        writer.writeByte(14);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceEventTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DeviceEventAdapter extends TypeAdapter<DeviceEvent> {
  @override
  final int typeId = 3;

  @override
  DeviceEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeviceEvent(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      type: fields[2] as DeviceEventType,
      description: fields[3] as String,
      relatedApp: fields[4] as String?,
      severityLevel: fields[5] as int,
      metadata: (fields[6] as Map?)?.cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, DeviceEvent obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.relatedApp)
      ..writeByte(5)
      ..write(obj.severityLevel)
      ..writeByte(6)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_contact_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedContactModelAdapter extends TypeAdapter<CachedContactModel> {
  @override
  final int typeId = 3;

  @override
  CachedContactModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedContactModel(
      phone: fields[0] as String,
      cachedAt: fields[5] as DateTime,
      isOnVelora: fields[6] as bool,
      displayName: fields[7] as String,
      uid: fields[1] as String?,
      veloraName: fields[2] as String?,
      photoUrl: fields[3] as String?,
      username: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CachedContactModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.phone)
      ..writeByte(1)
      ..write(obj.uid)
      ..writeByte(2)
      ..write(obj.veloraName)
      ..writeByte(3)
      ..write(obj.photoUrl)
      ..writeByte(4)
      ..write(obj.username)
      ..writeByte(5)
      ..write(obj.cachedAt)
      ..writeByte(6)
      ..write(obj.isOnVelora)
      ..writeByte(7)
      ..write(obj.displayName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedContactModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

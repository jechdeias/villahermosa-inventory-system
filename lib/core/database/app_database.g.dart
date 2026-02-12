// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _passwordHashMeta = const VerificationMeta(
    'passwordHash',
  );
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
    'password_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    email,
    passwordHash,
    role,
    phone,
    address,
    isActive,
    createdAt,
    updatedAt,
    isDeleted,
    syncStatus,
    remoteId,
    uuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
        _passwordHashMeta,
        passwordHash.isAcceptableOrUnknown(
          data['password_hash']!,
          _passwordHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      email:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}email'],
          )!,
      passwordHash:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}password_hash'],
          )!,
      role:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}role'],
          )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      isActive:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_active'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
      isDeleted:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_deleted'],
          )!,
      syncStatus:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}sync_status'],
          )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      uuid:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}uuid'],
          )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  /// Auto increment primary key for the user record.
  final int id;

  /// User's name for identification purposes.
  final String name;

  /// User's email address for authentication and identification.
  final String email;

  /// Hashed password for secure authentication storage.
  /// Never stores plain text passwords for security reasons.
  final String passwordHash;

  /// User role determining permissions and access level.
  /// Valid values: admin, warehouse, customer, delivery.
  final String role;

  /// User's phone number (optional).
  final String? phone;

  /// User's address (optional).
  final String? address;

  /// Indicates whether the user account is currently active.
  /// Inactive users cannot authenticate or access the system.
  final bool isActive;

  /// Timestamp when the user record was created.
  final DateTime createdAt;

  /// Timestamp when the user record was last updated.
  final DateTime updatedAt;

  /// Soft delete flag for logical deletion.
  /// Allows recovery of deleted records and maintains data integrity.
  final bool isDeleted;

  /// Synchronization status with remote backend.
  /// Tracks whether local changes need to be synced.
  final String syncStatus;

  /// Remote database ID for cross-system synchronization.
  /// Null for local-only records until synced.
  final String? remoteId;

  /// UUID for cross-system synchronization.
  final String uuid;
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.role,
    this.phone,
    this.address,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
    required this.syncStatus,
    this.remoteId,
    required this.uuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['email'] = Variable<String>(email);
    map['password_hash'] = Variable<String>(passwordHash);
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['uuid'] = Variable<String>(uuid);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      email: Value(email),
      passwordHash: Value(passwordHash),
      role: Value(role),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      address:
          address == null && nullToAbsent
              ? const Value.absent()
              : Value(address),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
      syncStatus: Value(syncStatus),
      remoteId:
          remoteId == null && nullToAbsent
              ? const Value.absent()
              : Value(remoteId),
      uuid: Value(uuid),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String>(json['email']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      role: serializer.fromJson<String>(json['role']),
      phone: serializer.fromJson<String?>(json['phone']),
      address: serializer.fromJson<String?>(json['address']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      uuid: serializer.fromJson<String>(json['uuid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String>(email),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'role': serializer.toJson<String>(role),
      'phone': serializer.toJson<String?>(phone),
      'address': serializer.toJson<String?>(address),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'remoteId': serializer.toJson<String?>(remoteId),
      'uuid': serializer.toJson<String>(uuid),
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? passwordHash,
    String? role,
    Value<String?> phone = const Value.absent(),
    Value<String?> address = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    String? syncStatus,
    Value<String?> remoteId = const Value.absent(),
    String? uuid,
  }) => User(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    passwordHash: passwordHash ?? this.passwordHash,
    role: role ?? this.role,
    phone: phone.present ? phone.value : this.phone,
    address: address.present ? address.value : this.address,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
    syncStatus: syncStatus ?? this.syncStatus,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    uuid: uuid ?? this.uuid,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      passwordHash:
          data.passwordHash.present
              ? data.passwordHash.value
              : this.passwordHash,
      role: data.role.present ? data.role.value : this.role,
      phone: data.phone.present ? data.phone.value : this.phone,
      address: data.address.present ? data.address.value : this.address,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('role: $role, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('uuid: $uuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    email,
    passwordHash,
    role,
    phone,
    address,
    isActive,
    createdAt,
    updatedAt,
    isDeleted,
    syncStatus,
    remoteId,
    uuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.name == this.name &&
          other.email == this.email &&
          other.passwordHash == this.passwordHash &&
          other.role == this.role &&
          other.phone == this.phone &&
          other.address == this.address &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted &&
          other.syncStatus == this.syncStatus &&
          other.remoteId == this.remoteId &&
          other.uuid == this.uuid);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> email;
  final Value<String> passwordHash;
  final Value<String> role;
  final Value<String?> phone;
  final Value<String?> address;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isDeleted;
  final Value<String> syncStatus;
  final Value<String?> remoteId;
  final Value<String> uuid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.role = const Value.absent(),
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.uuid = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String email,
    required String passwordHash,
    required String role,
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    required String uuid,
  }) : name = Value(name),
       email = Value(email),
       passwordHash = Value(passwordHash),
       role = Value(role),
       uuid = Value(uuid);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? passwordHash,
    Expression<String>? role,
    Expression<String>? phone,
    Expression<String>? address,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<String>? syncStatus,
    Expression<String>? remoteId,
    Expression<String>? uuid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (role != null) 'role': role,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (remoteId != null) 'remote_id': remoteId,
      if (uuid != null) 'uuid': uuid,
    });
  }

  UsersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? email,
    Value<String>? passwordHash,
    Value<String>? role,
    Value<String?>? phone,
    Value<String?>? address,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? isDeleted,
    Value<String>? syncStatus,
    Value<String?>? remoteId,
    Value<String>? uuid,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteId: remoteId ?? this.remoteId,
      uuid: uuid ?? this.uuid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('role: $role, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('uuid: $uuid')
          ..write(')'))
        .toString();
  }
}

class $CustomersTable extends Customers
    with TableInfo<$CustomersTable, Customer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _businessNameMeta = const VerificationMeta(
    'businessName',
  );
  @override
  late final GeneratedColumn<String> businessName = GeneratedColumn<String>(
    'business_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taxIdMeta = const VerificationMeta('taxId');
  @override
  late final GeneratedColumn<String> taxId = GeneratedColumn<String>(
    'tax_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerTypeMeta = const VerificationMeta(
    'customerType',
  );
  @override
  late final GeneratedColumn<String> customerType = GeneratedColumn<String>(
    'customer_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('individual'),
  );
  static const VerificationMeta _creditLimitMeta = const VerificationMeta(
    'creditLimit',
  );
  @override
  late final GeneratedColumn<double> creditLimit = GeneratedColumn<double>(
    'credit_limit',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentTermsMeta = const VerificationMeta(
    'paymentTerms',
  );
  @override
  late final GeneratedColumn<String> paymentTerms = GeneratedColumn<String>(
    'payment_terms',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _preferredContactMethodMeta =
      const VerificationMeta('preferredContactMethod');
  @override
  late final GeneratedColumn<String> preferredContactMethod =
      GeneratedColumn<String>(
        'preferred_contact_method',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('email'),
      );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    name,
    email,
    phone,
    address,
    businessName,
    taxId,
    customerType,
    creditLimit,
    paymentTerms,
    status,
    preferredContactMethod,
    isDeleted,
    remoteId,
    syncStatus,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Customer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('business_name')) {
      context.handle(
        _businessNameMeta,
        businessName.isAcceptableOrUnknown(
          data['business_name']!,
          _businessNameMeta,
        ),
      );
    }
    if (data.containsKey('tax_id')) {
      context.handle(
        _taxIdMeta,
        taxId.isAcceptableOrUnknown(data['tax_id']!, _taxIdMeta),
      );
    }
    if (data.containsKey('customer_type')) {
      context.handle(
        _customerTypeMeta,
        customerType.isAcceptableOrUnknown(
          data['customer_type']!,
          _customerTypeMeta,
        ),
      );
    }
    if (data.containsKey('credit_limit')) {
      context.handle(
        _creditLimitMeta,
        creditLimit.isAcceptableOrUnknown(
          data['credit_limit']!,
          _creditLimitMeta,
        ),
      );
    }
    if (data.containsKey('payment_terms')) {
      context.handle(
        _paymentTermsMeta,
        paymentTerms.isAcceptableOrUnknown(
          data['payment_terms']!,
          _paymentTermsMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('preferred_contact_method')) {
      context.handle(
        _preferredContactMethodMeta,
        preferredContactMethod.isAcceptableOrUnknown(
          data['preferred_contact_method']!,
          _preferredContactMethodMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Customer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Customer(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      uuid:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}uuid'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      email:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}email'],
          )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      businessName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_name'],
      ),
      taxId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tax_id'],
      ),
      customerType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}customer_type'],
          )!,
      creditLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}credit_limit'],
      ),
      paymentTerms: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_terms'],
      ),
      status:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}status'],
          )!,
      preferredContactMethod:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}preferred_contact_method'],
          )!,
      isDeleted:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_deleted'],
          )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      syncStatus:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}sync_status'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $CustomersTable createAlias(String alias) {
    return $CustomersTable(attachedDatabase, alias);
  }
}

class Customer extends DataClass implements Insertable<Customer> {
  final int id;
  final String uuid;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? businessName;
  final String? taxId;
  final String customerType;
  final double? creditLimit;
  final String? paymentTerms;
  final String status;
  final String preferredContactMethod;
  final bool isDeleted;
  final String? remoteId;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Customer({
    required this.id,
    required this.uuid,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.businessName,
    this.taxId,
    required this.customerType,
    this.creditLimit,
    this.paymentTerms,
    required this.status,
    required this.preferredContactMethod,
    required this.isDeleted,
    this.remoteId,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['name'] = Variable<String>(name);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || businessName != null) {
      map['business_name'] = Variable<String>(businessName);
    }
    if (!nullToAbsent || taxId != null) {
      map['tax_id'] = Variable<String>(taxId);
    }
    map['customer_type'] = Variable<String>(customerType);
    if (!nullToAbsent || creditLimit != null) {
      map['credit_limit'] = Variable<double>(creditLimit);
    }
    if (!nullToAbsent || paymentTerms != null) {
      map['payment_terms'] = Variable<String>(paymentTerms);
    }
    map['status'] = Variable<String>(status);
    map['preferred_contact_method'] = Variable<String>(preferredContactMethod);
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      uuid: Value(uuid),
      name: Value(name),
      email: Value(email),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      address:
          address == null && nullToAbsent
              ? const Value.absent()
              : Value(address),
      businessName:
          businessName == null && nullToAbsent
              ? const Value.absent()
              : Value(businessName),
      taxId:
          taxId == null && nullToAbsent ? const Value.absent() : Value(taxId),
      customerType: Value(customerType),
      creditLimit:
          creditLimit == null && nullToAbsent
              ? const Value.absent()
              : Value(creditLimit),
      paymentTerms:
          paymentTerms == null && nullToAbsent
              ? const Value.absent()
              : Value(paymentTerms),
      status: Value(status),
      preferredContactMethod: Value(preferredContactMethod),
      isDeleted: Value(isDeleted),
      remoteId:
          remoteId == null && nullToAbsent
              ? const Value.absent()
              : Value(remoteId),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Customer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Customer(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String>(json['email']),
      phone: serializer.fromJson<String?>(json['phone']),
      address: serializer.fromJson<String?>(json['address']),
      businessName: serializer.fromJson<String?>(json['businessName']),
      taxId: serializer.fromJson<String?>(json['taxId']),
      customerType: serializer.fromJson<String>(json['customerType']),
      creditLimit: serializer.fromJson<double?>(json['creditLimit']),
      paymentTerms: serializer.fromJson<String?>(json['paymentTerms']),
      status: serializer.fromJson<String>(json['status']),
      preferredContactMethod: serializer.fromJson<String>(
        json['preferredContactMethod'],
      ),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String>(email),
      'phone': serializer.toJson<String?>(phone),
      'address': serializer.toJson<String?>(address),
      'businessName': serializer.toJson<String?>(businessName),
      'taxId': serializer.toJson<String?>(taxId),
      'customerType': serializer.toJson<String>(customerType),
      'creditLimit': serializer.toJson<double?>(creditLimit),
      'paymentTerms': serializer.toJson<String?>(paymentTerms),
      'status': serializer.toJson<String>(status),
      'preferredContactMethod': serializer.toJson<String>(
        preferredContactMethod,
      ),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'remoteId': serializer.toJson<String?>(remoteId),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Customer copyWith({
    int? id,
    String? uuid,
    String? name,
    String? email,
    Value<String?> phone = const Value.absent(),
    Value<String?> address = const Value.absent(),
    Value<String?> businessName = const Value.absent(),
    Value<String?> taxId = const Value.absent(),
    String? customerType,
    Value<double?> creditLimit = const Value.absent(),
    Value<String?> paymentTerms = const Value.absent(),
    String? status,
    String? preferredContactMethod,
    bool? isDeleted,
    Value<String?> remoteId = const Value.absent(),
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Customer(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone.present ? phone.value : this.phone,
    address: address.present ? address.value : this.address,
    businessName: businessName.present ? businessName.value : this.businessName,
    taxId: taxId.present ? taxId.value : this.taxId,
    customerType: customerType ?? this.customerType,
    creditLimit: creditLimit.present ? creditLimit.value : this.creditLimit,
    paymentTerms: paymentTerms.present ? paymentTerms.value : this.paymentTerms,
    status: status ?? this.status,
    preferredContactMethod:
        preferredContactMethod ?? this.preferredContactMethod,
    isDeleted: isDeleted ?? this.isDeleted,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Customer copyWithCompanion(CustomersCompanion data) {
    return Customer(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      phone: data.phone.present ? data.phone.value : this.phone,
      address: data.address.present ? data.address.value : this.address,
      businessName:
          data.businessName.present
              ? data.businessName.value
              : this.businessName,
      taxId: data.taxId.present ? data.taxId.value : this.taxId,
      customerType:
          data.customerType.present
              ? data.customerType.value
              : this.customerType,
      creditLimit:
          data.creditLimit.present ? data.creditLimit.value : this.creditLimit,
      paymentTerms:
          data.paymentTerms.present
              ? data.paymentTerms.value
              : this.paymentTerms,
      status: data.status.present ? data.status.value : this.status,
      preferredContactMethod:
          data.preferredContactMethod.present
              ? data.preferredContactMethod.value
              : this.preferredContactMethod,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Customer(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('businessName: $businessName, ')
          ..write('taxId: $taxId, ')
          ..write('customerType: $customerType, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('paymentTerms: $paymentTerms, ')
          ..write('status: $status, ')
          ..write('preferredContactMethod: $preferredContactMethod, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('remoteId: $remoteId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    name,
    email,
    phone,
    address,
    businessName,
    taxId,
    customerType,
    creditLimit,
    paymentTerms,
    status,
    preferredContactMethod,
    isDeleted,
    remoteId,
    syncStatus,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Customer &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.name == this.name &&
          other.email == this.email &&
          other.phone == this.phone &&
          other.address == this.address &&
          other.businessName == this.businessName &&
          other.taxId == this.taxId &&
          other.customerType == this.customerType &&
          other.creditLimit == this.creditLimit &&
          other.paymentTerms == this.paymentTerms &&
          other.status == this.status &&
          other.preferredContactMethod == this.preferredContactMethod &&
          other.isDeleted == this.isDeleted &&
          other.remoteId == this.remoteId &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CustomersCompanion extends UpdateCompanion<Customer> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> name;
  final Value<String> email;
  final Value<String?> phone;
  final Value<String?> address;
  final Value<String?> businessName;
  final Value<String?> taxId;
  final Value<String> customerType;
  final Value<double?> creditLimit;
  final Value<String?> paymentTerms;
  final Value<String> status;
  final Value<String> preferredContactMethod;
  final Value<bool> isDeleted;
  final Value<String?> remoteId;
  final Value<String> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.businessName = const Value.absent(),
    this.taxId = const Value.absent(),
    this.customerType = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.paymentTerms = const Value.absent(),
    this.status = const Value.absent(),
    this.preferredContactMethod = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CustomersCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String name,
    required String email,
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.businessName = const Value.absent(),
    this.taxId = const Value.absent(),
    this.customerType = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.paymentTerms = const Value.absent(),
    this.status = const Value.absent(),
    this.preferredContactMethod = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : uuid = Value(uuid),
       name = Value(name),
       email = Value(email);
  static Insertable<Customer> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? phone,
    Expression<String>? address,
    Expression<String>? businessName,
    Expression<String>? taxId,
    Expression<String>? customerType,
    Expression<double>? creditLimit,
    Expression<String>? paymentTerms,
    Expression<String>? status,
    Expression<String>? preferredContactMethod,
    Expression<bool>? isDeleted,
    Expression<String>? remoteId,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (businessName != null) 'business_name': businessName,
      if (taxId != null) 'tax_id': taxId,
      if (customerType != null) 'customer_type': customerType,
      if (creditLimit != null) 'credit_limit': creditLimit,
      if (paymentTerms != null) 'payment_terms': paymentTerms,
      if (status != null) 'status': status,
      if (preferredContactMethod != null)
        'preferred_contact_method': preferredContactMethod,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (remoteId != null) 'remote_id': remoteId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CustomersCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? name,
    Value<String>? email,
    Value<String?>? phone,
    Value<String?>? address,
    Value<String?>? businessName,
    Value<String?>? taxId,
    Value<String>? customerType,
    Value<double?>? creditLimit,
    Value<String?>? paymentTerms,
    Value<String>? status,
    Value<String>? preferredContactMethod,
    Value<bool>? isDeleted,
    Value<String?>? remoteId,
    Value<String>? syncStatus,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CustomersCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      businessName: businessName ?? this.businessName,
      taxId: taxId ?? this.taxId,
      customerType: customerType ?? this.customerType,
      creditLimit: creditLimit ?? this.creditLimit,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      status: status ?? this.status,
      preferredContactMethod:
          preferredContactMethod ?? this.preferredContactMethod,
      isDeleted: isDeleted ?? this.isDeleted,
      remoteId: remoteId ?? this.remoteId,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (businessName.present) {
      map['business_name'] = Variable<String>(businessName.value);
    }
    if (taxId.present) {
      map['tax_id'] = Variable<String>(taxId.value);
    }
    if (customerType.present) {
      map['customer_type'] = Variable<String>(customerType.value);
    }
    if (creditLimit.present) {
      map['credit_limit'] = Variable<double>(creditLimit.value);
    }
    if (paymentTerms.present) {
      map['payment_terms'] = Variable<String>(paymentTerms.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (preferredContactMethod.present) {
      map['preferred_contact_method'] = Variable<String>(
        preferredContactMethod.value,
      );
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('businessName: $businessName, ')
          ..write('taxId: $taxId, ')
          ..write('customerType: $customerType, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('paymentTerms: $paymentTerms, ')
          ..write('status: $status, ')
          ..write('preferredContactMethod: $preferredContactMethod, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('remoteId: $remoteId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentStockMeta = const VerificationMeta(
    'currentStock',
  );
  @override
  late final GeneratedColumn<int> currentStock = GeneratedColumn<int>(
    'current_stock',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _minStockMeta = const VerificationMeta(
    'minStock',
  );
  @override
  late final GeneratedColumn<int> minStock = GeneratedColumn<int>(
    'min_stock',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _maxStockMeta = const VerificationMeta(
    'maxStock',
  );
  @override
  late final GeneratedColumn<int> maxStock = GeneratedColumn<int>(
    'max_stock',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dimensionsMeta = const VerificationMeta(
    'dimensions',
  );
  @override
  late final GeneratedColumn<String> dimensions = GeneratedColumn<String>(
    'dimensions',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costPriceMeta = const VerificationMeta(
    'costPrice',
  );
  @override
  late final GeneratedColumn<double> costPrice = GeneratedColumn<double>(
    'cost_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wholesalePriceMeta = const VerificationMeta(
    'wholesalePrice',
  );
  @override
  late final GeneratedColumn<double> wholesalePrice = GeneratedColumn<double>(
    'wholesale_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PHP'),
  );
  static const VerificationMeta _supplierMeta = const VerificationMeta(
    'supplier',
  );
  @override
  late final GeneratedColumn<String> supplier = GeneratedColumn<String>(
    'supplier',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _supplierSkuMeta = const VerificationMeta(
    'supplierSku',
  );
  @override
  late final GeneratedColumn<String> supplierSku = GeneratedColumn<String>(
    'supplier_sku',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _leadTimeDaysMeta = const VerificationMeta(
    'leadTimeDays',
  );
  @override
  late final GeneratedColumn<int> leadTimeDays = GeneratedColumn<int>(
    'lead_time_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    sku,
    name,
    description,
    category,
    brand,
    currentStock,
    minStock,
    maxStock,
    unit,
    weight,
    dimensions,
    unitPrice,
    costPrice,
    wholesalePrice,
    currency,
    supplier,
    supplierSku,
    leadTimeDays,
    status,
    location,
    barcode,
    tags,
    isDeleted,
    syncStatus,
    remoteId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    } else if (isInserting) {
      context.missing(_skuMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('current_stock')) {
      context.handle(
        _currentStockMeta,
        currentStock.isAcceptableOrUnknown(
          data['current_stock']!,
          _currentStockMeta,
        ),
      );
    }
    if (data.containsKey('min_stock')) {
      context.handle(
        _minStockMeta,
        minStock.isAcceptableOrUnknown(data['min_stock']!, _minStockMeta),
      );
    }
    if (data.containsKey('max_stock')) {
      context.handle(
        _maxStockMeta,
        maxStock.isAcceptableOrUnknown(data['max_stock']!, _maxStockMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    }
    if (data.containsKey('dimensions')) {
      context.handle(
        _dimensionsMeta,
        dimensions.isAcceptableOrUnknown(data['dimensions']!, _dimensionsMeta),
      );
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('cost_price')) {
      context.handle(
        _costPriceMeta,
        costPrice.isAcceptableOrUnknown(data['cost_price']!, _costPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_costPriceMeta);
    }
    if (data.containsKey('wholesale_price')) {
      context.handle(
        _wholesalePriceMeta,
        wholesalePrice.isAcceptableOrUnknown(
          data['wholesale_price']!,
          _wholesalePriceMeta,
        ),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('supplier')) {
      context.handle(
        _supplierMeta,
        supplier.isAcceptableOrUnknown(data['supplier']!, _supplierMeta),
      );
    }
    if (data.containsKey('supplier_sku')) {
      context.handle(
        _supplierSkuMeta,
        supplierSku.isAcceptableOrUnknown(
          data['supplier_sku']!,
          _supplierSkuMeta,
        ),
      );
    }
    if (data.containsKey('lead_time_days')) {
      context.handle(
        _leadTimeDaysMeta,
        leadTimeDays.isAcceptableOrUnknown(
          data['lead_time_days']!,
          _leadTimeDaysMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      uuid:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}uuid'],
          )!,
      sku:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}sku'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      category:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}category'],
          )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      currentStock:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}current_stock'],
          )!,
      minStock:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}min_stock'],
          )!,
      maxStock: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_stock'],
      ),
      unit:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}unit'],
          )!,
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      ),
      dimensions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dimensions'],
      ),
      unitPrice:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}unit_price'],
          )!,
      costPrice:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}cost_price'],
          )!,
      wholesalePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}wholesale_price'],
      ),
      currency:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}currency'],
          )!,
      supplier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier'],
      ),
      supplierSku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier_sku'],
      ),
      leadTimeDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lead_time_days'],
      ),
      status:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}status'],
          )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      isDeleted:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_deleted'],
          )!,
      syncStatus:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}sync_status'],
          )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final int id;
  final String uuid;
  final String sku;
  final String name;
  final String? description;
  final String category;
  final String? brand;
  final int currentStock;
  final int minStock;
  final int? maxStock;
  final String unit;
  final double? weight;
  final String? dimensions;
  final double unitPrice;
  final double costPrice;
  final double? wholesalePrice;
  final String currency;
  final String? supplier;
  final String? supplierSku;
  final int? leadTimeDays;
  final String status;
  final String? location;
  final String? barcode;
  final String? tags;
  final bool isDeleted;
  final String syncStatus;
  final String? remoteId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Product({
    required this.id,
    required this.uuid,
    required this.sku,
    required this.name,
    this.description,
    required this.category,
    this.brand,
    required this.currentStock,
    required this.minStock,
    this.maxStock,
    required this.unit,
    this.weight,
    this.dimensions,
    required this.unitPrice,
    required this.costPrice,
    this.wholesalePrice,
    required this.currency,
    this.supplier,
    this.supplierSku,
    this.leadTimeDays,
    required this.status,
    this.location,
    this.barcode,
    this.tags,
    required this.isDeleted,
    required this.syncStatus,
    this.remoteId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['sku'] = Variable<String>(sku);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    map['current_stock'] = Variable<int>(currentStock);
    map['min_stock'] = Variable<int>(minStock);
    if (!nullToAbsent || maxStock != null) {
      map['max_stock'] = Variable<int>(maxStock);
    }
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || weight != null) {
      map['weight'] = Variable<double>(weight);
    }
    if (!nullToAbsent || dimensions != null) {
      map['dimensions'] = Variable<String>(dimensions);
    }
    map['unit_price'] = Variable<double>(unitPrice);
    map['cost_price'] = Variable<double>(costPrice);
    if (!nullToAbsent || wholesalePrice != null) {
      map['wholesale_price'] = Variable<double>(wholesalePrice);
    }
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || supplier != null) {
      map['supplier'] = Variable<String>(supplier);
    }
    if (!nullToAbsent || supplierSku != null) {
      map['supplier_sku'] = Variable<String>(supplierSku);
    }
    if (!nullToAbsent || leadTimeDays != null) {
      map['lead_time_days'] = Variable<int>(leadTimeDays);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      sku: Value(sku),
      name: Value(name),
      description:
          description == null && nullToAbsent
              ? const Value.absent()
              : Value(description),
      category: Value(category),
      brand:
          brand == null && nullToAbsent ? const Value.absent() : Value(brand),
      currentStock: Value(currentStock),
      minStock: Value(minStock),
      maxStock:
          maxStock == null && nullToAbsent
              ? const Value.absent()
              : Value(maxStock),
      unit: Value(unit),
      weight:
          weight == null && nullToAbsent ? const Value.absent() : Value(weight),
      dimensions:
          dimensions == null && nullToAbsent
              ? const Value.absent()
              : Value(dimensions),
      unitPrice: Value(unitPrice),
      costPrice: Value(costPrice),
      wholesalePrice:
          wholesalePrice == null && nullToAbsent
              ? const Value.absent()
              : Value(wholesalePrice),
      currency: Value(currency),
      supplier:
          supplier == null && nullToAbsent
              ? const Value.absent()
              : Value(supplier),
      supplierSku:
          supplierSku == null && nullToAbsent
              ? const Value.absent()
              : Value(supplierSku),
      leadTimeDays:
          leadTimeDays == null && nullToAbsent
              ? const Value.absent()
              : Value(leadTimeDays),
      status: Value(status),
      location:
          location == null && nullToAbsent
              ? const Value.absent()
              : Value(location),
      barcode:
          barcode == null && nullToAbsent
              ? const Value.absent()
              : Value(barcode),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      isDeleted: Value(isDeleted),
      syncStatus: Value(syncStatus),
      remoteId:
          remoteId == null && nullToAbsent
              ? const Value.absent()
              : Value(remoteId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      sku: serializer.fromJson<String>(json['sku']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      category: serializer.fromJson<String>(json['category']),
      brand: serializer.fromJson<String?>(json['brand']),
      currentStock: serializer.fromJson<int>(json['currentStock']),
      minStock: serializer.fromJson<int>(json['minStock']),
      maxStock: serializer.fromJson<int?>(json['maxStock']),
      unit: serializer.fromJson<String>(json['unit']),
      weight: serializer.fromJson<double?>(json['weight']),
      dimensions: serializer.fromJson<String?>(json['dimensions']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      costPrice: serializer.fromJson<double>(json['costPrice']),
      wholesalePrice: serializer.fromJson<double?>(json['wholesalePrice']),
      currency: serializer.fromJson<String>(json['currency']),
      supplier: serializer.fromJson<String?>(json['supplier']),
      supplierSku: serializer.fromJson<String?>(json['supplierSku']),
      leadTimeDays: serializer.fromJson<int?>(json['leadTimeDays']),
      status: serializer.fromJson<String>(json['status']),
      location: serializer.fromJson<String?>(json['location']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      tags: serializer.fromJson<String?>(json['tags']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'sku': serializer.toJson<String>(sku),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'category': serializer.toJson<String>(category),
      'brand': serializer.toJson<String?>(brand),
      'currentStock': serializer.toJson<int>(currentStock),
      'minStock': serializer.toJson<int>(minStock),
      'maxStock': serializer.toJson<int?>(maxStock),
      'unit': serializer.toJson<String>(unit),
      'weight': serializer.toJson<double?>(weight),
      'dimensions': serializer.toJson<String?>(dimensions),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'costPrice': serializer.toJson<double>(costPrice),
      'wholesalePrice': serializer.toJson<double?>(wholesalePrice),
      'currency': serializer.toJson<String>(currency),
      'supplier': serializer.toJson<String?>(supplier),
      'supplierSku': serializer.toJson<String?>(supplierSku),
      'leadTimeDays': serializer.toJson<int?>(leadTimeDays),
      'status': serializer.toJson<String>(status),
      'location': serializer.toJson<String?>(location),
      'barcode': serializer.toJson<String?>(barcode),
      'tags': serializer.toJson<String?>(tags),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'remoteId': serializer.toJson<String?>(remoteId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Product copyWith({
    int? id,
    String? uuid,
    String? sku,
    String? name,
    Value<String?> description = const Value.absent(),
    String? category,
    Value<String?> brand = const Value.absent(),
    int? currentStock,
    int? minStock,
    Value<int?> maxStock = const Value.absent(),
    String? unit,
    Value<double?> weight = const Value.absent(),
    Value<String?> dimensions = const Value.absent(),
    double? unitPrice,
    double? costPrice,
    Value<double?> wholesalePrice = const Value.absent(),
    String? currency,
    Value<String?> supplier = const Value.absent(),
    Value<String?> supplierSku = const Value.absent(),
    Value<int?> leadTimeDays = const Value.absent(),
    String? status,
    Value<String?> location = const Value.absent(),
    Value<String?> barcode = const Value.absent(),
    Value<String?> tags = const Value.absent(),
    bool? isDeleted,
    String? syncStatus,
    Value<String?> remoteId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Product(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    sku: sku ?? this.sku,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    category: category ?? this.category,
    brand: brand.present ? brand.value : this.brand,
    currentStock: currentStock ?? this.currentStock,
    minStock: minStock ?? this.minStock,
    maxStock: maxStock.present ? maxStock.value : this.maxStock,
    unit: unit ?? this.unit,
    weight: weight.present ? weight.value : this.weight,
    dimensions: dimensions.present ? dimensions.value : this.dimensions,
    unitPrice: unitPrice ?? this.unitPrice,
    costPrice: costPrice ?? this.costPrice,
    wholesalePrice:
        wholesalePrice.present ? wholesalePrice.value : this.wholesalePrice,
    currency: currency ?? this.currency,
    supplier: supplier.present ? supplier.value : this.supplier,
    supplierSku: supplierSku.present ? supplierSku.value : this.supplierSku,
    leadTimeDays: leadTimeDays.present ? leadTimeDays.value : this.leadTimeDays,
    status: status ?? this.status,
    location: location.present ? location.value : this.location,
    barcode: barcode.present ? barcode.value : this.barcode,
    tags: tags.present ? tags.value : this.tags,
    isDeleted: isDeleted ?? this.isDeleted,
    syncStatus: syncStatus ?? this.syncStatus,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      sku: data.sku.present ? data.sku.value : this.sku,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      category: data.category.present ? data.category.value : this.category,
      brand: data.brand.present ? data.brand.value : this.brand,
      currentStock:
          data.currentStock.present
              ? data.currentStock.value
              : this.currentStock,
      minStock: data.minStock.present ? data.minStock.value : this.minStock,
      maxStock: data.maxStock.present ? data.maxStock.value : this.maxStock,
      unit: data.unit.present ? data.unit.value : this.unit,
      weight: data.weight.present ? data.weight.value : this.weight,
      dimensions:
          data.dimensions.present ? data.dimensions.value : this.dimensions,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      costPrice: data.costPrice.present ? data.costPrice.value : this.costPrice,
      wholesalePrice:
          data.wholesalePrice.present
              ? data.wholesalePrice.value
              : this.wholesalePrice,
      currency: data.currency.present ? data.currency.value : this.currency,
      supplier: data.supplier.present ? data.supplier.value : this.supplier,
      supplierSku:
          data.supplierSku.present ? data.supplierSku.value : this.supplierSku,
      leadTimeDays:
          data.leadTimeDays.present
              ? data.leadTimeDays.value
              : this.leadTimeDays,
      status: data.status.present ? data.status.value : this.status,
      location: data.location.present ? data.location.value : this.location,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      tags: data.tags.present ? data.tags.value : this.tags,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('sku: $sku, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('brand: $brand, ')
          ..write('currentStock: $currentStock, ')
          ..write('minStock: $minStock, ')
          ..write('maxStock: $maxStock, ')
          ..write('unit: $unit, ')
          ..write('weight: $weight, ')
          ..write('dimensions: $dimensions, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('costPrice: $costPrice, ')
          ..write('wholesalePrice: $wholesalePrice, ')
          ..write('currency: $currency, ')
          ..write('supplier: $supplier, ')
          ..write('supplierSku: $supplierSku, ')
          ..write('leadTimeDays: $leadTimeDays, ')
          ..write('status: $status, ')
          ..write('location: $location, ')
          ..write('barcode: $barcode, ')
          ..write('tags: $tags, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    uuid,
    sku,
    name,
    description,
    category,
    brand,
    currentStock,
    minStock,
    maxStock,
    unit,
    weight,
    dimensions,
    unitPrice,
    costPrice,
    wholesalePrice,
    currency,
    supplier,
    supplierSku,
    leadTimeDays,
    status,
    location,
    barcode,
    tags,
    isDeleted,
    syncStatus,
    remoteId,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.sku == this.sku &&
          other.name == this.name &&
          other.description == this.description &&
          other.category == this.category &&
          other.brand == this.brand &&
          other.currentStock == this.currentStock &&
          other.minStock == this.minStock &&
          other.maxStock == this.maxStock &&
          other.unit == this.unit &&
          other.weight == this.weight &&
          other.dimensions == this.dimensions &&
          other.unitPrice == this.unitPrice &&
          other.costPrice == this.costPrice &&
          other.wholesalePrice == this.wholesalePrice &&
          other.currency == this.currency &&
          other.supplier == this.supplier &&
          other.supplierSku == this.supplierSku &&
          other.leadTimeDays == this.leadTimeDays &&
          other.status == this.status &&
          other.location == this.location &&
          other.barcode == this.barcode &&
          other.tags == this.tags &&
          other.isDeleted == this.isDeleted &&
          other.syncStatus == this.syncStatus &&
          other.remoteId == this.remoteId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> sku;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> category;
  final Value<String?> brand;
  final Value<int> currentStock;
  final Value<int> minStock;
  final Value<int?> maxStock;
  final Value<String> unit;
  final Value<double?> weight;
  final Value<String?> dimensions;
  final Value<double> unitPrice;
  final Value<double> costPrice;
  final Value<double?> wholesalePrice;
  final Value<String> currency;
  final Value<String?> supplier;
  final Value<String?> supplierSku;
  final Value<int?> leadTimeDays;
  final Value<String> status;
  final Value<String?> location;
  final Value<String?> barcode;
  final Value<String?> tags;
  final Value<bool> isDeleted;
  final Value<String> syncStatus;
  final Value<String?> remoteId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.sku = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.brand = const Value.absent(),
    this.currentStock = const Value.absent(),
    this.minStock = const Value.absent(),
    this.maxStock = const Value.absent(),
    this.unit = const Value.absent(),
    this.weight = const Value.absent(),
    this.dimensions = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.wholesalePrice = const Value.absent(),
    this.currency = const Value.absent(),
    this.supplier = const Value.absent(),
    this.supplierSku = const Value.absent(),
    this.leadTimeDays = const Value.absent(),
    this.status = const Value.absent(),
    this.location = const Value.absent(),
    this.barcode = const Value.absent(),
    this.tags = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ProductsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String sku,
    required String name,
    this.description = const Value.absent(),
    required String category,
    this.brand = const Value.absent(),
    this.currentStock = const Value.absent(),
    this.minStock = const Value.absent(),
    this.maxStock = const Value.absent(),
    required String unit,
    this.weight = const Value.absent(),
    this.dimensions = const Value.absent(),
    required double unitPrice,
    required double costPrice,
    this.wholesalePrice = const Value.absent(),
    this.currency = const Value.absent(),
    this.supplier = const Value.absent(),
    this.supplierSku = const Value.absent(),
    this.leadTimeDays = const Value.absent(),
    this.status = const Value.absent(),
    this.location = const Value.absent(),
    this.barcode = const Value.absent(),
    this.tags = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : uuid = Value(uuid),
       sku = Value(sku),
       name = Value(name),
       category = Value(category),
       unit = Value(unit),
       unitPrice = Value(unitPrice),
       costPrice = Value(costPrice);
  static Insertable<Product> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? sku,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? category,
    Expression<String>? brand,
    Expression<int>? currentStock,
    Expression<int>? minStock,
    Expression<int>? maxStock,
    Expression<String>? unit,
    Expression<double>? weight,
    Expression<String>? dimensions,
    Expression<double>? unitPrice,
    Expression<double>? costPrice,
    Expression<double>? wholesalePrice,
    Expression<String>? currency,
    Expression<String>? supplier,
    Expression<String>? supplierSku,
    Expression<int>? leadTimeDays,
    Expression<String>? status,
    Expression<String>? location,
    Expression<String>? barcode,
    Expression<String>? tags,
    Expression<bool>? isDeleted,
    Expression<String>? syncStatus,
    Expression<String>? remoteId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (sku != null) 'sku': sku,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (brand != null) 'brand': brand,
      if (currentStock != null) 'current_stock': currentStock,
      if (minStock != null) 'min_stock': minStock,
      if (maxStock != null) 'max_stock': maxStock,
      if (unit != null) 'unit': unit,
      if (weight != null) 'weight': weight,
      if (dimensions != null) 'dimensions': dimensions,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (costPrice != null) 'cost_price': costPrice,
      if (wholesalePrice != null) 'wholesale_price': wholesalePrice,
      if (currency != null) 'currency': currency,
      if (supplier != null) 'supplier': supplier,
      if (supplierSku != null) 'supplier_sku': supplierSku,
      if (leadTimeDays != null) 'lead_time_days': leadTimeDays,
      if (status != null) 'status': status,
      if (location != null) 'location': location,
      if (barcode != null) 'barcode': barcode,
      if (tags != null) 'tags': tags,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (remoteId != null) 'remote_id': remoteId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ProductsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? sku,
    Value<String>? name,
    Value<String?>? description,
    Value<String>? category,
    Value<String?>? brand,
    Value<int>? currentStock,
    Value<int>? minStock,
    Value<int?>? maxStock,
    Value<String>? unit,
    Value<double?>? weight,
    Value<String?>? dimensions,
    Value<double>? unitPrice,
    Value<double>? costPrice,
    Value<double?>? wholesalePrice,
    Value<String>? currency,
    Value<String?>? supplier,
    Value<String?>? supplierSku,
    Value<int?>? leadTimeDays,
    Value<String>? status,
    Value<String?>? location,
    Value<String?>? barcode,
    Value<String?>? tags,
    Value<bool>? isDeleted,
    Value<String>? syncStatus,
    Value<String?>? remoteId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      currentStock: currentStock ?? this.currentStock,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      unit: unit ?? this.unit,
      weight: weight ?? this.weight,
      dimensions: dimensions ?? this.dimensions,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      currency: currency ?? this.currency,
      supplier: supplier ?? this.supplier,
      supplierSku: supplierSku ?? this.supplierSku,
      leadTimeDays: leadTimeDays ?? this.leadTimeDays,
      status: status ?? this.status,
      location: location ?? this.location,
      barcode: barcode ?? this.barcode,
      tags: tags ?? this.tags,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteId: remoteId ?? this.remoteId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (currentStock.present) {
      map['current_stock'] = Variable<int>(currentStock.value);
    }
    if (minStock.present) {
      map['min_stock'] = Variable<int>(minStock.value);
    }
    if (maxStock.present) {
      map['max_stock'] = Variable<int>(maxStock.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (dimensions.present) {
      map['dimensions'] = Variable<String>(dimensions.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (costPrice.present) {
      map['cost_price'] = Variable<double>(costPrice.value);
    }
    if (wholesalePrice.present) {
      map['wholesale_price'] = Variable<double>(wholesalePrice.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (supplier.present) {
      map['supplier'] = Variable<String>(supplier.value);
    }
    if (supplierSku.present) {
      map['supplier_sku'] = Variable<String>(supplierSku.value);
    }
    if (leadTimeDays.present) {
      map['lead_time_days'] = Variable<int>(leadTimeDays.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('sku: $sku, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('brand: $brand, ')
          ..write('currentStock: $currentStock, ')
          ..write('minStock: $minStock, ')
          ..write('maxStock: $maxStock, ')
          ..write('unit: $unit, ')
          ..write('weight: $weight, ')
          ..write('dimensions: $dimensions, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('costPrice: $costPrice, ')
          ..write('wholesalePrice: $wholesalePrice, ')
          ..write('currency: $currency, ')
          ..write('supplier: $supplier, ')
          ..write('supplierSku: $supplierSku, ')
          ..write('leadTimeDays: $leadTimeDays, ')
          ..write('status: $status, ')
          ..write('location: $location, ')
          ..write('barcode: $barcode, ')
          ..write('tags: $tags, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $StockMovementsTable extends StockMovements
    with TableInfo<$StockMovementsTable, StockMovement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _movementTypeMeta = const VerificationMeta(
    'movementType',
  );
  @override
  late final GeneratedColumn<String> movementType = GeneratedColumn<String>(
    'movement_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceTypeMeta = const VerificationMeta(
    'referenceType',
  );
  @override
  late final GeneratedColumn<String> referenceType = GeneratedColumn<String>(
    'reference_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referenceIdMeta = const VerificationMeta(
    'referenceId',
  );
  @override
  late final GeneratedColumn<String> referenceId = GeneratedColumn<String>(
    'reference_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userNameMeta = const VerificationMeta(
    'userName',
  );
  @override
  late final GeneratedColumn<String> userName = GeneratedColumn<String>(
    'user_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromLocationMeta = const VerificationMeta(
    'fromLocation',
  );
  @override
  late final GeneratedColumn<String> fromLocation = GeneratedColumn<String>(
    'from_location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toLocationMeta = const VerificationMeta(
    'toLocation',
  );
  @override
  late final GeneratedColumn<String> toLocation = GeneratedColumn<String>(
    'to_location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitCostMeta = const VerificationMeta(
    'unitCost',
  );
  @override
  late final GeneratedColumn<double> unitCost = GeneratedColumn<double>(
    'unit_cost',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalCostMeta = const VerificationMeta(
    'totalCost',
  );
  @override
  late final GeneratedColumn<double> totalCost = GeneratedColumn<double>(
    'total_cost',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('completed'),
  );
  static const VerificationMeta _approvedByMeta = const VerificationMeta(
    'approvedBy',
  );
  @override
  late final GeneratedColumn<String> approvedBy = GeneratedColumn<String>(
    'approved_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _approvedAtMeta = const VerificationMeta(
    'approvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> approvedAt = GeneratedColumn<DateTime>(
    'approved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    movementType,
    quantity,
    referenceType,
    referenceId,
    reason,
    notes,
    userId,
    userName,
    fromLocation,
    toLocation,
    unitCost,
    totalCost,
    status,
    approvedBy,
    approvedAt,
    isDeleted,
    syncStatus,
    remoteId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_movements';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockMovement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('movement_type')) {
      context.handle(
        _movementTypeMeta,
        movementType.isAcceptableOrUnknown(
          data['movement_type']!,
          _movementTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_movementTypeMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('reference_type')) {
      context.handle(
        _referenceTypeMeta,
        referenceType.isAcceptableOrUnknown(
          data['reference_type']!,
          _referenceTypeMeta,
        ),
      );
    }
    if (data.containsKey('reference_id')) {
      context.handle(
        _referenceIdMeta,
        referenceId.isAcceptableOrUnknown(
          data['reference_id']!,
          _referenceIdMeta,
        ),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('user_name')) {
      context.handle(
        _userNameMeta,
        userName.isAcceptableOrUnknown(data['user_name']!, _userNameMeta),
      );
    } else if (isInserting) {
      context.missing(_userNameMeta);
    }
    if (data.containsKey('from_location')) {
      context.handle(
        _fromLocationMeta,
        fromLocation.isAcceptableOrUnknown(
          data['from_location']!,
          _fromLocationMeta,
        ),
      );
    }
    if (data.containsKey('to_location')) {
      context.handle(
        _toLocationMeta,
        toLocation.isAcceptableOrUnknown(data['to_location']!, _toLocationMeta),
      );
    }
    if (data.containsKey('unit_cost')) {
      context.handle(
        _unitCostMeta,
        unitCost.isAcceptableOrUnknown(data['unit_cost']!, _unitCostMeta),
      );
    }
    if (data.containsKey('total_cost')) {
      context.handle(
        _totalCostMeta,
        totalCost.isAcceptableOrUnknown(data['total_cost']!, _totalCostMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('approved_by')) {
      context.handle(
        _approvedByMeta,
        approvedBy.isAcceptableOrUnknown(data['approved_by']!, _approvedByMeta),
      );
    }
    if (data.containsKey('approved_at')) {
      context.handle(
        _approvedAtMeta,
        approvedAt.isAcceptableOrUnknown(data['approved_at']!, _approvedAtMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockMovement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockMovement(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      productId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}product_id'],
          )!,
      movementType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}movement_type'],
          )!,
      quantity:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}quantity'],
          )!,
      referenceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_type'],
      ),
      referenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_id'],
      ),
      reason:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}reason'],
          )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      userId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}user_id'],
          )!,
      userName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}user_name'],
          )!,
      fromLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_location'],
      ),
      toLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_location'],
      ),
      unitCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_cost'],
      ),
      totalCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_cost'],
      ),
      status:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}status'],
          )!,
      approvedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approved_by'],
      ),
      approvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}approved_at'],
      ),
      isDeleted:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_deleted'],
          )!,
      syncStatus:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}sync_status'],
          )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $StockMovementsTable createAlias(String alias) {
    return $StockMovementsTable(attachedDatabase, alias);
  }
}

class StockMovement extends DataClass implements Insertable<StockMovement> {
  final String id;
  final String productId;
  final String movementType;
  final int quantity;
  final String? referenceType;
  final String? referenceId;
  final String reason;
  final String? notes;
  final String userId;
  final String userName;
  final String? fromLocation;
  final String? toLocation;
  final double? unitCost;
  final double? totalCost;
  final String status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final bool isDeleted;
  final String syncStatus;
  final String? remoteId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const StockMovement({
    required this.id,
    required this.productId,
    required this.movementType,
    required this.quantity,
    this.referenceType,
    this.referenceId,
    required this.reason,
    this.notes,
    required this.userId,
    required this.userName,
    this.fromLocation,
    this.toLocation,
    this.unitCost,
    this.totalCost,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    required this.isDeleted,
    required this.syncStatus,
    this.remoteId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['movement_type'] = Variable<String>(movementType);
    map['quantity'] = Variable<int>(quantity);
    if (!nullToAbsent || referenceType != null) {
      map['reference_type'] = Variable<String>(referenceType);
    }
    if (!nullToAbsent || referenceId != null) {
      map['reference_id'] = Variable<String>(referenceId);
    }
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['user_id'] = Variable<String>(userId);
    map['user_name'] = Variable<String>(userName);
    if (!nullToAbsent || fromLocation != null) {
      map['from_location'] = Variable<String>(fromLocation);
    }
    if (!nullToAbsent || toLocation != null) {
      map['to_location'] = Variable<String>(toLocation);
    }
    if (!nullToAbsent || unitCost != null) {
      map['unit_cost'] = Variable<double>(unitCost);
    }
    if (!nullToAbsent || totalCost != null) {
      map['total_cost'] = Variable<double>(totalCost);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || approvedBy != null) {
      map['approved_by'] = Variable<String>(approvedBy);
    }
    if (!nullToAbsent || approvedAt != null) {
      map['approved_at'] = Variable<DateTime>(approvedAt);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StockMovementsCompanion toCompanion(bool nullToAbsent) {
    return StockMovementsCompanion(
      id: Value(id),
      productId: Value(productId),
      movementType: Value(movementType),
      quantity: Value(quantity),
      referenceType:
          referenceType == null && nullToAbsent
              ? const Value.absent()
              : Value(referenceType),
      referenceId:
          referenceId == null && nullToAbsent
              ? const Value.absent()
              : Value(referenceId),
      reason: Value(reason),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      userId: Value(userId),
      userName: Value(userName),
      fromLocation:
          fromLocation == null && nullToAbsent
              ? const Value.absent()
              : Value(fromLocation),
      toLocation:
          toLocation == null && nullToAbsent
              ? const Value.absent()
              : Value(toLocation),
      unitCost:
          unitCost == null && nullToAbsent
              ? const Value.absent()
              : Value(unitCost),
      totalCost:
          totalCost == null && nullToAbsent
              ? const Value.absent()
              : Value(totalCost),
      status: Value(status),
      approvedBy:
          approvedBy == null && nullToAbsent
              ? const Value.absent()
              : Value(approvedBy),
      approvedAt:
          approvedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(approvedAt),
      isDeleted: Value(isDeleted),
      syncStatus: Value(syncStatus),
      remoteId:
          remoteId == null && nullToAbsent
              ? const Value.absent()
              : Value(remoteId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StockMovement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockMovement(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      movementType: serializer.fromJson<String>(json['movementType']),
      quantity: serializer.fromJson<int>(json['quantity']),
      referenceType: serializer.fromJson<String?>(json['referenceType']),
      referenceId: serializer.fromJson<String?>(json['referenceId']),
      reason: serializer.fromJson<String>(json['reason']),
      notes: serializer.fromJson<String?>(json['notes']),
      userId: serializer.fromJson<String>(json['userId']),
      userName: serializer.fromJson<String>(json['userName']),
      fromLocation: serializer.fromJson<String?>(json['fromLocation']),
      toLocation: serializer.fromJson<String?>(json['toLocation']),
      unitCost: serializer.fromJson<double?>(json['unitCost']),
      totalCost: serializer.fromJson<double?>(json['totalCost']),
      status: serializer.fromJson<String>(json['status']),
      approvedBy: serializer.fromJson<String?>(json['approvedBy']),
      approvedAt: serializer.fromJson<DateTime?>(json['approvedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'movementType': serializer.toJson<String>(movementType),
      'quantity': serializer.toJson<int>(quantity),
      'referenceType': serializer.toJson<String?>(referenceType),
      'referenceId': serializer.toJson<String?>(referenceId),
      'reason': serializer.toJson<String>(reason),
      'notes': serializer.toJson<String?>(notes),
      'userId': serializer.toJson<String>(userId),
      'userName': serializer.toJson<String>(userName),
      'fromLocation': serializer.toJson<String?>(fromLocation),
      'toLocation': serializer.toJson<String?>(toLocation),
      'unitCost': serializer.toJson<double?>(unitCost),
      'totalCost': serializer.toJson<double?>(totalCost),
      'status': serializer.toJson<String>(status),
      'approvedBy': serializer.toJson<String?>(approvedBy),
      'approvedAt': serializer.toJson<DateTime?>(approvedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'remoteId': serializer.toJson<String?>(remoteId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StockMovement copyWith({
    String? id,
    String? productId,
    String? movementType,
    int? quantity,
    Value<String?> referenceType = const Value.absent(),
    Value<String?> referenceId = const Value.absent(),
    String? reason,
    Value<String?> notes = const Value.absent(),
    String? userId,
    String? userName,
    Value<String?> fromLocation = const Value.absent(),
    Value<String?> toLocation = const Value.absent(),
    Value<double?> unitCost = const Value.absent(),
    Value<double?> totalCost = const Value.absent(),
    String? status,
    Value<String?> approvedBy = const Value.absent(),
    Value<DateTime?> approvedAt = const Value.absent(),
    bool? isDeleted,
    String? syncStatus,
    Value<String?> remoteId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => StockMovement(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    movementType: movementType ?? this.movementType,
    quantity: quantity ?? this.quantity,
    referenceType:
        referenceType.present ? referenceType.value : this.referenceType,
    referenceId: referenceId.present ? referenceId.value : this.referenceId,
    reason: reason ?? this.reason,
    notes: notes.present ? notes.value : this.notes,
    userId: userId ?? this.userId,
    userName: userName ?? this.userName,
    fromLocation: fromLocation.present ? fromLocation.value : this.fromLocation,
    toLocation: toLocation.present ? toLocation.value : this.toLocation,
    unitCost: unitCost.present ? unitCost.value : this.unitCost,
    totalCost: totalCost.present ? totalCost.value : this.totalCost,
    status: status ?? this.status,
    approvedBy: approvedBy.present ? approvedBy.value : this.approvedBy,
    approvedAt: approvedAt.present ? approvedAt.value : this.approvedAt,
    isDeleted: isDeleted ?? this.isDeleted,
    syncStatus: syncStatus ?? this.syncStatus,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StockMovement copyWithCompanion(StockMovementsCompanion data) {
    return StockMovement(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      movementType:
          data.movementType.present
              ? data.movementType.value
              : this.movementType,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      referenceType:
          data.referenceType.present
              ? data.referenceType.value
              : this.referenceType,
      referenceId:
          data.referenceId.present ? data.referenceId.value : this.referenceId,
      reason: data.reason.present ? data.reason.value : this.reason,
      notes: data.notes.present ? data.notes.value : this.notes,
      userId: data.userId.present ? data.userId.value : this.userId,
      userName: data.userName.present ? data.userName.value : this.userName,
      fromLocation:
          data.fromLocation.present
              ? data.fromLocation.value
              : this.fromLocation,
      toLocation:
          data.toLocation.present ? data.toLocation.value : this.toLocation,
      unitCost: data.unitCost.present ? data.unitCost.value : this.unitCost,
      totalCost: data.totalCost.present ? data.totalCost.value : this.totalCost,
      status: data.status.present ? data.status.value : this.status,
      approvedBy:
          data.approvedBy.present ? data.approvedBy.value : this.approvedBy,
      approvedAt:
          data.approvedAt.present ? data.approvedAt.value : this.approvedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockMovement(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('movementType: $movementType, ')
          ..write('quantity: $quantity, ')
          ..write('referenceType: $referenceType, ')
          ..write('referenceId: $referenceId, ')
          ..write('reason: $reason, ')
          ..write('notes: $notes, ')
          ..write('userId: $userId, ')
          ..write('userName: $userName, ')
          ..write('fromLocation: $fromLocation, ')
          ..write('toLocation: $toLocation, ')
          ..write('unitCost: $unitCost, ')
          ..write('totalCost: $totalCost, ')
          ..write('status: $status, ')
          ..write('approvedBy: $approvedBy, ')
          ..write('approvedAt: $approvedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    productId,
    movementType,
    quantity,
    referenceType,
    referenceId,
    reason,
    notes,
    userId,
    userName,
    fromLocation,
    toLocation,
    unitCost,
    totalCost,
    status,
    approvedBy,
    approvedAt,
    isDeleted,
    syncStatus,
    remoteId,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockMovement &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.movementType == this.movementType &&
          other.quantity == this.quantity &&
          other.referenceType == this.referenceType &&
          other.referenceId == this.referenceId &&
          other.reason == this.reason &&
          other.notes == this.notes &&
          other.userId == this.userId &&
          other.userName == this.userName &&
          other.fromLocation == this.fromLocation &&
          other.toLocation == this.toLocation &&
          other.unitCost == this.unitCost &&
          other.totalCost == this.totalCost &&
          other.status == this.status &&
          other.approvedBy == this.approvedBy &&
          other.approvedAt == this.approvedAt &&
          other.isDeleted == this.isDeleted &&
          other.syncStatus == this.syncStatus &&
          other.remoteId == this.remoteId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StockMovementsCompanion extends UpdateCompanion<StockMovement> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String> movementType;
  final Value<int> quantity;
  final Value<String?> referenceType;
  final Value<String?> referenceId;
  final Value<String> reason;
  final Value<String?> notes;
  final Value<String> userId;
  final Value<String> userName;
  final Value<String?> fromLocation;
  final Value<String?> toLocation;
  final Value<double?> unitCost;
  final Value<double?> totalCost;
  final Value<String> status;
  final Value<String?> approvedBy;
  final Value<DateTime?> approvedAt;
  final Value<bool> isDeleted;
  final Value<String> syncStatus;
  final Value<String?> remoteId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StockMovementsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.movementType = const Value.absent(),
    this.quantity = const Value.absent(),
    this.referenceType = const Value.absent(),
    this.referenceId = const Value.absent(),
    this.reason = const Value.absent(),
    this.notes = const Value.absent(),
    this.userId = const Value.absent(),
    this.userName = const Value.absent(),
    this.fromLocation = const Value.absent(),
    this.toLocation = const Value.absent(),
    this.unitCost = const Value.absent(),
    this.totalCost = const Value.absent(),
    this.status = const Value.absent(),
    this.approvedBy = const Value.absent(),
    this.approvedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockMovementsCompanion.insert({
    required String id,
    required String productId,
    required String movementType,
    required int quantity,
    this.referenceType = const Value.absent(),
    this.referenceId = const Value.absent(),
    required String reason,
    this.notes = const Value.absent(),
    required String userId,
    required String userName,
    this.fromLocation = const Value.absent(),
    this.toLocation = const Value.absent(),
    this.unitCost = const Value.absent(),
    this.totalCost = const Value.absent(),
    this.status = const Value.absent(),
    this.approvedBy = const Value.absent(),
    this.approvedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productId = Value(productId),
       movementType = Value(movementType),
       quantity = Value(quantity),
       reason = Value(reason),
       userId = Value(userId),
       userName = Value(userName);
  static Insertable<StockMovement> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? movementType,
    Expression<int>? quantity,
    Expression<String>? referenceType,
    Expression<String>? referenceId,
    Expression<String>? reason,
    Expression<String>? notes,
    Expression<String>? userId,
    Expression<String>? userName,
    Expression<String>? fromLocation,
    Expression<String>? toLocation,
    Expression<double>? unitCost,
    Expression<double>? totalCost,
    Expression<String>? status,
    Expression<String>? approvedBy,
    Expression<DateTime>? approvedAt,
    Expression<bool>? isDeleted,
    Expression<String>? syncStatus,
    Expression<String>? remoteId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (movementType != null) 'movement_type': movementType,
      if (quantity != null) 'quantity': quantity,
      if (referenceType != null) 'reference_type': referenceType,
      if (referenceId != null) 'reference_id': referenceId,
      if (reason != null) 'reason': reason,
      if (notes != null) 'notes': notes,
      if (userId != null) 'user_id': userId,
      if (userName != null) 'user_name': userName,
      if (fromLocation != null) 'from_location': fromLocation,
      if (toLocation != null) 'to_location': toLocation,
      if (unitCost != null) 'unit_cost': unitCost,
      if (totalCost != null) 'total_cost': totalCost,
      if (status != null) 'status': status,
      if (approvedBy != null) 'approved_by': approvedBy,
      if (approvedAt != null) 'approved_at': approvedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (remoteId != null) 'remote_id': remoteId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockMovementsCompanion copyWith({
    Value<String>? id,
    Value<String>? productId,
    Value<String>? movementType,
    Value<int>? quantity,
    Value<String?>? referenceType,
    Value<String?>? referenceId,
    Value<String>? reason,
    Value<String?>? notes,
    Value<String>? userId,
    Value<String>? userName,
    Value<String?>? fromLocation,
    Value<String?>? toLocation,
    Value<double?>? unitCost,
    Value<double?>? totalCost,
    Value<String>? status,
    Value<String?>? approvedBy,
    Value<DateTime?>? approvedAt,
    Value<bool>? isDeleted,
    Value<String>? syncStatus,
    Value<String?>? remoteId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return StockMovementsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      movementType: movementType ?? this.movementType,
      quantity: quantity ?? this.quantity,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      unitCost: unitCost ?? this.unitCost,
      totalCost: totalCost ?? this.totalCost,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteId: remoteId ?? this.remoteId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (movementType.present) {
      map['movement_type'] = Variable<String>(movementType.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (referenceType.present) {
      map['reference_type'] = Variable<String>(referenceType.value);
    }
    if (referenceId.present) {
      map['reference_id'] = Variable<String>(referenceId.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (userName.present) {
      map['user_name'] = Variable<String>(userName.value);
    }
    if (fromLocation.present) {
      map['from_location'] = Variable<String>(fromLocation.value);
    }
    if (toLocation.present) {
      map['to_location'] = Variable<String>(toLocation.value);
    }
    if (unitCost.present) {
      map['unit_cost'] = Variable<double>(unitCost.value);
    }
    if (totalCost.present) {
      map['total_cost'] = Variable<double>(totalCost.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (approvedBy.present) {
      map['approved_by'] = Variable<String>(approvedBy.value);
    }
    if (approvedAt.present) {
      map['approved_at'] = Variable<DateTime>(approvedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockMovementsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('movementType: $movementType, ')
          ..write('quantity: $quantity, ')
          ..write('referenceType: $referenceType, ')
          ..write('referenceId: $referenceId, ')
          ..write('reason: $reason, ')
          ..write('notes: $notes, ')
          ..write('userId: $userId, ')
          ..write('userName: $userName, ')
          ..write('fromLocation: $fromLocation, ')
          ..write('toLocation: $toLocation, ')
          ..write('unitCost: $unitCost, ')
          ..write('totalCost: $totalCost, ')
          ..write('status: $status, ')
          ..write('approvedBy: $approvedBy, ')
          ..write('approvedAt: $approvedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<int> remoteId = GeneratedColumn<int>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    remoteId,
    name,
    description,
    syncStatus,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {remoteId},
  ];
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_id'],
      ),
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      syncStatus:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}sync_status'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final int? remoteId;
  final String name;
  final String? description;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Category({
    required this.id,
    this.remoteId,
    required this.name,
    this.description,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<int>(remoteId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      remoteId:
          remoteId == null && nullToAbsent
              ? const Value.absent()
              : Value(remoteId),
      name: Value(name),
      description:
          description == null && nullToAbsent
              ? const Value.absent()
              : Value(description),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      remoteId: serializer.fromJson<int?>(json['remoteId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'remoteId': serializer.toJson<int?>(remoteId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Category copyWith({
    int? id,
    Value<int?> remoteId = const Value.absent(),
    String? name,
    Value<String?> description = const Value.absent(),
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Category(
    id: id ?? this.id,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    remoteId,
    name,
    description,
    syncStatus,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.name == this.name &&
          other.description == this.description &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<int?> remoteId;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<int>? remoteId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<int?>? remoteId,
    Value<String>? name,
    Value<String?>? description,
    Value<String>? syncStatus,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      description: description ?? this.description,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<int>(remoteId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $OrdersTable extends Orders with TableInfo<$OrdersTable, Order> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _salesRepIdMeta = const VerificationMeta(
    'salesRepId',
  );
  @override
  late final GeneratedColumn<String> salesRepId = GeneratedColumn<String>(
    'sales_rep_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderDateMeta = const VerificationMeta(
    'orderDate',
  );
  @override
  late final GeneratedColumn<DateTime> orderDate = GeneratedColumn<DateTime>(
    'order_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _orderNumberMeta = const VerificationMeta(
    'orderNumber',
  );
  @override
  late final GeneratedColumn<String> orderNumber = GeneratedColumn<String>(
    'order_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _taxAmountMeta = const VerificationMeta(
    'taxAmount',
  );
  @override
  late final GeneratedColumn<double> taxAmount = GeneratedColumn<double>(
    'tax_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _discountAmountMeta = const VerificationMeta(
    'discountAmount',
  );
  @override
  late final GeneratedColumn<double> discountAmount = GeneratedColumn<double>(
    'discount_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _paymentStatusMeta = const VerificationMeta(
    'paymentStatus',
  );
  @override
  late final GeneratedColumn<String> paymentStatus = GeneratedColumn<String>(
    'payment_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _deliveryAddressMeta = const VerificationMeta(
    'deliveryAddress',
  );
  @override
  late final GeneratedColumn<String> deliveryAddress = GeneratedColumn<String>(
    'delivery_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deliveryContactMeta = const VerificationMeta(
    'deliveryContact',
  );
  @override
  late final GeneratedColumn<String> deliveryContact = GeneratedColumn<String>(
    'delivery_contact',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deliveryPhoneMeta = const VerificationMeta(
    'deliveryPhone',
  );
  @override
  late final GeneratedColumn<String> deliveryPhone = GeneratedColumn<String>(
    'delivery_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _requestedDeliveryDateMeta =
      const VerificationMeta('requestedDeliveryDate');
  @override
  late final GeneratedColumn<DateTime> requestedDeliveryDate =
      GeneratedColumn<DateTime>(
        'requested_delivery_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _actualDeliveryDateMeta =
      const VerificationMeta('actualDeliveryDate');
  @override
  late final GeneratedColumn<DateTime> actualDeliveryDate =
      GeneratedColumn<DateTime>(
        'actual_delivery_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _warehouseStatusMeta = const VerificationMeta(
    'warehouseStatus',
  );
  @override
  late final GeneratedColumn<String> warehouseStatus = GeneratedColumn<String>(
    'warehouse_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _pickerIdMeta = const VerificationMeta(
    'pickerId',
  );
  @override
  late final GeneratedColumn<String> pickerId = GeneratedColumn<String>(
    'picker_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pickedAtMeta = const VerificationMeta(
    'pickedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pickedAt = GeneratedColumn<DateTime>(
    'picked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _packerIdMeta = const VerificationMeta(
    'packerId',
  );
  @override
  late final GeneratedColumn<String> packerId = GeneratedColumn<String>(
    'packer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _packedAtMeta = const VerificationMeta(
    'packedAt',
  );
  @override
  late final GeneratedColumn<DateTime> packedAt = GeneratedColumn<DateTime>(
    'packed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerNotesMeta = const VerificationMeta(
    'customerNotes',
  );
  @override
  late final GeneratedColumn<String> customerNotes = GeneratedColumn<String>(
    'customer_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _internalNotesMeta = const VerificationMeta(
    'internalNotes',
  );
  @override
  late final GeneratedColumn<String> internalNotes = GeneratedColumn<String>(
    'internal_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('normal'),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    customerId,
    salesRepId,
    orderDate,
    status,
    orderNumber,
    subtotal,
    taxAmount,
    discountAmount,
    totalAmount,
    paymentStatus,
    deliveryAddress,
    deliveryContact,
    deliveryPhone,
    requestedDeliveryDate,
    actualDeliveryDate,
    warehouseStatus,
    pickerId,
    pickedAt,
    packerId,
    packedAt,
    customerNotes,
    internalNotes,
    priority,
    isDeleted,
    syncStatus,
    remoteId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Order> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('sales_rep_id')) {
      context.handle(
        _salesRepIdMeta,
        salesRepId.isAcceptableOrUnknown(
          data['sales_rep_id']!,
          _salesRepIdMeta,
        ),
      );
    }
    if (data.containsKey('order_date')) {
      context.handle(
        _orderDateMeta,
        orderDate.isAcceptableOrUnknown(data['order_date']!, _orderDateMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('order_number')) {
      context.handle(
        _orderNumberMeta,
        orderNumber.isAcceptableOrUnknown(
          data['order_number']!,
          _orderNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_orderNumberMeta);
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    }
    if (data.containsKey('tax_amount')) {
      context.handle(
        _taxAmountMeta,
        taxAmount.isAcceptableOrUnknown(data['tax_amount']!, _taxAmountMeta),
      );
    }
    if (data.containsKey('discount_amount')) {
      context.handle(
        _discountAmountMeta,
        discountAmount.isAcceptableOrUnknown(
          data['discount_amount']!,
          _discountAmountMeta,
        ),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    }
    if (data.containsKey('payment_status')) {
      context.handle(
        _paymentStatusMeta,
        paymentStatus.isAcceptableOrUnknown(
          data['payment_status']!,
          _paymentStatusMeta,
        ),
      );
    }
    if (data.containsKey('delivery_address')) {
      context.handle(
        _deliveryAddressMeta,
        deliveryAddress.isAcceptableOrUnknown(
          data['delivery_address']!,
          _deliveryAddressMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deliveryAddressMeta);
    }
    if (data.containsKey('delivery_contact')) {
      context.handle(
        _deliveryContactMeta,
        deliveryContact.isAcceptableOrUnknown(
          data['delivery_contact']!,
          _deliveryContactMeta,
        ),
      );
    }
    if (data.containsKey('delivery_phone')) {
      context.handle(
        _deliveryPhoneMeta,
        deliveryPhone.isAcceptableOrUnknown(
          data['delivery_phone']!,
          _deliveryPhoneMeta,
        ),
      );
    }
    if (data.containsKey('requested_delivery_date')) {
      context.handle(
        _requestedDeliveryDateMeta,
        requestedDeliveryDate.isAcceptableOrUnknown(
          data['requested_delivery_date']!,
          _requestedDeliveryDateMeta,
        ),
      );
    }
    if (data.containsKey('actual_delivery_date')) {
      context.handle(
        _actualDeliveryDateMeta,
        actualDeliveryDate.isAcceptableOrUnknown(
          data['actual_delivery_date']!,
          _actualDeliveryDateMeta,
        ),
      );
    }
    if (data.containsKey('warehouse_status')) {
      context.handle(
        _warehouseStatusMeta,
        warehouseStatus.isAcceptableOrUnknown(
          data['warehouse_status']!,
          _warehouseStatusMeta,
        ),
      );
    }
    if (data.containsKey('picker_id')) {
      context.handle(
        _pickerIdMeta,
        pickerId.isAcceptableOrUnknown(data['picker_id']!, _pickerIdMeta),
      );
    }
    if (data.containsKey('picked_at')) {
      context.handle(
        _pickedAtMeta,
        pickedAt.isAcceptableOrUnknown(data['picked_at']!, _pickedAtMeta),
      );
    }
    if (data.containsKey('packer_id')) {
      context.handle(
        _packerIdMeta,
        packerId.isAcceptableOrUnknown(data['packer_id']!, _packerIdMeta),
      );
    }
    if (data.containsKey('packed_at')) {
      context.handle(
        _packedAtMeta,
        packedAt.isAcceptableOrUnknown(data['packed_at']!, _packedAtMeta),
      );
    }
    if (data.containsKey('customer_notes')) {
      context.handle(
        _customerNotesMeta,
        customerNotes.isAcceptableOrUnknown(
          data['customer_notes']!,
          _customerNotesMeta,
        ),
      );
    }
    if (data.containsKey('internal_notes')) {
      context.handle(
        _internalNotesMeta,
        internalNotes.isAcceptableOrUnknown(
          data['internal_notes']!,
          _internalNotesMeta,
        ),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Order map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Order(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      customerId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}customer_id'],
          )!,
      salesRepId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sales_rep_id'],
      ),
      orderDate:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}order_date'],
          )!,
      status:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}status'],
          )!,
      orderNumber:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}order_number'],
          )!,
      subtotal:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}subtotal'],
          )!,
      taxAmount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}tax_amount'],
          )!,
      discountAmount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}discount_amount'],
          )!,
      totalAmount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}total_amount'],
          )!,
      paymentStatus:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}payment_status'],
          )!,
      deliveryAddress:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}delivery_address'],
          )!,
      deliveryContact: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery_contact'],
      ),
      deliveryPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery_phone'],
      ),
      requestedDeliveryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}requested_delivery_date'],
      ),
      actualDeliveryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}actual_delivery_date'],
      ),
      warehouseStatus:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}warehouse_status'],
          )!,
      pickerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}picker_id'],
      ),
      pickedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}picked_at'],
      ),
      packerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}packer_id'],
      ),
      packedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}packed_at'],
      ),
      customerNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_notes'],
      ),
      internalNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}internal_notes'],
      ),
      priority:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}priority'],
          )!,
      isDeleted:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_deleted'],
          )!,
      syncStatus:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}sync_status'],
          )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $OrdersTable createAlias(String alias) {
    return $OrdersTable(attachedDatabase, alias);
  }
}

class Order extends DataClass implements Insertable<Order> {
  final String id;
  final String customerId;
  final String? salesRepId;
  final DateTime orderDate;
  final String status;
  final String orderNumber;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final String paymentStatus;
  final String deliveryAddress;
  final String? deliveryContact;
  final String? deliveryPhone;
  final DateTime? requestedDeliveryDate;
  final DateTime? actualDeliveryDate;
  final String warehouseStatus;
  final String? pickerId;
  final DateTime? pickedAt;
  final String? packerId;
  final DateTime? packedAt;
  final String? customerNotes;
  final String? internalNotes;
  final String priority;
  final bool isDeleted;
  final String syncStatus;
  final String? remoteId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Order({
    required this.id,
    required this.customerId,
    this.salesRepId,
    required this.orderDate,
    required this.status,
    required this.orderNumber,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.paymentStatus,
    required this.deliveryAddress,
    this.deliveryContact,
    this.deliveryPhone,
    this.requestedDeliveryDate,
    this.actualDeliveryDate,
    required this.warehouseStatus,
    this.pickerId,
    this.pickedAt,
    this.packerId,
    this.packedAt,
    this.customerNotes,
    this.internalNotes,
    required this.priority,
    required this.isDeleted,
    required this.syncStatus,
    this.remoteId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['customer_id'] = Variable<String>(customerId);
    if (!nullToAbsent || salesRepId != null) {
      map['sales_rep_id'] = Variable<String>(salesRepId);
    }
    map['order_date'] = Variable<DateTime>(orderDate);
    map['status'] = Variable<String>(status);
    map['order_number'] = Variable<String>(orderNumber);
    map['subtotal'] = Variable<double>(subtotal);
    map['tax_amount'] = Variable<double>(taxAmount);
    map['discount_amount'] = Variable<double>(discountAmount);
    map['total_amount'] = Variable<double>(totalAmount);
    map['payment_status'] = Variable<String>(paymentStatus);
    map['delivery_address'] = Variable<String>(deliveryAddress);
    if (!nullToAbsent || deliveryContact != null) {
      map['delivery_contact'] = Variable<String>(deliveryContact);
    }
    if (!nullToAbsent || deliveryPhone != null) {
      map['delivery_phone'] = Variable<String>(deliveryPhone);
    }
    if (!nullToAbsent || requestedDeliveryDate != null) {
      map['requested_delivery_date'] = Variable<DateTime>(
        requestedDeliveryDate,
      );
    }
    if (!nullToAbsent || actualDeliveryDate != null) {
      map['actual_delivery_date'] = Variable<DateTime>(actualDeliveryDate);
    }
    map['warehouse_status'] = Variable<String>(warehouseStatus);
    if (!nullToAbsent || pickerId != null) {
      map['picker_id'] = Variable<String>(pickerId);
    }
    if (!nullToAbsent || pickedAt != null) {
      map['picked_at'] = Variable<DateTime>(pickedAt);
    }
    if (!nullToAbsent || packerId != null) {
      map['packer_id'] = Variable<String>(packerId);
    }
    if (!nullToAbsent || packedAt != null) {
      map['packed_at'] = Variable<DateTime>(packedAt);
    }
    if (!nullToAbsent || customerNotes != null) {
      map['customer_notes'] = Variable<String>(customerNotes);
    }
    if (!nullToAbsent || internalNotes != null) {
      map['internal_notes'] = Variable<String>(internalNotes);
    }
    map['priority'] = Variable<String>(priority);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  OrdersCompanion toCompanion(bool nullToAbsent) {
    return OrdersCompanion(
      id: Value(id),
      customerId: Value(customerId),
      salesRepId:
          salesRepId == null && nullToAbsent
              ? const Value.absent()
              : Value(salesRepId),
      orderDate: Value(orderDate),
      status: Value(status),
      orderNumber: Value(orderNumber),
      subtotal: Value(subtotal),
      taxAmount: Value(taxAmount),
      discountAmount: Value(discountAmount),
      totalAmount: Value(totalAmount),
      paymentStatus: Value(paymentStatus),
      deliveryAddress: Value(deliveryAddress),
      deliveryContact:
          deliveryContact == null && nullToAbsent
              ? const Value.absent()
              : Value(deliveryContact),
      deliveryPhone:
          deliveryPhone == null && nullToAbsent
              ? const Value.absent()
              : Value(deliveryPhone),
      requestedDeliveryDate:
          requestedDeliveryDate == null && nullToAbsent
              ? const Value.absent()
              : Value(requestedDeliveryDate),
      actualDeliveryDate:
          actualDeliveryDate == null && nullToAbsent
              ? const Value.absent()
              : Value(actualDeliveryDate),
      warehouseStatus: Value(warehouseStatus),
      pickerId:
          pickerId == null && nullToAbsent
              ? const Value.absent()
              : Value(pickerId),
      pickedAt:
          pickedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(pickedAt),
      packerId:
          packerId == null && nullToAbsent
              ? const Value.absent()
              : Value(packerId),
      packedAt:
          packedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(packedAt),
      customerNotes:
          customerNotes == null && nullToAbsent
              ? const Value.absent()
              : Value(customerNotes),
      internalNotes:
          internalNotes == null && nullToAbsent
              ? const Value.absent()
              : Value(internalNotes),
      priority: Value(priority),
      isDeleted: Value(isDeleted),
      syncStatus: Value(syncStatus),
      remoteId:
          remoteId == null && nullToAbsent
              ? const Value.absent()
              : Value(remoteId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Order.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Order(
      id: serializer.fromJson<String>(json['id']),
      customerId: serializer.fromJson<String>(json['customerId']),
      salesRepId: serializer.fromJson<String?>(json['salesRepId']),
      orderDate: serializer.fromJson<DateTime>(json['orderDate']),
      status: serializer.fromJson<String>(json['status']),
      orderNumber: serializer.fromJson<String>(json['orderNumber']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      taxAmount: serializer.fromJson<double>(json['taxAmount']),
      discountAmount: serializer.fromJson<double>(json['discountAmount']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      paymentStatus: serializer.fromJson<String>(json['paymentStatus']),
      deliveryAddress: serializer.fromJson<String>(json['deliveryAddress']),
      deliveryContact: serializer.fromJson<String?>(json['deliveryContact']),
      deliveryPhone: serializer.fromJson<String?>(json['deliveryPhone']),
      requestedDeliveryDate: serializer.fromJson<DateTime?>(
        json['requestedDeliveryDate'],
      ),
      actualDeliveryDate: serializer.fromJson<DateTime?>(
        json['actualDeliveryDate'],
      ),
      warehouseStatus: serializer.fromJson<String>(json['warehouseStatus']),
      pickerId: serializer.fromJson<String?>(json['pickerId']),
      pickedAt: serializer.fromJson<DateTime?>(json['pickedAt']),
      packerId: serializer.fromJson<String?>(json['packerId']),
      packedAt: serializer.fromJson<DateTime?>(json['packedAt']),
      customerNotes: serializer.fromJson<String?>(json['customerNotes']),
      internalNotes: serializer.fromJson<String?>(json['internalNotes']),
      priority: serializer.fromJson<String>(json['priority']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'customerId': serializer.toJson<String>(customerId),
      'salesRepId': serializer.toJson<String?>(salesRepId),
      'orderDate': serializer.toJson<DateTime>(orderDate),
      'status': serializer.toJson<String>(status),
      'orderNumber': serializer.toJson<String>(orderNumber),
      'subtotal': serializer.toJson<double>(subtotal),
      'taxAmount': serializer.toJson<double>(taxAmount),
      'discountAmount': serializer.toJson<double>(discountAmount),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'paymentStatus': serializer.toJson<String>(paymentStatus),
      'deliveryAddress': serializer.toJson<String>(deliveryAddress),
      'deliveryContact': serializer.toJson<String?>(deliveryContact),
      'deliveryPhone': serializer.toJson<String?>(deliveryPhone),
      'requestedDeliveryDate': serializer.toJson<DateTime?>(
        requestedDeliveryDate,
      ),
      'actualDeliveryDate': serializer.toJson<DateTime?>(actualDeliveryDate),
      'warehouseStatus': serializer.toJson<String>(warehouseStatus),
      'pickerId': serializer.toJson<String?>(pickerId),
      'pickedAt': serializer.toJson<DateTime?>(pickedAt),
      'packerId': serializer.toJson<String?>(packerId),
      'packedAt': serializer.toJson<DateTime?>(packedAt),
      'customerNotes': serializer.toJson<String?>(customerNotes),
      'internalNotes': serializer.toJson<String?>(internalNotes),
      'priority': serializer.toJson<String>(priority),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'remoteId': serializer.toJson<String?>(remoteId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Order copyWith({
    String? id,
    String? customerId,
    Value<String?> salesRepId = const Value.absent(),
    DateTime? orderDate,
    String? status,
    String? orderNumber,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? totalAmount,
    String? paymentStatus,
    String? deliveryAddress,
    Value<String?> deliveryContact = const Value.absent(),
    Value<String?> deliveryPhone = const Value.absent(),
    Value<DateTime?> requestedDeliveryDate = const Value.absent(),
    Value<DateTime?> actualDeliveryDate = const Value.absent(),
    String? warehouseStatus,
    Value<String?> pickerId = const Value.absent(),
    Value<DateTime?> pickedAt = const Value.absent(),
    Value<String?> packerId = const Value.absent(),
    Value<DateTime?> packedAt = const Value.absent(),
    Value<String?> customerNotes = const Value.absent(),
    Value<String?> internalNotes = const Value.absent(),
    String? priority,
    bool? isDeleted,
    String? syncStatus,
    Value<String?> remoteId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Order(
    id: id ?? this.id,
    customerId: customerId ?? this.customerId,
    salesRepId: salesRepId.present ? salesRepId.value : this.salesRepId,
    orderDate: orderDate ?? this.orderDate,
    status: status ?? this.status,
    orderNumber: orderNumber ?? this.orderNumber,
    subtotal: subtotal ?? this.subtotal,
    taxAmount: taxAmount ?? this.taxAmount,
    discountAmount: discountAmount ?? this.discountAmount,
    totalAmount: totalAmount ?? this.totalAmount,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    deliveryAddress: deliveryAddress ?? this.deliveryAddress,
    deliveryContact:
        deliveryContact.present ? deliveryContact.value : this.deliveryContact,
    deliveryPhone:
        deliveryPhone.present ? deliveryPhone.value : this.deliveryPhone,
    requestedDeliveryDate:
        requestedDeliveryDate.present
            ? requestedDeliveryDate.value
            : this.requestedDeliveryDate,
    actualDeliveryDate:
        actualDeliveryDate.present
            ? actualDeliveryDate.value
            : this.actualDeliveryDate,
    warehouseStatus: warehouseStatus ?? this.warehouseStatus,
    pickerId: pickerId.present ? pickerId.value : this.pickerId,
    pickedAt: pickedAt.present ? pickedAt.value : this.pickedAt,
    packerId: packerId.present ? packerId.value : this.packerId,
    packedAt: packedAt.present ? packedAt.value : this.packedAt,
    customerNotes:
        customerNotes.present ? customerNotes.value : this.customerNotes,
    internalNotes:
        internalNotes.present ? internalNotes.value : this.internalNotes,
    priority: priority ?? this.priority,
    isDeleted: isDeleted ?? this.isDeleted,
    syncStatus: syncStatus ?? this.syncStatus,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Order copyWithCompanion(OrdersCompanion data) {
    return Order(
      id: data.id.present ? data.id.value : this.id,
      customerId:
          data.customerId.present ? data.customerId.value : this.customerId,
      salesRepId:
          data.salesRepId.present ? data.salesRepId.value : this.salesRepId,
      orderDate: data.orderDate.present ? data.orderDate.value : this.orderDate,
      status: data.status.present ? data.status.value : this.status,
      orderNumber:
          data.orderNumber.present ? data.orderNumber.value : this.orderNumber,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      taxAmount: data.taxAmount.present ? data.taxAmount.value : this.taxAmount,
      discountAmount:
          data.discountAmount.present
              ? data.discountAmount.value
              : this.discountAmount,
      totalAmount:
          data.totalAmount.present ? data.totalAmount.value : this.totalAmount,
      paymentStatus:
          data.paymentStatus.present
              ? data.paymentStatus.value
              : this.paymentStatus,
      deliveryAddress:
          data.deliveryAddress.present
              ? data.deliveryAddress.value
              : this.deliveryAddress,
      deliveryContact:
          data.deliveryContact.present
              ? data.deliveryContact.value
              : this.deliveryContact,
      deliveryPhone:
          data.deliveryPhone.present
              ? data.deliveryPhone.value
              : this.deliveryPhone,
      requestedDeliveryDate:
          data.requestedDeliveryDate.present
              ? data.requestedDeliveryDate.value
              : this.requestedDeliveryDate,
      actualDeliveryDate:
          data.actualDeliveryDate.present
              ? data.actualDeliveryDate.value
              : this.actualDeliveryDate,
      warehouseStatus:
          data.warehouseStatus.present
              ? data.warehouseStatus.value
              : this.warehouseStatus,
      pickerId: data.pickerId.present ? data.pickerId.value : this.pickerId,
      pickedAt: data.pickedAt.present ? data.pickedAt.value : this.pickedAt,
      packerId: data.packerId.present ? data.packerId.value : this.packerId,
      packedAt: data.packedAt.present ? data.packedAt.value : this.packedAt,
      customerNotes:
          data.customerNotes.present
              ? data.customerNotes.value
              : this.customerNotes,
      internalNotes:
          data.internalNotes.present
              ? data.internalNotes.value
              : this.internalNotes,
      priority: data.priority.present ? data.priority.value : this.priority,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Order(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('salesRepId: $salesRepId, ')
          ..write('orderDate: $orderDate, ')
          ..write('status: $status, ')
          ..write('orderNumber: $orderNumber, ')
          ..write('subtotal: $subtotal, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('deliveryAddress: $deliveryAddress, ')
          ..write('deliveryContact: $deliveryContact, ')
          ..write('deliveryPhone: $deliveryPhone, ')
          ..write('requestedDeliveryDate: $requestedDeliveryDate, ')
          ..write('actualDeliveryDate: $actualDeliveryDate, ')
          ..write('warehouseStatus: $warehouseStatus, ')
          ..write('pickerId: $pickerId, ')
          ..write('pickedAt: $pickedAt, ')
          ..write('packerId: $packerId, ')
          ..write('packedAt: $packedAt, ')
          ..write('customerNotes: $customerNotes, ')
          ..write('internalNotes: $internalNotes, ')
          ..write('priority: $priority, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    customerId,
    salesRepId,
    orderDate,
    status,
    orderNumber,
    subtotal,
    taxAmount,
    discountAmount,
    totalAmount,
    paymentStatus,
    deliveryAddress,
    deliveryContact,
    deliveryPhone,
    requestedDeliveryDate,
    actualDeliveryDate,
    warehouseStatus,
    pickerId,
    pickedAt,
    packerId,
    packedAt,
    customerNotes,
    internalNotes,
    priority,
    isDeleted,
    syncStatus,
    remoteId,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Order &&
          other.id == this.id &&
          other.customerId == this.customerId &&
          other.salesRepId == this.salesRepId &&
          other.orderDate == this.orderDate &&
          other.status == this.status &&
          other.orderNumber == this.orderNumber &&
          other.subtotal == this.subtotal &&
          other.taxAmount == this.taxAmount &&
          other.discountAmount == this.discountAmount &&
          other.totalAmount == this.totalAmount &&
          other.paymentStatus == this.paymentStatus &&
          other.deliveryAddress == this.deliveryAddress &&
          other.deliveryContact == this.deliveryContact &&
          other.deliveryPhone == this.deliveryPhone &&
          other.requestedDeliveryDate == this.requestedDeliveryDate &&
          other.actualDeliveryDate == this.actualDeliveryDate &&
          other.warehouseStatus == this.warehouseStatus &&
          other.pickerId == this.pickerId &&
          other.pickedAt == this.pickedAt &&
          other.packerId == this.packerId &&
          other.packedAt == this.packedAt &&
          other.customerNotes == this.customerNotes &&
          other.internalNotes == this.internalNotes &&
          other.priority == this.priority &&
          other.isDeleted == this.isDeleted &&
          other.syncStatus == this.syncStatus &&
          other.remoteId == this.remoteId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OrdersCompanion extends UpdateCompanion<Order> {
  final Value<String> id;
  final Value<String> customerId;
  final Value<String?> salesRepId;
  final Value<DateTime> orderDate;
  final Value<String> status;
  final Value<String> orderNumber;
  final Value<double> subtotal;
  final Value<double> taxAmount;
  final Value<double> discountAmount;
  final Value<double> totalAmount;
  final Value<String> paymentStatus;
  final Value<String> deliveryAddress;
  final Value<String?> deliveryContact;
  final Value<String?> deliveryPhone;
  final Value<DateTime?> requestedDeliveryDate;
  final Value<DateTime?> actualDeliveryDate;
  final Value<String> warehouseStatus;
  final Value<String?> pickerId;
  final Value<DateTime?> pickedAt;
  final Value<String?> packerId;
  final Value<DateTime?> packedAt;
  final Value<String?> customerNotes;
  final Value<String?> internalNotes;
  final Value<String> priority;
  final Value<bool> isDeleted;
  final Value<String> syncStatus;
  final Value<String?> remoteId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const OrdersCompanion({
    this.id = const Value.absent(),
    this.customerId = const Value.absent(),
    this.salesRepId = const Value.absent(),
    this.orderDate = const Value.absent(),
    this.status = const Value.absent(),
    this.orderNumber = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.deliveryAddress = const Value.absent(),
    this.deliveryContact = const Value.absent(),
    this.deliveryPhone = const Value.absent(),
    this.requestedDeliveryDate = const Value.absent(),
    this.actualDeliveryDate = const Value.absent(),
    this.warehouseStatus = const Value.absent(),
    this.pickerId = const Value.absent(),
    this.pickedAt = const Value.absent(),
    this.packerId = const Value.absent(),
    this.packedAt = const Value.absent(),
    this.customerNotes = const Value.absent(),
    this.internalNotes = const Value.absent(),
    this.priority = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrdersCompanion.insert({
    required String id,
    required String customerId,
    this.salesRepId = const Value.absent(),
    this.orderDate = const Value.absent(),
    this.status = const Value.absent(),
    required String orderNumber,
    this.subtotal = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    required String deliveryAddress,
    this.deliveryContact = const Value.absent(),
    this.deliveryPhone = const Value.absent(),
    this.requestedDeliveryDate = const Value.absent(),
    this.actualDeliveryDate = const Value.absent(),
    this.warehouseStatus = const Value.absent(),
    this.pickerId = const Value.absent(),
    this.pickedAt = const Value.absent(),
    this.packerId = const Value.absent(),
    this.packedAt = const Value.absent(),
    this.customerNotes = const Value.absent(),
    this.internalNotes = const Value.absent(),
    this.priority = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       customerId = Value(customerId),
       orderNumber = Value(orderNumber),
       deliveryAddress = Value(deliveryAddress);
  static Insertable<Order> custom({
    Expression<String>? id,
    Expression<String>? customerId,
    Expression<String>? salesRepId,
    Expression<DateTime>? orderDate,
    Expression<String>? status,
    Expression<String>? orderNumber,
    Expression<double>? subtotal,
    Expression<double>? taxAmount,
    Expression<double>? discountAmount,
    Expression<double>? totalAmount,
    Expression<String>? paymentStatus,
    Expression<String>? deliveryAddress,
    Expression<String>? deliveryContact,
    Expression<String>? deliveryPhone,
    Expression<DateTime>? requestedDeliveryDate,
    Expression<DateTime>? actualDeliveryDate,
    Expression<String>? warehouseStatus,
    Expression<String>? pickerId,
    Expression<DateTime>? pickedAt,
    Expression<String>? packerId,
    Expression<DateTime>? packedAt,
    Expression<String>? customerNotes,
    Expression<String>? internalNotes,
    Expression<String>? priority,
    Expression<bool>? isDeleted,
    Expression<String>? syncStatus,
    Expression<String>? remoteId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (customerId != null) 'customer_id': customerId,
      if (salesRepId != null) 'sales_rep_id': salesRepId,
      if (orderDate != null) 'order_date': orderDate,
      if (status != null) 'status': status,
      if (orderNumber != null) 'order_number': orderNumber,
      if (subtotal != null) 'subtotal': subtotal,
      if (taxAmount != null) 'tax_amount': taxAmount,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (deliveryAddress != null) 'delivery_address': deliveryAddress,
      if (deliveryContact != null) 'delivery_contact': deliveryContact,
      if (deliveryPhone != null) 'delivery_phone': deliveryPhone,
      if (requestedDeliveryDate != null)
        'requested_delivery_date': requestedDeliveryDate,
      if (actualDeliveryDate != null)
        'actual_delivery_date': actualDeliveryDate,
      if (warehouseStatus != null) 'warehouse_status': warehouseStatus,
      if (pickerId != null) 'picker_id': pickerId,
      if (pickedAt != null) 'picked_at': pickedAt,
      if (packerId != null) 'packer_id': packerId,
      if (packedAt != null) 'packed_at': packedAt,
      if (customerNotes != null) 'customer_notes': customerNotes,
      if (internalNotes != null) 'internal_notes': internalNotes,
      if (priority != null) 'priority': priority,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (remoteId != null) 'remote_id': remoteId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrdersCompanion copyWith({
    Value<String>? id,
    Value<String>? customerId,
    Value<String?>? salesRepId,
    Value<DateTime>? orderDate,
    Value<String>? status,
    Value<String>? orderNumber,
    Value<double>? subtotal,
    Value<double>? taxAmount,
    Value<double>? discountAmount,
    Value<double>? totalAmount,
    Value<String>? paymentStatus,
    Value<String>? deliveryAddress,
    Value<String?>? deliveryContact,
    Value<String?>? deliveryPhone,
    Value<DateTime?>? requestedDeliveryDate,
    Value<DateTime?>? actualDeliveryDate,
    Value<String>? warehouseStatus,
    Value<String?>? pickerId,
    Value<DateTime?>? pickedAt,
    Value<String?>? packerId,
    Value<DateTime?>? packedAt,
    Value<String?>? customerNotes,
    Value<String?>? internalNotes,
    Value<String>? priority,
    Value<bool>? isDeleted,
    Value<String>? syncStatus,
    Value<String?>? remoteId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return OrdersCompanion(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      salesRepId: salesRepId ?? this.salesRepId,
      orderDate: orderDate ?? this.orderDate,
      status: status ?? this.status,
      orderNumber: orderNumber ?? this.orderNumber,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryContact: deliveryContact ?? this.deliveryContact,
      deliveryPhone: deliveryPhone ?? this.deliveryPhone,
      requestedDeliveryDate:
          requestedDeliveryDate ?? this.requestedDeliveryDate,
      actualDeliveryDate: actualDeliveryDate ?? this.actualDeliveryDate,
      warehouseStatus: warehouseStatus ?? this.warehouseStatus,
      pickerId: pickerId ?? this.pickerId,
      pickedAt: pickedAt ?? this.pickedAt,
      packerId: packerId ?? this.packerId,
      packedAt: packedAt ?? this.packedAt,
      customerNotes: customerNotes ?? this.customerNotes,
      internalNotes: internalNotes ?? this.internalNotes,
      priority: priority ?? this.priority,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteId: remoteId ?? this.remoteId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (salesRepId.present) {
      map['sales_rep_id'] = Variable<String>(salesRepId.value);
    }
    if (orderDate.present) {
      map['order_date'] = Variable<DateTime>(orderDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (orderNumber.present) {
      map['order_number'] = Variable<String>(orderNumber.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (taxAmount.present) {
      map['tax_amount'] = Variable<double>(taxAmount.value);
    }
    if (discountAmount.present) {
      map['discount_amount'] = Variable<double>(discountAmount.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (paymentStatus.present) {
      map['payment_status'] = Variable<String>(paymentStatus.value);
    }
    if (deliveryAddress.present) {
      map['delivery_address'] = Variable<String>(deliveryAddress.value);
    }
    if (deliveryContact.present) {
      map['delivery_contact'] = Variable<String>(deliveryContact.value);
    }
    if (deliveryPhone.present) {
      map['delivery_phone'] = Variable<String>(deliveryPhone.value);
    }
    if (requestedDeliveryDate.present) {
      map['requested_delivery_date'] = Variable<DateTime>(
        requestedDeliveryDate.value,
      );
    }
    if (actualDeliveryDate.present) {
      map['actual_delivery_date'] = Variable<DateTime>(
        actualDeliveryDate.value,
      );
    }
    if (warehouseStatus.present) {
      map['warehouse_status'] = Variable<String>(warehouseStatus.value);
    }
    if (pickerId.present) {
      map['picker_id'] = Variable<String>(pickerId.value);
    }
    if (pickedAt.present) {
      map['picked_at'] = Variable<DateTime>(pickedAt.value);
    }
    if (packerId.present) {
      map['packer_id'] = Variable<String>(packerId.value);
    }
    if (packedAt.present) {
      map['packed_at'] = Variable<DateTime>(packedAt.value);
    }
    if (customerNotes.present) {
      map['customer_notes'] = Variable<String>(customerNotes.value);
    }
    if (internalNotes.present) {
      map['internal_notes'] = Variable<String>(internalNotes.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrdersCompanion(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('salesRepId: $salesRepId, ')
          ..write('orderDate: $orderDate, ')
          ..write('status: $status, ')
          ..write('orderNumber: $orderNumber, ')
          ..write('subtotal: $subtotal, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('deliveryAddress: $deliveryAddress, ')
          ..write('deliveryContact: $deliveryContact, ')
          ..write('deliveryPhone: $deliveryPhone, ')
          ..write('requestedDeliveryDate: $requestedDeliveryDate, ')
          ..write('actualDeliveryDate: $actualDeliveryDate, ')
          ..write('warehouseStatus: $warehouseStatus, ')
          ..write('pickerId: $pickerId, ')
          ..write('pickedAt: $pickedAt, ')
          ..write('packerId: $packerId, ')
          ..write('packedAt: $packedAt, ')
          ..write('customerNotes: $customerNotes, ')
          ..write('internalNotes: $internalNotes, ')
          ..write('priority: $priority, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrderItemsTable extends OrderItems
    with TableInfo<$OrderItemsTable, OrderItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrderItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
    'order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productSkuMeta = const VerificationMeta(
    'productSku',
  );
  @override
  late final GeneratedColumn<String> productSku = GeneratedColumn<String>(
    'product_sku',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productCategoryMeta = const VerificationMeta(
    'productCategory',
  );
  @override
  late final GeneratedColumn<String> productCategory = GeneratedColumn<String>(
    'product_category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deliveredQuantityMeta = const VerificationMeta(
    'deliveredQuantity',
  );
  @override
  late final GeneratedColumn<int> deliveredQuantity = GeneratedColumn<int>(
    'delivered_quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountAmountMeta = const VerificationMeta(
    'discountAmount',
  );
  @override
  late final GeneratedColumn<double> discountAmount = GeneratedColumn<double>(
    'discount_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _availableStockMeta = const VerificationMeta(
    'availableStock',
  );
  @override
  late final GeneratedColumn<int> availableStock = GeneratedColumn<int>(
    'available_stock',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stockStatusMeta = const VerificationMeta(
    'stockStatus',
  );
  @override
  late final GeneratedColumn<String> stockStatus = GeneratedColumn<String>(
    'stock_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('available'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _pickerIdMeta = const VerificationMeta(
    'pickerId',
  );
  @override
  late final GeneratedColumn<String> pickerId = GeneratedColumn<String>(
    'picker_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pickedAtMeta = const VerificationMeta(
    'pickedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pickedAt = GeneratedColumn<DateTime>(
    'picked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cancellationReasonMeta =
      const VerificationMeta('cancellationReason');
  @override
  late final GeneratedColumn<String> cancellationReason =
      GeneratedColumn<String>(
        'cancellation_reason',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    orderId,
    productId,
    productSku,
    productName,
    productCategory,
    quantity,
    deliveredQuantity,
    unitPrice,
    subtotal,
    discountAmount,
    totalAmount,
    availableStock,
    stockStatus,
    status,
    pickerId,
    pickedAt,
    notes,
    cancellationReason,
    isDeleted,
    syncStatus,
    remoteId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'order_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrderItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_sku')) {
      context.handle(
        _productSkuMeta,
        productSku.isAcceptableOrUnknown(data['product_sku']!, _productSkuMeta),
      );
    } else if (isInserting) {
      context.missing(_productSkuMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('product_category')) {
      context.handle(
        _productCategoryMeta,
        productCategory.isAcceptableOrUnknown(
          data['product_category']!,
          _productCategoryMeta,
        ),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('delivered_quantity')) {
      context.handle(
        _deliveredQuantityMeta,
        deliveredQuantity.isAcceptableOrUnknown(
          data['delivered_quantity']!,
          _deliveredQuantityMeta,
        ),
      );
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    } else if (isInserting) {
      context.missing(_subtotalMeta);
    }
    if (data.containsKey('discount_amount')) {
      context.handle(
        _discountAmountMeta,
        discountAmount.isAcceptableOrUnknown(
          data['discount_amount']!,
          _discountAmountMeta,
        ),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('available_stock')) {
      context.handle(
        _availableStockMeta,
        availableStock.isAcceptableOrUnknown(
          data['available_stock']!,
          _availableStockMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_availableStockMeta);
    }
    if (data.containsKey('stock_status')) {
      context.handle(
        _stockStatusMeta,
        stockStatus.isAcceptableOrUnknown(
          data['stock_status']!,
          _stockStatusMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('picker_id')) {
      context.handle(
        _pickerIdMeta,
        pickerId.isAcceptableOrUnknown(data['picker_id']!, _pickerIdMeta),
      );
    }
    if (data.containsKey('picked_at')) {
      context.handle(
        _pickedAtMeta,
        pickedAt.isAcceptableOrUnknown(data['picked_at']!, _pickedAtMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('cancellation_reason')) {
      context.handle(
        _cancellationReasonMeta,
        cancellationReason.isAcceptableOrUnknown(
          data['cancellation_reason']!,
          _cancellationReasonMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrderItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderItem(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      orderId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}order_id'],
          )!,
      productId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}product_id'],
          )!,
      productSku:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}product_sku'],
          )!,
      productName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}product_name'],
          )!,
      productCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_category'],
      ),
      quantity:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}quantity'],
          )!,
      deliveredQuantity:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}delivered_quantity'],
          )!,
      unitPrice:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}unit_price'],
          )!,
      subtotal:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}subtotal'],
          )!,
      discountAmount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}discount_amount'],
          )!,
      totalAmount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}total_amount'],
          )!,
      availableStock:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}available_stock'],
          )!,
      stockStatus:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}stock_status'],
          )!,
      status:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}status'],
          )!,
      pickerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}picker_id'],
      ),
      pickedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}picked_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      cancellationReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cancellation_reason'],
      ),
      isDeleted:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_deleted'],
          )!,
      syncStatus:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}sync_status'],
          )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $OrderItemsTable createAlias(String alias) {
    return $OrderItemsTable(attachedDatabase, alias);
  }
}

class OrderItem extends DataClass implements Insertable<OrderItem> {
  final String id;
  final String orderId;
  final String productId;
  final String productSku;
  final String productName;
  final String? productCategory;
  final int quantity;
  final int deliveredQuantity;
  final double unitPrice;
  final double subtotal;
  final double discountAmount;
  final double totalAmount;
  final int availableStock;
  final String stockStatus;
  final String status;
  final String? pickerId;
  final DateTime? pickedAt;
  final String? notes;
  final String? cancellationReason;
  final bool isDeleted;
  final String syncStatus;
  final String? remoteId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productSku,
    required this.productName,
    this.productCategory,
    required this.quantity,
    required this.deliveredQuantity,
    required this.unitPrice,
    required this.subtotal,
    required this.discountAmount,
    required this.totalAmount,
    required this.availableStock,
    required this.stockStatus,
    required this.status,
    this.pickerId,
    this.pickedAt,
    this.notes,
    this.cancellationReason,
    required this.isDeleted,
    required this.syncStatus,
    this.remoteId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['order_id'] = Variable<String>(orderId);
    map['product_id'] = Variable<String>(productId);
    map['product_sku'] = Variable<String>(productSku);
    map['product_name'] = Variable<String>(productName);
    if (!nullToAbsent || productCategory != null) {
      map['product_category'] = Variable<String>(productCategory);
    }
    map['quantity'] = Variable<int>(quantity);
    map['delivered_quantity'] = Variable<int>(deliveredQuantity);
    map['unit_price'] = Variable<double>(unitPrice);
    map['subtotal'] = Variable<double>(subtotal);
    map['discount_amount'] = Variable<double>(discountAmount);
    map['total_amount'] = Variable<double>(totalAmount);
    map['available_stock'] = Variable<int>(availableStock);
    map['stock_status'] = Variable<String>(stockStatus);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || pickerId != null) {
      map['picker_id'] = Variable<String>(pickerId);
    }
    if (!nullToAbsent || pickedAt != null) {
      map['picked_at'] = Variable<DateTime>(pickedAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || cancellationReason != null) {
      map['cancellation_reason'] = Variable<String>(cancellationReason);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  OrderItemsCompanion toCompanion(bool nullToAbsent) {
    return OrderItemsCompanion(
      id: Value(id),
      orderId: Value(orderId),
      productId: Value(productId),
      productSku: Value(productSku),
      productName: Value(productName),
      productCategory:
          productCategory == null && nullToAbsent
              ? const Value.absent()
              : Value(productCategory),
      quantity: Value(quantity),
      deliveredQuantity: Value(deliveredQuantity),
      unitPrice: Value(unitPrice),
      subtotal: Value(subtotal),
      discountAmount: Value(discountAmount),
      totalAmount: Value(totalAmount),
      availableStock: Value(availableStock),
      stockStatus: Value(stockStatus),
      status: Value(status),
      pickerId:
          pickerId == null && nullToAbsent
              ? const Value.absent()
              : Value(pickerId),
      pickedAt:
          pickedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(pickedAt),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      cancellationReason:
          cancellationReason == null && nullToAbsent
              ? const Value.absent()
              : Value(cancellationReason),
      isDeleted: Value(isDeleted),
      syncStatus: Value(syncStatus),
      remoteId:
          remoteId == null && nullToAbsent
              ? const Value.absent()
              : Value(remoteId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory OrderItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderItem(
      id: serializer.fromJson<String>(json['id']),
      orderId: serializer.fromJson<String>(json['orderId']),
      productId: serializer.fromJson<String>(json['productId']),
      productSku: serializer.fromJson<String>(json['productSku']),
      productName: serializer.fromJson<String>(json['productName']),
      productCategory: serializer.fromJson<String?>(json['productCategory']),
      quantity: serializer.fromJson<int>(json['quantity']),
      deliveredQuantity: serializer.fromJson<int>(json['deliveredQuantity']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      discountAmount: serializer.fromJson<double>(json['discountAmount']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      availableStock: serializer.fromJson<int>(json['availableStock']),
      stockStatus: serializer.fromJson<String>(json['stockStatus']),
      status: serializer.fromJson<String>(json['status']),
      pickerId: serializer.fromJson<String?>(json['pickerId']),
      pickedAt: serializer.fromJson<DateTime?>(json['pickedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      cancellationReason: serializer.fromJson<String?>(
        json['cancellationReason'],
      ),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'orderId': serializer.toJson<String>(orderId),
      'productId': serializer.toJson<String>(productId),
      'productSku': serializer.toJson<String>(productSku),
      'productName': serializer.toJson<String>(productName),
      'productCategory': serializer.toJson<String?>(productCategory),
      'quantity': serializer.toJson<int>(quantity),
      'deliveredQuantity': serializer.toJson<int>(deliveredQuantity),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'subtotal': serializer.toJson<double>(subtotal),
      'discountAmount': serializer.toJson<double>(discountAmount),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'availableStock': serializer.toJson<int>(availableStock),
      'stockStatus': serializer.toJson<String>(stockStatus),
      'status': serializer.toJson<String>(status),
      'pickerId': serializer.toJson<String?>(pickerId),
      'pickedAt': serializer.toJson<DateTime?>(pickedAt),
      'notes': serializer.toJson<String?>(notes),
      'cancellationReason': serializer.toJson<String?>(cancellationReason),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'remoteId': serializer.toJson<String?>(remoteId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  OrderItem copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? productSku,
    String? productName,
    Value<String?> productCategory = const Value.absent(),
    int? quantity,
    int? deliveredQuantity,
    double? unitPrice,
    double? subtotal,
    double? discountAmount,
    double? totalAmount,
    int? availableStock,
    String? stockStatus,
    String? status,
    Value<String?> pickerId = const Value.absent(),
    Value<DateTime?> pickedAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> cancellationReason = const Value.absent(),
    bool? isDeleted,
    String? syncStatus,
    Value<String?> remoteId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => OrderItem(
    id: id ?? this.id,
    orderId: orderId ?? this.orderId,
    productId: productId ?? this.productId,
    productSku: productSku ?? this.productSku,
    productName: productName ?? this.productName,
    productCategory:
        productCategory.present ? productCategory.value : this.productCategory,
    quantity: quantity ?? this.quantity,
    deliveredQuantity: deliveredQuantity ?? this.deliveredQuantity,
    unitPrice: unitPrice ?? this.unitPrice,
    subtotal: subtotal ?? this.subtotal,
    discountAmount: discountAmount ?? this.discountAmount,
    totalAmount: totalAmount ?? this.totalAmount,
    availableStock: availableStock ?? this.availableStock,
    stockStatus: stockStatus ?? this.stockStatus,
    status: status ?? this.status,
    pickerId: pickerId.present ? pickerId.value : this.pickerId,
    pickedAt: pickedAt.present ? pickedAt.value : this.pickedAt,
    notes: notes.present ? notes.value : this.notes,
    cancellationReason:
        cancellationReason.present
            ? cancellationReason.value
            : this.cancellationReason,
    isDeleted: isDeleted ?? this.isDeleted,
    syncStatus: syncStatus ?? this.syncStatus,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  OrderItem copyWithCompanion(OrderItemsCompanion data) {
    return OrderItem(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productSku:
          data.productSku.present ? data.productSku.value : this.productSku,
      productName:
          data.productName.present ? data.productName.value : this.productName,
      productCategory:
          data.productCategory.present
              ? data.productCategory.value
              : this.productCategory,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      deliveredQuantity:
          data.deliveredQuantity.present
              ? data.deliveredQuantity.value
              : this.deliveredQuantity,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      discountAmount:
          data.discountAmount.present
              ? data.discountAmount.value
              : this.discountAmount,
      totalAmount:
          data.totalAmount.present ? data.totalAmount.value : this.totalAmount,
      availableStock:
          data.availableStock.present
              ? data.availableStock.value
              : this.availableStock,
      stockStatus:
          data.stockStatus.present ? data.stockStatus.value : this.stockStatus,
      status: data.status.present ? data.status.value : this.status,
      pickerId: data.pickerId.present ? data.pickerId.value : this.pickerId,
      pickedAt: data.pickedAt.present ? data.pickedAt.value : this.pickedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      cancellationReason:
          data.cancellationReason.present
              ? data.cancellationReason.value
              : this.cancellationReason,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderItem(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('productId: $productId, ')
          ..write('productSku: $productSku, ')
          ..write('productName: $productName, ')
          ..write('productCategory: $productCategory, ')
          ..write('quantity: $quantity, ')
          ..write('deliveredQuantity: $deliveredQuantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('subtotal: $subtotal, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('availableStock: $availableStock, ')
          ..write('stockStatus: $stockStatus, ')
          ..write('status: $status, ')
          ..write('pickerId: $pickerId, ')
          ..write('pickedAt: $pickedAt, ')
          ..write('notes: $notes, ')
          ..write('cancellationReason: $cancellationReason, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    orderId,
    productId,
    productSku,
    productName,
    productCategory,
    quantity,
    deliveredQuantity,
    unitPrice,
    subtotal,
    discountAmount,
    totalAmount,
    availableStock,
    stockStatus,
    status,
    pickerId,
    pickedAt,
    notes,
    cancellationReason,
    isDeleted,
    syncStatus,
    remoteId,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderItem &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.productId == this.productId &&
          other.productSku == this.productSku &&
          other.productName == this.productName &&
          other.productCategory == this.productCategory &&
          other.quantity == this.quantity &&
          other.deliveredQuantity == this.deliveredQuantity &&
          other.unitPrice == this.unitPrice &&
          other.subtotal == this.subtotal &&
          other.discountAmount == this.discountAmount &&
          other.totalAmount == this.totalAmount &&
          other.availableStock == this.availableStock &&
          other.stockStatus == this.stockStatus &&
          other.status == this.status &&
          other.pickerId == this.pickerId &&
          other.pickedAt == this.pickedAt &&
          other.notes == this.notes &&
          other.cancellationReason == this.cancellationReason &&
          other.isDeleted == this.isDeleted &&
          other.syncStatus == this.syncStatus &&
          other.remoteId == this.remoteId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OrderItemsCompanion extends UpdateCompanion<OrderItem> {
  final Value<String> id;
  final Value<String> orderId;
  final Value<String> productId;
  final Value<String> productSku;
  final Value<String> productName;
  final Value<String?> productCategory;
  final Value<int> quantity;
  final Value<int> deliveredQuantity;
  final Value<double> unitPrice;
  final Value<double> subtotal;
  final Value<double> discountAmount;
  final Value<double> totalAmount;
  final Value<int> availableStock;
  final Value<String> stockStatus;
  final Value<String> status;
  final Value<String?> pickerId;
  final Value<DateTime?> pickedAt;
  final Value<String?> notes;
  final Value<String?> cancellationReason;
  final Value<bool> isDeleted;
  final Value<String> syncStatus;
  final Value<String?> remoteId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const OrderItemsCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productSku = const Value.absent(),
    this.productName = const Value.absent(),
    this.productCategory = const Value.absent(),
    this.quantity = const Value.absent(),
    this.deliveredQuantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.availableStock = const Value.absent(),
    this.stockStatus = const Value.absent(),
    this.status = const Value.absent(),
    this.pickerId = const Value.absent(),
    this.pickedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.cancellationReason = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrderItemsCompanion.insert({
    required String id,
    required String orderId,
    required String productId,
    required String productSku,
    required String productName,
    this.productCategory = const Value.absent(),
    required int quantity,
    this.deliveredQuantity = const Value.absent(),
    required double unitPrice,
    required double subtotal,
    this.discountAmount = const Value.absent(),
    required double totalAmount,
    required int availableStock,
    this.stockStatus = const Value.absent(),
    this.status = const Value.absent(),
    this.pickerId = const Value.absent(),
    this.pickedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.cancellationReason = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       orderId = Value(orderId),
       productId = Value(productId),
       productSku = Value(productSku),
       productName = Value(productName),
       quantity = Value(quantity),
       unitPrice = Value(unitPrice),
       subtotal = Value(subtotal),
       totalAmount = Value(totalAmount),
       availableStock = Value(availableStock);
  static Insertable<OrderItem> custom({
    Expression<String>? id,
    Expression<String>? orderId,
    Expression<String>? productId,
    Expression<String>? productSku,
    Expression<String>? productName,
    Expression<String>? productCategory,
    Expression<int>? quantity,
    Expression<int>? deliveredQuantity,
    Expression<double>? unitPrice,
    Expression<double>? subtotal,
    Expression<double>? discountAmount,
    Expression<double>? totalAmount,
    Expression<int>? availableStock,
    Expression<String>? stockStatus,
    Expression<String>? status,
    Expression<String>? pickerId,
    Expression<DateTime>? pickedAt,
    Expression<String>? notes,
    Expression<String>? cancellationReason,
    Expression<bool>? isDeleted,
    Expression<String>? syncStatus,
    Expression<String>? remoteId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (productId != null) 'product_id': productId,
      if (productSku != null) 'product_sku': productSku,
      if (productName != null) 'product_name': productName,
      if (productCategory != null) 'product_category': productCategory,
      if (quantity != null) 'quantity': quantity,
      if (deliveredQuantity != null) 'delivered_quantity': deliveredQuantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (subtotal != null) 'subtotal': subtotal,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (availableStock != null) 'available_stock': availableStock,
      if (stockStatus != null) 'stock_status': stockStatus,
      if (status != null) 'status': status,
      if (pickerId != null) 'picker_id': pickerId,
      if (pickedAt != null) 'picked_at': pickedAt,
      if (notes != null) 'notes': notes,
      if (cancellationReason != null) 'cancellation_reason': cancellationReason,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (remoteId != null) 'remote_id': remoteId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrderItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? orderId,
    Value<String>? productId,
    Value<String>? productSku,
    Value<String>? productName,
    Value<String?>? productCategory,
    Value<int>? quantity,
    Value<int>? deliveredQuantity,
    Value<double>? unitPrice,
    Value<double>? subtotal,
    Value<double>? discountAmount,
    Value<double>? totalAmount,
    Value<int>? availableStock,
    Value<String>? stockStatus,
    Value<String>? status,
    Value<String?>? pickerId,
    Value<DateTime?>? pickedAt,
    Value<String?>? notes,
    Value<String?>? cancellationReason,
    Value<bool>? isDeleted,
    Value<String>? syncStatus,
    Value<String?>? remoteId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return OrderItemsCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productSku: productSku ?? this.productSku,
      productName: productName ?? this.productName,
      productCategory: productCategory ?? this.productCategory,
      quantity: quantity ?? this.quantity,
      deliveredQuantity: deliveredQuantity ?? this.deliveredQuantity,
      unitPrice: unitPrice ?? this.unitPrice,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      availableStock: availableStock ?? this.availableStock,
      stockStatus: stockStatus ?? this.stockStatus,
      status: status ?? this.status,
      pickerId: pickerId ?? this.pickerId,
      pickedAt: pickedAt ?? this.pickedAt,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteId: remoteId ?? this.remoteId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productSku.present) {
      map['product_sku'] = Variable<String>(productSku.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (productCategory.present) {
      map['product_category'] = Variable<String>(productCategory.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (deliveredQuantity.present) {
      map['delivered_quantity'] = Variable<int>(deliveredQuantity.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (discountAmount.present) {
      map['discount_amount'] = Variable<double>(discountAmount.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (availableStock.present) {
      map['available_stock'] = Variable<int>(availableStock.value);
    }
    if (stockStatus.present) {
      map['stock_status'] = Variable<String>(stockStatus.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (pickerId.present) {
      map['picker_id'] = Variable<String>(pickerId.value);
    }
    if (pickedAt.present) {
      map['picked_at'] = Variable<DateTime>(pickedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (cancellationReason.present) {
      map['cancellation_reason'] = Variable<String>(cancellationReason.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrderItemsCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('productId: $productId, ')
          ..write('productSku: $productSku, ')
          ..write('productName: $productName, ')
          ..write('productCategory: $productCategory, ')
          ..write('quantity: $quantity, ')
          ..write('deliveredQuantity: $deliveredQuantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('subtotal: $subtotal, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('availableStock: $availableStock, ')
          ..write('stockStatus: $stockStatus, ')
          ..write('status: $status, ')
          ..write('pickerId: $pickerId, ')
          ..write('pickedAt: $pickedAt, ')
          ..write('notes: $notes, ')
          ..write('cancellationReason: $cancellationReason, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeliveriesTable extends Deliveries
    with TableInfo<$DeliveriesTable, Delivery> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeliveriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
    'order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deliveryPersonnelIdMeta =
      const VerificationMeta('deliveryPersonnelId');
  @override
  late final GeneratedColumn<String> deliveryPersonnelId =
      GeneratedColumn<String>(
        'delivery_personnel_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _deliveryPersonnelNameMeta =
      const VerificationMeta('deliveryPersonnelName');
  @override
  late final GeneratedColumn<String> deliveryPersonnelName =
      GeneratedColumn<String>(
        'delivery_personnel_name',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _deliveryPersonnelPhoneMeta =
      const VerificationMeta('deliveryPersonnelPhone');
  @override
  late final GeneratedColumn<String> deliveryPersonnelPhone =
      GeneratedColumn<String>(
        'delivery_personnel_phone',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _deliveryNumberMeta = const VerificationMeta(
    'deliveryNumber',
  );
  @override
  late final GeneratedColumn<String> deliveryNumber = GeneratedColumn<String>(
    'delivery_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _scheduledDateMeta = const VerificationMeta(
    'scheduledDate',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledDate =
      GeneratedColumn<DateTime>(
        'scheduled_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _actualStartTimeMeta = const VerificationMeta(
    'actualStartTime',
  );
  @override
  late final GeneratedColumn<DateTime> actualStartTime =
      GeneratedColumn<DateTime>(
        'actual_start_time',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _actualCompletionTimeMeta =
      const VerificationMeta('actualCompletionTime');
  @override
  late final GeneratedColumn<DateTime> actualCompletionTime =
      GeneratedColumn<DateTime>(
        'actual_completion_time',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _subStatusMeta = const VerificationMeta(
    'subStatus',
  );
  @override
  late final GeneratedColumn<String> subStatus = GeneratedColumn<String>(
    'sub_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _routeMeta = const VerificationMeta('route');
  @override
  late final GeneratedColumn<String> route = GeneratedColumn<String>(
    'route',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _routeOrderMeta = const VerificationMeta(
    'routeOrder',
  );
  @override
  late final GeneratedColumn<int> routeOrder = GeneratedColumn<int>(
    'route_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vehicleNumberMeta = const VerificationMeta(
    'vehicleNumber',
  );
  @override
  late final GeneratedColumn<String> vehicleNumber = GeneratedColumn<String>(
    'vehicle_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startLocationMeta = const VerificationMeta(
    'startLocation',
  );
  @override
  late final GeneratedColumn<String> startLocation = GeneratedColumn<String>(
    'start_location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endLocationMeta = const VerificationMeta(
    'endLocation',
  );
  @override
  late final GeneratedColumn<String> endLocation = GeneratedColumn<String>(
    'end_location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startLatitudeMeta = const VerificationMeta(
    'startLatitude',
  );
  @override
  late final GeneratedColumn<double> startLatitude = GeneratedColumn<double>(
    'start_latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startLongitudeMeta = const VerificationMeta(
    'startLongitude',
  );
  @override
  late final GeneratedColumn<double> startLongitude = GeneratedColumn<double>(
    'start_longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endLatitudeMeta = const VerificationMeta(
    'endLatitude',
  );
  @override
  late final GeneratedColumn<double> endLatitude = GeneratedColumn<double>(
    'end_latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endLongitudeMeta = const VerificationMeta(
    'endLongitude',
  );
  @override
  late final GeneratedColumn<double> endLongitude = GeneratedColumn<double>(
    'end_longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proofOfDeliveryTypeMeta =
      const VerificationMeta('proofOfDeliveryType');
  @override
  late final GeneratedColumn<String> proofOfDeliveryType =
      GeneratedColumn<String>(
        'proof_of_delivery_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _proofOfDeliveryUrlMeta =
      const VerificationMeta('proofOfDeliveryUrl');
  @override
  late final GeneratedColumn<String> proofOfDeliveryUrl =
      GeneratedColumn<String>(
        'proof_of_delivery_url',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _recipientNameMeta = const VerificationMeta(
    'recipientName',
  );
  @override
  late final GeneratedColumn<String> recipientName = GeneratedColumn<String>(
    'recipient_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recipientRelationMeta = const VerificationMeta(
    'recipientRelation',
  );
  @override
  late final GeneratedColumn<String> recipientRelation =
      GeneratedColumn<String>(
        'recipient_relation',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _deliveryNotesMeta = const VerificationMeta(
    'deliveryNotes',
  );
  @override
  late final GeneratedColumn<String> deliveryNotes = GeneratedColumn<String>(
    'delivery_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _collectedAmountMeta = const VerificationMeta(
    'collectedAmount',
  );
  @override
  late final GeneratedColumn<double> collectedAmount = GeneratedColumn<double>(
    'collected_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checkNumberMeta = const VerificationMeta(
    'checkNumber',
  );
  @override
  late final GeneratedColumn<String> checkNumber = GeneratedColumn<String>(
    'check_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _issueTypeMeta = const VerificationMeta(
    'issueType',
  );
  @override
  late final GeneratedColumn<String> issueType = GeneratedColumn<String>(
    'issue_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _issueDescriptionMeta = const VerificationMeta(
    'issueDescription',
  );
  @override
  late final GeneratedColumn<String> issueDescription = GeneratedColumn<String>(
    'issue_description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resolutionMeta = const VerificationMeta(
    'resolution',
  );
  @override
  late final GeneratedColumn<String> resolution = GeneratedColumn<String>(
    'resolution',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('normal'),
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptDateMeta = const VerificationMeta(
    'nextAttemptDate',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptDate =
      GeneratedColumn<DateTime>(
        'next_attempt_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    orderId,
    deliveryPersonnelId,
    deliveryPersonnelName,
    deliveryPersonnelPhone,
    deliveryNumber,
    scheduledDate,
    actualStartTime,
    actualCompletionTime,
    status,
    subStatus,
    route,
    routeOrder,
    vehicleNumber,
    startLocation,
    endLocation,
    startLatitude,
    startLongitude,
    endLatitude,
    endLongitude,
    proofOfDeliveryType,
    proofOfDeliveryUrl,
    recipientName,
    recipientRelation,
    deliveryNotes,
    collectedAmount,
    paymentMethod,
    checkNumber,
    issueType,
    issueDescription,
    resolution,
    priority,
    attemptCount,
    nextAttemptDate,
    isDeleted,
    syncStatus,
    remoteId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deliveries';
  @override
  VerificationContext validateIntegrity(
    Insertable<Delivery> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('delivery_personnel_id')) {
      context.handle(
        _deliveryPersonnelIdMeta,
        deliveryPersonnelId.isAcceptableOrUnknown(
          data['delivery_personnel_id']!,
          _deliveryPersonnelIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deliveryPersonnelIdMeta);
    }
    if (data.containsKey('delivery_personnel_name')) {
      context.handle(
        _deliveryPersonnelNameMeta,
        deliveryPersonnelName.isAcceptableOrUnknown(
          data['delivery_personnel_name']!,
          _deliveryPersonnelNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deliveryPersonnelNameMeta);
    }
    if (data.containsKey('delivery_personnel_phone')) {
      context.handle(
        _deliveryPersonnelPhoneMeta,
        deliveryPersonnelPhone.isAcceptableOrUnknown(
          data['delivery_personnel_phone']!,
          _deliveryPersonnelPhoneMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deliveryPersonnelPhoneMeta);
    }
    if (data.containsKey('delivery_number')) {
      context.handle(
        _deliveryNumberMeta,
        deliveryNumber.isAcceptableOrUnknown(
          data['delivery_number']!,
          _deliveryNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deliveryNumberMeta);
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
        _scheduledDateMeta,
        scheduledDate.isAcceptableOrUnknown(
          data['scheduled_date']!,
          _scheduledDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledDateMeta);
    }
    if (data.containsKey('actual_start_time')) {
      context.handle(
        _actualStartTimeMeta,
        actualStartTime.isAcceptableOrUnknown(
          data['actual_start_time']!,
          _actualStartTimeMeta,
        ),
      );
    }
    if (data.containsKey('actual_completion_time')) {
      context.handle(
        _actualCompletionTimeMeta,
        actualCompletionTime.isAcceptableOrUnknown(
          data['actual_completion_time']!,
          _actualCompletionTimeMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('sub_status')) {
      context.handle(
        _subStatusMeta,
        subStatus.isAcceptableOrUnknown(data['sub_status']!, _subStatusMeta),
      );
    }
    if (data.containsKey('route')) {
      context.handle(
        _routeMeta,
        route.isAcceptableOrUnknown(data['route']!, _routeMeta),
      );
    } else if (isInserting) {
      context.missing(_routeMeta);
    }
    if (data.containsKey('route_order')) {
      context.handle(
        _routeOrderMeta,
        routeOrder.isAcceptableOrUnknown(data['route_order']!, _routeOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_routeOrderMeta);
    }
    if (data.containsKey('vehicle_number')) {
      context.handle(
        _vehicleNumberMeta,
        vehicleNumber.isAcceptableOrUnknown(
          data['vehicle_number']!,
          _vehicleNumberMeta,
        ),
      );
    }
    if (data.containsKey('start_location')) {
      context.handle(
        _startLocationMeta,
        startLocation.isAcceptableOrUnknown(
          data['start_location']!,
          _startLocationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startLocationMeta);
    }
    if (data.containsKey('end_location')) {
      context.handle(
        _endLocationMeta,
        endLocation.isAcceptableOrUnknown(
          data['end_location']!,
          _endLocationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_endLocationMeta);
    }
    if (data.containsKey('start_latitude')) {
      context.handle(
        _startLatitudeMeta,
        startLatitude.isAcceptableOrUnknown(
          data['start_latitude']!,
          _startLatitudeMeta,
        ),
      );
    }
    if (data.containsKey('start_longitude')) {
      context.handle(
        _startLongitudeMeta,
        startLongitude.isAcceptableOrUnknown(
          data['start_longitude']!,
          _startLongitudeMeta,
        ),
      );
    }
    if (data.containsKey('end_latitude')) {
      context.handle(
        _endLatitudeMeta,
        endLatitude.isAcceptableOrUnknown(
          data['end_latitude']!,
          _endLatitudeMeta,
        ),
      );
    }
    if (data.containsKey('end_longitude')) {
      context.handle(
        _endLongitudeMeta,
        endLongitude.isAcceptableOrUnknown(
          data['end_longitude']!,
          _endLongitudeMeta,
        ),
      );
    }
    if (data.containsKey('proof_of_delivery_type')) {
      context.handle(
        _proofOfDeliveryTypeMeta,
        proofOfDeliveryType.isAcceptableOrUnknown(
          data['proof_of_delivery_type']!,
          _proofOfDeliveryTypeMeta,
        ),
      );
    }
    if (data.containsKey('proof_of_delivery_url')) {
      context.handle(
        _proofOfDeliveryUrlMeta,
        proofOfDeliveryUrl.isAcceptableOrUnknown(
          data['proof_of_delivery_url']!,
          _proofOfDeliveryUrlMeta,
        ),
      );
    }
    if (data.containsKey('recipient_name')) {
      context.handle(
        _recipientNameMeta,
        recipientName.isAcceptableOrUnknown(
          data['recipient_name']!,
          _recipientNameMeta,
        ),
      );
    }
    if (data.containsKey('recipient_relation')) {
      context.handle(
        _recipientRelationMeta,
        recipientRelation.isAcceptableOrUnknown(
          data['recipient_relation']!,
          _recipientRelationMeta,
        ),
      );
    }
    if (data.containsKey('delivery_notes')) {
      context.handle(
        _deliveryNotesMeta,
        deliveryNotes.isAcceptableOrUnknown(
          data['delivery_notes']!,
          _deliveryNotesMeta,
        ),
      );
    }
    if (data.containsKey('collected_amount')) {
      context.handle(
        _collectedAmountMeta,
        collectedAmount.isAcceptableOrUnknown(
          data['collected_amount']!,
          _collectedAmountMeta,
        ),
      );
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('check_number')) {
      context.handle(
        _checkNumberMeta,
        checkNumber.isAcceptableOrUnknown(
          data['check_number']!,
          _checkNumberMeta,
        ),
      );
    }
    if (data.containsKey('issue_type')) {
      context.handle(
        _issueTypeMeta,
        issueType.isAcceptableOrUnknown(data['issue_type']!, _issueTypeMeta),
      );
    }
    if (data.containsKey('issue_description')) {
      context.handle(
        _issueDescriptionMeta,
        issueDescription.isAcceptableOrUnknown(
          data['issue_description']!,
          _issueDescriptionMeta,
        ),
      );
    }
    if (data.containsKey('resolution')) {
      context.handle(
        _resolutionMeta,
        resolution.isAcceptableOrUnknown(data['resolution']!, _resolutionMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('next_attempt_date')) {
      context.handle(
        _nextAttemptDateMeta,
        nextAttemptDate.isAcceptableOrUnknown(
          data['next_attempt_date']!,
          _nextAttemptDateMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Delivery map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Delivery(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      orderId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}order_id'],
          )!,
      deliveryPersonnelId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}delivery_personnel_id'],
          )!,
      deliveryPersonnelName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}delivery_personnel_name'],
          )!,
      deliveryPersonnelPhone:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}delivery_personnel_phone'],
          )!,
      deliveryNumber:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}delivery_number'],
          )!,
      scheduledDate:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}scheduled_date'],
          )!,
      actualStartTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}actual_start_time'],
      ),
      actualCompletionTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}actual_completion_time'],
      ),
      status:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}status'],
          )!,
      subStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub_status'],
      ),
      route:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}route'],
          )!,
      routeOrder:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}route_order'],
          )!,
      vehicleNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vehicle_number'],
      ),
      startLocation:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}start_location'],
          )!,
      endLocation:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}end_location'],
          )!,
      startLatitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}start_latitude'],
      ),
      startLongitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}start_longitude'],
      ),
      endLatitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}end_latitude'],
      ),
      endLongitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}end_longitude'],
      ),
      proofOfDeliveryType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}proof_of_delivery_type'],
      ),
      proofOfDeliveryUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}proof_of_delivery_url'],
      ),
      recipientName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipient_name'],
      ),
      recipientRelation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipient_relation'],
      ),
      deliveryNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery_notes'],
      ),
      collectedAmount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}collected_amount'],
          )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      ),
      checkNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}check_number'],
      ),
      issueType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issue_type'],
      ),
      issueDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issue_description'],
      ),
      resolution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolution'],
      ),
      priority:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}priority'],
          )!,
      attemptCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}attempt_count'],
          )!,
      nextAttemptDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_date'],
      ),
      isDeleted:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_deleted'],
          )!,
      syncStatus:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}sync_status'],
          )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $DeliveriesTable createAlias(String alias) {
    return $DeliveriesTable(attachedDatabase, alias);
  }
}

class Delivery extends DataClass implements Insertable<Delivery> {
  final String id;
  final String orderId;
  final String deliveryPersonnelId;
  final String deliveryPersonnelName;
  final String deliveryPersonnelPhone;
  final String deliveryNumber;
  final DateTime scheduledDate;
  final DateTime? actualStartTime;
  final DateTime? actualCompletionTime;
  final String status;
  final String? subStatus;
  final String route;
  final int routeOrder;
  final String? vehicleNumber;
  final String startLocation;
  final String endLocation;
  final double? startLatitude;
  final double? startLongitude;
  final double? endLatitude;
  final double? endLongitude;
  final String? proofOfDeliveryType;
  final String? proofOfDeliveryUrl;
  final String? recipientName;
  final String? recipientRelation;
  final String? deliveryNotes;
  final double collectedAmount;
  final String? paymentMethod;
  final String? checkNumber;
  final String? issueType;
  final String? issueDescription;
  final String? resolution;
  final String priority;
  final int attemptCount;
  final DateTime? nextAttemptDate;
  final bool isDeleted;
  final String syncStatus;
  final String? remoteId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Delivery({
    required this.id,
    required this.orderId,
    required this.deliveryPersonnelId,
    required this.deliveryPersonnelName,
    required this.deliveryPersonnelPhone,
    required this.deliveryNumber,
    required this.scheduledDate,
    this.actualStartTime,
    this.actualCompletionTime,
    required this.status,
    this.subStatus,
    required this.route,
    required this.routeOrder,
    this.vehicleNumber,
    required this.startLocation,
    required this.endLocation,
    this.startLatitude,
    this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    this.proofOfDeliveryType,
    this.proofOfDeliveryUrl,
    this.recipientName,
    this.recipientRelation,
    this.deliveryNotes,
    required this.collectedAmount,
    this.paymentMethod,
    this.checkNumber,
    this.issueType,
    this.issueDescription,
    this.resolution,
    required this.priority,
    required this.attemptCount,
    this.nextAttemptDate,
    required this.isDeleted,
    required this.syncStatus,
    this.remoteId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['order_id'] = Variable<String>(orderId);
    map['delivery_personnel_id'] = Variable<String>(deliveryPersonnelId);
    map['delivery_personnel_name'] = Variable<String>(deliveryPersonnelName);
    map['delivery_personnel_phone'] = Variable<String>(deliveryPersonnelPhone);
    map['delivery_number'] = Variable<String>(deliveryNumber);
    map['scheduled_date'] = Variable<DateTime>(scheduledDate);
    if (!nullToAbsent || actualStartTime != null) {
      map['actual_start_time'] = Variable<DateTime>(actualStartTime);
    }
    if (!nullToAbsent || actualCompletionTime != null) {
      map['actual_completion_time'] = Variable<DateTime>(actualCompletionTime);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || subStatus != null) {
      map['sub_status'] = Variable<String>(subStatus);
    }
    map['route'] = Variable<String>(route);
    map['route_order'] = Variable<int>(routeOrder);
    if (!nullToAbsent || vehicleNumber != null) {
      map['vehicle_number'] = Variable<String>(vehicleNumber);
    }
    map['start_location'] = Variable<String>(startLocation);
    map['end_location'] = Variable<String>(endLocation);
    if (!nullToAbsent || startLatitude != null) {
      map['start_latitude'] = Variable<double>(startLatitude);
    }
    if (!nullToAbsent || startLongitude != null) {
      map['start_longitude'] = Variable<double>(startLongitude);
    }
    if (!nullToAbsent || endLatitude != null) {
      map['end_latitude'] = Variable<double>(endLatitude);
    }
    if (!nullToAbsent || endLongitude != null) {
      map['end_longitude'] = Variable<double>(endLongitude);
    }
    if (!nullToAbsent || proofOfDeliveryType != null) {
      map['proof_of_delivery_type'] = Variable<String>(proofOfDeliveryType);
    }
    if (!nullToAbsent || proofOfDeliveryUrl != null) {
      map['proof_of_delivery_url'] = Variable<String>(proofOfDeliveryUrl);
    }
    if (!nullToAbsent || recipientName != null) {
      map['recipient_name'] = Variable<String>(recipientName);
    }
    if (!nullToAbsent || recipientRelation != null) {
      map['recipient_relation'] = Variable<String>(recipientRelation);
    }
    if (!nullToAbsent || deliveryNotes != null) {
      map['delivery_notes'] = Variable<String>(deliveryNotes);
    }
    map['collected_amount'] = Variable<double>(collectedAmount);
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    if (!nullToAbsent || checkNumber != null) {
      map['check_number'] = Variable<String>(checkNumber);
    }
    if (!nullToAbsent || issueType != null) {
      map['issue_type'] = Variable<String>(issueType);
    }
    if (!nullToAbsent || issueDescription != null) {
      map['issue_description'] = Variable<String>(issueDescription);
    }
    if (!nullToAbsent || resolution != null) {
      map['resolution'] = Variable<String>(resolution);
    }
    map['priority'] = Variable<String>(priority);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || nextAttemptDate != null) {
      map['next_attempt_date'] = Variable<DateTime>(nextAttemptDate);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DeliveriesCompanion toCompanion(bool nullToAbsent) {
    return DeliveriesCompanion(
      id: Value(id),
      orderId: Value(orderId),
      deliveryPersonnelId: Value(deliveryPersonnelId),
      deliveryPersonnelName: Value(deliveryPersonnelName),
      deliveryPersonnelPhone: Value(deliveryPersonnelPhone),
      deliveryNumber: Value(deliveryNumber),
      scheduledDate: Value(scheduledDate),
      actualStartTime:
          actualStartTime == null && nullToAbsent
              ? const Value.absent()
              : Value(actualStartTime),
      actualCompletionTime:
          actualCompletionTime == null && nullToAbsent
              ? const Value.absent()
              : Value(actualCompletionTime),
      status: Value(status),
      subStatus:
          subStatus == null && nullToAbsent
              ? const Value.absent()
              : Value(subStatus),
      route: Value(route),
      routeOrder: Value(routeOrder),
      vehicleNumber:
          vehicleNumber == null && nullToAbsent
              ? const Value.absent()
              : Value(vehicleNumber),
      startLocation: Value(startLocation),
      endLocation: Value(endLocation),
      startLatitude:
          startLatitude == null && nullToAbsent
              ? const Value.absent()
              : Value(startLatitude),
      startLongitude:
          startLongitude == null && nullToAbsent
              ? const Value.absent()
              : Value(startLongitude),
      endLatitude:
          endLatitude == null && nullToAbsent
              ? const Value.absent()
              : Value(endLatitude),
      endLongitude:
          endLongitude == null && nullToAbsent
              ? const Value.absent()
              : Value(endLongitude),
      proofOfDeliveryType:
          proofOfDeliveryType == null && nullToAbsent
              ? const Value.absent()
              : Value(proofOfDeliveryType),
      proofOfDeliveryUrl:
          proofOfDeliveryUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(proofOfDeliveryUrl),
      recipientName:
          recipientName == null && nullToAbsent
              ? const Value.absent()
              : Value(recipientName),
      recipientRelation:
          recipientRelation == null && nullToAbsent
              ? const Value.absent()
              : Value(recipientRelation),
      deliveryNotes:
          deliveryNotes == null && nullToAbsent
              ? const Value.absent()
              : Value(deliveryNotes),
      collectedAmount: Value(collectedAmount),
      paymentMethod:
          paymentMethod == null && nullToAbsent
              ? const Value.absent()
              : Value(paymentMethod),
      checkNumber:
          checkNumber == null && nullToAbsent
              ? const Value.absent()
              : Value(checkNumber),
      issueType:
          issueType == null && nullToAbsent
              ? const Value.absent()
              : Value(issueType),
      issueDescription:
          issueDescription == null && nullToAbsent
              ? const Value.absent()
              : Value(issueDescription),
      resolution:
          resolution == null && nullToAbsent
              ? const Value.absent()
              : Value(resolution),
      priority: Value(priority),
      attemptCount: Value(attemptCount),
      nextAttemptDate:
          nextAttemptDate == null && nullToAbsent
              ? const Value.absent()
              : Value(nextAttemptDate),
      isDeleted: Value(isDeleted),
      syncStatus: Value(syncStatus),
      remoteId:
          remoteId == null && nullToAbsent
              ? const Value.absent()
              : Value(remoteId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Delivery.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Delivery(
      id: serializer.fromJson<String>(json['id']),
      orderId: serializer.fromJson<String>(json['orderId']),
      deliveryPersonnelId: serializer.fromJson<String>(
        json['deliveryPersonnelId'],
      ),
      deliveryPersonnelName: serializer.fromJson<String>(
        json['deliveryPersonnelName'],
      ),
      deliveryPersonnelPhone: serializer.fromJson<String>(
        json['deliveryPersonnelPhone'],
      ),
      deliveryNumber: serializer.fromJson<String>(json['deliveryNumber']),
      scheduledDate: serializer.fromJson<DateTime>(json['scheduledDate']),
      actualStartTime: serializer.fromJson<DateTime?>(json['actualStartTime']),
      actualCompletionTime: serializer.fromJson<DateTime?>(
        json['actualCompletionTime'],
      ),
      status: serializer.fromJson<String>(json['status']),
      subStatus: serializer.fromJson<String?>(json['subStatus']),
      route: serializer.fromJson<String>(json['route']),
      routeOrder: serializer.fromJson<int>(json['routeOrder']),
      vehicleNumber: serializer.fromJson<String?>(json['vehicleNumber']),
      startLocation: serializer.fromJson<String>(json['startLocation']),
      endLocation: serializer.fromJson<String>(json['endLocation']),
      startLatitude: serializer.fromJson<double?>(json['startLatitude']),
      startLongitude: serializer.fromJson<double?>(json['startLongitude']),
      endLatitude: serializer.fromJson<double?>(json['endLatitude']),
      endLongitude: serializer.fromJson<double?>(json['endLongitude']),
      proofOfDeliveryType: serializer.fromJson<String?>(
        json['proofOfDeliveryType'],
      ),
      proofOfDeliveryUrl: serializer.fromJson<String?>(
        json['proofOfDeliveryUrl'],
      ),
      recipientName: serializer.fromJson<String?>(json['recipientName']),
      recipientRelation: serializer.fromJson<String?>(
        json['recipientRelation'],
      ),
      deliveryNotes: serializer.fromJson<String?>(json['deliveryNotes']),
      collectedAmount: serializer.fromJson<double>(json['collectedAmount']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      checkNumber: serializer.fromJson<String?>(json['checkNumber']),
      issueType: serializer.fromJson<String?>(json['issueType']),
      issueDescription: serializer.fromJson<String?>(json['issueDescription']),
      resolution: serializer.fromJson<String?>(json['resolution']),
      priority: serializer.fromJson<String>(json['priority']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      nextAttemptDate: serializer.fromJson<DateTime?>(json['nextAttemptDate']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'orderId': serializer.toJson<String>(orderId),
      'deliveryPersonnelId': serializer.toJson<String>(deliveryPersonnelId),
      'deliveryPersonnelName': serializer.toJson<String>(deliveryPersonnelName),
      'deliveryPersonnelPhone': serializer.toJson<String>(
        deliveryPersonnelPhone,
      ),
      'deliveryNumber': serializer.toJson<String>(deliveryNumber),
      'scheduledDate': serializer.toJson<DateTime>(scheduledDate),
      'actualStartTime': serializer.toJson<DateTime?>(actualStartTime),
      'actualCompletionTime': serializer.toJson<DateTime?>(
        actualCompletionTime,
      ),
      'status': serializer.toJson<String>(status),
      'subStatus': serializer.toJson<String?>(subStatus),
      'route': serializer.toJson<String>(route),
      'routeOrder': serializer.toJson<int>(routeOrder),
      'vehicleNumber': serializer.toJson<String?>(vehicleNumber),
      'startLocation': serializer.toJson<String>(startLocation),
      'endLocation': serializer.toJson<String>(endLocation),
      'startLatitude': serializer.toJson<double?>(startLatitude),
      'startLongitude': serializer.toJson<double?>(startLongitude),
      'endLatitude': serializer.toJson<double?>(endLatitude),
      'endLongitude': serializer.toJson<double?>(endLongitude),
      'proofOfDeliveryType': serializer.toJson<String?>(proofOfDeliveryType),
      'proofOfDeliveryUrl': serializer.toJson<String?>(proofOfDeliveryUrl),
      'recipientName': serializer.toJson<String?>(recipientName),
      'recipientRelation': serializer.toJson<String?>(recipientRelation),
      'deliveryNotes': serializer.toJson<String?>(deliveryNotes),
      'collectedAmount': serializer.toJson<double>(collectedAmount),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'checkNumber': serializer.toJson<String?>(checkNumber),
      'issueType': serializer.toJson<String?>(issueType),
      'issueDescription': serializer.toJson<String?>(issueDescription),
      'resolution': serializer.toJson<String?>(resolution),
      'priority': serializer.toJson<String>(priority),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'nextAttemptDate': serializer.toJson<DateTime?>(nextAttemptDate),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'remoteId': serializer.toJson<String?>(remoteId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Delivery copyWith({
    String? id,
    String? orderId,
    String? deliveryPersonnelId,
    String? deliveryPersonnelName,
    String? deliveryPersonnelPhone,
    String? deliveryNumber,
    DateTime? scheduledDate,
    Value<DateTime?> actualStartTime = const Value.absent(),
    Value<DateTime?> actualCompletionTime = const Value.absent(),
    String? status,
    Value<String?> subStatus = const Value.absent(),
    String? route,
    int? routeOrder,
    Value<String?> vehicleNumber = const Value.absent(),
    String? startLocation,
    String? endLocation,
    Value<double?> startLatitude = const Value.absent(),
    Value<double?> startLongitude = const Value.absent(),
    Value<double?> endLatitude = const Value.absent(),
    Value<double?> endLongitude = const Value.absent(),
    Value<String?> proofOfDeliveryType = const Value.absent(),
    Value<String?> proofOfDeliveryUrl = const Value.absent(),
    Value<String?> recipientName = const Value.absent(),
    Value<String?> recipientRelation = const Value.absent(),
    Value<String?> deliveryNotes = const Value.absent(),
    double? collectedAmount,
    Value<String?> paymentMethod = const Value.absent(),
    Value<String?> checkNumber = const Value.absent(),
    Value<String?> issueType = const Value.absent(),
    Value<String?> issueDescription = const Value.absent(),
    Value<String?> resolution = const Value.absent(),
    String? priority,
    int? attemptCount,
    Value<DateTime?> nextAttemptDate = const Value.absent(),
    bool? isDeleted,
    String? syncStatus,
    Value<String?> remoteId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Delivery(
    id: id ?? this.id,
    orderId: orderId ?? this.orderId,
    deliveryPersonnelId: deliveryPersonnelId ?? this.deliveryPersonnelId,
    deliveryPersonnelName: deliveryPersonnelName ?? this.deliveryPersonnelName,
    deliveryPersonnelPhone:
        deliveryPersonnelPhone ?? this.deliveryPersonnelPhone,
    deliveryNumber: deliveryNumber ?? this.deliveryNumber,
    scheduledDate: scheduledDate ?? this.scheduledDate,
    actualStartTime:
        actualStartTime.present ? actualStartTime.value : this.actualStartTime,
    actualCompletionTime:
        actualCompletionTime.present
            ? actualCompletionTime.value
            : this.actualCompletionTime,
    status: status ?? this.status,
    subStatus: subStatus.present ? subStatus.value : this.subStatus,
    route: route ?? this.route,
    routeOrder: routeOrder ?? this.routeOrder,
    vehicleNumber:
        vehicleNumber.present ? vehicleNumber.value : this.vehicleNumber,
    startLocation: startLocation ?? this.startLocation,
    endLocation: endLocation ?? this.endLocation,
    startLatitude:
        startLatitude.present ? startLatitude.value : this.startLatitude,
    startLongitude:
        startLongitude.present ? startLongitude.value : this.startLongitude,
    endLatitude: endLatitude.present ? endLatitude.value : this.endLatitude,
    endLongitude: endLongitude.present ? endLongitude.value : this.endLongitude,
    proofOfDeliveryType:
        proofOfDeliveryType.present
            ? proofOfDeliveryType.value
            : this.proofOfDeliveryType,
    proofOfDeliveryUrl:
        proofOfDeliveryUrl.present
            ? proofOfDeliveryUrl.value
            : this.proofOfDeliveryUrl,
    recipientName:
        recipientName.present ? recipientName.value : this.recipientName,
    recipientRelation:
        recipientRelation.present
            ? recipientRelation.value
            : this.recipientRelation,
    deliveryNotes:
        deliveryNotes.present ? deliveryNotes.value : this.deliveryNotes,
    collectedAmount: collectedAmount ?? this.collectedAmount,
    paymentMethod:
        paymentMethod.present ? paymentMethod.value : this.paymentMethod,
    checkNumber: checkNumber.present ? checkNumber.value : this.checkNumber,
    issueType: issueType.present ? issueType.value : this.issueType,
    issueDescription:
        issueDescription.present
            ? issueDescription.value
            : this.issueDescription,
    resolution: resolution.present ? resolution.value : this.resolution,
    priority: priority ?? this.priority,
    attemptCount: attemptCount ?? this.attemptCount,
    nextAttemptDate:
        nextAttemptDate.present ? nextAttemptDate.value : this.nextAttemptDate,
    isDeleted: isDeleted ?? this.isDeleted,
    syncStatus: syncStatus ?? this.syncStatus,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Delivery copyWithCompanion(DeliveriesCompanion data) {
    return Delivery(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      deliveryPersonnelId:
          data.deliveryPersonnelId.present
              ? data.deliveryPersonnelId.value
              : this.deliveryPersonnelId,
      deliveryPersonnelName:
          data.deliveryPersonnelName.present
              ? data.deliveryPersonnelName.value
              : this.deliveryPersonnelName,
      deliveryPersonnelPhone:
          data.deliveryPersonnelPhone.present
              ? data.deliveryPersonnelPhone.value
              : this.deliveryPersonnelPhone,
      deliveryNumber:
          data.deliveryNumber.present
              ? data.deliveryNumber.value
              : this.deliveryNumber,
      scheduledDate:
          data.scheduledDate.present
              ? data.scheduledDate.value
              : this.scheduledDate,
      actualStartTime:
          data.actualStartTime.present
              ? data.actualStartTime.value
              : this.actualStartTime,
      actualCompletionTime:
          data.actualCompletionTime.present
              ? data.actualCompletionTime.value
              : this.actualCompletionTime,
      status: data.status.present ? data.status.value : this.status,
      subStatus: data.subStatus.present ? data.subStatus.value : this.subStatus,
      route: data.route.present ? data.route.value : this.route,
      routeOrder:
          data.routeOrder.present ? data.routeOrder.value : this.routeOrder,
      vehicleNumber:
          data.vehicleNumber.present
              ? data.vehicleNumber.value
              : this.vehicleNumber,
      startLocation:
          data.startLocation.present
              ? data.startLocation.value
              : this.startLocation,
      endLocation:
          data.endLocation.present ? data.endLocation.value : this.endLocation,
      startLatitude:
          data.startLatitude.present
              ? data.startLatitude.value
              : this.startLatitude,
      startLongitude:
          data.startLongitude.present
              ? data.startLongitude.value
              : this.startLongitude,
      endLatitude:
          data.endLatitude.present ? data.endLatitude.value : this.endLatitude,
      endLongitude:
          data.endLongitude.present
              ? data.endLongitude.value
              : this.endLongitude,
      proofOfDeliveryType:
          data.proofOfDeliveryType.present
              ? data.proofOfDeliveryType.value
              : this.proofOfDeliveryType,
      proofOfDeliveryUrl:
          data.proofOfDeliveryUrl.present
              ? data.proofOfDeliveryUrl.value
              : this.proofOfDeliveryUrl,
      recipientName:
          data.recipientName.present
              ? data.recipientName.value
              : this.recipientName,
      recipientRelation:
          data.recipientRelation.present
              ? data.recipientRelation.value
              : this.recipientRelation,
      deliveryNotes:
          data.deliveryNotes.present
              ? data.deliveryNotes.value
              : this.deliveryNotes,
      collectedAmount:
          data.collectedAmount.present
              ? data.collectedAmount.value
              : this.collectedAmount,
      paymentMethod:
          data.paymentMethod.present
              ? data.paymentMethod.value
              : this.paymentMethod,
      checkNumber:
          data.checkNumber.present ? data.checkNumber.value : this.checkNumber,
      issueType: data.issueType.present ? data.issueType.value : this.issueType,
      issueDescription:
          data.issueDescription.present
              ? data.issueDescription.value
              : this.issueDescription,
      resolution:
          data.resolution.present ? data.resolution.value : this.resolution,
      priority: data.priority.present ? data.priority.value : this.priority,
      attemptCount:
          data.attemptCount.present
              ? data.attemptCount.value
              : this.attemptCount,
      nextAttemptDate:
          data.nextAttemptDate.present
              ? data.nextAttemptDate.value
              : this.nextAttemptDate,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Delivery(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('deliveryPersonnelId: $deliveryPersonnelId, ')
          ..write('deliveryPersonnelName: $deliveryPersonnelName, ')
          ..write('deliveryPersonnelPhone: $deliveryPersonnelPhone, ')
          ..write('deliveryNumber: $deliveryNumber, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('actualStartTime: $actualStartTime, ')
          ..write('actualCompletionTime: $actualCompletionTime, ')
          ..write('status: $status, ')
          ..write('subStatus: $subStatus, ')
          ..write('route: $route, ')
          ..write('routeOrder: $routeOrder, ')
          ..write('vehicleNumber: $vehicleNumber, ')
          ..write('startLocation: $startLocation, ')
          ..write('endLocation: $endLocation, ')
          ..write('startLatitude: $startLatitude, ')
          ..write('startLongitude: $startLongitude, ')
          ..write('endLatitude: $endLatitude, ')
          ..write('endLongitude: $endLongitude, ')
          ..write('proofOfDeliveryType: $proofOfDeliveryType, ')
          ..write('proofOfDeliveryUrl: $proofOfDeliveryUrl, ')
          ..write('recipientName: $recipientName, ')
          ..write('recipientRelation: $recipientRelation, ')
          ..write('deliveryNotes: $deliveryNotes, ')
          ..write('collectedAmount: $collectedAmount, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('checkNumber: $checkNumber, ')
          ..write('issueType: $issueType, ')
          ..write('issueDescription: $issueDescription, ')
          ..write('resolution: $resolution, ')
          ..write('priority: $priority, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextAttemptDate: $nextAttemptDate, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    orderId,
    deliveryPersonnelId,
    deliveryPersonnelName,
    deliveryPersonnelPhone,
    deliveryNumber,
    scheduledDate,
    actualStartTime,
    actualCompletionTime,
    status,
    subStatus,
    route,
    routeOrder,
    vehicleNumber,
    startLocation,
    endLocation,
    startLatitude,
    startLongitude,
    endLatitude,
    endLongitude,
    proofOfDeliveryType,
    proofOfDeliveryUrl,
    recipientName,
    recipientRelation,
    deliveryNotes,
    collectedAmount,
    paymentMethod,
    checkNumber,
    issueType,
    issueDescription,
    resolution,
    priority,
    attemptCount,
    nextAttemptDate,
    isDeleted,
    syncStatus,
    remoteId,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Delivery &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.deliveryPersonnelId == this.deliveryPersonnelId &&
          other.deliveryPersonnelName == this.deliveryPersonnelName &&
          other.deliveryPersonnelPhone == this.deliveryPersonnelPhone &&
          other.deliveryNumber == this.deliveryNumber &&
          other.scheduledDate == this.scheduledDate &&
          other.actualStartTime == this.actualStartTime &&
          other.actualCompletionTime == this.actualCompletionTime &&
          other.status == this.status &&
          other.subStatus == this.subStatus &&
          other.route == this.route &&
          other.routeOrder == this.routeOrder &&
          other.vehicleNumber == this.vehicleNumber &&
          other.startLocation == this.startLocation &&
          other.endLocation == this.endLocation &&
          other.startLatitude == this.startLatitude &&
          other.startLongitude == this.startLongitude &&
          other.endLatitude == this.endLatitude &&
          other.endLongitude == this.endLongitude &&
          other.proofOfDeliveryType == this.proofOfDeliveryType &&
          other.proofOfDeliveryUrl == this.proofOfDeliveryUrl &&
          other.recipientName == this.recipientName &&
          other.recipientRelation == this.recipientRelation &&
          other.deliveryNotes == this.deliveryNotes &&
          other.collectedAmount == this.collectedAmount &&
          other.paymentMethod == this.paymentMethod &&
          other.checkNumber == this.checkNumber &&
          other.issueType == this.issueType &&
          other.issueDescription == this.issueDescription &&
          other.resolution == this.resolution &&
          other.priority == this.priority &&
          other.attemptCount == this.attemptCount &&
          other.nextAttemptDate == this.nextAttemptDate &&
          other.isDeleted == this.isDeleted &&
          other.syncStatus == this.syncStatus &&
          other.remoteId == this.remoteId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DeliveriesCompanion extends UpdateCompanion<Delivery> {
  final Value<String> id;
  final Value<String> orderId;
  final Value<String> deliveryPersonnelId;
  final Value<String> deliveryPersonnelName;
  final Value<String> deliveryPersonnelPhone;
  final Value<String> deliveryNumber;
  final Value<DateTime> scheduledDate;
  final Value<DateTime?> actualStartTime;
  final Value<DateTime?> actualCompletionTime;
  final Value<String> status;
  final Value<String?> subStatus;
  final Value<String> route;
  final Value<int> routeOrder;
  final Value<String?> vehicleNumber;
  final Value<String> startLocation;
  final Value<String> endLocation;
  final Value<double?> startLatitude;
  final Value<double?> startLongitude;
  final Value<double?> endLatitude;
  final Value<double?> endLongitude;
  final Value<String?> proofOfDeliveryType;
  final Value<String?> proofOfDeliveryUrl;
  final Value<String?> recipientName;
  final Value<String?> recipientRelation;
  final Value<String?> deliveryNotes;
  final Value<double> collectedAmount;
  final Value<String?> paymentMethod;
  final Value<String?> checkNumber;
  final Value<String?> issueType;
  final Value<String?> issueDescription;
  final Value<String?> resolution;
  final Value<String> priority;
  final Value<int> attemptCount;
  final Value<DateTime?> nextAttemptDate;
  final Value<bool> isDeleted;
  final Value<String> syncStatus;
  final Value<String?> remoteId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DeliveriesCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.deliveryPersonnelId = const Value.absent(),
    this.deliveryPersonnelName = const Value.absent(),
    this.deliveryPersonnelPhone = const Value.absent(),
    this.deliveryNumber = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.actualStartTime = const Value.absent(),
    this.actualCompletionTime = const Value.absent(),
    this.status = const Value.absent(),
    this.subStatus = const Value.absent(),
    this.route = const Value.absent(),
    this.routeOrder = const Value.absent(),
    this.vehicleNumber = const Value.absent(),
    this.startLocation = const Value.absent(),
    this.endLocation = const Value.absent(),
    this.startLatitude = const Value.absent(),
    this.startLongitude = const Value.absent(),
    this.endLatitude = const Value.absent(),
    this.endLongitude = const Value.absent(),
    this.proofOfDeliveryType = const Value.absent(),
    this.proofOfDeliveryUrl = const Value.absent(),
    this.recipientName = const Value.absent(),
    this.recipientRelation = const Value.absent(),
    this.deliveryNotes = const Value.absent(),
    this.collectedAmount = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.checkNumber = const Value.absent(),
    this.issueType = const Value.absent(),
    this.issueDescription = const Value.absent(),
    this.resolution = const Value.absent(),
    this.priority = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.nextAttemptDate = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeliveriesCompanion.insert({
    required String id,
    required String orderId,
    required String deliveryPersonnelId,
    required String deliveryPersonnelName,
    required String deliveryPersonnelPhone,
    required String deliveryNumber,
    required DateTime scheduledDate,
    this.actualStartTime = const Value.absent(),
    this.actualCompletionTime = const Value.absent(),
    this.status = const Value.absent(),
    this.subStatus = const Value.absent(),
    required String route,
    required int routeOrder,
    this.vehicleNumber = const Value.absent(),
    required String startLocation,
    required String endLocation,
    this.startLatitude = const Value.absent(),
    this.startLongitude = const Value.absent(),
    this.endLatitude = const Value.absent(),
    this.endLongitude = const Value.absent(),
    this.proofOfDeliveryType = const Value.absent(),
    this.proofOfDeliveryUrl = const Value.absent(),
    this.recipientName = const Value.absent(),
    this.recipientRelation = const Value.absent(),
    this.deliveryNotes = const Value.absent(),
    this.collectedAmount = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.checkNumber = const Value.absent(),
    this.issueType = const Value.absent(),
    this.issueDescription = const Value.absent(),
    this.resolution = const Value.absent(),
    this.priority = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.nextAttemptDate = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       orderId = Value(orderId),
       deliveryPersonnelId = Value(deliveryPersonnelId),
       deliveryPersonnelName = Value(deliveryPersonnelName),
       deliveryPersonnelPhone = Value(deliveryPersonnelPhone),
       deliveryNumber = Value(deliveryNumber),
       scheduledDate = Value(scheduledDate),
       route = Value(route),
       routeOrder = Value(routeOrder),
       startLocation = Value(startLocation),
       endLocation = Value(endLocation);
  static Insertable<Delivery> custom({
    Expression<String>? id,
    Expression<String>? orderId,
    Expression<String>? deliveryPersonnelId,
    Expression<String>? deliveryPersonnelName,
    Expression<String>? deliveryPersonnelPhone,
    Expression<String>? deliveryNumber,
    Expression<DateTime>? scheduledDate,
    Expression<DateTime>? actualStartTime,
    Expression<DateTime>? actualCompletionTime,
    Expression<String>? status,
    Expression<String>? subStatus,
    Expression<String>? route,
    Expression<int>? routeOrder,
    Expression<String>? vehicleNumber,
    Expression<String>? startLocation,
    Expression<String>? endLocation,
    Expression<double>? startLatitude,
    Expression<double>? startLongitude,
    Expression<double>? endLatitude,
    Expression<double>? endLongitude,
    Expression<String>? proofOfDeliveryType,
    Expression<String>? proofOfDeliveryUrl,
    Expression<String>? recipientName,
    Expression<String>? recipientRelation,
    Expression<String>? deliveryNotes,
    Expression<double>? collectedAmount,
    Expression<String>? paymentMethod,
    Expression<String>? checkNumber,
    Expression<String>? issueType,
    Expression<String>? issueDescription,
    Expression<String>? resolution,
    Expression<String>? priority,
    Expression<int>? attemptCount,
    Expression<DateTime>? nextAttemptDate,
    Expression<bool>? isDeleted,
    Expression<String>? syncStatus,
    Expression<String>? remoteId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (deliveryPersonnelId != null)
        'delivery_personnel_id': deliveryPersonnelId,
      if (deliveryPersonnelName != null)
        'delivery_personnel_name': deliveryPersonnelName,
      if (deliveryPersonnelPhone != null)
        'delivery_personnel_phone': deliveryPersonnelPhone,
      if (deliveryNumber != null) 'delivery_number': deliveryNumber,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (actualStartTime != null) 'actual_start_time': actualStartTime,
      if (actualCompletionTime != null)
        'actual_completion_time': actualCompletionTime,
      if (status != null) 'status': status,
      if (subStatus != null) 'sub_status': subStatus,
      if (route != null) 'route': route,
      if (routeOrder != null) 'route_order': routeOrder,
      if (vehicleNumber != null) 'vehicle_number': vehicleNumber,
      if (startLocation != null) 'start_location': startLocation,
      if (endLocation != null) 'end_location': endLocation,
      if (startLatitude != null) 'start_latitude': startLatitude,
      if (startLongitude != null) 'start_longitude': startLongitude,
      if (endLatitude != null) 'end_latitude': endLatitude,
      if (endLongitude != null) 'end_longitude': endLongitude,
      if (proofOfDeliveryType != null)
        'proof_of_delivery_type': proofOfDeliveryType,
      if (proofOfDeliveryUrl != null)
        'proof_of_delivery_url': proofOfDeliveryUrl,
      if (recipientName != null) 'recipient_name': recipientName,
      if (recipientRelation != null) 'recipient_relation': recipientRelation,
      if (deliveryNotes != null) 'delivery_notes': deliveryNotes,
      if (collectedAmount != null) 'collected_amount': collectedAmount,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (checkNumber != null) 'check_number': checkNumber,
      if (issueType != null) 'issue_type': issueType,
      if (issueDescription != null) 'issue_description': issueDescription,
      if (resolution != null) 'resolution': resolution,
      if (priority != null) 'priority': priority,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (nextAttemptDate != null) 'next_attempt_date': nextAttemptDate,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (remoteId != null) 'remote_id': remoteId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeliveriesCompanion copyWith({
    Value<String>? id,
    Value<String>? orderId,
    Value<String>? deliveryPersonnelId,
    Value<String>? deliveryPersonnelName,
    Value<String>? deliveryPersonnelPhone,
    Value<String>? deliveryNumber,
    Value<DateTime>? scheduledDate,
    Value<DateTime?>? actualStartTime,
    Value<DateTime?>? actualCompletionTime,
    Value<String>? status,
    Value<String?>? subStatus,
    Value<String>? route,
    Value<int>? routeOrder,
    Value<String?>? vehicleNumber,
    Value<String>? startLocation,
    Value<String>? endLocation,
    Value<double?>? startLatitude,
    Value<double?>? startLongitude,
    Value<double?>? endLatitude,
    Value<double?>? endLongitude,
    Value<String?>? proofOfDeliveryType,
    Value<String?>? proofOfDeliveryUrl,
    Value<String?>? recipientName,
    Value<String?>? recipientRelation,
    Value<String?>? deliveryNotes,
    Value<double>? collectedAmount,
    Value<String?>? paymentMethod,
    Value<String?>? checkNumber,
    Value<String?>? issueType,
    Value<String?>? issueDescription,
    Value<String?>? resolution,
    Value<String>? priority,
    Value<int>? attemptCount,
    Value<DateTime?>? nextAttemptDate,
    Value<bool>? isDeleted,
    Value<String>? syncStatus,
    Value<String?>? remoteId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DeliveriesCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      deliveryPersonnelId: deliveryPersonnelId ?? this.deliveryPersonnelId,
      deliveryPersonnelName:
          deliveryPersonnelName ?? this.deliveryPersonnelName,
      deliveryPersonnelPhone:
          deliveryPersonnelPhone ?? this.deliveryPersonnelPhone,
      deliveryNumber: deliveryNumber ?? this.deliveryNumber,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualCompletionTime: actualCompletionTime ?? this.actualCompletionTime,
      status: status ?? this.status,
      subStatus: subStatus ?? this.subStatus,
      route: route ?? this.route,
      routeOrder: routeOrder ?? this.routeOrder,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      startLatitude: startLatitude ?? this.startLatitude,
      startLongitude: startLongitude ?? this.startLongitude,
      endLatitude: endLatitude ?? this.endLatitude,
      endLongitude: endLongitude ?? this.endLongitude,
      proofOfDeliveryType: proofOfDeliveryType ?? this.proofOfDeliveryType,
      proofOfDeliveryUrl: proofOfDeliveryUrl ?? this.proofOfDeliveryUrl,
      recipientName: recipientName ?? this.recipientName,
      recipientRelation: recipientRelation ?? this.recipientRelation,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      collectedAmount: collectedAmount ?? this.collectedAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      checkNumber: checkNumber ?? this.checkNumber,
      issueType: issueType ?? this.issueType,
      issueDescription: issueDescription ?? this.issueDescription,
      resolution: resolution ?? this.resolution,
      priority: priority ?? this.priority,
      attemptCount: attemptCount ?? this.attemptCount,
      nextAttemptDate: nextAttemptDate ?? this.nextAttemptDate,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteId: remoteId ?? this.remoteId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (deliveryPersonnelId.present) {
      map['delivery_personnel_id'] = Variable<String>(
        deliveryPersonnelId.value,
      );
    }
    if (deliveryPersonnelName.present) {
      map['delivery_personnel_name'] = Variable<String>(
        deliveryPersonnelName.value,
      );
    }
    if (deliveryPersonnelPhone.present) {
      map['delivery_personnel_phone'] = Variable<String>(
        deliveryPersonnelPhone.value,
      );
    }
    if (deliveryNumber.present) {
      map['delivery_number'] = Variable<String>(deliveryNumber.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate.value);
    }
    if (actualStartTime.present) {
      map['actual_start_time'] = Variable<DateTime>(actualStartTime.value);
    }
    if (actualCompletionTime.present) {
      map['actual_completion_time'] = Variable<DateTime>(
        actualCompletionTime.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (subStatus.present) {
      map['sub_status'] = Variable<String>(subStatus.value);
    }
    if (route.present) {
      map['route'] = Variable<String>(route.value);
    }
    if (routeOrder.present) {
      map['route_order'] = Variable<int>(routeOrder.value);
    }
    if (vehicleNumber.present) {
      map['vehicle_number'] = Variable<String>(vehicleNumber.value);
    }
    if (startLocation.present) {
      map['start_location'] = Variable<String>(startLocation.value);
    }
    if (endLocation.present) {
      map['end_location'] = Variable<String>(endLocation.value);
    }
    if (startLatitude.present) {
      map['start_latitude'] = Variable<double>(startLatitude.value);
    }
    if (startLongitude.present) {
      map['start_longitude'] = Variable<double>(startLongitude.value);
    }
    if (endLatitude.present) {
      map['end_latitude'] = Variable<double>(endLatitude.value);
    }
    if (endLongitude.present) {
      map['end_longitude'] = Variable<double>(endLongitude.value);
    }
    if (proofOfDeliveryType.present) {
      map['proof_of_delivery_type'] = Variable<String>(
        proofOfDeliveryType.value,
      );
    }
    if (proofOfDeliveryUrl.present) {
      map['proof_of_delivery_url'] = Variable<String>(proofOfDeliveryUrl.value);
    }
    if (recipientName.present) {
      map['recipient_name'] = Variable<String>(recipientName.value);
    }
    if (recipientRelation.present) {
      map['recipient_relation'] = Variable<String>(recipientRelation.value);
    }
    if (deliveryNotes.present) {
      map['delivery_notes'] = Variable<String>(deliveryNotes.value);
    }
    if (collectedAmount.present) {
      map['collected_amount'] = Variable<double>(collectedAmount.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (checkNumber.present) {
      map['check_number'] = Variable<String>(checkNumber.value);
    }
    if (issueType.present) {
      map['issue_type'] = Variable<String>(issueType.value);
    }
    if (issueDescription.present) {
      map['issue_description'] = Variable<String>(issueDescription.value);
    }
    if (resolution.present) {
      map['resolution'] = Variable<String>(resolution.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (nextAttemptDate.present) {
      map['next_attempt_date'] = Variable<DateTime>(nextAttemptDate.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeliveriesCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('deliveryPersonnelId: $deliveryPersonnelId, ')
          ..write('deliveryPersonnelName: $deliveryPersonnelName, ')
          ..write('deliveryPersonnelPhone: $deliveryPersonnelPhone, ')
          ..write('deliveryNumber: $deliveryNumber, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('actualStartTime: $actualStartTime, ')
          ..write('actualCompletionTime: $actualCompletionTime, ')
          ..write('status: $status, ')
          ..write('subStatus: $subStatus, ')
          ..write('route: $route, ')
          ..write('routeOrder: $routeOrder, ')
          ..write('vehicleNumber: $vehicleNumber, ')
          ..write('startLocation: $startLocation, ')
          ..write('endLocation: $endLocation, ')
          ..write('startLatitude: $startLatitude, ')
          ..write('startLongitude: $startLongitude, ')
          ..write('endLatitude: $endLatitude, ')
          ..write('endLongitude: $endLongitude, ')
          ..write('proofOfDeliveryType: $proofOfDeliveryType, ')
          ..write('proofOfDeliveryUrl: $proofOfDeliveryUrl, ')
          ..write('recipientName: $recipientName, ')
          ..write('recipientRelation: $recipientRelation, ')
          ..write('deliveryNotes: $deliveryNotes, ')
          ..write('collectedAmount: $collectedAmount, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('checkNumber: $checkNumber, ')
          ..write('issueType: $issueType, ')
          ..write('issueDescription: $issueDescription, ')
          ..write('resolution: $resolution, ')
          ..write('priority: $priority, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextAttemptDate: $nextAttemptDate, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $CustomersTable customers = $CustomersTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $StockMovementsTable stockMovements = $StockMovementsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $OrdersTable orders = $OrdersTable(this);
  late final $OrderItemsTable orderItems = $OrderItemsTable(this);
  late final $DeliveriesTable deliveries = $DeliveriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    customers,
    products,
    stockMovements,
    categories,
    orders,
    orderItems,
    deliveries,
  ];
}

typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      required String name,
      required String email,
      required String passwordHash,
      required String role,
      Value<String?> phone,
      Value<String?> address,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> isDeleted,
      Value<String> syncStatus,
      Value<String?> remoteId,
      required String uuid,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> email,
      Value<String> passwordHash,
      Value<String> role,
      Value<String?> phone,
      Value<String?> address,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> isDeleted,
      Value<String> syncStatus,
      Value<String?> remoteId,
      Value<String> uuid,
    });

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
          User,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> passwordHash = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> uuid = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                name: name,
                email: email,
                passwordHash: passwordHash,
                role: role,
                phone: phone,
                address: address,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                syncStatus: syncStatus,
                remoteId: remoteId,
                uuid: uuid,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String email,
                required String passwordHash,
                required String role,
                Value<String?> phone = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                required String uuid,
              }) => UsersCompanion.insert(
                id: id,
                name: name,
                email: email,
                passwordHash: passwordHash,
                role: role,
                phone: phone,
                address: address,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                syncStatus: syncStatus,
                remoteId: remoteId,
                uuid: uuid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
      User,
      PrefetchHooks Function()
    >;
typedef $$CustomersTableCreateCompanionBuilder =
    CustomersCompanion Function({
      Value<int> id,
      required String uuid,
      required String name,
      required String email,
      Value<String?> phone,
      Value<String?> address,
      Value<String?> businessName,
      Value<String?> taxId,
      Value<String> customerType,
      Value<double?> creditLimit,
      Value<String?> paymentTerms,
      Value<String> status,
      Value<String> preferredContactMethod,
      Value<bool> isDeleted,
      Value<String?> remoteId,
      Value<String> syncStatus,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$CustomersTableUpdateCompanionBuilder =
    CustomersCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> name,
      Value<String> email,
      Value<String?> phone,
      Value<String?> address,
      Value<String?> businessName,
      Value<String?> taxId,
      Value<String> customerType,
      Value<double?> creditLimit,
      Value<String?> paymentTerms,
      Value<String> status,
      Value<String> preferredContactMethod,
      Value<bool> isDeleted,
      Value<String?> remoteId,
      Value<String> syncStatus,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$CustomersTableFilterComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableFilterComposer({
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

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxId => $composableBuilder(
    column: $table.taxId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerType => $composableBuilder(
    column: $table.customerType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentTerms => $composableBuilder(
    column: $table.paymentTerms,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredContactMethod => $composableBuilder(
    column: $table.preferredContactMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomersTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableOrderingComposer({
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

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxId => $composableBuilder(
    column: $table.taxId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerType => $composableBuilder(
    column: $table.customerType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentTerms => $composableBuilder(
    column: $table.paymentTerms,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredContactMethod => $composableBuilder(
    column: $table.preferredContactMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taxId =>
      $composableBuilder(column: $table.taxId, builder: (column) => column);

  GeneratedColumn<String> get customerType => $composableBuilder(
    column: $table.customerType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentTerms => $composableBuilder(
    column: $table.paymentTerms,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get preferredContactMethod => $composableBuilder(
    column: $table.preferredContactMethod,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CustomersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomersTable,
          Customer,
          $$CustomersTableFilterComposer,
          $$CustomersTableOrderingComposer,
          $$CustomersTableAnnotationComposer,
          $$CustomersTableCreateCompanionBuilder,
          $$CustomersTableUpdateCompanionBuilder,
          (Customer, BaseReferences<_$AppDatabase, $CustomersTable, Customer>),
          Customer,
          PrefetchHooks Function()
        > {
  $$CustomersTableTableManager(_$AppDatabase db, $CustomersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$CustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$CustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$CustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> businessName = const Value.absent(),
                Value<String?> taxId = const Value.absent(),
                Value<String> customerType = const Value.absent(),
                Value<double?> creditLimit = const Value.absent(),
                Value<String?> paymentTerms = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> preferredContactMethod = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CustomersCompanion(
                id: id,
                uuid: uuid,
                name: name,
                email: email,
                phone: phone,
                address: address,
                businessName: businessName,
                taxId: taxId,
                customerType: customerType,
                creditLimit: creditLimit,
                paymentTerms: paymentTerms,
                status: status,
                preferredContactMethod: preferredContactMethod,
                isDeleted: isDeleted,
                remoteId: remoteId,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String name,
                required String email,
                Value<String?> phone = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> businessName = const Value.absent(),
                Value<String?> taxId = const Value.absent(),
                Value<String> customerType = const Value.absent(),
                Value<double?> creditLimit = const Value.absent(),
                Value<String?> paymentTerms = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> preferredContactMethod = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CustomersCompanion.insert(
                id: id,
                uuid: uuid,
                name: name,
                email: email,
                phone: phone,
                address: address,
                businessName: businessName,
                taxId: taxId,
                customerType: customerType,
                creditLimit: creditLimit,
                paymentTerms: paymentTerms,
                status: status,
                preferredContactMethod: preferredContactMethod,
                isDeleted: isDeleted,
                remoteId: remoteId,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomersTable,
      Customer,
      $$CustomersTableFilterComposer,
      $$CustomersTableOrderingComposer,
      $$CustomersTableAnnotationComposer,
      $$CustomersTableCreateCompanionBuilder,
      $$CustomersTableUpdateCompanionBuilder,
      (Customer, BaseReferences<_$AppDatabase, $CustomersTable, Customer>),
      Customer,
      PrefetchHooks Function()
    >;
typedef $$ProductsTableCreateCompanionBuilder =
    ProductsCompanion Function({
      Value<int> id,
      required String uuid,
      required String sku,
      required String name,
      Value<String?> description,
      required String category,
      Value<String?> brand,
      Value<int> currentStock,
      Value<int> minStock,
      Value<int?> maxStock,
      required String unit,
      Value<double?> weight,
      Value<String?> dimensions,
      required double unitPrice,
      required double costPrice,
      Value<double?> wholesalePrice,
      Value<String> currency,
      Value<String?> supplier,
      Value<String?> supplierSku,
      Value<int?> leadTimeDays,
      Value<String> status,
      Value<String?> location,
      Value<String?> barcode,
      Value<String?> tags,
      Value<bool> isDeleted,
      Value<String> syncStatus,
      Value<String?> remoteId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$ProductsTableUpdateCompanionBuilder =
    ProductsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> sku,
      Value<String> name,
      Value<String?> description,
      Value<String> category,
      Value<String?> brand,
      Value<int> currentStock,
      Value<int> minStock,
      Value<int?> maxStock,
      Value<String> unit,
      Value<double?> weight,
      Value<String?> dimensions,
      Value<double> unitPrice,
      Value<double> costPrice,
      Value<double?> wholesalePrice,
      Value<String> currency,
      Value<String?> supplier,
      Value<String?> supplierSku,
      Value<int?> leadTimeDays,
      Value<String> status,
      Value<String?> location,
      Value<String?> barcode,
      Value<String?> tags,
      Value<bool> isDeleted,
      Value<String> syncStatus,
      Value<String?> remoteId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
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

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentStock => $composableBuilder(
    column: $table.currentStock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minStock => $composableBuilder(
    column: $table.minStock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxStock => $composableBuilder(
    column: $table.maxStock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dimensions => $composableBuilder(
    column: $table.dimensions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get wholesalePrice => $composableBuilder(
    column: $table.wholesalePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supplier => $composableBuilder(
    column: $table.supplier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supplierSku => $composableBuilder(
    column: $table.supplierSku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get leadTimeDays => $composableBuilder(
    column: $table.leadTimeDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
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

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentStock => $composableBuilder(
    column: $table.currentStock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minStock => $composableBuilder(
    column: $table.minStock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxStock => $composableBuilder(
    column: $table.maxStock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dimensions => $composableBuilder(
    column: $table.dimensions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get wholesalePrice => $composableBuilder(
    column: $table.wholesalePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supplier => $composableBuilder(
    column: $table.supplier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supplierSku => $composableBuilder(
    column: $table.supplierSku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get leadTimeDays => $composableBuilder(
    column: $table.leadTimeDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<int> get currentStock => $composableBuilder(
    column: $table.currentStock,
    builder: (column) => column,
  );

  GeneratedColumn<int> get minStock =>
      $composableBuilder(column: $table.minStock, builder: (column) => column);

  GeneratedColumn<int> get maxStock =>
      $composableBuilder(column: $table.maxStock, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<String> get dimensions => $composableBuilder(
    column: $table.dimensions,
    builder: (column) => column,
  );

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<double> get costPrice =>
      $composableBuilder(column: $table.costPrice, builder: (column) => column);

  GeneratedColumn<double> get wholesalePrice => $composableBuilder(
    column: $table.wholesalePrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get supplier =>
      $composableBuilder(column: $table.supplier, builder: (column) => column);

  GeneratedColumn<String> get supplierSku => $composableBuilder(
    column: $table.supplierSku,
    builder: (column) => column,
  );

  GeneratedColumn<int> get leadTimeDays => $composableBuilder(
    column: $table.leadTimeDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          Product,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
          Product,
          PrefetchHooks Function()
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> sku = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<int> currentStock = const Value.absent(),
                Value<int> minStock = const Value.absent(),
                Value<int?> maxStock = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<double?> weight = const Value.absent(),
                Value<String?> dimensions = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<double> costPrice = const Value.absent(),
                Value<double?> wholesalePrice = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String?> supplier = const Value.absent(),
                Value<String?> supplierSku = const Value.absent(),
                Value<int?> leadTimeDays = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                uuid: uuid,
                sku: sku,
                name: name,
                description: description,
                category: category,
                brand: brand,
                currentStock: currentStock,
                minStock: minStock,
                maxStock: maxStock,
                unit: unit,
                weight: weight,
                dimensions: dimensions,
                unitPrice: unitPrice,
                costPrice: costPrice,
                wholesalePrice: wholesalePrice,
                currency: currency,
                supplier: supplier,
                supplierSku: supplierSku,
                leadTimeDays: leadTimeDays,
                status: status,
                location: location,
                barcode: barcode,
                tags: tags,
                isDeleted: isDeleted,
                syncStatus: syncStatus,
                remoteId: remoteId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String sku,
                required String name,
                Value<String?> description = const Value.absent(),
                required String category,
                Value<String?> brand = const Value.absent(),
                Value<int> currentStock = const Value.absent(),
                Value<int> minStock = const Value.absent(),
                Value<int?> maxStock = const Value.absent(),
                required String unit,
                Value<double?> weight = const Value.absent(),
                Value<String?> dimensions = const Value.absent(),
                required double unitPrice,
                required double costPrice,
                Value<double?> wholesalePrice = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String?> supplier = const Value.absent(),
                Value<String?> supplierSku = const Value.absent(),
                Value<int?> leadTimeDays = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                uuid: uuid,
                sku: sku,
                name: name,
                description: description,
                category: category,
                brand: brand,
                currentStock: currentStock,
                minStock: minStock,
                maxStock: maxStock,
                unit: unit,
                weight: weight,
                dimensions: dimensions,
                unitPrice: unitPrice,
                costPrice: costPrice,
                wholesalePrice: wholesalePrice,
                currency: currency,
                supplier: supplier,
                supplierSku: supplierSku,
                leadTimeDays: leadTimeDays,
                status: status,
                location: location,
                barcode: barcode,
                tags: tags,
                isDeleted: isDeleted,
                syncStatus: syncStatus,
                remoteId: remoteId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      Product,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
      Product,
      PrefetchHooks Function()
    >;
typedef $$StockMovementsTableCreateCompanionBuilder =
    StockMovementsCompanion Function({
      required String id,
      required String productId,
      required String movementType,
      required int quantity,
      Value<String?> referenceType,
      Value<String?> referenceId,
      required String reason,
      Value<String?> notes,
      required String userId,
      required String userName,
      Value<String?> fromLocation,
      Value<String?> toLocation,
      Value<double?> unitCost,
      Value<double?> totalCost,
      Value<String> status,
      Value<String?> approvedBy,
      Value<DateTime?> approvedAt,
      Value<bool> isDeleted,
      Value<String> syncStatus,
      Value<String?> remoteId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$StockMovementsTableUpdateCompanionBuilder =
    StockMovementsCompanion Function({
      Value<String> id,
      Value<String> productId,
      Value<String> movementType,
      Value<int> quantity,
      Value<String?> referenceType,
      Value<String?> referenceId,
      Value<String> reason,
      Value<String?> notes,
      Value<String> userId,
      Value<String> userName,
      Value<String?> fromLocation,
      Value<String?> toLocation,
      Value<double?> unitCost,
      Value<double?> totalCost,
      Value<String> status,
      Value<String?> approvedBy,
      Value<DateTime?> approvedAt,
      Value<bool> isDeleted,
      Value<String> syncStatus,
      Value<String?> remoteId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$StockMovementsTableFilterComposer
    extends Composer<_$AppDatabase, $StockMovementsTable> {
  $$StockMovementsTableFilterComposer({
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

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromLocation => $composableBuilder(
    column: $table.fromLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toLocation => $composableBuilder(
    column: $table.toLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitCost => $composableBuilder(
    column: $table.unitCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalCost => $composableBuilder(
    column: $table.totalCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get approvedAt => $composableBuilder(
    column: $table.approvedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StockMovementsTableOrderingComposer
    extends Composer<_$AppDatabase, $StockMovementsTable> {
  $$StockMovementsTableOrderingComposer({
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

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromLocation => $composableBuilder(
    column: $table.fromLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toLocation => $composableBuilder(
    column: $table.toLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitCost => $composableBuilder(
    column: $table.unitCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalCost => $composableBuilder(
    column: $table.totalCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get approvedAt => $composableBuilder(
    column: $table.approvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StockMovementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockMovementsTable> {
  $$StockMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get userName =>
      $composableBuilder(column: $table.userName, builder: (column) => column);

  GeneratedColumn<String> get fromLocation => $composableBuilder(
    column: $table.fromLocation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toLocation => $composableBuilder(
    column: $table.toLocation,
    builder: (column) => column,
  );

  GeneratedColumn<double> get unitCost =>
      $composableBuilder(column: $table.unitCost, builder: (column) => column);

  GeneratedColumn<double> get totalCost =>
      $composableBuilder(column: $table.totalCost, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get approvedAt => $composableBuilder(
    column: $table.approvedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StockMovementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StockMovementsTable,
          StockMovement,
          $$StockMovementsTableFilterComposer,
          $$StockMovementsTableOrderingComposer,
          $$StockMovementsTableAnnotationComposer,
          $$StockMovementsTableCreateCompanionBuilder,
          $$StockMovementsTableUpdateCompanionBuilder,
          (
            StockMovement,
            BaseReferences<_$AppDatabase, $StockMovementsTable, StockMovement>,
          ),
          StockMovement,
          PrefetchHooks Function()
        > {
  $$StockMovementsTableTableManager(
    _$AppDatabase db,
    $StockMovementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$StockMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$StockMovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$StockMovementsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> movementType = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<String?> referenceType = const Value.absent(),
                Value<String?> referenceId = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> userName = const Value.absent(),
                Value<String?> fromLocation = const Value.absent(),
                Value<String?> toLocation = const Value.absent(),
                Value<double?> unitCost = const Value.absent(),
                Value<double?> totalCost = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> approvedBy = const Value.absent(),
                Value<DateTime?> approvedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockMovementsCompanion(
                id: id,
                productId: productId,
                movementType: movementType,
                quantity: quantity,
                referenceType: referenceType,
                referenceId: referenceId,
                reason: reason,
                notes: notes,
                userId: userId,
                userName: userName,
                fromLocation: fromLocation,
                toLocation: toLocation,
                unitCost: unitCost,
                totalCost: totalCost,
                status: status,
                approvedBy: approvedBy,
                approvedAt: approvedAt,
                isDeleted: isDeleted,
                syncStatus: syncStatus,
                remoteId: remoteId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String productId,
                required String movementType,
                required int quantity,
                Value<String?> referenceType = const Value.absent(),
                Value<String?> referenceId = const Value.absent(),
                required String reason,
                Value<String?> notes = const Value.absent(),
                required String userId,
                required String userName,
                Value<String?> fromLocation = const Value.absent(),
                Value<String?> toLocation = const Value.absent(),
                Value<double?> unitCost = const Value.absent(),
                Value<double?> totalCost = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> approvedBy = const Value.absent(),
                Value<DateTime?> approvedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockMovementsCompanion.insert(
                id: id,
                productId: productId,
                movementType: movementType,
                quantity: quantity,
                referenceType: referenceType,
                referenceId: referenceId,
                reason: reason,
                notes: notes,
                userId: userId,
                userName: userName,
                fromLocation: fromLocation,
                toLocation: toLocation,
                unitCost: unitCost,
                totalCost: totalCost,
                status: status,
                approvedBy: approvedBy,
                approvedAt: approvedAt,
                isDeleted: isDeleted,
                syncStatus: syncStatus,
                remoteId: remoteId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StockMovementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StockMovementsTable,
      StockMovement,
      $$StockMovementsTableFilterComposer,
      $$StockMovementsTableOrderingComposer,
      $$StockMovementsTableAnnotationComposer,
      $$StockMovementsTableCreateCompanionBuilder,
      $$StockMovementsTableUpdateCompanionBuilder,
      (
        StockMovement,
        BaseReferences<_$AppDatabase, $StockMovementsTable, StockMovement>,
      ),
      StockMovement,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      Value<int?> remoteId,
      required String name,
      Value<String?> description,
      Value<String> syncStatus,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      Value<int?> remoteId,
      Value<String> name,
      Value<String?> description,
      Value<String> syncStatus,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
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

  ColumnFilters<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
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

  ColumnOrderings<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
          Category,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> remoteId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                remoteId: remoteId,
                name: name,
                description: description,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> remoteId = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                remoteId: remoteId,
                name: name,
                description: description,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
      Category,
      PrefetchHooks Function()
    >;
typedef $$OrdersTableCreateCompanionBuilder =
    OrdersCompanion Function({
      required String id,
      required String customerId,
      Value<String?> salesRepId,
      Value<DateTime> orderDate,
      Value<String> status,
      required String orderNumber,
      Value<double> subtotal,
      Value<double> taxAmount,
      Value<double> discountAmount,
      Value<double> totalAmount,
      Value<String> paymentStatus,
      required String deliveryAddress,
      Value<String?> deliveryContact,
      Value<String?> deliveryPhone,
      Value<DateTime?> requestedDeliveryDate,
      Value<DateTime?> actualDeliveryDate,
      Value<String> warehouseStatus,
      Value<String?> pickerId,
      Value<DateTime?> pickedAt,
      Value<String?> packerId,
      Value<DateTime?> packedAt,
      Value<String?> customerNotes,
      Value<String?> internalNotes,
      Value<String> priority,
      Value<bool> isDeleted,
      Value<String> syncStatus,
      Value<String?> remoteId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$OrdersTableUpdateCompanionBuilder =
    OrdersCompanion Function({
      Value<String> id,
      Value<String> customerId,
      Value<String?> salesRepId,
      Value<DateTime> orderDate,
      Value<String> status,
      Value<String> orderNumber,
      Value<double> subtotal,
      Value<double> taxAmount,
      Value<double> discountAmount,
      Value<double> totalAmount,
      Value<String> paymentStatus,
      Value<String> deliveryAddress,
      Value<String?> deliveryContact,
      Value<String?> deliveryPhone,
      Value<DateTime?> requestedDeliveryDate,
      Value<DateTime?> actualDeliveryDate,
      Value<String> warehouseStatus,
      Value<String?> pickerId,
      Value<DateTime?> pickedAt,
      Value<String?> packerId,
      Value<DateTime?> packedAt,
      Value<String?> customerNotes,
      Value<String?> internalNotes,
      Value<String> priority,
      Value<bool> isDeleted,
      Value<String> syncStatus,
      Value<String?> remoteId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$OrdersTableFilterComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableFilterComposer({
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

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get salesRepId => $composableBuilder(
    column: $table.salesRepId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get orderDate => $composableBuilder(
    column: $table.orderDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderNumber => $composableBuilder(
    column: $table.orderNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get taxAmount => $composableBuilder(
    column: $table.taxAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryAddress => $composableBuilder(
    column: $table.deliveryAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryContact => $composableBuilder(
    column: $table.deliveryContact,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryPhone => $composableBuilder(
    column: $table.deliveryPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get requestedDeliveryDate => $composableBuilder(
    column: $table.requestedDeliveryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get actualDeliveryDate => $composableBuilder(
    column: $table.actualDeliveryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get warehouseStatus => $composableBuilder(
    column: $table.warehouseStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pickerId => $composableBuilder(
    column: $table.pickerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pickedAt => $composableBuilder(
    column: $table.pickedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packerId => $composableBuilder(
    column: $table.packerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get packedAt => $composableBuilder(
    column: $table.packedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerNotes => $composableBuilder(
    column: $table.customerNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get internalNotes => $composableBuilder(
    column: $table.internalNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableOrderingComposer({
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

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get salesRepId => $composableBuilder(
    column: $table.salesRepId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get orderDate => $composableBuilder(
    column: $table.orderDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderNumber => $composableBuilder(
    column: $table.orderNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get taxAmount => $composableBuilder(
    column: $table.taxAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryAddress => $composableBuilder(
    column: $table.deliveryAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryContact => $composableBuilder(
    column: $table.deliveryContact,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryPhone => $composableBuilder(
    column: $table.deliveryPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get requestedDeliveryDate => $composableBuilder(
    column: $table.requestedDeliveryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get actualDeliveryDate => $composableBuilder(
    column: $table.actualDeliveryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get warehouseStatus => $composableBuilder(
    column: $table.warehouseStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pickerId => $composableBuilder(
    column: $table.pickerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pickedAt => $composableBuilder(
    column: $table.pickedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packerId => $composableBuilder(
    column: $table.packerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get packedAt => $composableBuilder(
    column: $table.packedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerNotes => $composableBuilder(
    column: $table.customerNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get internalNotes => $composableBuilder(
    column: $table.internalNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get salesRepId => $composableBuilder(
    column: $table.salesRepId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get orderDate =>
      $composableBuilder(column: $table.orderDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get orderNumber => $composableBuilder(
    column: $table.orderNumber,
    builder: (column) => column,
  );

  GeneratedColumn<double> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<double> get taxAmount =>
      $composableBuilder(column: $table.taxAmount, builder: (column) => column);

  GeneratedColumn<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveryAddress => $composableBuilder(
    column: $table.deliveryAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveryContact => $composableBuilder(
    column: $table.deliveryContact,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveryPhone => $composableBuilder(
    column: $table.deliveryPhone,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get requestedDeliveryDate => $composableBuilder(
    column: $table.requestedDeliveryDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get actualDeliveryDate => $composableBuilder(
    column: $table.actualDeliveryDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get warehouseStatus => $composableBuilder(
    column: $table.warehouseStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pickerId =>
      $composableBuilder(column: $table.pickerId, builder: (column) => column);

  GeneratedColumn<DateTime> get pickedAt =>
      $composableBuilder(column: $table.pickedAt, builder: (column) => column);

  GeneratedColumn<String> get packerId =>
      $composableBuilder(column: $table.packerId, builder: (column) => column);

  GeneratedColumn<DateTime> get packedAt =>
      $composableBuilder(column: $table.packedAt, builder: (column) => column);

  GeneratedColumn<String> get customerNotes => $composableBuilder(
    column: $table.customerNotes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get internalNotes => $composableBuilder(
    column: $table.internalNotes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OrdersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrdersTable,
          Order,
          $$OrdersTableFilterComposer,
          $$OrdersTableOrderingComposer,
          $$OrdersTableAnnotationComposer,
          $$OrdersTableCreateCompanionBuilder,
          $$OrdersTableUpdateCompanionBuilder,
          (Order, BaseReferences<_$AppDatabase, $OrdersTable, Order>),
          Order,
          PrefetchHooks Function()
        > {
  $$OrdersTableTableManager(_$AppDatabase db, $OrdersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$OrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$OrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$OrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<String?> salesRepId = const Value.absent(),
                Value<DateTime> orderDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> orderNumber = const Value.absent(),
                Value<double> subtotal = const Value.absent(),
                Value<double> taxAmount = const Value.absent(),
                Value<double> discountAmount = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<String> paymentStatus = const Value.absent(),
                Value<String> deliveryAddress = const Value.absent(),
                Value<String?> deliveryContact = const Value.absent(),
                Value<String?> deliveryPhone = const Value.absent(),
                Value<DateTime?> requestedDeliveryDate = const Value.absent(),
                Value<DateTime?> actualDeliveryDate = const Value.absent(),
                Value<String> warehouseStatus = const Value.absent(),
                Value<String?> pickerId = const Value.absent(),
                Value<DateTime?> pickedAt = const Value.absent(),
                Value<String?> packerId = const Value.absent(),
                Value<DateTime?> packedAt = const Value.absent(),
                Value<String?> customerNotes = const Value.absent(),
                Value<String?> internalNotes = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdersCompanion(
                id: id,
                customerId: customerId,
                salesRepId: salesRepId,
                orderDate: orderDate,
                status: status,
                orderNumber: orderNumber,
                subtotal: subtotal,
                taxAmount: taxAmount,
                discountAmount: discountAmount,
                totalAmount: totalAmount,
                paymentStatus: paymentStatus,
                deliveryAddress: deliveryAddress,
                deliveryContact: deliveryContact,
                deliveryPhone: deliveryPhone,
                requestedDeliveryDate: requestedDeliveryDate,
                actualDeliveryDate: actualDeliveryDate,
                warehouseStatus: warehouseStatus,
                pickerId: pickerId,
                pickedAt: pickedAt,
                packerId: packerId,
                packedAt: packedAt,
                customerNotes: customerNotes,
                internalNotes: internalNotes,
                priority: priority,
                isDeleted: isDeleted,
                syncStatus: syncStatus,
                remoteId: remoteId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String customerId,
                Value<String?> salesRepId = const Value.absent(),
                Value<DateTime> orderDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                required String orderNumber,
                Value<double> subtotal = const Value.absent(),
                Value<double> taxAmount = const Value.absent(),
                Value<double> discountAmount = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<String> paymentStatus = const Value.absent(),
                required String deliveryAddress,
                Value<String?> deliveryContact = const Value.absent(),
                Value<String?> deliveryPhone = const Value.absent(),
                Value<DateTime?> requestedDeliveryDate = const Value.absent(),
                Value<DateTime?> actualDeliveryDate = const Value.absent(),
                Value<String> warehouseStatus = const Value.absent(),
                Value<String?> pickerId = const Value.absent(),
                Value<DateTime?> pickedAt = const Value.absent(),
                Value<String?> packerId = const Value.absent(),
                Value<DateTime?> packedAt = const Value.absent(),
                Value<String?> customerNotes = const Value.absent(),
                Value<String?> internalNotes = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdersCompanion.insert(
                id: id,
                customerId: customerId,
                salesRepId: salesRepId,
                orderDate: orderDate,
                status: status,
                orderNumber: orderNumber,
                subtotal: subtotal,
                taxAmount: taxAmount,
                discountAmount: discountAmount,
                totalAmount: totalAmount,
                paymentStatus: paymentStatus,
                deliveryAddress: deliveryAddress,
                deliveryContact: deliveryContact,
                deliveryPhone: deliveryPhone,
                requestedDeliveryDate: requestedDeliveryDate,
                actualDeliveryDate: actualDeliveryDate,
                warehouseStatus: warehouseStatus,
                pickerId: pickerId,
                pickedAt: pickedAt,
                packerId: packerId,
                packedAt: packedAt,
                customerNotes: customerNotes,
                internalNotes: internalNotes,
                priority: priority,
                isDeleted: isDeleted,
                syncStatus: syncStatus,
                remoteId: remoteId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrdersTable,
      Order,
      $$OrdersTableFilterComposer,
      $$OrdersTableOrderingComposer,
      $$OrdersTableAnnotationComposer,
      $$OrdersTableCreateCompanionBuilder,
      $$OrdersTableUpdateCompanionBuilder,
      (Order, BaseReferences<_$AppDatabase, $OrdersTable, Order>),
      Order,
      PrefetchHooks Function()
    >;
typedef $$OrderItemsTableCreateCompanionBuilder =
    OrderItemsCompanion Function({
      required String id,
      required String orderId,
      required String productId,
      required String productSku,
      required String productName,
      Value<String?> productCategory,
      required int quantity,
      Value<int> deliveredQuantity,
      required double unitPrice,
      required double subtotal,
      Value<double> discountAmount,
      required double totalAmount,
      required int availableStock,
      Value<String> stockStatus,
      Value<String> status,
      Value<String?> pickerId,
      Value<DateTime?> pickedAt,
      Value<String?> notes,
      Value<String?> cancellationReason,
      Value<bool> isDeleted,
      Value<String> syncStatus,
      Value<String?> remoteId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$OrderItemsTableUpdateCompanionBuilder =
    OrderItemsCompanion Function({
      Value<String> id,
      Value<String> orderId,
      Value<String> productId,
      Value<String> productSku,
      Value<String> productName,
      Value<String?> productCategory,
      Value<int> quantity,
      Value<int> deliveredQuantity,
      Value<double> unitPrice,
      Value<double> subtotal,
      Value<double> discountAmount,
      Value<double> totalAmount,
      Value<int> availableStock,
      Value<String> stockStatus,
      Value<String> status,
      Value<String?> pickerId,
      Value<DateTime?> pickedAt,
      Value<String?> notes,
      Value<String?> cancellationReason,
      Value<bool> isDeleted,
      Value<String> syncStatus,
      Value<String?> remoteId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$OrderItemsTableFilterComposer
    extends Composer<_$AppDatabase, $OrderItemsTable> {
  $$OrderItemsTableFilterComposer({
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

  ColumnFilters<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productSku => $composableBuilder(
    column: $table.productSku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productCategory => $composableBuilder(
    column: $table.productCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deliveredQuantity => $composableBuilder(
    column: $table.deliveredQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get availableStock => $composableBuilder(
    column: $table.availableStock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stockStatus => $composableBuilder(
    column: $table.stockStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pickerId => $composableBuilder(
    column: $table.pickerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pickedAt => $composableBuilder(
    column: $table.pickedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cancellationReason => $composableBuilder(
    column: $table.cancellationReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OrderItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $OrderItemsTable> {
  $$OrderItemsTableOrderingComposer({
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

  ColumnOrderings<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productSku => $composableBuilder(
    column: $table.productSku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productCategory => $composableBuilder(
    column: $table.productCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deliveredQuantity => $composableBuilder(
    column: $table.deliveredQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get availableStock => $composableBuilder(
    column: $table.availableStock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stockStatus => $composableBuilder(
    column: $table.stockStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pickerId => $composableBuilder(
    column: $table.pickerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pickedAt => $composableBuilder(
    column: $table.pickedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cancellationReason => $composableBuilder(
    column: $table.cancellationReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrderItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrderItemsTable> {
  $$OrderItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get productSku => $composableBuilder(
    column: $table.productSku,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productCategory => $composableBuilder(
    column: $table.productCategory,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get deliveredQuantity => $composableBuilder(
    column: $table.deliveredQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<double> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get availableStock => $composableBuilder(
    column: $table.availableStock,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stockStatus => $composableBuilder(
    column: $table.stockStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get pickerId =>
      $composableBuilder(column: $table.pickerId, builder: (column) => column);

  GeneratedColumn<DateTime> get pickedAt =>
      $composableBuilder(column: $table.pickedAt, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get cancellationReason => $composableBuilder(
    column: $table.cancellationReason,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OrderItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrderItemsTable,
          OrderItem,
          $$OrderItemsTableFilterComposer,
          $$OrderItemsTableOrderingComposer,
          $$OrderItemsTableAnnotationComposer,
          $$OrderItemsTableCreateCompanionBuilder,
          $$OrderItemsTableUpdateCompanionBuilder,
          (
            OrderItem,
            BaseReferences<_$AppDatabase, $OrderItemsTable, OrderItem>,
          ),
          OrderItem,
          PrefetchHooks Function()
        > {
  $$OrderItemsTableTableManager(_$AppDatabase db, $OrderItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$OrderItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$OrderItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$OrderItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> orderId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> productSku = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String?> productCategory = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int> deliveredQuantity = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<double> subtotal = const Value.absent(),
                Value<double> discountAmount = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<int> availableStock = const Value.absent(),
                Value<String> stockStatus = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> pickerId = const Value.absent(),
                Value<DateTime?> pickedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> cancellationReason = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrderItemsCompanion(
                id: id,
                orderId: orderId,
                productId: productId,
                productSku: productSku,
                productName: productName,
                productCategory: productCategory,
                quantity: quantity,
                deliveredQuantity: deliveredQuantity,
                unitPrice: unitPrice,
                subtotal: subtotal,
                discountAmount: discountAmount,
                totalAmount: totalAmount,
                availableStock: availableStock,
                stockStatus: stockStatus,
                status: status,
                pickerId: pickerId,
                pickedAt: pickedAt,
                notes: notes,
                cancellationReason: cancellationReason,
                isDeleted: isDeleted,
                syncStatus: syncStatus,
                remoteId: remoteId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String orderId,
                required String productId,
                required String productSku,
                required String productName,
                Value<String?> productCategory = const Value.absent(),
                required int quantity,
                Value<int> deliveredQuantity = const Value.absent(),
                required double unitPrice,
                required double subtotal,
                Value<double> discountAmount = const Value.absent(),
                required double totalAmount,
                required int availableStock,
                Value<String> stockStatus = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> pickerId = const Value.absent(),
                Value<DateTime?> pickedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> cancellationReason = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrderItemsCompanion.insert(
                id: id,
                orderId: orderId,
                productId: productId,
                productSku: productSku,
                productName: productName,
                productCategory: productCategory,
                quantity: quantity,
                deliveredQuantity: deliveredQuantity,
                unitPrice: unitPrice,
                subtotal: subtotal,
                discountAmount: discountAmount,
                totalAmount: totalAmount,
                availableStock: availableStock,
                stockStatus: stockStatus,
                status: status,
                pickerId: pickerId,
                pickedAt: pickedAt,
                notes: notes,
                cancellationReason: cancellationReason,
                isDeleted: isDeleted,
                syncStatus: syncStatus,
                remoteId: remoteId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OrderItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrderItemsTable,
      OrderItem,
      $$OrderItemsTableFilterComposer,
      $$OrderItemsTableOrderingComposer,
      $$OrderItemsTableAnnotationComposer,
      $$OrderItemsTableCreateCompanionBuilder,
      $$OrderItemsTableUpdateCompanionBuilder,
      (OrderItem, BaseReferences<_$AppDatabase, $OrderItemsTable, OrderItem>),
      OrderItem,
      PrefetchHooks Function()
    >;
typedef $$DeliveriesTableCreateCompanionBuilder =
    DeliveriesCompanion Function({
      required String id,
      required String orderId,
      required String deliveryPersonnelId,
      required String deliveryPersonnelName,
      required String deliveryPersonnelPhone,
      required String deliveryNumber,
      required DateTime scheduledDate,
      Value<DateTime?> actualStartTime,
      Value<DateTime?> actualCompletionTime,
      Value<String> status,
      Value<String?> subStatus,
      required String route,
      required int routeOrder,
      Value<String?> vehicleNumber,
      required String startLocation,
      required String endLocation,
      Value<double?> startLatitude,
      Value<double?> startLongitude,
      Value<double?> endLatitude,
      Value<double?> endLongitude,
      Value<String?> proofOfDeliveryType,
      Value<String?> proofOfDeliveryUrl,
      Value<String?> recipientName,
      Value<String?> recipientRelation,
      Value<String?> deliveryNotes,
      Value<double> collectedAmount,
      Value<String?> paymentMethod,
      Value<String?> checkNumber,
      Value<String?> issueType,
      Value<String?> issueDescription,
      Value<String?> resolution,
      Value<String> priority,
      Value<int> attemptCount,
      Value<DateTime?> nextAttemptDate,
      Value<bool> isDeleted,
      Value<String> syncStatus,
      Value<String?> remoteId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$DeliveriesTableUpdateCompanionBuilder =
    DeliveriesCompanion Function({
      Value<String> id,
      Value<String> orderId,
      Value<String> deliveryPersonnelId,
      Value<String> deliveryPersonnelName,
      Value<String> deliveryPersonnelPhone,
      Value<String> deliveryNumber,
      Value<DateTime> scheduledDate,
      Value<DateTime?> actualStartTime,
      Value<DateTime?> actualCompletionTime,
      Value<String> status,
      Value<String?> subStatus,
      Value<String> route,
      Value<int> routeOrder,
      Value<String?> vehicleNumber,
      Value<String> startLocation,
      Value<String> endLocation,
      Value<double?> startLatitude,
      Value<double?> startLongitude,
      Value<double?> endLatitude,
      Value<double?> endLongitude,
      Value<String?> proofOfDeliveryType,
      Value<String?> proofOfDeliveryUrl,
      Value<String?> recipientName,
      Value<String?> recipientRelation,
      Value<String?> deliveryNotes,
      Value<double> collectedAmount,
      Value<String?> paymentMethod,
      Value<String?> checkNumber,
      Value<String?> issueType,
      Value<String?> issueDescription,
      Value<String?> resolution,
      Value<String> priority,
      Value<int> attemptCount,
      Value<DateTime?> nextAttemptDate,
      Value<bool> isDeleted,
      Value<String> syncStatus,
      Value<String?> remoteId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$DeliveriesTableFilterComposer
    extends Composer<_$AppDatabase, $DeliveriesTable> {
  $$DeliveriesTableFilterComposer({
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

  ColumnFilters<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryPersonnelId => $composableBuilder(
    column: $table.deliveryPersonnelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryPersonnelName => $composableBuilder(
    column: $table.deliveryPersonnelName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryPersonnelPhone => $composableBuilder(
    column: $table.deliveryPersonnelPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryNumber => $composableBuilder(
    column: $table.deliveryNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get actualStartTime => $composableBuilder(
    column: $table.actualStartTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get actualCompletionTime => $composableBuilder(
    column: $table.actualCompletionTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subStatus => $composableBuilder(
    column: $table.subStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get route => $composableBuilder(
    column: $table.route,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get routeOrder => $composableBuilder(
    column: $table.routeOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vehicleNumber => $composableBuilder(
    column: $table.vehicleNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startLocation => $composableBuilder(
    column: $table.startLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endLocation => $composableBuilder(
    column: $table.endLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get startLatitude => $composableBuilder(
    column: $table.startLatitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get startLongitude => $composableBuilder(
    column: $table.startLongitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get endLatitude => $composableBuilder(
    column: $table.endLatitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get endLongitude => $composableBuilder(
    column: $table.endLongitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get proofOfDeliveryType => $composableBuilder(
    column: $table.proofOfDeliveryType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get proofOfDeliveryUrl => $composableBuilder(
    column: $table.proofOfDeliveryUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipientName => $composableBuilder(
    column: $table.recipientName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipientRelation => $composableBuilder(
    column: $table.recipientRelation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryNotes => $composableBuilder(
    column: $table.deliveryNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get collectedAmount => $composableBuilder(
    column: $table.collectedAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checkNumber => $composableBuilder(
    column: $table.checkNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issueType => $composableBuilder(
    column: $table.issueType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issueDescription => $composableBuilder(
    column: $table.issueDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptDate => $composableBuilder(
    column: $table.nextAttemptDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeliveriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DeliveriesTable> {
  $$DeliveriesTableOrderingComposer({
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

  ColumnOrderings<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryPersonnelId => $composableBuilder(
    column: $table.deliveryPersonnelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryPersonnelName => $composableBuilder(
    column: $table.deliveryPersonnelName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryPersonnelPhone => $composableBuilder(
    column: $table.deliveryPersonnelPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryNumber => $composableBuilder(
    column: $table.deliveryNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get actualStartTime => $composableBuilder(
    column: $table.actualStartTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get actualCompletionTime => $composableBuilder(
    column: $table.actualCompletionTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subStatus => $composableBuilder(
    column: $table.subStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get route => $composableBuilder(
    column: $table.route,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get routeOrder => $composableBuilder(
    column: $table.routeOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vehicleNumber => $composableBuilder(
    column: $table.vehicleNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startLocation => $composableBuilder(
    column: $table.startLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endLocation => $composableBuilder(
    column: $table.endLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get startLatitude => $composableBuilder(
    column: $table.startLatitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get startLongitude => $composableBuilder(
    column: $table.startLongitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get endLatitude => $composableBuilder(
    column: $table.endLatitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get endLongitude => $composableBuilder(
    column: $table.endLongitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get proofOfDeliveryType => $composableBuilder(
    column: $table.proofOfDeliveryType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get proofOfDeliveryUrl => $composableBuilder(
    column: $table.proofOfDeliveryUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipientName => $composableBuilder(
    column: $table.recipientName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipientRelation => $composableBuilder(
    column: $table.recipientRelation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryNotes => $composableBuilder(
    column: $table.deliveryNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get collectedAmount => $composableBuilder(
    column: $table.collectedAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checkNumber => $composableBuilder(
    column: $table.checkNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issueType => $composableBuilder(
    column: $table.issueType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issueDescription => $composableBuilder(
    column: $table.issueDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptDate => $composableBuilder(
    column: $table.nextAttemptDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeliveriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeliveriesTable> {
  $$DeliveriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get deliveryPersonnelId => $composableBuilder(
    column: $table.deliveryPersonnelId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveryPersonnelName => $composableBuilder(
    column: $table.deliveryPersonnelName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveryPersonnelPhone => $composableBuilder(
    column: $table.deliveryPersonnelPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveryNumber => $composableBuilder(
    column: $table.deliveryNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get actualStartTime => $composableBuilder(
    column: $table.actualStartTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get actualCompletionTime => $composableBuilder(
    column: $table.actualCompletionTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get subStatus =>
      $composableBuilder(column: $table.subStatus, builder: (column) => column);

  GeneratedColumn<String> get route =>
      $composableBuilder(column: $table.route, builder: (column) => column);

  GeneratedColumn<int> get routeOrder => $composableBuilder(
    column: $table.routeOrder,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vehicleNumber => $composableBuilder(
    column: $table.vehicleNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startLocation => $composableBuilder(
    column: $table.startLocation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endLocation => $composableBuilder(
    column: $table.endLocation,
    builder: (column) => column,
  );

  GeneratedColumn<double> get startLatitude => $composableBuilder(
    column: $table.startLatitude,
    builder: (column) => column,
  );

  GeneratedColumn<double> get startLongitude => $composableBuilder(
    column: $table.startLongitude,
    builder: (column) => column,
  );

  GeneratedColumn<double> get endLatitude => $composableBuilder(
    column: $table.endLatitude,
    builder: (column) => column,
  );

  GeneratedColumn<double> get endLongitude => $composableBuilder(
    column: $table.endLongitude,
    builder: (column) => column,
  );

  GeneratedColumn<String> get proofOfDeliveryType => $composableBuilder(
    column: $table.proofOfDeliveryType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get proofOfDeliveryUrl => $composableBuilder(
    column: $table.proofOfDeliveryUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recipientName => $composableBuilder(
    column: $table.recipientName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recipientRelation => $composableBuilder(
    column: $table.recipientRelation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveryNotes => $composableBuilder(
    column: $table.deliveryNotes,
    builder: (column) => column,
  );

  GeneratedColumn<double> get collectedAmount => $composableBuilder(
    column: $table.collectedAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checkNumber => $composableBuilder(
    column: $table.checkNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get issueType =>
      $composableBuilder(column: $table.issueType, builder: (column) => column);

  GeneratedColumn<String> get issueDescription => $composableBuilder(
    column: $table.issueDescription,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => column,
  );

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextAttemptDate => $composableBuilder(
    column: $table.nextAttemptDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DeliveriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeliveriesTable,
          Delivery,
          $$DeliveriesTableFilterComposer,
          $$DeliveriesTableOrderingComposer,
          $$DeliveriesTableAnnotationComposer,
          $$DeliveriesTableCreateCompanionBuilder,
          $$DeliveriesTableUpdateCompanionBuilder,
          (Delivery, BaseReferences<_$AppDatabase, $DeliveriesTable, Delivery>),
          Delivery,
          PrefetchHooks Function()
        > {
  $$DeliveriesTableTableManager(_$AppDatabase db, $DeliveriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$DeliveriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$DeliveriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$DeliveriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> orderId = const Value.absent(),
                Value<String> deliveryPersonnelId = const Value.absent(),
                Value<String> deliveryPersonnelName = const Value.absent(),
                Value<String> deliveryPersonnelPhone = const Value.absent(),
                Value<String> deliveryNumber = const Value.absent(),
                Value<DateTime> scheduledDate = const Value.absent(),
                Value<DateTime?> actualStartTime = const Value.absent(),
                Value<DateTime?> actualCompletionTime = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> subStatus = const Value.absent(),
                Value<String> route = const Value.absent(),
                Value<int> routeOrder = const Value.absent(),
                Value<String?> vehicleNumber = const Value.absent(),
                Value<String> startLocation = const Value.absent(),
                Value<String> endLocation = const Value.absent(),
                Value<double?> startLatitude = const Value.absent(),
                Value<double?> startLongitude = const Value.absent(),
                Value<double?> endLatitude = const Value.absent(),
                Value<double?> endLongitude = const Value.absent(),
                Value<String?> proofOfDeliveryType = const Value.absent(),
                Value<String?> proofOfDeliveryUrl = const Value.absent(),
                Value<String?> recipientName = const Value.absent(),
                Value<String?> recipientRelation = const Value.absent(),
                Value<String?> deliveryNotes = const Value.absent(),
                Value<double> collectedAmount = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<String?> checkNumber = const Value.absent(),
                Value<String?> issueType = const Value.absent(),
                Value<String?> issueDescription = const Value.absent(),
                Value<String?> resolution = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime?> nextAttemptDate = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeliveriesCompanion(
                id: id,
                orderId: orderId,
                deliveryPersonnelId: deliveryPersonnelId,
                deliveryPersonnelName: deliveryPersonnelName,
                deliveryPersonnelPhone: deliveryPersonnelPhone,
                deliveryNumber: deliveryNumber,
                scheduledDate: scheduledDate,
                actualStartTime: actualStartTime,
                actualCompletionTime: actualCompletionTime,
                status: status,
                subStatus: subStatus,
                route: route,
                routeOrder: routeOrder,
                vehicleNumber: vehicleNumber,
                startLocation: startLocation,
                endLocation: endLocation,
                startLatitude: startLatitude,
                startLongitude: startLongitude,
                endLatitude: endLatitude,
                endLongitude: endLongitude,
                proofOfDeliveryType: proofOfDeliveryType,
                proofOfDeliveryUrl: proofOfDeliveryUrl,
                recipientName: recipientName,
                recipientRelation: recipientRelation,
                deliveryNotes: deliveryNotes,
                collectedAmount: collectedAmount,
                paymentMethod: paymentMethod,
                checkNumber: checkNumber,
                issueType: issueType,
                issueDescription: issueDescription,
                resolution: resolution,
                priority: priority,
                attemptCount: attemptCount,
                nextAttemptDate: nextAttemptDate,
                isDeleted: isDeleted,
                syncStatus: syncStatus,
                remoteId: remoteId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String orderId,
                required String deliveryPersonnelId,
                required String deliveryPersonnelName,
                required String deliveryPersonnelPhone,
                required String deliveryNumber,
                required DateTime scheduledDate,
                Value<DateTime?> actualStartTime = const Value.absent(),
                Value<DateTime?> actualCompletionTime = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> subStatus = const Value.absent(),
                required String route,
                required int routeOrder,
                Value<String?> vehicleNumber = const Value.absent(),
                required String startLocation,
                required String endLocation,
                Value<double?> startLatitude = const Value.absent(),
                Value<double?> startLongitude = const Value.absent(),
                Value<double?> endLatitude = const Value.absent(),
                Value<double?> endLongitude = const Value.absent(),
                Value<String?> proofOfDeliveryType = const Value.absent(),
                Value<String?> proofOfDeliveryUrl = const Value.absent(),
                Value<String?> recipientName = const Value.absent(),
                Value<String?> recipientRelation = const Value.absent(),
                Value<String?> deliveryNotes = const Value.absent(),
                Value<double> collectedAmount = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<String?> checkNumber = const Value.absent(),
                Value<String?> issueType = const Value.absent(),
                Value<String?> issueDescription = const Value.absent(),
                Value<String?> resolution = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime?> nextAttemptDate = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeliveriesCompanion.insert(
                id: id,
                orderId: orderId,
                deliveryPersonnelId: deliveryPersonnelId,
                deliveryPersonnelName: deliveryPersonnelName,
                deliveryPersonnelPhone: deliveryPersonnelPhone,
                deliveryNumber: deliveryNumber,
                scheduledDate: scheduledDate,
                actualStartTime: actualStartTime,
                actualCompletionTime: actualCompletionTime,
                status: status,
                subStatus: subStatus,
                route: route,
                routeOrder: routeOrder,
                vehicleNumber: vehicleNumber,
                startLocation: startLocation,
                endLocation: endLocation,
                startLatitude: startLatitude,
                startLongitude: startLongitude,
                endLatitude: endLatitude,
                endLongitude: endLongitude,
                proofOfDeliveryType: proofOfDeliveryType,
                proofOfDeliveryUrl: proofOfDeliveryUrl,
                recipientName: recipientName,
                recipientRelation: recipientRelation,
                deliveryNotes: deliveryNotes,
                collectedAmount: collectedAmount,
                paymentMethod: paymentMethod,
                checkNumber: checkNumber,
                issueType: issueType,
                issueDescription: issueDescription,
                resolution: resolution,
                priority: priority,
                attemptCount: attemptCount,
                nextAttemptDate: nextAttemptDate,
                isDeleted: isDeleted,
                syncStatus: syncStatus,
                remoteId: remoteId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeliveriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeliveriesTable,
      Delivery,
      $$DeliveriesTableFilterComposer,
      $$DeliveriesTableOrderingComposer,
      $$DeliveriesTableAnnotationComposer,
      $$DeliveriesTableCreateCompanionBuilder,
      $$DeliveriesTableUpdateCompanionBuilder,
      (Delivery, BaseReferences<_$AppDatabase, $DeliveriesTable, Delivery>),
      Delivery,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db, _db.customers);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$StockMovementsTableTableManager get stockMovements =>
      $$StockMovementsTableTableManager(_db, _db.stockMovements);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$OrdersTableTableManager get orders =>
      $$OrdersTableTableManager(_db, _db.orders);
  $$OrderItemsTableTableManager get orderItems =>
      $$OrderItemsTableTableManager(_db, _db.orderItems);
  $$DeliveriesTableTableManager get deliveries =>
      $$DeliveriesTableTableManager(_db, _db.deliveries);
}

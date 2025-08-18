import 'package:json_annotation/json_annotation.dart';

part 'family_member.g.dart';

enum MemberRole { parent, child }

@JsonSerializable()
class FamilyMember {
  final String id;
  final String? name;
  final String? email;
  final MemberRole role;
  final int? age;
  final String? avatarUrl;
  final List<String> interests;
  final DateTime createdAt;
  final DateTime? lastActive;
  final bool isActive;
  final Map<String, dynamic>? settings;

  FamilyMember({
    required this.id,
    this.name,
    this.email,
    required this.role,
    this.age,
    this.avatarUrl,
    List<String>? interests,
    DateTime? createdAt,
    this.lastActive,
    this.isActive = true,
    this.settings,
  })  : interests = interests ?? [],
        createdAt = createdAt ?? DateTime.now();

  factory FamilyMember.fromJson(Map<String, dynamic> json) =>
      _$FamilyMemberFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyMemberToJson(this);

  FamilyMember copyWith({
    String? id,
    String? name,
    String? email,
    MemberRole? role,
    int? age,
    String? avatarUrl,
    List<String>? interests,
    DateTime? createdAt,
    DateTime? lastActive,
    bool? isActive,
    Map<String, dynamic>? settings,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      age: age ?? this.age,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      interests: interests ?? this.interests,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      isActive: isActive ?? this.isActive,
      settings: settings ?? this.settings,
    );
  }

  bool get isChild => role == MemberRole.child;
  bool get isParent => role == MemberRole.parent;

  String get displayAge {
    if (age == null) return '';
    return '$age years old';
  }

  String get initials {
    if (name == null || name!.trim().isEmpty) {
      return '?';
    }
    
    final trimmedName = name!.trim();
    final parts = trimmedName.split(' ');
    
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    
    if (trimmedName.isNotEmpty) {
      return trimmedName.substring(0, 1).toUpperCase();
    }
    
    return '?';
  }
}

@JsonSerializable()
class Family {
  final String id;
  final String name;
  final List<FamilyMember> members;
  final String? subscriptionPlan;
  final DateTime createdAt;
  final Map<String, dynamic>? settings;

  Family({
    required this.id,
    required this.name,
    List<FamilyMember>? members,
    this.subscriptionPlan,
    DateTime? createdAt,
    this.settings,
  })  : members = members ?? [],
        createdAt = createdAt ?? DateTime.now();

  factory Family.fromJson(Map<String, dynamic> json) => _$FamilyFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyToJson(this);

  List<FamilyMember> get children =>
      members.where((m) => m.isChild).toList();

  List<FamilyMember> get parents =>
      members.where((m) => m.isParent).toList();

  int get childCount => children.length;
  int get parentCount => parents.length;

  Family copyWith({
    String? id,
    String? name,
    List<FamilyMember>? members,
    String? subscriptionPlan,
    DateTime? createdAt,
    Map<String, dynamic>? settings,
  }) {
    return Family(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      createdAt: createdAt ?? this.createdAt,
      settings: settings ?? this.settings,
    );
  }
}
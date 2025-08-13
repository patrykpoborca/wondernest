import 'package:json_annotation/json_annotation.dart';

part 'coppa_consent.g.dart';

@JsonSerializable()
class CoppaConsent {
  final String id;
  final String parentId;
  final String childId;
  final ConsentStatus status;
  final DateTime consentDate;
  final String ipAddress;
  final String deviceId;
  final Map<String, bool> permissions;
  final String? parentSignature;
  final DateTime? expiryDate;
  final bool dataCollectionConsent;
  final bool thirdPartySharing;
  final bool marketingConsent;

  CoppaConsent({
    required this.id,
    required this.parentId,
    required this.childId,
    required this.status,
    required this.consentDate,
    required this.ipAddress,
    required this.deviceId,
    required this.permissions,
    this.parentSignature,
    this.expiryDate,
    required this.dataCollectionConsent,
    required this.thirdPartySharing,
    required this.marketingConsent,
  });

  factory CoppaConsent.fromJson(Map<String, dynamic> json) =>
      _$CoppaConsentFromJson(json);

  Map<String, dynamic> toJson() => _$CoppaConsentToJson(this);
}

enum ConsentStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('granted')
  granted,
  @JsonValue('denied')
  denied,
  @JsonValue('revoked')
  revoked,
  @JsonValue('expired')
  expired,
}
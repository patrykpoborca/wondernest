import 'package:json_annotation/json_annotation.dart';

enum AppMode {
  @JsonValue('kid')
  kid,
  @JsonValue('parent')
  parent,
}

extension AppModeExtension on AppMode {
  String get displayName {
    switch (this) {
      case AppMode.kid:
        return 'Kid Mode';
      case AppMode.parent:
        return 'Parent Mode';
    }
  }

  bool get isKidMode => this == AppMode.kid;
  bool get isParentMode => this == AppMode.parent;
}
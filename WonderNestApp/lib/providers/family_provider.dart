import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/family_member.dart';
import '../core/services/mock_api_service.dart';

// Selected child provider
final selectedChildProvider = StateProvider<FamilyMember?>((ref) => null);

// Family API service provider
final familyApiServiceProvider = Provider<FamilyApiService>((ref) {
  return FamilyApiService();
});

// Family state notifier
class FamilyNotifier extends AsyncNotifier<Family> {
  @override
  Future<Family> build() async {
    return await _fetchFamily();
  }

  Future<Family> _fetchFamily() async {
    final service = ref.read(familyApiServiceProvider);
    return await service.getFamily();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _fetchFamily();
    });
  }

  Future<void> addChild(FamilyMember child) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(familyApiServiceProvider);
      await service.addFamilyMember(child);
      return await _fetchFamily();
    });
  }

  Future<void> updateChild(FamilyMember child) async {
    state = await AsyncValue.guard(() async {
      final service = ref.read(familyApiServiceProvider);
      await service.updateFamilyMember(child);
      return await _fetchFamily();
    });
  }

  Future<void> removeChild(String childId) async {
    state = await AsyncValue.guard(() async {
      final service = ref.read(familyApiServiceProvider);
      await service.removeFamilyMember(childId);
      return await _fetchFamily();
    });
  }

  void selectChild(FamilyMember? child) {
    ref.read(selectedChildProvider.notifier).state = child;
  }
}

// Family provider
final familyProvider = AsyncNotifierProvider<FamilyNotifier, Family>(() {
  return FamilyNotifier();
});

// Mock Family API Service extension
class FamilyApiService {
  // Simulated database
  static Family? _mockFamily;

  Future<Family> getFamily() async {
    await Future.delayed(const Duration(seconds: 1));

    if (_mockFamily == null) {
      // Initialize with mock data
      _mockFamily = Family(
        id: 'fam_001',
        name: 'The Wonder Family',
        members: [
          FamilyMember(
            id: 'parent_001',
            name: 'Parent User',
            email: 'parent@wondernest.com',
            role: MemberRole.parent,
            lastActive: DateTime.now(),
          ),
        ],
        subscriptionPlan: 'free',
      );
    }

    return _mockFamily!;
  }

  Future<void> addFamilyMember(FamilyMember member) async {
    await Future.delayed(const Duration(seconds: 1));

    if (_mockFamily != null) {
      final updatedMembers = [..._mockFamily!.members, member];
      _mockFamily = _mockFamily!.copyWith(members: updatedMembers);
    }
  }

  Future<void> updateFamilyMember(FamilyMember member) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (_mockFamily != null) {
      final updatedMembers = _mockFamily!.members.map((m) {
        if (m.id == member.id) {
          return member;
        }
        return m;
      }).toList();
      _mockFamily = _mockFamily!.copyWith(members: updatedMembers);
    }
  }

  Future<void> removeFamilyMember(String memberId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (_mockFamily != null) {
      final updatedMembers =
          _mockFamily!.members.where((m) => m.id != memberId).toList();
      _mockFamily = _mockFamily!.copyWith(members: updatedMembers);
    }
  }
}

// Child profile form provider
final childProfileFormProvider =
    StateNotifierProvider.autoDispose<ChildProfileFormNotifier, ChildProfileFormState>(
        (ref) {
  return ChildProfileFormNotifier();
});

class ChildProfileFormState {
  final String name;
  final int? age;
  final List<String> interests;
  final String? avatarPath;
  final bool isLoading;
  final String? error;

  ChildProfileFormState({
    this.name = '',
    this.age,
    this.interests = const [],
    this.avatarPath,
    this.isLoading = false,
    this.error,
  });

  ChildProfileFormState copyWith({
    String? name,
    int? age,
    List<String>? interests,
    String? avatarPath,
    bool? isLoading,
    String? error,
  }) {
    return ChildProfileFormState(
      name: name ?? this.name,
      age: age ?? this.age,
      interests: interests ?? this.interests,
      avatarPath: avatarPath ?? this.avatarPath,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ChildProfileFormNotifier extends StateNotifier<ChildProfileFormState> {
  ChildProfileFormNotifier() : super(ChildProfileFormState());

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateAge(int age) {
    state = state.copyWith(age: age);
  }

  void toggleInterest(String interest) {
    final interests = [...state.interests];
    if (interests.contains(interest)) {
      interests.remove(interest);
    } else {
      interests.add(interest);
    }
    state = state.copyWith(interests: interests);
  }

  void updateAvatar(String path) {
    state = state.copyWith(avatarPath: path);
  }

  void reset() {
    state = ChildProfileFormState();
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }
}

// Available interests provider
final availableInterestsProvider = Provider<List<String>>((ref) {
  return [
    'Science',
    'Math',
    'Reading',
    'Art',
    'Music',
    'Sports',
    'Animals',
    'Nature',
    'Technology',
    'History',
    'Geography',
    'Languages',
    'Cooking',
    'Dancing',
    'Games',
    'Puzzles',
  ];
});
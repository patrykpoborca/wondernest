import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/family_member.dart' as fm;
import 'auth_provider.dart';
import '../../core/services/timber_wrapper.dart';

// Selected child provider
final selectedChildProvider = StateProvider<fm.FamilyMember?>((ref) => null);

// Family API service provider
final familyApiServiceProvider = Provider<FamilyApiService>((ref) {
  return FamilyApiService(ref.read(apiServiceProvider));
});

// Family state notifier
class FamilyNotifier extends AsyncNotifier<fm.Family> {
  @override
  Future<fm.Family> build() async {
    // Check if user is authenticated before fetching family
    final authState = ref.read(authProvider);
    if (!authState.isLoggedIn) {
      // Return empty family if not logged in
      return fm.Family(
        id: 'empty',
        name: 'My Family',
        members: [],
        subscriptionPlan: 'free',
      );
    }
    return await _fetchFamily();
  }

  Future<fm.Family> _fetchFamily() async {
    try {
      final service = ref.read(familyApiServiceProvider);
      return await service.getFamily();
    } catch (e) {
      // If error occurs (likely auth error), return empty family
      Timber.d('[FamilyProvider] Error fetching family: $e');
      return fm.Family(
        id: 'empty',
        name: 'My Family',
        members: [],
        subscriptionPlan: 'free',
      );
    }
  }

  Future<void> refresh() async {
    // Check if user is authenticated before refreshing
    final authState = ref.read(authProvider);
    if (!authState.isLoggedIn) {
      return;
    }
    
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _fetchFamily();
    });
  }

  Future<void> addChild(fm.FamilyMember child) async {
    // Check if user is authenticated before adding child
    final authState = ref.read(authProvider);
    if (!authState.isLoggedIn) {
      throw Exception('You must be logged in to add a child profile');
    }
    
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(familyApiServiceProvider);
      await service.addFamilyMember(child);
      return await _fetchFamily();
    });
  }

  Future<void> updateChild(fm.FamilyMember child) async {
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

  void selectChild(fm.FamilyMember? child) {
    ref.read(selectedChildProvider.notifier).state = child;
  }
}

// Family provider
final familyProvider = AsyncNotifierProvider<FamilyNotifier, fm.Family>(() {
  return FamilyNotifier();
});

// Family API Service that integrates with real backend
class FamilyApiService {
  final ApiService _apiService;
  
  FamilyApiService(this._apiService);
  
  // Cache for offline support
  static fm.Family? _cachedFamily;

  Future<fm.Family> getFamily() async {
    try {
      // Get family profile from backend
      final response = await _apiService.getFamilyProfile();
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          List<fm.FamilyMember> members = [];
          
          // The family profile response now includes a complete structure:
          // - family: basic family info
          // - members: all family members 
          // - children: detailed child profiles
          
          // Extract family info
          final family = data['family'];
          final familyMembers = data['members'] as List? ?? [];
          final children = data['children'] as List? ?? [];
          
          // Add parent members
          for (final member in familyMembers) {
            if (member['role'] == 'parent') {
              members.add(fm.FamilyMember(
                id: member['userId'] ?? 'parent_001',
                name: '${member['firstName'] ?? 'Parent'} ${member['lastName'] ?? ''}',
                email: member['email'],
                role: fm.MemberRole.parent,
                lastActive: DateTime.now(),
                createdAt: member['joinedAt'] != null 
                    ? DateTime.parse(member['joinedAt'])
                    : DateTime.now(),
              ));
            }
          }
          
          // Add children from detailed child profiles
          for (final child in children) {
            // Calculate age from birthDate or use provided age
            int? age = child['age'];
            if (age == null && child['birthDate'] != null) {
              try {
                final birthDate = DateTime.parse(child['birthDate']);
                age = DateTime.now().difference(birthDate).inDays ~/ 365;
              } catch (e) {
                // Handle parse error
              }
            }
            
            members.add(fm.FamilyMember(
              id: child['id'] ?? '',
              name: child['name'] ?? 'Child',
              role: fm.MemberRole.child,
              age: age,
              avatarUrl: child['avatarUrl'] ?? '🐻',
              interests: List<String>.from(child['interests'] ?? []),
              createdAt: child['createdAt'] != null 
                  ? DateTime.parse(child['createdAt'])
                  : DateTime.now(),
            ));
          }
          
          final familyData = fm.Family(
            id: family['id'] ?? 'fam_001',
            name: family['name'] ?? 'My Family',
            members: members,
            subscriptionPlan: 'free', // TODO: Get from family settings
            createdAt: family['createdAt'] != null 
                ? DateTime.parse(family['createdAt'])
                : DateTime.now(),
          );
          
          // Cache for offline support
          _cachedFamily = familyData;
          return familyData;
        }
      }
    } catch (e) {
      // If error and we have cached data, return it
      if (_cachedFamily != null) {
        return _cachedFamily!;
      }
      
      // Otherwise return a default family structure
      return fm.Family(
        id: 'fam_default',
        name: 'My Family',
        members: [],
        subscriptionPlan: 'free',
      );
    }
    
    // Return cached or default if something went wrong
    return _cachedFamily ?? fm.Family(
      id: 'fam_default',
      name: 'My Family',
      members: [],
      subscriptionPlan: 'free',
    );
  }

  Future<void> addFamilyMember(fm.FamilyMember member) async {
    if (member.role == fm.MemberRole.child) {
      // Parse birth date from settings or calculate from age
      DateTime birthDate = DateTime.now();
      
      if (member.settings != null && member.settings!['birthDate'] != null) {
        try {
          birthDate = DateTime.parse(member.settings!['birthDate']);
        } catch (e) {
          // Fallback to age calculation if parse fails
          if (member.age != null) {
            birthDate = DateTime.now().subtract(Duration(days: member.age! * 365));
          }
        }
      } else if (member.age != null) {
        birthDate = DateTime.now().subtract(Duration(days: member.age! * 365));
      }
      
      // Extract gender from settings
      String? gender;
      if (member.settings != null && member.settings!['gender'] != null) {
        gender = member.settings!['gender'];
      }
      
      final response = await _apiService.createChild(
        name: member.name ?? 'Unnamed Child',
        birthDate: birthDate,
        gender: gender,
        interests: member.interests,
        avatar: member.avatarUrl,
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = response.data?['error']?['message'] ?? 'Failed to add child';
        throw Exception(error);
      }
    }
  }

  Future<void> updateFamilyMember(fm.FamilyMember member) async {
    if (member.role == fm.MemberRole.child) {
      // Parse birth date from settings or calculate from age
      DateTime birthDate = DateTime.now();
      
      if (member.settings != null && member.settings!['birthDate'] != null) {
        try {
          birthDate = DateTime.parse(member.settings!['birthDate']);
        } catch (e) {
          // Fallback to age calculation if parse fails
          if (member.age != null) {
            birthDate = DateTime.now().subtract(Duration(days: member.age! * 365));
          }
        }
      } else if (member.age != null) {
        birthDate = DateTime.now().subtract(Duration(days: member.age! * 365));
      }
      
      // Extract gender from settings
      String? gender;
      if (member.settings != null && member.settings!['gender'] != null) {
        gender = member.settings!['gender'];
      }
      
      final response = await _apiService.updateChild(
        childId: member.id,
        name: member.name ?? 'Unnamed Child',
        birthDate: birthDate,
        gender: gender,
        interests: member.interests,
        avatar: member.avatarUrl,
      );
      
      if (response.statusCode != 200) {
        final error = response.data?['error']?['message'] ?? 'Failed to update child';
        throw Exception(error);
      }
    }
  }

  Future<void> removeFamilyMember(String memberId) async {
    final response = await _apiService.deleteChild(memberId);
    
    if (response.statusCode != 200) {
      throw Exception('Failed to remove child');
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
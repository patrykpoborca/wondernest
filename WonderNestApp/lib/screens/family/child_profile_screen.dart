import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import '../../models/family_member.dart' as fm;
import '../../providers/family_provider.dart';

class ChildProfileScreen extends ConsumerStatefulWidget {
  final String? childId;
  final bool isEditing;

  const ChildProfileScreen({
    super.key,
    this.childId,
    this.isEditing = false,
  });

  @override
  ConsumerState<ChildProfileScreen> createState() =>
      _ChildProfileScreenState();
}

class _ChildProfileScreenState extends ConsumerState<ChildProfileScreen> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  int _currentStep = 0;
  final int _totalSteps = 4;
  File? _avatarFile;
  double _selectedAge = 5;
  DateTime? _selectedBirthDate;
  String? _selectedGender;
  final Set<String> _selectedInterests = {};

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.childId != null) {
      _loadExistingChild();
    }
  }

  void _loadExistingChild() {
    // Load existing child data for editing
    final familyAsync = ref.read(familyProvider);
    familyAsync.whenData((family) {
      final children = family.children;
      if (children.isEmpty) return;
      
      final child = children.firstWhere(
        (c) => c.id == widget.childId,
        orElse: () => fm.FamilyMember(
          id: '',
          name: '',
          role: fm.MemberRole.child,
        ),
      );
      if (child.id.isNotEmpty) {
        _nameController.text = child.name ?? '';
        _selectedAge = child.age?.toDouble() ?? 5;
        _selectedInterests.addAll(child.interests);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(childProfileFormProvider);
    final availableInterests = ref.watch(availableInterestsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Profile' : 'Create Child Profile'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft()),
          onPressed: () {
            if (_currentStep > 0) {
              _previousStep();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: StepProgressIndicator(
              totalSteps: _totalSteps,
              currentStep: _currentStep + 1,
              selectedColor: theme.colorScheme.primary,
              unselectedColor: theme.colorScheme.surfaceContainerHighest,
              roundedEdges: const Radius.circular(10),
              size: 8,
            ),
          ),

          // Step Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _getStepTitle(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _getStepSubtitle(),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // Form Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildNameStep(theme),
                _buildAgeStep(theme),
                _buildAvatarStep(theme),
                _buildInterestsStep(theme, availableInterests),
              ],
            ),
          ),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: formState.isLoading ? null : _handleNextStep,
                    child: formState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_currentStep == _totalSteps - 1
                            ? (widget.isEditing ? 'Update' : 'Create Profile')
                            : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Icon(
              PhosphorIcons.user(),
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: "Child's Name",
                hintText: 'Enter your child\'s name',
                prefixIcon: Icon(PhosphorIcons.textT()),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                if (value.length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
              onChanged: (value) {
                ref.read(childProfileFormProvider.notifier).updateName(value);
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.info(),
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This name will be displayed throughout the app to personalize your child\'s experience.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            PhosphorIcons.cake(),
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'Birth Date',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          // Birth date picker
          InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedBirthDate ?? DateTime.now().subtract(Duration(days: 365 * 5)),
                firstDate: DateTime.now().subtract(Duration(days: 365 * 14)), // Max 14 years old
                lastDate: DateTime.now().subtract(Duration(days: 365)), // Min 1 year old
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: theme.colorScheme,
                    ),
                    child: child!,
                  );
                },
              );
              
              if (picked != null) {
                setState(() {
                  _selectedBirthDate = picked;
                  _selectedAge = (DateTime.now().difference(picked).inDays / 365).clamp(1, 14);
                });
                ref
                    .read(childProfileFormProvider.notifier)
                    .updateAge(_selectedAge.round());
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedBirthDate != null 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.outline,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: _selectedBirthDate != null
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
                    : Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PhosphorIcons.calendar(),
                    color: _selectedBirthDate != null 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedBirthDate != null
                        ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                        : 'Select Birth Date',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: _selectedBirthDate != null 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_selectedBirthDate != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(${_selectedAge.round()} years old)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Gender selection (optional)
          Text(
            'Gender (Optional)',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGenderOption('Male', PhosphorIcons.user(), theme),
              const SizedBox(width: 12),
              _buildGenderOption('Female', PhosphorIcons.userFocus(), theme),
              const SizedBox(width: 12),
              _buildGenderOption('Other', PhosphorIcons.users(), theme),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.shield(),
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Birth date helps us recommend age-appropriate content and ensure COPPA compliance.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGenderOption(String gender, IconData icon, ThemeData theme) {
    final isSelected = _selectedGender == gender;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedGender = isSelected ? null : gender;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
            const SizedBox(height: 4),
            Text(
              gender,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 80,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage:
                      _avatarFile != null ? FileImage(_avatarFile!) : null,
                  child: _avatarFile == null
                      ? Icon(
                          PhosphorIcons.camera(),
                          size: 48,
                          color: theme.colorScheme.onPrimaryContainer,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      PhosphorIcons.pencil(),
                      size: 20,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Choose an Avatar',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps your child identify their profile',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAvatarOption(
                icon: PhosphorIcons.camera(),
                label: 'Camera',
                onTap: () => _pickAvatar(source: ImageSource.camera),
                theme: theme,
              ),
              _buildAvatarOption(
                icon: PhosphorIcons.image(),
                label: 'Gallery',
                onTap: () => _pickAvatar(source: ImageSource.gallery),
                theme: theme,
              ),
              _buildAvatarOption(
                icon: PhosphorIcons.smiley(),
                label: 'Default',
                onTap: _useDefaultAvatar,
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestsStep(ThemeData theme, List<String> interests) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            PhosphorIcons.star(),
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Select Interests',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose topics your child enjoys',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: interests.map((interest) {
                  final isSelected = _selectedInterests.contains(interest);
                  return FilterChip(
                    label: Text(interest),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedInterests.add(interest);
                        } else {
                          _selectedInterests.remove(interest);
                        }
                      });
                      ref
                          .read(childProfileFormProvider.notifier)
                          .toggleInterest(interest);
                    },
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    selectedColor: theme.colorScheme.primaryContainer,
                    checkmarkColor: theme.colorScheme.primary,
                  );
                }).toList(),
              ),
            ),
          ),
          if (_selectedInterests.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.check(),
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedInterests.length} interests selected',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return "What's your child's name?";
      case 1:
        return 'How old is your child?';
      case 2:
        return 'Add a fun avatar!';
      case 3:
        return 'What does your child like?';
      default:
        return '';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'This helps personalize the experience';
      case 1:
        return 'We\'ll show age-appropriate content';
      case 2:
        return 'Make the profile unique and recognizable';
      case 3:
        return 'We\'ll recommend content based on these interests';
      default:
        return '';
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleNextStep() async {
    // Validate current step
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Submit the form
      await _submitProfile();
    }
  }

  Future<void> _pickAvatar({ImageSource? source}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source ?? ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _avatarFile = File(image.path);
        });
        ref
            .read(childProfileFormProvider.notifier)
            .updateAvatar(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _useDefaultAvatar() {
    setState(() {
      _avatarFile = null;
    });
    ref.read(childProfileFormProvider.notifier).updateAvatar('');
  }

  Future<void> _submitProfile() async {
    // Validate required fields
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a name for your child'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _currentStep = 0;
        _pageController.jumpToPage(0);
      });
      return;
    }
    
    if (_nameController.text.trim().length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name must be at least 2 characters'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _currentStep = 0;
        _pageController.jumpToPage(0);
      });
      return;
    }
    
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your child\'s birth date'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _currentStep = 1;
        _pageController.jumpToPage(1);
      });
      return;
    }
    
    final formNotifier = ref.read(childProfileFormProvider.notifier);
    formNotifier.setLoading(true);

    try {
      final member = fm.FamilyMember(
        id: widget.childId ?? 'child_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        role: fm.MemberRole.child,
        age: _selectedAge.round(),
        interests: _selectedInterests.toList(),
        avatarUrl: _avatarFile?.path ?? '',
        settings: {
          'birthDate': _selectedBirthDate?.toIso8601String(),
          'gender': _selectedGender,
        },
      );

      if (widget.isEditing) {
        await ref.read(familyProvider.notifier).updateChild(member);
      } else {
        await ref.read(familyProvider.notifier).addChild(member);
      }

      formNotifier.reset();

      if (mounted) {
        // Navigate to COPPA consent if creating new profile
        if (!widget.isEditing) {
          context.go(
            '/coppa-consent?childId=${member.id}&childName=${member.name}&childAge=${member.age}',
          );
        } else {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
            ),
          );
        }
      }
    } catch (e) {
      formNotifier.setError(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      formNotifier.setLoading(false);
    }
  }
}
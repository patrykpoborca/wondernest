import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';

class CoppaConsentScreen extends ConsumerStatefulWidget {
  final String childId;
  final String childName;
  final int childAge;

  const CoppaConsentScreen({
    super.key,
    required this.childId,
    required this.childName,
    required this.childAge,
  });

  @override
  ConsumerState<CoppaConsentScreen> createState() => _CoppaConsentScreenState();
}

class _CoppaConsentScreenState extends ConsumerState<CoppaConsentScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _signatureController = TextEditingController();
  
  int _currentStep = 0;
  bool _isLoading = false;
  
  // Consent permissions
  bool _dataCollectionConsent = false;
  bool _thirdPartySharingConsent = false;
  bool _marketingConsent = false;
  bool _analyticsConsent = false;
  bool _audioMonitoringConsent = false;
  bool _educationalDataConsent = false;
  
  // Verification
  String _verificationMethod = 'credit_card';
  bool _hasReadTerms = false;
  bool _hasVerifiedAge = false;

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'COPPA Parental Consent',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primaryBlue,
          ),
        ),
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _handleStepContinue,
          onStepCancel: _handleStepCancel,
          controlsBuilder: (context, details) {
            return Row(
              children: [
                if (_currentStep < 3)
                  ElevatedButton(
                    onPressed: _canContinue() ? details.onStepContinue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(_currentStep == 3 ? 'Submit' : 'Continue'),
                  ),
                if (_currentStep == 3)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitConsent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Submit Consent'),
                  ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
              ],
            );
          },
          steps: [
            Step(
              title: const Text('Information'),
              content: _buildInformationStep(),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Data Collection'),
              content: _buildDataCollectionStep(),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Verification'),
              content: _buildVerificationStep(),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Signature'),
              content: _buildSignatureStep(),
              isActive: _currentStep >= 3,
              state: _currentStep > 3 ? StepState.complete : StepState.indexed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    'COPPA Compliance',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'The Children\'s Online Privacy Protection Act (COPPA) requires parental consent for collecting personal information from children under 13.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'Child Information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        _buildInfoRow('Child Name', widget.childName),
        _buildInfoRow('Age', '${widget.childAge} years old'),
        _buildInfoRow('Account Type', 'Child Account (Restricted)'),
        
        const SizedBox(height: 24),
        
        Text(
          'What We Collect',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        _buildBulletPoint('Profile information (name, age, avatar)'),
        _buildBulletPoint('App usage and activity data'),
        _buildBulletPoint('Educational progress and achievements'),
        _buildBulletPoint('Content preferences and interests'),
        _buildBulletPoint('Device information for safety'),
        
        const SizedBox(height: 24),
        
        Text(
          'How We Protect Your Child',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        _buildBulletPoint('All data is encrypted and secure'),
        _buildBulletPoint('No direct messaging or social features'),
        _buildBulletPoint('Content is pre-screened and age-appropriate'),
        _buildBulletPoint('Audio is processed locally, never recorded'),
        _buildBulletPoint('You can delete data at any time'),
      ],
    );
  }

  Widget _buildDataCollectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Please select what data collection you consent to:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        
        _buildConsentSwitch(
          'Essential Data Collection',
          'Required for app functionality (profile, preferences)',
          true,
          false, // Cannot be disabled
        ),
        
        _buildConsentSwitch(
          'Educational Progress Tracking',
          'Track learning progress and achievements',
          _educationalDataConsent,
          true,
          onChanged: (value) => setState(() => _educationalDataConsent = value),
        ),
        
        _buildConsentSwitch(
          'Usage Analytics',
          'Anonymous app usage statistics for improvement',
          _analyticsConsent,
          true,
          onChanged: (value) => setState(() => _analyticsConsent = value),
        ),
        
        _buildConsentSwitch(
          'Audio Monitoring',
          'Local processing only for safety keywords',
          _audioMonitoringConsent,
          true,
          onChanged: (value) => setState(() => _audioMonitoringConsent = value),
        ),
        
        _buildConsentSwitch(
          'Third-Party Educational Partners',
          'Share progress with educational content providers',
          _thirdPartySharingConsent,
          true,
          onChanged: (value) => setState(() => _thirdPartySharingConsent = value),
        ),
        
        _buildConsentSwitch(
          'Marketing Communications',
          'Receive updates about new features and content',
          _marketingConsent,
          true,
          onChanged: (value) => setState(() => _marketingConsent = value),
        ),
        
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You can change these settings at any time in the Parent Dashboard.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        CheckboxListTile(
          value: _dataCollectionConsent,
          onChanged: (value) => setState(() => _dataCollectionConsent = value ?? false),
          title: const Text(
            'I consent to the data collection practices described above',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parental Verification',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'We need to verify that you are an adult and the parent/guardian of this child.',
        ),
        const SizedBox(height: 24),
        
        Text(
          'Verification Method',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        RadioListTile<String>(
          title: const Text('Credit Card (\$0.50 charge, refunded)'),
          subtitle: const Text('Most secure and instant verification'),
          value: 'credit_card',
          groupValue: _verificationMethod,
          onChanged: (value) => setState(() => _verificationMethod = value!),
        ),
        
        RadioListTile<String>(
          title: const Text('Driver\'s License'),
          subtitle: const Text('Upload photo of your ID'),
          value: 'drivers_license',
          groupValue: _verificationMethod,
          onChanged: (value) => setState(() => _verificationMethod = value!),
        ),
        
        RadioListTile<String>(
          title: const Text('Last 4 digits of SSN'),
          subtitle: const Text('US residents only'),
          value: 'ssn',
          groupValue: _verificationMethod,
          onChanged: (value) => setState(() => _verificationMethod = value!),
        ),
        
        const SizedBox(height: 24),
        
        if (_verificationMethod == 'credit_card')
          _buildCreditCardVerification(),
        if (_verificationMethod == 'drivers_license')
          _buildLicenseVerification(),
        if (_verificationMethod == 'ssn')
          _buildSSNVerification(),
        
        const SizedBox(height: 24),
        
        CheckboxListTile(
          value: _hasVerifiedAge,
          onChanged: (value) => setState(() => _hasVerifiedAge = value ?? false),
          title: const Text(
            'I confirm that I am 18 years or older',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildSignatureStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Electronic Signature',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
        ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Consent Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Text('Child: ${widget.childName}'),
                Text('Age: ${widget.childAge} years old'),
                const SizedBox(height: 8),
                const Text('Permissions Granted:'),
                if (_educationalDataConsent)
                  _buildPermissionItem('Educational Progress Tracking'),
                if (_analyticsConsent)
                  _buildPermissionItem('Usage Analytics'),
                if (_audioMonitoringConsent)
                  _buildPermissionItem('Audio Monitoring (Local Only)'),
                if (_thirdPartySharingConsent)
                  _buildPermissionItem('Third-Party Educational Partners'),
                if (_marketingConsent)
                  _buildPermissionItem('Marketing Communications'),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          TextFormField(
            controller: _signatureController,
            decoration: InputDecoration(
              labelText: 'Parent/Guardian Full Name',
              hintText: 'Enter your full legal name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.edit),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your full name';
              }
              if (value.split(' ').length < 2) {
                return 'Please enter your full name (first and last)';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          CheckboxListTile(
            value: _hasReadTerms,
            onChanged: (value) => setState(() => _hasReadTerms = value ?? false),
            title: const Text(
              'I have read and agree to the Terms of Service and Privacy Policy',
              style: TextStyle(fontSize: 14),
            ),
            subtitle: GestureDetector(
              onTap: () {
                // Open terms
              },
              child: const Text(
                'View Terms and Privacy Policy',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: Colors.green[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Rights',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You can review, update, or delete your child\'s data at any time. '
                        'You can also revoke consent from the Parent Dashboard.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardVerification() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'A \$0.50 charge will be made and immediately refunded to verify your card.',
                  style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            // Open payment processor
          },
          icon: const Icon(Icons.credit_card),
          label: const Text('Verify with Credit Card'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildLicenseVerification() {
    return Column(
      children: [
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 8),
                Text(
                  'Upload Driver\'s License',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your ID will be verified and immediately deleted',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildSSNVerification() {
    return Column(
      children: [
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Last 4 digits of SSN',
            hintText: 'XXXX',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.lock),
          ),
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),
        Text(
          'This information is encrypted and used only for verification',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentSwitch(
    String title,
    String subtitle,
    bool value,
    bool enabled, {
    ValueChanged<bool>? onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
        value: value,
        onChanged: enabled ? onChanged : null,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildPermissionItem(String permission) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4),
      child: Row(
        children: [
          Icon(Icons.check, size: 16, color: Colors.green[600]),
          const SizedBox(width: 8),
          Text(
            permission,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  bool _canContinue() {
    switch (_currentStep) {
      case 0:
        return true; // Information step, always can continue
      case 1:
        return _dataCollectionConsent;
      case 2:
        return _hasVerifiedAge;
      case 3:
        return _hasReadTerms && _signatureController.text.isNotEmpty;
      default:
        return false;
    }
  }

  void _handleStepContinue() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _handleStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _submitConsent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Submit consent to API
      await _apiService.submitCOPPAConsent(
        childId: widget.childId,
        consentType: 'full',
        permissions: {
          'dataCollection': true,
          'educationalData': _educationalDataConsent,
          'analytics': _analyticsConsent,
          'audioMonitoring': _audioMonitoringConsent,
          'thirdPartySharing': _thirdPartySharingConsent,
          'marketing': _marketingConsent,
        },
        verificationMethod: _verificationMethod,
        verificationData: {
          'parentSignature': _signatureController.text,
        },
      );

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Consent Submitted'),
            content: const Text(
              'Thank you for providing parental consent. '
              'Your child can now safely use WonderNest.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/parent-dashboard');
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting consent: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
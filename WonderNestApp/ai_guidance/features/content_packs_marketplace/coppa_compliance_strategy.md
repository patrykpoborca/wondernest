# Content Packs Marketplace - COPPA Compliance Strategy

## COPPA Overview and Marketplace Impact

The Children's Online Privacy Protection Act (COPPA) requires special protections for children under 13 when collecting, using, or disclosing personal information online. The Content Packs Marketplace introduces additional COPPA considerations through:
- Commercial transactions involving children
- Content preference tracking and analytics  
- Enhanced user profiles for personalization
- Cross-feature usage data collection

## Legal Framework and Requirements

### COPPA Core Requirements for Marketplace
1. **Verifiable Parental Consent**: Required before collecting personal information from children under 13
2. **Clear Privacy Notices**: Parents must understand what data is collected and how it's used
3. **Limited Collection**: Only collect personal information necessary for marketplace functionality
4. **No Unauthorized Disclosure**: Children's information cannot be shared without parental consent
5. **Parental Access Rights**: Parents can review, delete, or refuse further collection of child's information
6. **Reasonable Security**: Implement appropriate safeguards for children's personal information

### Marketplace-Specific Considerations
- **Purchase Transactions**: All purchases require verifiable parental consent
- **Usage Analytics**: Tracking pack usage for recommendations requires careful data handling
- **Content Preferences**: Learning child preferences for personalization must be COPPA-compliant
- **Reviews and Ratings**: Child-generated content requires special protections
- **Cross-Platform Data**: Syncing purchase data across devices needs parental oversight

## Technical Implementation Strategy

### Age Verification and Consent Management

```sql
-- Enhanced COPPA consent tracking for marketplace
CREATE TABLE compliance.marketplace_coppa_consent (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Family and child identification  
    family_id UUID NOT NULL REFERENCES core.families(id),
    child_id UUID NOT NULL REFERENCES core.children(id),
    parent_id UUID NOT NULL REFERENCES core.users(id),
    
    -- Consent specifics for marketplace
    marketplace_purchases_consent BOOLEAN NOT NULL DEFAULT false,
    usage_analytics_consent BOOLEAN NOT NULL DEFAULT false,
    personalization_consent BOOLEAN NOT NULL DEFAULT false,
    content_recommendations_consent BOOLEAN NOT NULL DEFAULT false,
    
    -- Consent verification details
    consent_method VARCHAR(50) NOT NULL, -- 'email_verification', 'sms_verification', 'credit_card_verification'
    verification_token VARCHAR(255),
    verification_completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Consent scope and limitations
    spending_limit_cents INTEGER, -- Parent-set spending limits
    content_categories_allowed TEXT[], -- Restricted content categories
    data_sharing_level VARCHAR(50) DEFAULT 'minimal', -- 'none', 'minimal', 'enhanced'
    
    -- Consent lifecycle
    consent_given_at TIMESTAMP WITH TIME ZONE NOT NULL,
    consent_expires_at TIMESTAMP WITH TIME ZONE, -- For review/renewal
    consent_withdrawn_at TIMESTAMP WITH TIME ZONE,
    
    -- Audit trail
    ip_address INET,
    user_agent TEXT,
    consent_record_hash VARCHAR(64), -- For integrity verification
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Ensure one active consent record per child
CREATE UNIQUE INDEX idx_marketplace_coppa_consent_active 
ON compliance.marketplace_coppa_consent (child_id) 
WHERE consent_withdrawn_at IS NULL;
```

### Purchase Authorization System

```dart
// COPPA-compliant purchase flow
class COPPAMarketplacePurchaseService {
  Future<PurchaseAuthorizationResult> initiatePurchase({
    required String childId,
    required String packId,
    required double amount,
  }) async {
    
    // Step 1: Verify child's COPPA status
    final child = await _childRepository.getChild(childId);
    final coppaStatus = await _coppaService.getMarketplaceConsent(child.id);
    
    if (child.age < 13 && !coppaStatus.hasValidConsent) {
      return PurchaseAuthorizationResult.coppaViolationError(
        message: "Parental consent required for purchases by children under 13"
      );
    }
    
    // Step 2: Check spending limits
    if (coppaStatus.spendingLimitCents != null) {
      final monthlySpent = await _getMonthlySpending(childId);
      if (monthlySpent + (amount * 100) > coppaStatus.spendingLimitCents!) {
        return PurchaseAuthorizationResult.spendingLimitExceeded();
      }
    }
    
    // Step 3: Verify content appropriateness
    final pack = await _packRepository.getPack(packId);
    if (coppaStatus.contentCategoriesAllowed?.isNotEmpty == true) {
      if (!coppaStatus.contentCategoriesAllowed!.contains(pack.primaryCategory)) {
        return PurchaseAuthorizationResult.contentRestricted();
      }
    }
    
    // Step 4: Require additional parental approval for purchases
    final parentalApprovalToken = await _requestParentalApproval(
      childId: childId,
      packId: packId,
      amount: amount,
      parentId: coppaStatus.parentId,
    );
    
    return PurchaseAuthorizationResult.approved(
      authorizationToken: parentalApprovalToken,
      expiresAt: DateTime.now().add(Duration(minutes: 15)),
    );
  }
  
  Future<String> _requestParentalApproval({
    required String childId,
    required String packId,
    required double amount,
    required String parentId,
  }) async {
    
    // Generate secure approval request
    final approvalRequest = ApprovalRequest(
      id: Uuid().v4(),
      childId: childId,
      packId: packId,
      amount: amount,
      parentId: parentId,
      expiresAt: DateTime.now().add(Duration(minutes: 15)),
    );
    
    // Store pending request
    await _approvalRepository.storePendingRequest(approvalRequest);
    
    // Send notification to parent
    await _notificationService.sendPurchaseApprovalRequest(
      parentId: parentId,
      approvalRequest: approvalRequest,
    );
    
    // Return token for verification
    return approvalRequest.id;
  }
}
```

### Data Minimization Implementation

```dart
// Minimal data collection for COPPA compliance
class COPPACompliantAnalyticsService {
  
  Future<void> trackPackUsage({
    required String childId,
    required String packId,
    required String feature,
    required List<String> assetsUsed,
    required int sessionDurationSeconds,
  }) async {
    
    final child = await _childRepository.getChild(childId);
    final coppaConsent = await _coppaService.getMarketplaceConsent(childId);
    
    // Only collect analytics if parents have consented
    if (child.age < 13 && !coppaConsent.usageAnalyticsConsent) {
      Timber.i('Skipping analytics collection - no parental consent for child under 13');
      return;
    }
    
    // Collect minimal necessary data only
    final analyticsEvent = MinimalPackUsageEvent(
      // NO personally identifiable information
      anonymizedChildId: _generateAnonymizedId(childId), // One-way hash
      packCategory: (await _packRepository.getPack(packId)).primaryCategory,
      ageGroup: _getAgeGroup(child.age), // Grouped: "3-5", "6-8", etc.
      sessionDuration: _bucketDuration(sessionDurationSeconds), // Bucketed for privacy
      assetsUsedCount: assetsUsed.length, // Count only, not specific assets
      feature: feature,
      timestamp: DateTime.now().toUtc(),
      
      // NO individual asset IDs
      // NO exact child age
      // NO identifying information
      // NO location data
      // NO device fingerprinting
    );
    
    await _analyticsRepository.recordEvent(analyticsEvent);
  }
  
  String _generateAnonymizedId(String childId) {
    // Create consistent but non-reversible identifier
    return sha256.convert(utf8.encode('$childId:${_saltKey}')).toString();
  }
  
  String _getAgeGroup(int age) {
    // Group ages for privacy protection
    if (age <= 3) return '0-3';
    if (age <= 5) return '4-5';
    if (age <= 7) return '6-7';
    if (age <= 9) return '8-9';
    return '10+';
  }
  
  String _bucketDuration(int seconds) {
    // Bucket session durations to prevent fingerprinting
    if (seconds < 300) return 'short'; // < 5 minutes
    if (seconds < 900) return 'medium'; // 5-15 minutes
    if (seconds < 1800) return 'long'; // 15-30 minutes
    return 'extended'; // 30+ minutes
  }
}
```

## Privacy-by-Design Architecture

### Data Collection Principles

#### 1. Purpose Limitation
```dart
enum DataCollectionPurpose {
  purchaseProcessing,    // Required for transactions
  contentDelivery,       // Required to provide purchased content
  parentalControls,      // Required for COPPA compliance
  basicRecommendations,  // Optional, requires consent
  enhancedPersonalization, // Optional, requires explicit consent
}

class DataCollectionPolicy {
  static bool isCollectionAllowed({
    required int childAge,
    required DataCollectionPurpose purpose,
    required COPPAConsentRecord consent,
  }) {
    // Always allowed purposes (essential for service)
    if (purpose == DataCollectionPurpose.purchaseProcessing ||
        purpose == DataCollectionPurpose.contentDelivery ||
        purpose == DataCollectionPurpose.parentalControls) {
      return true;
    }
    
    // Age-based restrictions
    if (childAge >= 13) {
      return true; // COPPA doesn't apply to 13+
    }
    
    // Under 13 requires specific consent
    switch (purpose) {
      case DataCollectionPurpose.basicRecommendations:
        return consent.contentRecommendationsConsent;
      case DataCollectionPurpose.enhancedPersonalization:
        return consent.personalizationConsent;
      default:
        return false;
    }
  }
}
```

#### 2. Data Minimization
```sql
-- Separate storage for different data sensitivity levels
CREATE SCHEMA marketplace_essential; -- Required data only
CREATE SCHEMA marketplace_analytics; -- Optional analytics data
CREATE SCHEMA marketplace_personalization; -- Enhanced personalization data

-- Essential data (always collected)
CREATE TABLE marketplace_essential.purchases (
    id UUID PRIMARY KEY,
    family_id UUID NOT NULL,
    child_id UUID NOT NULL,
    pack_id UUID NOT NULL,
    amount_cents INTEGER NOT NULL,
    purchase_date TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- No additional tracking data
    -- No usage patterns
    -- No preferences
);

-- Analytics data (consent-dependent)
CREATE TABLE marketplace_analytics.usage_events (
    id UUID PRIMARY KEY,
    anonymized_child_id VARCHAR(64) NOT NULL, -- One-way hash
    pack_category VARCHAR(50) NOT NULL,
    age_group VARCHAR(10) NOT NULL,
    session_bucket VARCHAR(20) NOT NULL,
    event_date DATE NOT NULL, -- Day precision only
    
    -- No personally identifiable information
    -- No exact timestamps
    -- No individual asset tracking
);
```

#### 3. Consent Granularity
```dart
class COPPAConsentManager {
  static const List<ConsentOption> marketplaceConsentOptions = [
    ConsentOption(
      id: 'purchase_basic',
      title: 'Content Pack Purchases',
      description: 'Allow your child to request content pack purchases (requires your approval)',
      required: true,
      category: ConsentCategory.essential,
    ),
    ConsentOption(
      id: 'recommendations_basic',
      title: 'Content Recommendations',
      description: 'Show your child content packs similar to ones they enjoy',
      required: false,
      category: ConsentCategory.optional,
      dataUsed: ['Pack categories used', 'General age group'],
    ),
    ConsentOption(
      id: 'personalization_enhanced',
      title: 'Personalized Experience',
      description: 'Customize the marketplace based on your child\'s interests and learning goals',
      required: false,
      category: ConsentCategory.enhanced,
      dataUsed: ['Educational preferences', 'Usage patterns', 'Content preferences'],
    ),
  ];
  
  Future<void> updateConsent({
    required String childId,
    required Map<String, bool> consentChoices,
    required String parentId,
  }) async {
    
    // Validate parent authority
    await _validateParentAuthorization(parentId, childId);
    
    // Update consent record
    final updatedConsent = await _coppaRepository.updateMarketplaceConsent(
      childId: childId,
      consentChoices: consentChoices,
      parentId: parentId,
    );
    
    // Apply data retention based on consent changes
    await _applyDataRetentionPolicies(childId, updatedConsent);
    
    // Notify relevant services of consent changes
    await _notifyServicesOfConsentChange(childId, updatedConsent);
  }
}
```

## Parental Control Integration

### Enhanced Parental Dashboard
```dart
class MarketplaceCOPPAControls extends StatelessWidget {
  final String childId;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Spending Controls
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text('Monthly Spending Limit'),
                subtitle: Text('Set maximum monthly pack purchases'),
                trailing: DropdownButton<int>(
                  value: currentSpendingLimit,
                  items: [0, 10, 25, 50, 100].map((limit) =>
                    DropdownMenuItem(
                      value: limit,
                      child: Text(limit == 0 ? 'No purchases' : '\$$limit'),
                    )
                  ).toList(),
                  onChanged: _updateSpendingLimit,
                ),
              ),
            ],
          ),
        ),
        
        // Content Restrictions
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text('Content Categories'),
                subtitle: Text('Choose which types of content packs are available'),
              ),
              CheckboxListTile(
                title: Text('Educational Content'),
                value: allowEducational,
                onChanged: _updateContentAllowance,
              ),
              CheckboxListTile(
                title: Text('Creative & Art'),
                value: allowCreative,
                onChanged: _updateContentAllowance,
              ),
              CheckboxListTile(
                title: Text('Characters & Stories'),
                value: allowCharacters,
                onChanged: _updateContentAllowance,
              ),
            ],
          ),
        ),
        
        // Data Collection Preferences
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text('Data & Privacy'),
                subtitle: Text('Control what data is collected about your child'),
              ),
              SwitchListTile(
                title: Text('Content Recommendations'),
                subtitle: Text('Use purchase history to suggest new content'),
                value: allowRecommendations,
                onChanged: _updateDataConsent,
              ),
              SwitchListTile(
                title: Text('Personalized Experience'),
                subtitle: Text('Customize app based on interests and learning goals'),
                value: allowPersonalization,
                onChanged: _updateDataConsent,
              ),
            ],
          ),
        ),
        
        // Purchase History & Analytics
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text('Purchase Activity'),
                subtitle: Text('View and manage your child\'s content purchases'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: _viewPurchaseHistory,
              ),
              ListTile(
                title: Text('Download Data Report'),
                subtitle: Text('Get a copy of all data collected about your child'),
                trailing: Icon(Icons.download),
                onTap: _downloadDataReport,
              ),
              ListTile(
                title: Text('Delete Child Data'),
                subtitle: Text('Permanently remove child\'s marketplace data'),
                trailing: Icon(Icons.delete_forever),
                onTap: _showDeleteConfirmation,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

## Data Retention and Deletion

### Automated Data Lifecycle Management
```sql
-- Automated data retention policies
CREATE OR REPLACE FUNCTION compliance.apply_coppa_data_retention()
RETURNS void AS $$
DECLARE
    child_record RECORD;
BEGIN
    -- Process children who have turned 13 or consent has been withdrawn
    FOR child_record IN 
        SELECT c.id, c.date_of_birth, cc.consent_withdrawn_at
        FROM core.children c
        LEFT JOIN compliance.marketplace_coppa_consent cc ON c.id = cc.child_id
        WHERE (
            -- Child turned 13 more than 6 months ago
            (c.date_of_birth + INTERVAL '13 years 6 months' < NOW())
            OR
            -- Consent was withdrawn more than 30 days ago
            (cc.consent_withdrawn_at IS NOT NULL AND cc.consent_withdrawn_at < NOW() - INTERVAL '30 days')
        )
    LOOP
        -- Archive essential purchase data (keep for legal/financial reasons)
        INSERT INTO compliance.archived_child_purchases
        SELECT * FROM marketplace.user_pack_purchases 
        WHERE child_id = child_record.id;
        
        -- Delete detailed analytics data
        DELETE FROM marketplace.pack_usage_analytics 
        WHERE child_id = child_record.id;
        
        -- Delete personalization data
        DELETE FROM marketplace.user_pack_preferences 
        WHERE child_id = child_record.id;
        
        -- Anonymize reviews (keep for aggregate ratings)
        UPDATE marketplace.pack_reviews 
        SET family_id = NULL, parent_id = NULL, review_text = NULL, review_title = NULL
        WHERE family_id IN (SELECT family_id FROM core.children WHERE id = child_record.id);
        
        -- Log data deletion
        INSERT INTO compliance.data_deletion_log (
            child_id, 
            deletion_reason, 
            data_types_deleted, 
            deleted_at
        ) VALUES (
            child_record.id,
            CASE 
                WHEN child_record.consent_withdrawn_at IS NOT NULL THEN 'consent_withdrawn'
                ELSE 'age_out'
            END,
            ARRAY['analytics', 'personalization', 'detailed_reviews'],
            NOW()
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Schedule automated retention policy execution
SELECT cron.schedule('coppa-data-retention', '0 2 * * *', 'SELECT compliance.apply_coppa_data_retention();');
```

### Parent-Requested Data Deletion
```dart
class COPPADataDeletionService {
  Future<DataDeletionResult> requestChildDataDeletion({
    required String childId,
    required String parentId,
    required String deletionReason,
  }) async {
    
    // Verify parental authority
    await _validateParentAuthorization(parentId, childId);
    
    // Create deletion request record
    final deletionRequest = DataDeletionRequest(
      id: Uuid().v4(),
      childId: childId,
      parentId: parentId,
      requestedAt: DateTime.now(),
      reason: deletionReason,
      status: DeletionStatus.pending,
    );
    
    await _deletionRepository.createRequest(deletionRequest);
    
    // Start deletion process (may take up to 30 days for complete removal)
    await _initiateDataDeletion(deletionRequest);
    
    // Notify parent of deletion timeline
    await _notificationService.sendDeletionConfirmation(
      parentId: parentId,
      estimatedCompletionDate: DateTime.now().add(Duration(days: 30)),
    );
    
    return DataDeletionResult.success(
      requestId: deletionRequest.id,
      estimatedCompletionDate: DateTime.now().add(Duration(days: 30)),
    );
  }
  
  Future<void> _initiateDataDeletion(DataDeletionRequest request) async {
    
    // Immediate actions (soft delete, stop data collection)
    await _stopDataCollection(request.childId);
    await _softDeletePersonalData(request.childId);
    
    // Schedule hard deletion after grace period
    await _scheduleHardDeletion(request);
    
    // Notify all systems to stop processing this child's data
    await _broadcastDataDeletionNotice(request.childId);
  }
}
```

## Legal and Regulatory Compliance

### Documentation and Audit Trail
```sql
-- Comprehensive audit logging for COPPA compliance
CREATE TABLE compliance.coppa_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Event identification
    event_type VARCHAR(100) NOT NULL, -- 'consent_given', 'consent_withdrawn', 'data_accessed', 'data_deleted'
    event_description TEXT NOT NULL,
    
    -- Subject information
    child_id UUID,
    family_id UUID,
    parent_id UUID,
    
    -- Event details
    event_data JSONB, -- Structured data about the event
    
    -- Context
    ip_address INET,
    user_agent TEXT,
    session_id UUID,
    
    -- Legal compliance
    legal_basis VARCHAR(100), -- 'parental_consent', 'legitimate_interest', 'contract_performance'
    data_categories TEXT[], -- Types of data involved
    
    -- Timestamps
    event_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    -- Integrity
    event_hash VARCHAR(64) NOT NULL -- Hash of event data for integrity verification
);

-- Index for audit queries
CREATE INDEX idx_coppa_audit_log_child ON compliance.coppa_audit_log (child_id, event_timestamp);
CREATE INDEX idx_coppa_audit_log_type ON compliance.coppa_audit_log (event_type, event_timestamp);
```

### Regulatory Reporting
```dart
class COPPAComplianceReporting {
  Future<ComplianceReport> generateComplianceReport({
    required DateRange dateRange,
    required ReportType reportType,
  }) async {
    
    switch (reportType) {
      case ReportType.dataCollection:
        return _generateDataCollectionReport(dateRange);
      case ReportType.consentManagement:
        return _generateConsentReport(dateRange);
      case ReportType.incidentResponse:
        return _generateIncidentReport(dateRange);
      case ReportType.dataRetention:
        return _generateRetentionReport(dateRange);
    }
  }
  
  Future<DataCollectionReport> _generateDataCollectionReport(DateRange dateRange) async {
    
    final report = DataCollectionReport(
      reportPeriod: dateRange,
      generatedAt: DateTime.now(),
    );
    
    // Count of children under 13 with marketplace data
    report.childrenUnder13Count = await _getChildrenUnder13Count();
    
    // Types of data collected
    report.dataTypesCollected = [
      DataType(
        type: 'Purchase History',
        purpose: 'Transaction Processing',
        legalBasis: 'Contract Performance',
        retentionPeriod: '7 years (financial records)',
      ),
      DataType(
        type: 'Usage Analytics',
        purpose: 'Content Recommendations',
        legalBasis: 'Parental Consent',
        retentionPeriod: '2 years or until consent withdrawn',
      ),
    ];
    
    // Consent statistics
    report.consentStats = await _getConsentStatistics(dateRange);
    
    // Data deletion requests
    report.deletionRequests = await _getDeletionRequestStats(dateRange);
    
    return report;
  }
}
```

## Incident Response and Breach Management

### Data Breach Response Protocol
```dart
class COPPAIncidentResponse {
  Future<void> handlePotentialDataBreach({
    required String incidentId,
    required IncidentSeverity severity,
    required List<String> affectedChildIds,
    required String description,
  }) async {
    
    // Immediate response actions
    await _containIncident(incidentId);
    await _assessImpact(affectedChildIds);
    
    // COPPA-specific breach handling
    for (String childId in affectedChildIds) {
      final child = await _childRepository.getChild(childId);
      
      if (child.age < 13) {
        // Enhanced notification requirements for children under 13
        await _notifyParentsOfBreach(
          childId: childId,
          incidentDetails: description,
          dataTypesAffected: await _identifyAffectedDataTypes(childId),
          mitigationSteps: await _getMitigationSteps(),
        );
        
        // Regulatory notification if required
        if (severity >= IncidentSeverity.high) {
          await _notifyFTCOfBreach(incidentId, childId, description);
        }
      }
    }
    
    // Document incident for compliance
    await _documentIncident(incidentId, affectedChildIds, description);
  }
  
  Future<void> _notifyParentsOfBreach({
    required String childId,
    required String incidentDetails,
    required List<String> dataTypesAffected,
    required List<String> mitigationSteps,
  }) async {
    
    final family = await _familyRepository.getFamilyForChild(childId);
    final parents = await _familyRepository.getParents(family.id);
    
    for (final parent in parents) {
      await _emailService.sendBreachNotification(
        recipientEmail: parent.email,
        templateId: 'coppa_breach_notification',
        templateData: {
          'childName': (await _childRepository.getChild(childId)).name,
          'incidentDate': DateTime.now().toIso8601String(),
          'dataTypesAffected': dataTypesAffected,
          'mitigationSteps': mitigationSteps,
          'contactInfo': _getIncidentResponseContactInfo(),
        },
      );
    }
  }
}
```

This comprehensive COPPA compliance strategy ensures that the Content Packs Marketplace operates within legal requirements while providing a safe, privacy-protected experience for children and transparency for parents.
# Game-Marketplace Integration: Technical Architecture

## 1. Content Discovery for Games

### Content Pack Discovery API
Games access marketplace content through a standardized API that respects child privacy and parental controls:

```dart
// Core service for game-marketplace integration
abstract class GameContentService {
  /// Get available content packs for a specific child and game
  Future<List<ContentPack>> getAvailableContentPacks({
    required String childId,
    required String gameId,
    ContentPackFilter? filter,
  });

  /// Check if specific content pack is accessible
  Future<bool> isContentPackAccessible({
    required String childId,
    required String contentPackId,
  });

  /// Get content pack metadata for game integration
  Future<ContentPackManifest?> getContentPackManifest(String contentPackId);

  /// Download and cache content pack assets
  Future<ContentPackAssets> downloadContentPack({
    required String childId,
    required String contentPackId,
    ProgressCallback? onProgress,
  });

  /// Get cached/offline content packs
  Future<List<String>> getOfflineContentPacks(String childId);
}
```

### Content Pack Manifest Structure
Content packs include comprehensive metadata for seamless game integration:

```dart
class ContentPackManifest {
  final String id;
  final String title;
  final String description;
  final String gameCompatibility; // Game ID or "universal"
  
  // Educational metadata
  final List<String> learningObjectives;
  final List<String> skillAreas;
  final AgeRange targetAgeRange;
  final DifficultyLevel difficultyLevel;
  
  // Technical specifications
  final ContentPackType type;
  final List<AssetDefinition> assets;
  final Map<String, dynamic> gameIntegrationData;
  final String minimumGameVersion;
  
  // Access and licensing
  final ContentPackLicense license;
  final bool requiresParentApproval;
  final List<String> prerequisites; // Other content pack IDs
  
  // Usage analytics (privacy-compliant)
  final bool allowsUsageTracking;
  final bool allowsProgressTracking;
  
  ContentPackManifest({
    required this.id,
    required this.title,
    required this.description,
    required this.gameCompatibility,
    required this.learningObjectives,
    required this.skillAreas,
    required this.targetAgeRange,
    required this.difficultyLevel,
    required this.type,
    required this.assets,
    required this.gameIntegrationData,
    required this.minimumGameVersion,
    required this.license,
    this.requiresParentApproval = true,
    this.prerequisites = const [],
    this.allowsUsageTracking = false,
    this.allowsProgressTracking = true,
  });
}

enum ContentPackType {
  storyPack,      // Stories and narratives
  activityPack,   // Interactive activities
  characterPack,  // Characters and avatars
  themePack,      // Visual themes and environments
  skillPack,      // Skill-building exercises
  multiPack       // Combined content types
}

class AssetDefinition {
  final String id;
  final String filename;
  final String type; // image, audio, video, data, config
  final int sizeBytes;
  final String checksum; // For integrity verification
  final bool required;
  final Map<String, String> metadata;
  
  AssetDefinition({
    required this.id,
    required this.filename,
    required this.type,
    required this.sizeBytes,
    required this.checksum,
    this.required = true,
    this.metadata = const {},
  });
}
```

### Secure Asset Loading Pattern
Content packs use signed URLs with temporary access for security:

```dart
class ContentPackAssets {
  final String contentPackId;
  final String localPath;
  final Map<String, String> assetPaths; // assetId -> local file path
  final DateTime downloadedAt;
  final DateTime expiresAt;
  final bool isOfflineAvailable;
  
  /// Get asset by ID with fallback to online if needed
  Future<String?> getAssetPath(String assetId) async {
    if (assetPaths.containsKey(assetId)) {
      final path = assetPaths[assetId]!;
      if (await File(path).exists()) {
        return path;
      }
    }
    
    // Fallback to online asset with signed URL
    if (!isOfflineAvailable) {
      return await _requestSignedAssetUrl(assetId);
    }
    
    return null;
  }
  
  /// Preload assets for smooth gameplay
  Future<void> preloadAssets(List<String> assetIds) async {
    for (final assetId in assetIds) {
      await _preloadAsset(assetId);
    }
  }
  
  Future<String?> _requestSignedAssetUrl(String assetId) async {
    // Request signed URL from backend with child authentication
    // URLs expire after 1 hour for security
    return await GameContentService.instance.getSignedAssetUrl(
      contentPackId: contentPackId,
      assetId: assetId,
    );
  }
}
```

## 2. Child-Friendly Content Management

### In-Game Content Discovery Widget
A child-friendly interface that appears naturally within games:

```dart
class InGameContentDiscoveryWidget extends ConsumerStatefulWidget {
  final String gameId;
  final String childId;
  final ContentDiscoveryContext context;
  
  const InGameContentDiscoveryWidget({
    Key? key,
    required this.gameId,
    required this.childId,
    required this.context,
  }) : super(key: key);

  @override
  ConsumerState<InGameContentDiscoveryWidget> createState() => 
      _InGameContentDiscoveryWidgetState();
}

class _InGameContentDiscoveryWidgetState 
    extends ConsumerState<InGameContentDiscoveryWidget> 
    with TickerProviderStateMixin {
    
  late AnimationController _celebrationController;
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final availableContent = ref.watch(
      availableContentForChildProvider(widget.childId)
    );
    
    return availableContent.when(
      data: (contentPacks) => _buildContentDiscovery(contentPacks),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(),
    );
  }
  
  Widget _buildContentDiscovery(List<ContentPack> contentPacks) {
    if (contentPacks.isEmpty) {
      return SizedBox.shrink(); // No content, no widget
    }
    
    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Celebration header for new content
          if (_hasNewContent(contentPacks))
            _buildCelebrationHeader(),
            
          // Content cards
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: contentPacks.length,
              itemBuilder: (context, index) => 
                  _buildContentCard(contentPacks[index]),
            ),
          ),
          
          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }
  
  Widget _buildContentCard(ContentPack contentPack) {
    return Container(
      width: 140,
      margin: EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            contentPack.themeColor.withOpacity(0.8),
            contentPack.themeColor.withOpacity(0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: contentPack.themeColor.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showContentPreview(contentPack),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Content preview image
                Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: contentPack.previewImage != null
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(
                              contentPack.previewImage!
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: contentPack.previewImage == null
                      ? Icon(
                          contentPack.type.icon,
                          size: 40,
                          color: Colors.white,
                        )
                      : null,
                ),
                
                SizedBox(height: 8),
                
                // Title
                Text(
                  contentPack.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: 4),
                
                // Learning objectives
                Expanded(
                  child: Text(
                    contentPack.primaryLearningObjective,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Status indicator
                if (contentPack.isNew)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'NEW!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showContentPreview(ContentPack contentPack) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContentPreviewSheet(
        contentPack: contentPack,
        childId: widget.childId,
        onRequestAccess: () => _requestParentApproval(contentPack),
      ),
    );
  }
  
  void _requestParentApproval(ContentPack contentPack) {
    // Show child-friendly message about asking parent
    showDialog(
      context: context,
      builder: (context) => ChildFriendlyDialog(
        title: "Ask a Grown-Up!",
        content: "This looks like fun! Ask your parent or guardian to unlock this for you.",
        illustration: "assets/illustrations/ask_parent.svg",
        primaryAction: ChildFriendlyAction(
          text: "Got it!",
          onPressed: () {
            Navigator.of(context).pop();
            // Send notification to parent app
            ref.read(parentNotificationServiceProvider).sendContentRequest(
              childId: widget.childId,
              contentPackId: contentPack.id,
            );
          },
        ),
      ),
    );
  }
}
```

### Content Organization System
Children can organize their content into collections with parent guidance:

```dart
class ChildLibraryOrganizer extends ConsumerWidget {
  final String childId;
  
  const ChildLibraryOrganizer({Key? key, required this.childId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childLibrary = ref.watch(childLibraryProvider(childId));
    
    return childLibrary.when(
      data: (library) => _buildLibraryView(library, ref),
      loading: () => LibraryLoadingShimmer(),
      error: (error, stack) => LibraryErrorView(),
    );
  }
  
  Widget _buildLibraryView(ChildLibrary library, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        // Continue playing section
        SliverToBoxAdapter(
          child: _buildContinuePlayingSection(library.recentContent),
        ),
        
        // Collections
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final collection = library.collections[index];
              return _buildCollectionTile(collection, ref);
            },
            childCount: library.collections.length,
          ),
        ),
        
        // All content grid
        SliverPadding(
          padding: EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final content = library.allContent[index];
                return _buildContentTile(content, ref);
              },
              childCount: library.allContent.length,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCollectionTile(ContentCollection collection, WidgetRef ref) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: collection.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openCollection(collection),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: collection.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    collection.icon,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                
                SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        collection.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      SizedBox(height: 4),
                      
                      Text(
                        '${collection.itemCount} items',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (collection.hasNewContent)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

## 3. Educational Integration Patterns

### Achievement-Based Content Unlocks
Content becomes available through educational achievements rather than purchases:

```dart
class ContentUnlockSystem {
  /// Check if child has earned access to content through achievements
  static Future<bool> checkContentUnlockEligibility({
    required String childId,
    required String contentPackId,
  }) async {
    final achievements = await AchievementService.getChildAchievements(childId);
    final contentPack = await ContentService.getContentPack(contentPackId);
    
    // Check achievement prerequisites
    for (final requirement in contentPack.unlockRequirements) {
      if (!_hasMetRequirement(achievements, requirement)) {
        return false;
      }
    }
    
    return true;
  }
  
  static bool _hasMetRequirement(
    List<Achievement> achievements, 
    UnlockRequirement requirement
  ) {
    switch (requirement.type) {
      case RequirementType.achievementUnlock:
        return achievements.any((a) => a.id == requirement.achievementId);
        
      case RequirementType.skillLevel:
        final skill = achievements
            .where((a) => a.skillArea == requirement.skillArea)
            .fold<int>(0, (max, a) => math.max(max, a.level));
        return skill >= requirement.minimumLevel;
        
      case RequirementType.completionCount:
        final completions = achievements
            .where((a) => a.category == requirement.category)
            .length;
        return completions >= requirement.minimumCount;
        
      case RequirementType.parentApproval:
        return ParentApprovalService.hasApproval(
          childId: requirement.childId,
          contentPackId: requirement.contentPackId,
        );
    }
  }
}

class UnlockRequirement {
  final RequirementType type;
  final String? achievementId;
  final String? skillArea;
  final int? minimumLevel;
  final String? category;
  final int? minimumCount;
  final String? childId;
  final String? contentPackId;
  
  UnlockRequirement({
    required this.type,
    this.achievementId,
    this.skillArea,
    this.minimumLevel,
    this.category,
    this.minimumCount,
    this.childId,
    this.contentPackId,
  });
}

enum RequirementType {
  achievementUnlock,
  skillLevel,
  completionCount,
  parentApproval,
}
```

### Progress Integration System
Content pack usage integrates with broader educational progress tracking:

```dart
class EducationalProgressIntegration {
  /// Track progress made within marketplace content
  static Future<void> recordContentProgress({
    required String childId,
    required String contentPackId,
    required ProgressData progress,
  }) async {
    final contentPack = await ContentService.getContentPack(contentPackId);
    
    // Map content progress to educational objectives
    for (final objective in contentPack.learningObjectives) {
      await _recordObjectiveProgress(childId, objective, progress);
    }
    
    // Update skill areas
    for (final skillArea in contentPack.skillAreas) {
      await _updateSkillProgress(childId, skillArea, progress);
    }
    
    // Check for new achievements
    await _checkAchievementTriggers(childId, contentPackId, progress);
    
    // Generate insights for parents
    await _generateProgressInsights(childId, contentPack, progress);
  }
  
  static Future<void> _recordObjectiveProgress(
    String childId,
    LearningObjective objective,
    ProgressData progress,
  ) async {
    final objectiveProgress = ObjectiveProgress(
      childId: childId,
      objectiveId: objective.id,
      progressValue: progress.completionPercentage,
      skillsDemonstrated: progress.skillsDemonstrated,
      timeSpent: progress.timeSpent,
      timestamp: DateTime.now(),
    );
    
    await ProgressTrackingService.recordObjectiveProgress(objectiveProgress);
  }
  
  static Future<void> _generateProgressInsights(
    String childId,
    ContentPack contentPack,
    ProgressData progress,
  ) async {
    final insights = <ProgressInsight>[];
    
    // Skill development insights
    for (final skill in progress.skillsDemonstrated) {
      if (skill.showsImprovement) {
        insights.add(ProgressInsight(
          type: InsightType.skillImprovement,
          message: 'Great progress in ${skill.name}!',
          evidence: skill.evidenceData,
          contentSource: contentPack.title,
        ));
      }
    }
    
    // Learning pattern insights
    if (progress.engagementLevel > 0.8) {
      insights.add(ProgressInsight(
        type: InsightType.highEngagement,
        message: '${contentPack.title} really captured their attention',
        metrics: {'engagement': progress.engagementLevel},
      ));
    }
    
    await ParentInsightService.addInsights(childId, insights);
  }
}
```

## 4. COPPA-Compliant Game Features

### Parental Consent Flow for Content Access
All content access requires explicit parental approval:

```dart
class ParentApprovalSystem {
  /// Request parental approval for content pack access
  static Future<ApprovalStatus> requestContentApproval({
    required String childId,
    required String contentPackId,
    required ContentAccessContext context,
  }) async {
    // Check if approval already exists
    final existingApproval = await _getExistingApproval(childId, contentPackId);
    if (existingApproval?.isValid == true) {
      return ApprovalStatus.approved;
    }
    
    // Create approval request
    final request = ContentApprovalRequest(
      id: Uuid().v4(),
      childId: childId,
      contentPackId: contentPackId,
      requestContext: context,
      requestedAt: DateTime.now(),
      status: ApprovalRequestStatus.pending,
    );
    
    await ApprovalRequestService.createRequest(request);
    
    // Notify parents through multiple channels
    await _notifyParents(request);
    
    return ApprovalStatus.pending;
  }
  
  static Future<void> _notifyParents(ContentApprovalRequest request) async {
    final parents = await FamilyService.getParents(request.childId);
    final contentPack = await ContentService.getContentPack(request.contentPackId);
    
    for (final parent in parents) {
      // In-app notification
      await NotificationService.sendNotification(
        userId: parent.id,
        notification: ContentApprovalNotification(
          childName: request.childProfile.name,
          contentTitle: contentPack.title,
          contentDescription: contentPack.description,
          educationalBenefits: contentPack.learningObjectives,
          approvalUrl: _generateApprovalUrl(request),
        ),
      );
      
      // Email notification (if enabled)
      if (parent.notificationPreferences.emailEnabled) {
        await EmailService.sendContentApprovalEmail(
          parentEmail: parent.email,
          request: request,
          contentPack: contentPack,
        );
      }
      
      // Push notification (if enabled)
      if (parent.notificationPreferences.pushEnabled) {
        await PushNotificationService.sendContentApproval(
          parentDeviceToken: parent.deviceToken,
          childName: request.childProfile.name,
          contentTitle: contentPack.title,
        );
      }
    }
  }
  
  /// Parent approval interface
  static Widget buildApprovalInterface({
    required ContentApprovalRequest request,
    required VoidCallback onApprove,
    required VoidCallback onDeny,
  }) {
    return ParentApprovalScreen(
      request: request,
      child: Column(
        children: [
          // Content preview
          ContentPreviewCard(contentPack: request.contentPack),
          
          SizedBox(height: 24),
          
          // Educational value section
          EducationalValueSection(
            objectives: request.contentPack.learningObjectives,
            skillAreas: request.contentPack.skillAreas,
            ageAppropriateness: request.contentPack.ageAppropriateness,
          ),
          
          SizedBox(height: 24),
          
          // Privacy and safety info
          PrivacySafetySection(
            dataCollection: request.contentPack.dataCollectionPolicy,
            contentModeration: request.contentPack.moderationStatus,
            creatorInfo: request.contentPack.creatorProfile,
          ),
          
          SizedBox(height: 24),
          
          // Cost and licensing
          if (request.contentPack.price > 0)
            CostLicensingSection(
              price: request.contentPack.price,
              license: request.contentPack.license,
              familySharing: request.contentPack.familySharing,
            ),
          
          SizedBox(height: 32),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDeny,
                  child: Text('Not Right Now'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              
              SizedBox(width: 16),
              
              Expanded(
                child: ElevatedButton(
                  onPressed: onApprove,
                  child: Text('Approve Access'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### Privacy-Protected Progress Sharing
Progress data focuses on educational outcomes without personal information:

```dart
class PrivacyCompliantAnalytics {
  /// Record educational progress without PII
  static Future<void> recordEducationalProgress({
    required String anonymizedChildId, // Hashed, not reversible to real ID
    required String contentPackId,
    required EducationalMetrics metrics,
  }) async {
    final progressRecord = AnonymizedProgressRecord(
      sessionId: Uuid().v4(),
      anonymizedChildId: anonymizedChildId,
      contentPackId: contentPackId,
      
      // Educational metrics only
      learningObjectivesAttempted: metrics.objectivesAttempted,
      learningObjectivesCompleted: metrics.objectivesCompleted,
      skillsImproved: metrics.skillsImproved,
      engagementLevel: metrics.engagementLevel,
      difficultyProgression: metrics.difficultyProgression,
      
      // Time-based metrics (no specific times, just durations)
      sessionDurationMinutes: metrics.sessionDuration.inMinutes,
      totalTimeSpentMinutes: metrics.totalTimeSpent.inMinutes,
      
      // Performance metrics
      accuracyRate: metrics.accuracyRate,
      completionRate: metrics.completionRate,
      hintsUsed: metrics.hintsUsed,
      
      // NO personal identifiers, names, or specific content details
      timestamp: DateTime.now(),
    );
    
    await AnalyticsService.recordAnonymizedProgress(progressRecord);
    
    // Generate insights for parents (re-identified at parent app level)
    await _generateParentInsights(contentPackId, metrics);
  }
  
  /// Generate educational insights for parents
  static Future<void> _generateParentInsights(
    String contentPackId,
    EducationalMetrics metrics,
  ) async {
    final insights = <ParentInsight>[];
    
    // Achievement insights
    if (metrics.objectivesCompleted.isNotEmpty) {
      insights.add(ParentInsight(
        type: InsightType.learningMilestone,
        title: 'Learning Milestone Reached!',
        description: 'Your child completed ${metrics.objectivesCompleted.length} learning objectives',
        educationalValue: metrics.objectivesCompleted,
        contentSource: contentPackId,
      ));
    }
    
    // Skill development insights
    for (final skill in metrics.skillsImproved) {
      insights.add(ParentInsight(
        type: InsightType.skillDevelopment,
        title: '${skill.name} Skills Growing',
        description: 'Shows improvement in ${skill.specificAreas.join(", ")}',
        evidence: skill.improvementEvidence,
      ));
    }
    
    // Engagement insights
    if (metrics.engagementLevel > 0.8) {
      insights.add(ParentInsight(
        type: InsightType.highEngagement,
        title: 'Highly Engaged Content',
        description: 'This content really captured their attention and interest',
        recommendations: _generateEngagementRecommendations(contentPackId),
      ));
    }
    
    await ParentInsightService.queueInsights(insights);
  }
}
```

## 5. Technical Plugin Architecture

### ContentAwareGamePlugin Base Class
Extended game plugin interface for marketplace integration:

```dart
abstract class ContentAwareGamePlugin extends GamePlugin {
  /// Get supported content pack types for this game
  List<ContentPackType> get supportedContentTypes;
  
  /// Get content integration points within the game
  List<ContentIntegrationPoint> get integrationPoints;
  
  /// Validate content pack compatibility
  Future<bool> isContentPackCompatible(ContentPackManifest manifest);
  
  /// Load content pack into game
  Future<void> loadContentPack({
    required String contentPackId,
    required ContentPackAssets assets,
    ContentLoadingContext? context,
  });
  
  /// Unload content pack from game
  Future<void> unloadContentPack(String contentPackId);
  
  /// Get currently loaded content packs
  List<String> getLoadedContentPacks();
  
  /// Handle content pack updates
  Future<void> updateContentPack({
    required String contentPackId,
    required ContentPackAssets newAssets,
  });
  
  /// Get content integration UI widget
  Widget buildContentIntegrationUI({
    required BuildContext context,
    required ChildProfile child,
    required ContentIntegrationPoint integrationPoint,
  });
  
  /// Handle content unlock events
  Future<void> onContentUnlocked({
    required String contentPackId,
    required ContentUnlockContext context,
  });
  
  /// Generate content usage analytics
  Future<ContentUsageMetrics> generateUsageMetrics(String contentPackId);
}

class ContentIntegrationPoint {
  final String id;
  final String name;
  final String description;
  final ContentIntegrationType type;
  final Map<String, dynamic> configuration;
  final bool requiresParentApproval;
  
  ContentIntegrationPoint({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.configuration = const {},
    this.requiresParentApproval = true,
  });
}

enum ContentIntegrationType {
  menuItem,        // Add new menu options
  characterSkin,   // New character appearances
  environment,     // New game environments
  activity,        // New activities or mini-games
  story,          // New story content
  achievement,    // New achievements
  item,          // New in-game items
  skill,         // New skill challenges
}
```

### Asset Loading and Caching System
Efficient content delivery with offline support:

```dart
class GameContentCacheManager {
  static const String _cacheDirectory = 'game_content_cache';
  static final Map<String, ContentPackCache> _activeCaches = {};
  
  /// Get content pack with automatic caching
  static Future<ContentPackAssets?> getContentPack({
    required String childId,
    required String contentPackId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${childId}_$contentPackId';
    
    // Check active cache first
    if (!forceRefresh && _activeCaches.containsKey(cacheKey)) {
      final cache = _activeCaches[cacheKey]!;
      if (!cache.isExpired) {
        return cache.assets;
      }
    }
    
    // Check disk cache
    final diskCache = await _loadFromDiskCache(cacheKey);
    if (diskCache != null && !diskCache.isExpired && !forceRefresh) {
      _activeCaches[cacheKey] = diskCache;
      return diskCache.assets;
    }
    
    // Download fresh content
    return await _downloadAndCache(childId, contentPackId);
  }
  
  static Future<ContentPackAssets?> _downloadAndCache(
    String childId,
    String contentPackId,
  ) async {
    try {
      // Get download URLs from backend
      final downloadInfo = await GameContentService.instance
          .getContentPackDownloadInfo(
        childId: childId,
        contentPackId: contentPackId,
      );
      
      if (downloadInfo == null) return null;
      
      // Create local cache directory
      final cacheDir = await _createCacheDirectory(childId, contentPackId);
      
      // Download and verify assets
      final assetPaths = <String, String>{};
      for (final asset in downloadInfo.assets) {
        final localPath = await _downloadAsset(
          asset: asset,
          targetDirectory: cacheDir,
        );
        
        if (localPath != null) {
          assetPaths[asset.id] = localPath;
        }
      }
      
      // Create assets object
      final assets = ContentPackAssets(
        contentPackId: contentPackId,
        localPath: cacheDir.path,
        assetPaths: assetPaths,
        downloadedAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: 30)),
        isOfflineAvailable: true,
      );
      
      // Cache in memory and disk
      final cache = ContentPackCache(
        assets: assets,
        cachedAt: DateTime.now(),
        expiresAt: assets.expiresAt,
      );
      
      _activeCaches['${childId}_$contentPackId'] = cache;
      await _saveToDiskCache('${childId}_$contentPackId', cache);
      
      return assets;
      
    } catch (e, stackTrace) {
      Timber.e('Failed to download content pack $contentPackId: $e', 
               stackTrace: stackTrace);
      return null;
    }
  }
  
  static Future<String?> _downloadAsset({
    required AssetDownloadInfo asset,
    required Directory targetDirectory,
  }) async {
    try {
      final response = await Dio().download(
        asset.signedUrl,
        '${targetDirectory.path}/${asset.filename}',
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            ContentDownloadNotifier.updateProgress(asset.id, progress);
          }
        },
      );
      
      if (response.statusCode == 200) {
        final file = File('${targetDirectory.path}/${asset.filename}');
        
        // Verify file integrity
        final actualChecksum = await _calculateChecksum(file);
        if (actualChecksum == asset.expectedChecksum) {
          return file.path;
        } else {
          Timber.w('Checksum mismatch for asset ${asset.id}');
          await file.delete();
          return null;
        }
      }
      
      return null;
      
    } catch (e, stackTrace) {
      Timber.e('Failed to download asset ${asset.id}: $e', 
               stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Preload content packs for smooth gameplay
  static Future<void> preloadContentPacks({
    required String childId,
    required List<String> contentPackIds,
  }) async {
    for (final contentPackId in contentPackIds) {
      await getContentPack(
        childId: childId,
        contentPackId: contentPackId,
      );
    }
  }
  
  /// Clean up expired cache entries
  static Future<void> cleanupCache() async {
    final expiredKeys = _activeCaches.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();
    
    for (final key in expiredKeys) {
      _activeCaches.remove(key);
      await _removeFromDiskCache(key);
    }
  }
  
  /// Get cache storage size
  static Future<int> getCacheSize() async {
    final cacheDir = await _getCacheBaseDirectory();
    if (!cacheDir.existsSync()) return 0;
    
    int totalSize = 0;
    await for (final entity in cacheDir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    
    return totalSize;
  }
}

class ContentPackCache {
  final ContentPackAssets assets;
  final DateTime cachedAt;
  final DateTime expiresAt;
  
  ContentPackCache({
    required this.assets,
    required this.cachedAt,
    required this.expiresAt,
  });
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());
}
```

This comprehensive architecture provides:

1. **Secure Content Discovery**: Games can safely query available content with full COPPA compliance
2. **Child-Friendly Interfaces**: Content discovery feels natural and educational rather than commercial
3. **Educational Integration**: Marketplace content enhances learning objectives and tracks meaningful progress
4. **Privacy Protection**: All data collection focuses on educational outcomes with parental oversight
5. **Technical Excellence**: Robust caching, offline support, and plugin architecture for scalable integration

The system transforms marketplace content from external purchases into natural educational progression within games, maintaining child safety while driving platform engagement and creator revenue.
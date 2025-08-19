import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/child_profile.dart';
import '../../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'game_plugin.dart';
import 'game_persistence.dart';

/// Manages parent approval flow for games and content
class ParentApprovalManager {
  static final ParentApprovalManager _instance = ParentApprovalManager._internal();
  factory ParentApprovalManager() => _instance;
  ParentApprovalManager._internal();

  final GamePersistenceManager _persistence = GamePersistenceManager();
  final Map<String, ApprovalRequest> _pendingRequests = {};

  /// Request parent approval for a game
  Future<ApprovalResult> requestGameApproval({
    required String gameId,
    required String childId,
    required GamePlugin game,
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    // Check if game is already approved
    if (await isGameApproved(gameId, childId)) {
      return ApprovalResult.approved();
    }

    // Check if there's a pending request
    final requestKey = '${gameId}_$childId';
    if (_pendingRequests.containsKey(requestKey)) {
      return ApprovalResult.pending(_pendingRequests[requestKey]!);
    }

    // Create new approval request
    final request = ApprovalRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      gameId: gameId,
      childId: childId,
      gameName: game.gameName,
      gameDescription: game.gameDescription,
      category: game.category,
      minAge: game.minAge,
      maxAge: game.maxAge,
      educationalTopics: game.educationalTopics,
      requestedAt: DateTime.now(),
      status: ApprovalStatus.pending,
    );

    _pendingRequests[requestKey] = request;

    // Save request for persistence
    await _saveApprovalRequest(request);

    // Show approval dialog or navigate to approval screen
    if (context.mounted) {
      final result = await _showApprovalDialog(context, ref, request, game);
      
      if (result != null) {
        await _processApprovalResponse(request, result);
        _pendingRequests.remove(requestKey);
        return result;
      }
    }

    return ApprovalResult.pending(request);
  }

  /// Check if a game is approved for a child
  Future<bool> isGameApproved(String gameId, String childId) async {
    // Check local approval cache first
    final approvals = await _loadGameApprovals(childId);
    return approvals[gameId]?.isApproved ?? false;
  }

  /// Get all pending approval requests for a parent
  Future<List<ApprovalRequest>> getPendingRequests(String parentId) async {
    // This would typically load from API
    return _pendingRequests.values
        .where((request) => request.status == ApprovalStatus.pending)
        .toList();
  }

  /// Approve a game request
  Future<void> approveGame({
    required String requestId,
    required String reason,
    Map<String, dynamic>? restrictions,
  }) async {
    final request = _findRequestById(requestId);
    if (request == null) return;

    final approval = GameApproval(
      gameId: request.gameId,
      childId: request.childId,
      isApproved: true,
      approvedAt: DateTime.now(),
      reason: reason,
      restrictions: restrictions,
    );

    await _saveGameApproval(approval);
    
    // Update request status
    request.status = ApprovalStatus.approved;
    request.approvedAt = DateTime.now();
    request.parentResponse = reason;

    await _updateApprovalRequest(request);
  }

  /// Reject a game request
  Future<void> rejectGame({
    required String requestId,
    required String reason,
  }) async {
    final request = _findRequestById(requestId);
    if (request == null) return;

    final approval = GameApproval(
      gameId: request.gameId,
      childId: request.childId,
      isApproved: false,
      approvedAt: DateTime.now(),
      reason: reason,
    );

    await _saveGameApproval(approval);
    
    // Update request status
    request.status = ApprovalStatus.rejected;
    request.approvedAt = DateTime.now();
    request.parentResponse = reason;

    await _updateApprovalRequest(request);
  }

  /// Get game restrictions for a child
  Future<Map<String, dynamic>?> getGameRestrictions(String gameId, String childId) async {
    final approvals = await _loadGameApprovals(childId);
    return approvals[gameId]?.restrictions;
  }

  /// Check if child can access a specific game feature
  Future<bool> canAccessFeature({
    required String gameId,
    required String childId,
    required String featureName,
  }) async {
    final restrictions = await getGameRestrictions(gameId, childId);
    if (restrictions == null) return true;

    final blockedFeatures = restrictions['blockedFeatures'] as List<dynamic>? ?? [];
    return !blockedFeatures.contains(featureName);
  }

  /// Get time restrictions for a game
  Future<TimeRestriction?> getTimeRestrictions(String gameId, String childId) async {
    final restrictions = await getGameRestrictions(gameId, childId);
    if (restrictions == null || restrictions['timeRestrictions'] == null) {
      return null;
    }

    final timeData = restrictions['timeRestrictions'] as Map<String, dynamic>;
    return TimeRestriction.fromJson(timeData);
  }

  /// Check if child can play now based on time restrictions
  Future<bool> canPlayNow(String gameId, String childId) async {
    final timeRestriction = await getTimeRestrictions(gameId, childId);
    if (timeRestriction == null) return true;

    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);
    
    // Check daily time limit
    if (timeRestriction.maxDailyMinutes != null) {
      final todayPlayTime = await _getTodayPlayTime(gameId, childId);
      if (todayPlayTime >= timeRestriction.maxDailyMinutes!) {
        return false;
      }
    }

    // Check time window
    if (timeRestriction.allowedStartTime != null && timeRestriction.allowedEndTime != null) {
      return _isTimeInWindow(
        currentTime,
        timeRestriction.allowedStartTime!,
        timeRestriction.allowedEndTime!,
      );
    }

    // Check blocked days
    if (timeRestriction.blockedDays != null) {
      final weekday = now.weekday;
      return !timeRestriction.blockedDays!.contains(weekday);
    }

    return true;
  }

  /// Private methods

  Future<void> _saveApprovalRequest(ApprovalRequest request) async {
    // Save to local storage and queue for sync
    final data = request.toJson();
    await _persistence.saveGameEvent(ApprovalRequestEvent(
      gameId: request.gameId,
      childId: request.childId,
      sessionId: 'approval_${request.id}',
      requestData: data,
    ));
  }

  Future<void> _updateApprovalRequest(ApprovalRequest request) async {
    await _saveApprovalRequest(request);
  }

  Future<Map<String, GameApproval>> _loadGameApprovals(String childId) async {
    // This would load from local storage
    // For now, return empty map
    return {};
  }

  Future<void> _saveGameApproval(GameApproval approval) async {
    // Save to local storage and sync to server
    final data = approval.toJson();
    await _persistence.saveGameEvent(ApprovalResponseEvent(
      gameId: approval.gameId,
      childId: approval.childId,
      sessionId: 'approval_response_${DateTime.now().millisecondsSinceEpoch}',
      approvalData: data,
    ));
  }

  ApprovalRequest? _findRequestById(String requestId) {
    return _pendingRequests.values
        .where((request) => request.id == requestId)
        .firstOrNull;
  }

  Future<ApprovalResult?> _showApprovalDialog(
    BuildContext context,
    WidgetRef ref,
    ApprovalRequest request,
    GamePlugin game,
  ) async {
    return showDialog<ApprovalResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ApprovalDialog(
        request: request,
        game: game,
        ref: ref,
      ),
    );
  }

  Future<void> _processApprovalResponse(ApprovalRequest request, ApprovalResult result) async {
    if (result.isApproved) {
      await approveGame(
        requestId: request.id,
        reason: result.reason ?? 'Approved by parent',
        restrictions: result.restrictions,
      );
    } else {
      await rejectGame(
        requestId: request.id,
        reason: result.reason ?? 'Rejected by parent',
      );
    }
  }

  Future<int> _getTodayPlayTime(String gameId, String childId) async {
    // This would calculate today's play time from game events
    // For now, return 0
    return 0;
  }

  bool _isTimeInWindow(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      // Normal window (e.g., 9:00 - 17:00)
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Overnight window (e.g., 20:00 - 8:00)
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }
}

/// Represents a parent approval request
class ApprovalRequest {
  final String id;
  final String gameId;
  final String childId;
  final String gameName;
  final String gameDescription;
  final GameCategory category;
  final int minAge;
  final int maxAge;
  final List<String> educationalTopics;
  final DateTime requestedAt;
  ApprovalStatus status;
  DateTime? approvedAt;
  String? parentResponse;

  ApprovalRequest({
    required this.id,
    required this.gameId,
    required this.childId,
    required this.gameName,
    required this.gameDescription,
    required this.category,
    required this.minAge,
    required this.maxAge,
    required this.educationalTopics,
    required this.requestedAt,
    required this.status,
    this.approvedAt,
    this.parentResponse,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameId': gameId,
      'childId': childId,
      'gameName': gameName,
      'gameDescription': gameDescription,
      'category': category.name,
      'minAge': minAge,
      'maxAge': maxAge,
      'educationalTopics': educationalTopics,
      'requestedAt': requestedAt.toIso8601String(),
      'status': status.name,
      'approvedAt': approvedAt?.toIso8601String(),
      'parentResponse': parentResponse,
    };
  }

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) {
    return ApprovalRequest(
      id: json['id'],
      gameId: json['gameId'],
      childId: json['childId'],
      gameName: json['gameName'],
      gameDescription: json['gameDescription'],
      category: GameCategory.values.byName(json['category']),
      minAge: json['minAge'],
      maxAge: json['maxAge'],
      educationalTopics: List<String>.from(json['educationalTopics']),
      requestedAt: DateTime.parse(json['requestedAt']),
      status: ApprovalStatus.values.byName(json['status']),
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      parentResponse: json['parentResponse'],
    );
  }
}

/// Approval status enumeration
enum ApprovalStatus {
  pending,
  approved,
  rejected,
}

/// Represents the result of an approval request
class ApprovalResult {
  final bool isApproved;
  final String? reason;
  final Map<String, dynamic>? restrictions;
  final ApprovalRequest? pendingRequest;

  const ApprovalResult._({
    required this.isApproved,
    this.reason,
    this.restrictions,
    this.pendingRequest,
  });

  factory ApprovalResult.approved({String? reason, Map<String, dynamic>? restrictions}) {
    return ApprovalResult._(
      isApproved: true,
      reason: reason,
      restrictions: restrictions,
    );
  }

  factory ApprovalResult.rejected({String? reason}) {
    return ApprovalResult._(
      isApproved: false,
      reason: reason,
    );
  }

  factory ApprovalResult.pending(ApprovalRequest request) {
    return ApprovalResult._(
      isApproved: false,
      pendingRequest: request,
    );
  }

  bool get isPending => pendingRequest != null;
  bool get isRejected => !isApproved && pendingRequest == null;
}

/// Represents game approval record
class GameApproval {
  final String gameId;
  final String childId;
  final bool isApproved;
  final DateTime approvedAt;
  final String reason;
  final Map<String, dynamic>? restrictions;

  const GameApproval({
    required this.gameId,
    required this.childId,
    required this.isApproved,
    required this.approvedAt,
    required this.reason,
    this.restrictions,
  });

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'childId': childId,
      'isApproved': isApproved,
      'approvedAt': approvedAt.toIso8601String(),
      'reason': reason,
      'restrictions': restrictions,
    };
  }

  factory GameApproval.fromJson(Map<String, dynamic> json) {
    return GameApproval(
      gameId: json['gameId'],
      childId: json['childId'],
      isApproved: json['isApproved'],
      approvedAt: DateTime.parse(json['approvedAt']),
      reason: json['reason'],
      restrictions: json['restrictions'],
    );
  }
}

/// Time-based restrictions for game access
class TimeRestriction {
  final int? maxDailyMinutes;
  final TimeOfDay? allowedStartTime;
  final TimeOfDay? allowedEndTime;
  final List<int>? blockedDays; // 1-7 for Mon-Sun

  const TimeRestriction({
    this.maxDailyMinutes,
    this.allowedStartTime,
    this.allowedEndTime,
    this.blockedDays,
  });

  Map<String, dynamic> toJson() {
    return {
      'maxDailyMinutes': maxDailyMinutes,
      'allowedStartTime': allowedStartTime != null 
          ? '${allowedStartTime!.hour}:${allowedStartTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'allowedEndTime': allowedEndTime != null
          ? '${allowedEndTime!.hour}:${allowedEndTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'blockedDays': blockedDays,
    };
  }

  factory TimeRestriction.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseTime(String? timeStr) {
      if (timeStr == null) return null;
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return TimeRestriction(
      maxDailyMinutes: json['maxDailyMinutes'],
      allowedStartTime: parseTime(json['allowedStartTime']),
      allowedEndTime: parseTime(json['allowedEndTime']),
      blockedDays: json['blockedDays'] != null 
          ? List<int>.from(json['blockedDays'])
          : null,
    );
  }
}

/// Game events for approval system
class ApprovalRequestEvent extends GameEvent {
  final Map<String, dynamic> requestData;

  ApprovalRequestEvent({
    required super.gameId,
    required super.childId,
    required super.sessionId,
    required this.requestData,
  }) : super(data: requestData);

  @override
  String get eventType => 'approval_request';
}

class ApprovalResponseEvent extends GameEvent {
  final Map<String, dynamic> approvalData;

  ApprovalResponseEvent({
    required super.gameId,
    required super.childId,
    required super.sessionId,
    required this.approvalData,
  }) : super(data: approvalData);

  @override
  String get eventType => 'approval_response';
}

/// Approval dialog widget
class ApprovalDialog extends StatefulWidget {
  final ApprovalRequest request;
  final GamePlugin game;
  final WidgetRef ref;

  const ApprovalDialog({
    super.key,
    required this.request,
    required this.game,
    required this.ref,
  });

  @override
  State<ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends State<ApprovalDialog> {
  bool _requiresParentAuth = true;
  bool _authenticationInProgress = false;

  @override
  Widget build(BuildContext context) {
    if (_requiresParentAuth) {
      return _buildAuthDialog();
    }

    return _buildApprovalDialog();
  }

  Widget _buildAuthDialog() {
    return AlertDialog(
      title: const Text('Parent Authentication Required'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.security, size: 64, color: Colors.orange),
          const SizedBox(height: 16),
          Text(
            '${widget.request.gameName} requires parent approval.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please authenticate to continue.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(ApprovalResult.rejected()),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _authenticationInProgress ? null : _authenticateParent,
          child: _authenticationInProgress
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Authenticate'),
        ),
      ],
    );
  }

  Widget _buildApprovalDialog() {
    return AlertDialog(
      title: Text('Approve ${widget.request.gameName}?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.request.gameDescription,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildGameInfo(),
            const SizedBox(height: 16),
            _buildEducationalTopics(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            ApprovalResult.rejected(reason: 'Not appropriate for child'),
          ),
          child: const Text('Reject'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(
            ApprovalResult.approved(reason: 'Approved by parent'),
          ),
          child: const Text('Approve'),
        ),
        TextButton(
          onPressed: () => _showAdvancedOptions(),
          child: const Text('Options'),
        ),
      ],
    );
  }

  Widget _buildGameInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.request.category.icon, size: 24),
                const SizedBox(width: 8),
                Text(
                  widget.request.category.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Age Range: ${widget.request.minAge}-${widget.request.maxAge} years'),
            Text('Play Time: ~${widget.game.estimatedPlayTimeMinutes} minutes'),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationalTopics() {
    if (widget.request.educationalTopics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Educational Topics:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          children: widget.request.educationalTopics
              .map((topic) => Chip(
                    label: Text(topic),
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Future<void> _authenticateParent() async {
    setState(() {
      _authenticationInProgress = true;
    });

    try {
      // Navigate to PIN entry or use the existing auth flow
      if (context.mounted) {
        final result = await context.push('/pin-entry');
        if (result == true) {
          setState(() {
            _requiresParentAuth = false;
            _authenticationInProgress = false;
          });
        } else {
          Navigator.of(context).pop(ApprovalResult.rejected());
        }
      }
    } catch (e) {
      setState(() {
        _authenticationInProgress = false;
      });
      Navigator.of(context).pop(ApprovalResult.rejected());
    }
  }

  void _showAdvancedOptions() {
    // This would show a more detailed approval dialog with time restrictions, etc.
    // For now, just approve with basic settings
    Navigator.of(context).pop(
      ApprovalResult.approved(
        reason: 'Approved with standard restrictions',
        restrictions: {
          'maxDailyMinutes': 30,
          'allowedStartTime': '09:00',
          'allowedEndTime': '19:00',
        },
      ),
    );
  }
}

/// Providers for Riverpod integration

final parentApprovalManagerProvider = Provider<ParentApprovalManager>((ref) {
  return ParentApprovalManager();
});

final gameApprovalStatusProvider = FutureProvider.family<bool, ({String gameId, String childId})>((ref, params) async {
  final manager = ref.read(parentApprovalManagerProvider);
  return await manager.isGameApproved(params.gameId, params.childId);
});

final pendingApprovalRequestsProvider = FutureProvider.family<List<ApprovalRequest>, String>((ref, parentId) async {
  final manager = ref.read(parentApprovalManagerProvider);
  return await manager.getPendingRequests(parentId);
});

final canPlayGameNowProvider = FutureProvider.family<bool, ({String gameId, String childId})>((ref, params) async {
  final manager = ref.read(parentApprovalManagerProvider);
  return await manager.canPlayNow(params.gameId, params.childId);
});
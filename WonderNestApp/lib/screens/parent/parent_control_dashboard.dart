import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_mode_provider.dart';
import '../../models/app_mode.dart';
import '../../models/child_profile.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';

class ParentControlDashboard extends ConsumerStatefulWidget {
  const ParentControlDashboard({super.key});

  @override
  ConsumerState<ParentControlDashboard> createState() => _ParentControlDashboardState();
}

class _ParentControlDashboardState extends ConsumerState<ParentControlDashboard> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  
  ChildProfile? _selectedChild;
  List<ChildProfile> _children = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadChildren();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChildren() async {
    // Load children profiles from API
    setState(() {
      _isLoading = false;
      // Mock data for now
      _children = [
        ChildProfile(
          id: 'child_1',
          name: 'Timmy',
          age: 7,
          birthDate: DateTime(2017, 3, 15),
          gender: 'male',
          interests: ['dinosaurs', 'space', 'lego'],
          contentSettings: ContentSettings(
            maxAgeRating: 7,
            blockedCategories: [],
            allowedDomains: ['pbskids.org'],
            subtitlesEnabled: true,
            audioMonitoringEnabled: true,
            educationalContentOnly: false,
          ),
          timeRestrictions: TimeRestrictions(
            weekdayLimits: {},
            weekendLimits: {},
            dailyScreenTimeMinutes: 120,
            bedtimeEnabled: true,
            bedtimeStart: '20:00',
            bedtimeEnd: '07:00',
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      if (_children.isNotEmpty) {
        _selectedChild = _children.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appMode = ref.watch(appModeProvider);
    
    // Ensure we're in parent mode
    if (appMode.currentMode != AppMode.parent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/pin-entry');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Parent Controls',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Child selector
          if (_children.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButton<ChildProfile>(
                value: _selectedChild,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryBlue),
                items: _children.map((child) {
                  return DropdownMenuItem(
                    value: child,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.primaryBlue,
                          child: Text(
                            child.name[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          child.name,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (child) {
                  setState(() {
                    _selectedChild = child;
                  });
                },
              ),
            ),
          
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textPrimary),
            onPressed: () => context.push('/settings'),
          ),
          
          // Lock to kid mode
          IconButton(
            icon: const Icon(Icons.lock, color: Colors.red),
            onPressed: () {
              ref.read(appModeProvider.notifier).switchToKidMode();
              context.go('/child-home');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tab bar
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: AppColors.primaryBlue,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primaryBlue,
                    tabs: const [
                      Tab(text: 'Overview', icon: Icon(Icons.dashboard, size: 20)),
                      Tab(text: 'Screen Time', icon: Icon(Icons.timer, size: 20)),
                      Tab(text: 'Content', icon: Icon(Icons.movie, size: 20)),
                      Tab(text: 'Activity', icon: Icon(Icons.analytics, size: 20)),
                      Tab(text: 'Settings', icon: Icon(Icons.tune, size: 20)),
                    ],
                  ),
                ),
                
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildScreenTimeTab(),
                      _buildContentTab(),
                      _buildActivityTab(),
                      _buildSettingsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick stats cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Today\'s Screen Time',
                  '1h 23m',
                  Icons.timer,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Educational',
                  '45m',
                  Icons.school,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Games Played',
                  '3',
                  Icons.games,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'New Words',
                  '12',
                  Icons.abc,
                  Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Recent Activity
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            'Watched "Learning ABCs"',
            'YouTube Kids',
            '15 minutes ago',
            Icons.play_circle,
            Colors.red,
          ),
          _buildActivityItem(
            'Played Math Adventure',
            'Educational Game',
            '1 hour ago',
            Icons.games,
            Colors.purple,
          ),
          _buildActivityItem(
            'Read "The Little Prince"',
            'Story Time',
            '2 hours ago',
            Icons.book,
            Colors.blue,
          ),
          
          const SizedBox(height: 24),
          
          // Alerts
          Text(
            'Alerts',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildAlertCard(
            'Screen time limit approaching',
            'Timmy has 15 minutes remaining today',
            Icons.warning,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildScreenTimeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly chart
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Screen Time',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 180,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              return Text(
                                days[value.toInt()],
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}m',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(7, (index) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: (60 + index * 15).toDouble(),
                              color: AppColors.primaryBlue,
                              width: 20,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Time limits settings
          Text(
            'Time Limits',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildTimeLimitSetting('Daily Limit', '2 hours', true),
          _buildTimeLimitSetting('Weekday Limit', '1.5 hours', true),
          _buildTimeLimitSetting('Weekend Limit', '3 hours', true),
          _buildTimeLimitSetting('Educational Bonus', '30 minutes', false),
          
          const SizedBox(height: 24),
          
          // Bedtime settings
          Text(
            'Bedtime',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable Bedtime'),
                  subtitle: const Text('Automatically lock app during bedtime'),
                  value: _selectedChild?.timeRestrictions.bedtimeEnabled ?? true,
                  onChanged: (value) {
                    // Update bedtime setting
                  },
                ),
                ListTile(
                  title: const Text('Bedtime Start'),
                  trailing: Text(
                    _selectedChild?.timeRestrictions.bedtimeStart ?? '20:00',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    // Show time picker
                  },
                ),
                ListTile(
                  title: const Text('Bedtime End'),
                  trailing: Text(
                    _selectedChild?.timeRestrictions.bedtimeEnd ?? '07:00',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    // Show time picker
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content filters
          Text(
            'Content Filters',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildFilterSetting('Age Rating', 'Up to 7 years'),
                const Divider(),
                _buildFilterSetting('Violence', 'None'),
                const Divider(),
                _buildFilterSetting('Language', 'Mild'),
                const Divider(),
                _buildFilterToggle('Educational Content Only', false),
                const Divider(),
                _buildFilterToggle('Enable Subtitles', true),
                const Divider(),
                _buildFilterToggle('Audio Monitoring', true),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Whitelisted content
          Text(
            'Whitelisted Content',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildWhitelistItem('PBS Kids', 'Website', true),
          _buildWhitelistItem('Sesame Street', 'YouTube Channel', true),
          _buildWhitelistItem('Math Adventure', 'Game', true),
          
          const SizedBox(height: 12),
          
          ElevatedButton.icon(
            onPressed: () {
              // Add whitelist item
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Whitelisted Content'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Blocked keywords
          Text(
            'Blocked Keywords',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['scary', 'monster', 'violent'].map((keyword) {
              return Chip(
                label: Text(keyword),
                onDeleted: () {
                  // Remove keyword
                },
                deleteIconColor: Colors.red,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today\'s Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildActivityStat('Total Screen Time', '1h 23m'),
                _buildActivityStat('Educational Content', '45m (55%)'),
                _buildActivityStat('Entertainment', '38m (45%)'),
                _buildActivityStat('Games Played', '3'),
                _buildActivityStat('Videos Watched', '5'),
                _buildActivityStat('New Words Learned', '12'),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Detailed activity log
          Text(
            'Activity Log',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildDetailedActivityItem(
            '10:30 AM',
            'Watched "Learning ABCs"',
            'YouTube Kids - Educational',
            '15 minutes',
            Icons.play_circle,
            Colors.red,
          ),
          _buildDetailedActivityItem(
            '11:00 AM',
            'Played Math Adventure',
            'Game - Level 3 completed',
            '20 minutes',
            Icons.games,
            Colors.purple,
          ),
          _buildDetailedActivityItem(
            '2:30 PM',
            'Read "The Little Prince"',
            'Story Time - Chapter 3',
            '25 minutes',
            Icons.book,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile settings
          Text(
            'Child Profile',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primaryBlue,
                    child: Text(
                      _selectedChild?.name[0] ?? 'T',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  title: Text(_selectedChild?.name ?? 'Timmy'),
                  subtitle: Text('Age: ${_selectedChild?.age ?? 7}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // Edit profile
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Birth Date'),
                  subtitle: Text('March 15, 2017'),
                  onTap: () {},
                ),
                ListTile(
                  title: const Text('Interests'),
                  subtitle: Wrap(
                    spacing: 8,
                    children: (_selectedChild?.interests ?? []).map((interest) {
                      return Chip(
                        label: Text(interest, style: const TextStyle(fontSize: 12)),
                        backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                      );
                    }).toList(),
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Privacy settings
          Text(
            'Privacy & Safety',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Data Collection'),
                  subtitle: const Text('Allow anonymous usage statistics'),
                  value: true,
                  onChanged: (value) {},
                ),
                SwitchListTile(
                  title: const Text('Audio Monitoring'),
                  subtitle: const Text('Monitor for safety keywords'),
                  value: true,
                  onChanged: (value) {},
                ),
                SwitchListTile(
                  title: const Text('Location Access'),
                  subtitle: const Text('For local content recommendations'),
                  value: false,
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Account actions
          ElevatedButton(
            onPressed: () {
              // Export data
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Export Child Data'),
          ),
          
          const SizedBox(height: 12),
          
          OutlinedButton(
            onPressed: () {
              // Delete profile
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete Child Profile'),
          ),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time,
      IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          time,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(String title, String message, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeLimitSetting(String title, String value, bool enabled) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                value,
                style: TextStyle(
                  color: enabled ? AppColors.primaryBlue : Colors.grey,
                ),
              ),
            ],
          ),
          Switch(
            value: enabled,
            onChanged: (value) {
              // Update setting
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSetting(String title, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () {
        // Show filter options
      },
    );
  }

  Widget _buildFilterToggle(String title, bool value) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: (newValue) {
        // Update setting
      },
    );
  }

  Widget _buildWhitelistItem(String title, String type, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.circle_outlined,
            color: isActive ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  type,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              // Remove from whitelist
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStat(String label, String value) {
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

  Widget _buildDetailedActivityItem(String time, String title, String subtitle,
      String duration, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      duration,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
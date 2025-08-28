# UI/UX Recommendations for WonderNest Website

## Design Philosophy

The WonderNest website should embody the same child-centered, educational focus as the mobile app while providing desktop-optimized experiences for parents and administrators. The design must balance playfulness with professionalism, ensuring parents feel confident while maintaining the whimsical, learning-focused aesthetic children associate with WonderNest.

## 1. Parent Portal Dashboard Design

### Visual Design System

#### Color Palette
```scss
// Primary Brand Colors (inherited from mobile app)
$wonder-primary: #6366F1;      // Indigo - trust and reliability
$wonder-secondary: #10B981;    // Emerald - growth and learning  
$wonder-accent: #F59E0B;       // Amber - creativity and engagement

// Parent Portal Specific
$parent-background: #F8FAFC;   // Soft gray background
$parent-card-bg: #FFFFFF;      // Clean white cards
$parent-text-primary: #1F2937; // Dark gray for readability
$parent-text-secondary: #6B7280; // Medium gray for secondary text

// Child-Specific Colors (for data visualization)
$child-colors: (
  'child-1': #8B5CF6,  // Purple
  'child-2': #06B6D4,  // Cyan
  'child-3': #EF4444,  // Red
  'child-4': #F97316   // Orange
);
```

#### Typography System
```scss
// Font Stack - friendly yet professional
$font-primary: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
$font-headings: 'Poppins', 'Inter', sans-serif; // Playful headings

// Type Scale
$text-xs: 0.75rem;    // 12px
$text-sm: 0.875rem;   // 14px  
$text-base: 1rem;     // 16px
$text-lg: 1.125rem;   // 18px
$text-xl: 1.25rem;    // 20px
$text-2xl: 1.5rem;    // 24px
$text-3xl: 1.875rem;  // 30px
```

### Parent Dashboard Layout

#### Main Dashboard Structure
```tsx
const ParentDashboard = () => (
  <div className="min-h-screen bg-parent-background">
    {/* Header */}
    <Header>
      <WonderNestLogo />
      <NavigationTabs />
      <UserProfile />
    </Header>
    
    {/* Main Content */}
    <main className="max-w-7xl mx-auto px-4 py-6">
      <div className="grid grid-cols-12 gap-6">
        
        {/* Children Overview Cards - Top Priority */}
        <section className="col-span-12">
          <h2 className="text-2xl font-semibold mb-4">Your Children</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {children.map(child => (
              <ChildSummaryCard key={child.id} child={child} />
            ))}
          </div>
        </section>
        
        {/* Analytics & Insights */}
        <section className="col-span-12 lg:col-span-8">
          <WeeklyProgressChart />
          <RecentActivityFeed />
        </section>
        
        {/* Quick Actions & Notifications */}
        <aside className="col-span-12 lg:col-span-4">
          <PendingApprovalsWidget />
          <BookmarkSuggestionsWidget />
          <DevelopmentalInsightsWidget />
        </aside>
      </div>
    </main>
  </div>
);
```

#### Child Summary Card Design
```tsx
const ChildSummaryCard = ({ child }: { child: Child }) => (
  <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden hover:shadow-md transition-shadow">
    {/* Child Header */}
    <div className="p-4 bg-gradient-to-r from-wonder-primary to-wonder-secondary">
      <div className="flex items-center space-x-3">
        <Avatar 
          src={child.avatarUrl} 
          fallback={child.firstName[0]} 
          size="lg"
          className="ring-2 ring-white"
        />
        <div className="text-white">
          <h3 className="font-semibold text-lg">{child.firstName}</h3>
          <p className="text-sm opacity-90">
            {calculateAge(child.birthDate)} • {child.totalPlayTimeThisWeek} min this week
          </p>
        </div>
      </div>
    </div>
    
    {/* Progress Overview */}
    <div className="p-4 space-y-3">
      {/* Weekly Progress */}
      <div>
        <div className="flex justify-between items-center mb-1">
          <span className="text-sm text-gray-600">Weekly Goal</span>
          <span className="text-sm font-medium">{child.weeklyProgress}%</span>
        </div>
        <ProgressBar 
          progress={child.weeklyProgress} 
          color="wonder-secondary"
        />
      </div>
      
      {/* Recent Achievements */}
      <div className="flex items-center space-x-2">
        <StarIcon className="w-4 h-4 text-wonder-accent" />
        <span className="text-sm text-gray-600">
          {child.achievementsThisWeek} achievements this week
        </span>
      </div>
      
      {/* Favorite Games */}
      <div>
        <span className="text-sm text-gray-600">Currently Playing:</span>
        <div className="mt-1 flex flex-wrap gap-1">
          {child.favoriteGames.slice(0, 2).map(game => (
            <Badge key={game.id} variant="secondary" size="sm">
              {game.name}
            </Badge>
          ))}
        </div>
      </div>
      
      {/* Quick Actions */}
      <div className="pt-2 border-t border-gray-100 flex space-x-2">
        <Button 
          size="sm" 
          variant="outline"
          onClick={() => navigateToChildDetail(child.id)}
        >
          View Details
        </Button>
        <Button 
          size="sm" 
          variant="ghost"
          onClick={() => openBookmarkModal(child.id)}
        >
          Add Bookmark
        </Button>
      </div>
    </div>
  </div>
);
```

### Child Detail Page Design

#### Analytics Dashboard
```tsx
const ChildAnalyticsPage = ({ childId }: { childId: string }) => (
  <div className="space-y-6">
    {/* Header with Child Info */}
    <ChildDetailHeader child={child} />
    
    {/* Time Period Selector */}
    <div className="flex justify-between items-center">
      <h1 className="text-2xl font-bold">Learning Analytics</h1>
      <TimePeriodSelector 
        value={timePeriod} 
        onChange={setTimePeriod}
        options={['week', 'month', '3months', 'year']}
      />
    </div>
    
    <div className="grid grid-cols-12 gap-6">
      
      {/* Main Charts */}
      <section className="col-span-12 lg:col-span-8 space-y-6">
        
        {/* Play Time Trends */}
        <ChartCard title="Daily Play Time">
          <LineChart
            data={playTimeData}
            xAxis="date"
            yAxis="minutes"
            color="wonder-primary"
          />
        </ChartCard>
        
        {/* Skills Development Radar */}
        <ChartCard title="Skills Development">
          <RadarChart
            data={skillsData}
            categories={['Problem Solving', 'Creativity', 'Logic', 'Motor Skills', 'Language']}
            color="wonder-secondary"
          />
        </ChartCard>
        
        {/* Game Category Breakdown */}
        <ChartCard title="Activity Categories">
          <DonutChart
            data={categoryData}
            colors={['wonder-primary', 'wonder-secondary', 'wonder-accent']}
          />
        </ChartCard>
      </section>
      
      {/* Sidebar Insights */}
      <aside className="col-span-12 lg:col-span-4 space-y-6">
        
        {/* Developmental Insights */}
        <InsightCard
          title="This Week's Highlights"
          icon={<SparklesIcon />}
          insights={weeklyInsights}
        />
        
        {/* Achievement Progress */}
        <AchievementProgressCard achievements={recentAchievements} />
        
        {/* Recommended Content */}
        <RecommendationCard 
          title="Suggested Games"
          recommendations={gameRecommendations}
        />
        
        {/* Settings Quick Access */}
        <QuickSettingsCard childId={childId} />
        
      </aside>
    </div>
  </div>
);
```

### Bookmarking Interface

#### Game Discovery & Bookmarking
```tsx
const GameBrowserPage = () => (
  <div className="space-y-6">
    {/* Search and Filter Header */}
    <div className="bg-white rounded-lg shadow-sm p-6">
      <div className="flex flex-col lg:flex-row gap-4">
        <SearchInput 
          placeholder="Search educational games..."
          value={searchTerm}
          onChange={setSearchTerm}
          className="flex-1"
        />
        <div className="flex gap-2">
          <AgeRangeSelector value={ageRange} onChange={setAgeRange} />
          <CategoryFilter value={categories} onChange={setCategories} />
          <SortSelector value={sortBy} onChange={setSortBy} />
        </div>
      </div>
    </div>
    
    {/* Child Selector */}
    <ChildSelector 
      selectedChildren={selectedChildren}
      onChange={setSelectedChildren}
      label="Bookmark for:"
    />
    
    {/* Game Grid */}
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
      {games.map(game => (
        <GameCard 
          key={game.id}
          game={game}
          onBookmark={(gameId) => handleBookmark(gameId, selectedChildren)}
          isBookmarked={checkIfBookmarked(game.id, selectedChildren)}
        />
      ))}
    </div>
  </div>
);

const GameCard = ({ game, onBookmark, isBookmarked }) => (
  <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden hover:shadow-md transition-all">
    {/* Game Thumbnail */}
    <div className="relative aspect-video bg-gradient-to-br from-wonder-primary to-wonder-secondary">
      <img 
        src={game.thumbnailUrl} 
        alt={game.title}
        className="w-full h-full object-cover"
      />
      <div className="absolute top-2 right-2">
        <BookmarkButton 
          isBookmarked={isBookmarked}
          onClick={() => onBookmark(game.id)}
          size="sm"
        />
      </div>
      
      {/* Age Rating Badge */}
      <div className="absolute bottom-2 left-2">
        <Badge variant="secondary">
          Ages {game.minAge}-{game.maxAge}
        </Badge>
      </div>
    </div>
    
    {/* Game Info */}
    <div className="p-4">
      <h3 className="font-semibold text-lg mb-2">{game.title}</h3>
      <p className="text-gray-600 text-sm mb-3 line-clamp-2">
        {game.description}
      </p>
      
      {/* Educational Tags */}
      <div className="flex flex-wrap gap-1 mb-3">
        {game.educationalObjectives.slice(0, 2).map(objective => (
          <Badge key={objective} variant="outline" size="xs">
            {objective}
          </Badge>
        ))}
      </div>
      
      {/* Rating and Stats */}
      <div className="flex items-center justify-between text-sm text-gray-500">
        <div className="flex items-center space-x-1">
          <StarIcon className="w-4 h-4 text-yellow-400" />
          <span>{game.rating}</span>
        </div>
        <span>{game.playCount} plays</span>
      </div>
    </div>
  </div>
);
```

## 2. Admin Portal Dashboard Design

### Admin Dashboard Layout

#### Modern Admin Interface
```tsx
const AdminDashboard = () => (
  <div className="min-h-screen bg-gray-50">
    {/* Admin Header */}
    <AdminHeader>
      <div className="flex items-center space-x-4">
        <WonderNestAdminLogo />
        <div className="flex items-center space-x-2 text-sm text-gray-600">
          <ShieldCheckIcon className="w-4 h-4" />
          <span>Admin Portal</span>
        </div>
      </div>
      
      <div className="flex items-center space-x-4">
        <NotificationDropdown />
        <AdminUserMenu />
      </div>
    </AdminHeader>
    
    {/* Sidebar Navigation */}
    <div className="flex">
      <AdminSidebar />
      
      {/* Main Content Area */}
      <main className="flex-1 p-6">
        <div className="max-w-7xl mx-auto">
          
          {/* Dashboard Stats Overview */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            <StatCard
              title="Total Users"
              value={platformStats.totalUsers}
              change="+12%"
              changeType="positive"
              icon={<UsersIcon />}
            />
            <StatCard
              title="Active Children"
              value={platformStats.activeChildren}
              change="+8%"
              changeType="positive"
              icon={<UserIcon />}
            />
            <StatCard
              title="Content Items"
              value={platformStats.contentItems}
              change="+15%"
              changeType="positive"
              icon={<BookOpenIcon />}
            />
            <StatCard
              title="Pending Approvals"
              value={platformStats.pendingApprovals}
              change="-3"
              changeType="neutral"
              icon={<ClockIcon />}
            />
          </div>
          
          {/* Main Dashboard Content */}
          <div className="grid grid-cols-12 gap-6">
            
            {/* Platform Activity Chart */}
            <section className="col-span-12 lg:col-span-8">
              <DashboardCard title="Platform Activity">
                <MultiLineChart
                  data={activityData}
                  lines={[
                    { key: 'dailyActiveUsers', name: 'Daily Active Users', color: '#6366F1' },
                    { key: 'newRegistrations', name: 'New Registrations', color: '#10B981' },
                    { key: 'contentCreated', name: 'Content Created', color: '#F59E0B' }
                  ]}
                />
              </DashboardCard>
            </section>
            
            {/* Quick Actions & Alerts */}
            <aside className="col-span-12 lg:col-span-4 space-y-6">
              <ContentModerationQueue />
              <SystemHealthWidget />
              <QuickActionsWidget />
            </aside>
            
            {/* User Engagement Analytics */}
            <section className="col-span-12">
              <DashboardCard title="User Engagement">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                  <EngagementMetric
                    title="Average Session Duration"
                    value="18 min"
                    trend="+5%"
                    chart={<MiniAreaChart data={sessionDurationData} />}
                  />
                  <EngagementMetric
                    title="Daily Active Rate"
                    value="64%"
                    trend="+2%"
                    chart={<MiniBarChart data={activeRateData} />}
                  />
                  <EngagementMetric
                    title="Content Completion Rate"
                    value="78%"
                    trend="+7%"
                    chart={<MiniLineChart data={completionRateData} />}
                  />
                </div>
              </DashboardCard>
            </section>
          </div>
        </div>
      </main>
    </div>
  </div>
);
```

### Content Moderation Interface

#### Content Review Dashboard
```tsx
const ContentModerationPage = () => (
  <div className="space-y-6">
    {/* Moderation Header */}
    <div className="flex justify-between items-center">
      <h1 className="text-2xl font-bold">Content Moderation</h1>
      <div className="flex items-center space-x-4">
        <StatusFilter value={statusFilter} onChange={setStatusFilter} />
        <PriorityFilter value={priorityFilter} onChange={setPriorityFilter} />
        <Button variant="outline" onClick={refreshQueue}>
          <RefreshIcon className="w-4 h-4 mr-2" />
          Refresh
        </Button>
      </div>
    </div>
    
    {/* Moderation Queue */}
    <div className="bg-white rounded-lg shadow-sm">
      <div className="border-b border-gray-200 p-4">
        <div className="flex items-center justify-between">
          <h2 className="font-semibold">Pending Review ({pendingCount})</h2>
          <div className="flex items-center space-x-2 text-sm text-gray-600">
            <ClockIcon className="w-4 h-4" />
            <span>Average review time: 8 min</span>
          </div>
        </div>
      </div>
      
      <div className="divide-y divide-gray-200">
        {contentItems.map(item => (
          <ContentReviewItem 
            key={item.id}
            item={item}
            onApprove={handleApprove}
            onReject={handleReject}
            onRequestChanges={handleRequestChanges}
          />
        ))}
      </div>
    </div>
  </div>
);

const ContentReviewItem = ({ item, onApprove, onReject, onRequestChanges }) => (
  <div className="p-6 hover:bg-gray-50">
    <div className="flex items-start space-x-4">
      {/* Content Preview */}
      <div className="flex-shrink-0">
        <div className="w-24 h-24 bg-gray-200 rounded-lg overflow-hidden">
          {item.thumbnailUrl ? (
            <img 
              src={item.thumbnailUrl} 
              alt={item.title}
              className="w-full h-full object-cover"
            />
          ) : (
            <div className="w-full h-full flex items-center justify-center">
              <DocumentIcon className="w-8 h-8 text-gray-400" />
            </div>
          )}
        </div>
      </div>
      
      {/* Content Details */}
      <div className="flex-1">
        <div className="flex items-start justify-between">
          <div>
            <h3 className="font-semibold text-lg">{item.title}</h3>
            <p className="text-gray-600 text-sm mb-2">{item.description}</p>
            
            <div className="flex items-center space-x-4 text-sm text-gray-500">
              <span>By: {item.creator.name}</span>
              <span>Created: {formatDate(item.createdAt)}</span>
              <span>Type: {item.contentType}</span>
              <span>Ages: {item.minAge}-{item.maxAge}</span>
            </div>
          </div>
          
          {/* Priority Badge */}
          <PriorityBadge priority={item.priority} />
        </div>
        
        {/* Educational Objectives */}
        <div className="mt-3 flex flex-wrap gap-1">
          {item.educationalObjectives.map(objective => (
            <Badge key={objective} variant="secondary" size="sm">
              {objective}
            </Badge>
          ))}
        </div>
        
        {/* Review Actions */}
        <div className="mt-4 flex items-center space-x-3">
          <Button 
            size="sm"
            variant="success"
            onClick={() => onApprove(item.id)}
          >
            <CheckIcon className="w-4 h-4 mr-1" />
            Approve
          </Button>
          <Button 
            size="sm"
            variant="outline"
            onClick={() => onRequestChanges(item.id)}
          >
            <EditIcon className="w-4 h-4 mr-1" />
            Request Changes
          </Button>
          <Button 
            size="sm"
            variant="destructive"
            onClick={() => onReject(item.id)}
          >
            <XIcon className="w-4 h-4 mr-1" />
            Reject
          </Button>
          <Button 
            size="sm"
            variant="ghost"
            onClick={() => openPreviewModal(item)}
          >
            <EyeIcon className="w-4 h-4 mr-1" />
            Preview
          </Button>
        </div>
      </div>
    </div>
  </div>
);
```

### User Management Interface

#### User Administration Dashboard
```tsx
const UserManagementPage = () => (
  <div className="space-y-6">
    {/* User Management Header */}
    <div className="flex justify-between items-center">
      <h1 className="text-2xl font-bold">User Management</h1>
      <div className="flex items-center space-x-4">
        <SearchInput 
          placeholder="Search users..."
          value={searchTerm}
          onChange={setSearchTerm}
        />
        <UserTypeFilter value={userTypeFilter} onChange={setUserTypeFilter} />
        <Button onClick={openCreateUserModal}>
          <PlusIcon className="w-4 h-4 mr-2" />
          Add User
        </Button>
      </div>
    </div>
    
    {/* User Statistics */}
    <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
      <UserStatCard
        title="Total Families"
        value={userStats.totalFamilies}
        icon={<HomeIcon />}
        trend="+12"
      />
      <UserStatCard
        title="Active Parents"
        value={userStats.activeParents}
        icon={<UsersIcon />}
        trend="+8"
      />
      <UserStatCard
        title="Children Profiles"
        value={userStats.childProfiles}
        icon={<UserIcon />}
        trend="+15"
      />
      <UserStatCard
        title="Premium Accounts"
        value={userStats.premiumAccounts}
        icon={<StarIcon />}
        trend="+3"
      />
    </div>
    
    {/* User Data Table */}
    <div className="bg-white rounded-lg shadow-sm">
      <UserDataTable
        users={filteredUsers}
        loading={loading}
        onSort={handleSort}
        onEdit={handleEditUser}
        onDelete={handleDeleteUser}
        onViewDetails={handleViewUserDetails}
      />
    </div>
  </div>
);
```

## 3. Content Manager Interface

### Story Creation Tool

#### Rich Content Editor
```tsx
const StoryCreationPage = () => (
  <div className="min-h-screen bg-gray-50">
    <div className="flex">
      {/* Story Editor Toolbar */}
      <div className="w-64 bg-white shadow-sm p-4">
        <div className="space-y-4">
          <StoryMetadataPanel />
          <CharacterPanel />
          <AssetLibraryPanel />
          <SettingsPanel />
        </div>
      </div>
      
      {/* Main Editor */}
      <div className="flex-1 flex flex-col">
        {/* Editor Header */}
        <div className="bg-white border-b border-gray-200 p-4 flex justify-between items-center">
          <div className="flex items-center space-x-4">
            <h1 className="font-semibold text-lg">{storyTitle || 'Untitled Story'}</h1>
            <SaveStatus status={saveStatus} />
          </div>
          
          <div className="flex items-center space-x-2">
            <Button variant="outline" onClick={previewStory}>
              <PlayIcon className="w-4 h-4 mr-2" />
              Preview
            </Button>
            <Button variant="outline" onClick={saveAsDraft}>
              Save Draft
            </Button>
            <Button onClick={submitForReview}>
              Submit for Review
            </Button>
          </div>
        </div>
        
        {/* Story Canvas */}
        <div className="flex-1 p-6">
          <div className="max-w-4xl mx-auto">
            <StoryCanvas 
              pages={storyPages}
              currentPage={currentPageIndex}
              onPageChange={setCurrentPageIndex}
              onContentUpdate={handleContentUpdate}
            />
          </div>
        </div>
        
        {/* Page Navigation */}
        <div className="bg-white border-t border-gray-200 p-4">
          <PageNavigator
            pages={storyPages}
            currentPage={currentPageIndex}
            onPageSelect={setCurrentPageIndex}
            onAddPage={addNewPage}
            onDeletePage={deletePage}
            onReorderPages={reorderPages}
          />
        </div>
      </div>
    </div>
  </div>
);

const StoryCanvas = ({ pages, currentPage, onPageChange, onContentUpdate }) => {
  const page = pages[currentPage];
  
  return (
    <div className="bg-white rounded-lg shadow-lg overflow-hidden">
      {/* Page Content Editor */}
      <div className="aspect-video relative bg-gradient-to-br from-blue-50 to-purple-50">
        {/* Background Layer */}
        <BackgroundLayer
          background={page.background}
          onBackgroundChange={(bg) => onContentUpdate(currentPage, { background: bg })}
        />
        
        {/* Interactive Elements Layer */}
        <InteractiveElementsLayer
          elements={page.elements}
          onElementsChange={(elements) => onContentUpdate(currentPage, { elements })}
        />
        
        {/* Text Overlay Layer */}
        <TextOverlayLayer
          textBlocks={page.textBlocks}
          onTextChange={(textBlocks) => onContentUpdate(currentPage, { textBlocks })}
        />
        
        {/* Audio Controls */}
        <AudioControlsLayer
          audioTracks={page.audioTracks}
          onAudioChange={(audioTracks) => onContentUpdate(currentPage, { audioTracks })}
        />
      </div>
      
      {/* Page Settings Panel */}
      <div className="p-4 bg-gray-50 border-t">
        <PageSettings
          settings={page.settings}
          onSettingsChange={(settings) => onContentUpdate(currentPage, { settings })}
        />
      </div>
    </div>
  );
};
```

## 4. Responsive Design Considerations

### Mobile-First Approach
```scss
// Responsive breakpoints
$mobile: 320px;
$tablet: 768px;
$desktop: 1024px;
$wide: 1440px;

// Mobile-first dashboard adaptations
.dashboard-grid {
  display: grid;
  gap: 1rem;
  
  // Mobile (default)
  grid-template-columns: 1fr;
  
  // Tablet
  @media (min-width: $tablet) {
    grid-template-columns: repeat(2, 1fr);
    gap: 1.5rem;
  }
  
  // Desktop
  @media (min-width: $desktop) {
    grid-template-columns: repeat(3, 1fr);
    gap: 2rem;
  }
  
  // Wide screens
  @media (min-width: $wide) {
    grid-template-columns: repeat(4, 1fr);
  }
}

// Mobile navigation adaptations
.admin-sidebar {
  // Mobile: slide-over drawer
  @media (max-width: $tablet - 1px) {
    position: fixed;
    top: 0;
    left: 0;
    height: 100vh;
    width: 280px;
    transform: translateX(-100%);
    transition: transform 0.3s ease;
    z-index: 50;
    
    &.open {
      transform: translateX(0);
    }
  }
  
  // Desktop: persistent sidebar
  @media (min-width: $tablet) {
    position: sticky;
    top: 0;
    height: 100vh;
    width: 256px;
  }
}
```

## 5. Accessibility Compliance

### WCAG 2.1 AA Standards
```tsx
// Accessible form components
const AccessibleFormField = ({ 
  label, 
  id, 
  error, 
  required, 
  helpText,
  children 
}) => (
  <div className="form-field">
    <label 
      htmlFor={id}
      className={`form-label ${required ? 'required' : ''}`}
    >
      {label}
      {required && <span aria-label="required" className="text-red-500">*</span>}
    </label>
    
    <div className="form-input-wrapper">
      {React.cloneElement(children, {
        id,
        'aria-describedby': `${id}-help ${error ? `${id}-error` : ''}`.trim(),
        'aria-invalid': error ? 'true' : 'false',
        required
      })}
    </div>
    
    {helpText && (
      <div id={`${id}-help`} className="form-help-text">
        {helpText}
      </div>
    )}
    
    {error && (
      <div 
        id={`${id}-error`} 
        className="form-error-text" 
        role="alert"
        aria-live="polite"
      >
        {error}
      </div>
    )}
  </div>
);

// Accessible data visualization
const AccessibleChart = ({ data, title, description }) => (
  <div className="chart-container">
    <div className="sr-only">
      <h3>{title}</h3>
      <p>{description}</p>
      <table>
        <thead>
          <tr>
            <th>Period</th>
            <th>Value</th>
          </tr>
        </thead>
        <tbody>
          {data.map((point, index) => (
            <tr key={index}>
              <td>{point.label}</td>
              <td>{point.value}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
    
    <div aria-hidden="true">
      <Chart data={data} />
    </div>
  </div>
);
```

## 6. Performance Optimization

### Code Splitting & Lazy Loading
```tsx
// Route-based code splitting
const ParentDashboard = lazy(() => import('./pages/ParentDashboard'));
const AdminPanel = lazy(() => import('./pages/AdminPanel'));
const ContentCreator = lazy(() => import('./pages/ContentCreator'));

// Component-based lazy loading
const HeavyAnalyticsChart = lazy(() => 
  import('./components/HeavyAnalyticsChart').then(module => ({
    default: module.HeavyAnalyticsChart
  }))
);

// Conditional loading based on user role
const AdminRoutes = () => {
  const { user } = useAuth();
  
  if (!user || user.userType !== 'admin') {
    return <Navigate to="/unauthorized" />;
  }
  
  return (
    <Suspense fallback={<AdminLoadingSkeleton />}>
      <AdminPanel />
    </Suspense>
  );
};
```

This comprehensive UI/UX design system ensures:

1. **Child-Centered Design**: Maintains WonderNest's educational focus while providing professional tools
2. **Role-Specific Interfaces**: Tailored experiences for parents, admins, and content managers  
3. **Responsive Design**: Optimized for desktop, tablet, and mobile devices
4. **Accessibility**: WCAG 2.1 AA compliant with screen reader support
5. **Performance**: Code splitting and lazy loading for optimal load times
6. **Visual Consistency**: Cohesive design system extending the mobile app brand
7. **User Experience**: Intuitive workflows that reduce cognitive load while providing powerful functionality

The design balances the playful, educational nature of WonderNest with the professional needs of parents and administrators, creating an ecosystem that serves all stakeholders effectively.
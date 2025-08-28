# WonderNest Website Platform

## Overview
A comprehensive web platform that complements the WonderNest mobile app, providing parents with desktop access to manage their children's educational journey and enabling content teams to efficiently create and moderate educational content. The website maintains strict COPPA compliance while offering role-based access for Parents, Admins, and Content Managers.

## User Stories

### Parent Portal
- As a parent, I want to securely login to view my children's progress so that I can track their development
- As a parent, I want to manage child profiles and content filtering settings from my desktop so that I have more control over their experience
- As a parent, I want to see detailed analytics and developmental insights so that I can support my child's learning
- As a parent, I want to approve or deny premium purchases and content sharing requests so that I maintain control over my child's activities
- As a parent, I want to bookmark age-appropriate games for later mobile access so that my child can easily find suitable content

### Child Games Section (Parent-Mediated)
- As a parent, I want to browse and bookmark educational games for my children so that they have curated content on their mobile devices
- As a parent, I want to preview games before they appear on my child's device so that I can ensure content appropriateness
- As a child (with parent supervision), I want to safely discover new educational games so that I can continue learning

### Admin/Content Manager Portal
- As an admin, I want to securely manage user accounts and system settings so that the platform operates smoothly
- As a content manager, I want to create and edit stories/games using intuitive tools so that I can efficiently produce educational content
- As a content manager, I want to moderate and approve user-generated content so that all content meets safety standards
- As an admin, I want to view platform analytics and user engagement metrics so that I can make data-driven decisions
- As a content manager, I want to manage content publishing workflows so that new content is properly reviewed before release

## Acceptance Criteria

### Security & Compliance
- [ ] All user authentication uses JWT tokens with proper refresh mechanisms
- [ ] Role-based access control prevents unauthorized access between Parent/Admin/Content Manager areas
- [ ] COPPA compliance maintained - no direct child accounts, all access parent-mediated
- [ ] Content moderation workflow enforces safety review before publication
- [ ] Secure file upload with content scanning for story/game assets

### Parent Portal
- [ ] Secure login system compatible with existing mobile app authentication
- [ ] Dashboard displays child progress with developmental insights
- [ ] Child profile management with photo, preferences, and content filters
- [ ] Activity reports showing game usage, achievements, and learning progress
- [ ] Approval system for premium purchases and content sharing
- [ ] Game bookmarking system for later mobile access

### Admin Portal
- [ ] Separate admin authentication system with elevated privileges
- [ ] User management interface for parents and content managers
- [ ] System analytics dashboard with platform-wide metrics
- [ ] Content moderation queue with approval/rejection workflows
- [ ] Story/game creation tools with drag-drop interface
- [ ] Asset management system for images, audio, and interactive elements

### Technical Requirements
- [ ] Responsive design works on desktop, tablet, and mobile browsers
- [ ] Integration with existing PostgreSQL database and Redis cache
- [ ] API endpoints support both web and mobile app clients
- [ ] Real-time updates for approval notifications and content status
- [ ] Offline capability for content creation (with sync when online)

## Technical Constraints
- Must integrate with existing KTOR 3.0 backend without breaking mobile app functionality
- Must use existing PostgreSQL schemas (core, games, content, analytics, compliance)
- Must maintain JWT authentication compatibility with Flutter mobile app
- Must work offline for parent dashboard viewing (cached data)
- Must be COPPA compliant with no direct child data collection
- Must support content versioning and approval workflows
- Must handle file uploads up to 100MB for story assets

## Security Considerations
- **Authentication**: Multi-tier auth system (Parent JWT, Admin separate login, Content Manager role-based)
- **Authorization**: Role-based permissions with fine-grained access controls
- **Content Security**: All uploaded content scanned for inappropriate material
- **Data Privacy**: Parent controls all child data access, audit logging for admin actions
- **Session Management**: Web sessions compatible with mobile app session sharing
- **COPPA Compliance**: No cookies or tracking for child-facing content, parent consent required

## Integration Points
- **Mobile App**: Shared authentication, bookmarked games appear in mobile app
- **Backend**: Extends existing KTOR routes with web-specific endpoints
- **Database**: Utilizes existing schemas with new web-specific tables
- **Analytics**: Integrates with existing analytics pipeline for unified reporting

## Success Metrics
- Parent engagement: 70% of parents access web portal monthly
- Content creation: Content managers can publish 5x more stories per month
- Safety: 99.9% of content passes moderation before child exposure
- User satisfaction: 4.5+ rating for parent dashboard usability
- Performance: Page load times under 2 seconds for all portal pages
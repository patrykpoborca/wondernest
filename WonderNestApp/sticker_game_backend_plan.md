# Sticker Game Backend Integration Plan

## Overview
This document outlines the comprehensive plan for integrating the sticker game with the WonderNest backend, ensuring COPPA compliance, robust analytics, and seamless parent-child workflow.

## Database Schema Requirements

### 1. Game Tables (in `games` schema)
```sql
-- Game definitions and metadata
CREATE TABLE games.sticker_game_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    background_image_url VARCHAR(500),
    sticker_set_id UUID NOT NULL,
    target_age_min INTEGER NOT NULL,
    target_age_max INTEGER NOT NULL,
    difficulty_level INTEGER CHECK (difficulty_level BETWEEN 1 AND 5),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE
);

-- Available sticker sets
CREATE TABLE games.sticker_sets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    theme VARCHAR(100) NOT NULL, -- animals, vehicles, food, etc.
    sticker_data JSONB NOT NULL, -- Array of sticker definitions
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE
);

-- Individual game sessions
CREATE TABLE games.sticker_game_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL REFERENCES core.children(id),
    template_id UUID NOT NULL REFERENCES games.sticker_game_templates(id),
    session_state JSONB NOT NULL, -- Current game state (sticker positions, completion status)
    start_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_time TIMESTAMP WITH TIME ZONE,
    completion_percentage INTEGER DEFAULT 0 CHECK (completion_percentage BETWEEN 0 AND 100),
    is_completed BOOLEAN DEFAULT FALSE,
    play_duration_seconds INTEGER DEFAULT 0
);

-- Game interactions for analytics
CREATE TABLE games.sticker_game_interactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES games.sticker_game_sessions(id),
    interaction_type VARCHAR(50) NOT NULL, -- sticker_placed, sticker_moved, sticker_removed, game_completed
    interaction_data JSONB NOT NULL, -- Specific interaction details
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 2. Analytics Tables (extend existing `analytics` schema)
```sql
-- Daily game metrics per child
CREATE TABLE analytics.daily_game_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL REFERENCES core.children(id),
    date DATE NOT NULL,
    game_type VARCHAR(50) NOT NULL, -- 'sticker_game'
    total_sessions INTEGER DEFAULT 0,
    total_play_time_seconds INTEGER DEFAULT 0,
    games_completed INTEGER DEFAULT 0,
    average_completion_time_seconds INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(child_id, date, game_type)
);

-- Development insights from game play
CREATE TABLE analytics.game_development_insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL REFERENCES core.children(id),
    insight_type VARCHAR(100) NOT NULL, -- fine_motor_skills, creativity, focus_duration
    insight_data JSONB NOT NULL,
    confidence_score DECIMAL(3,2) CHECK (confidence_score BETWEEN 0 AND 1),
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 3. Parent Approval Workflow Tables
```sql
-- Parent approval requests for game content
CREATE TABLE compliance.parent_approval_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES core.families(id),
    child_id UUID NOT NULL REFERENCES core.children(id),
    request_type VARCHAR(50) NOT NULL, -- 'new_game_access', 'analytics_sharing'
    request_data JSONB NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'denied')),
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    reviewed_by UUID REFERENCES core.users(id)
);
```

## API Endpoints Design

### 1. Game Management Endpoints
```
GET /api/v1/games/sticker/templates
- Fetch available game templates for child's age
- Query params: childId, ageGroup, difficulty

POST /api/v1/games/sticker/sessions
- Start new game session
- Body: { childId, templateId }
- Returns: sessionId, gameState

PUT /api/v1/games/sticker/sessions/{sessionId}
- Update game session state
- Body: { sessionState, interactions[] }

GET /api/v1/games/sticker/sessions/{sessionId}
- Retrieve current game session

POST /api/v1/games/sticker/sessions/{sessionId}/complete
- Mark session as completed
- Body: { finalState, completionTime }
```

### 2. Analytics Endpoints
```
GET /api/v1/analytics/children/{childId}/games/daily
- Daily game metrics for parent dashboard
- Query params: startDate, endDate

GET /api/v1/analytics/children/{childId}/games/insights
- Development insights from game play
- Query params: insightTypes[], timeRange

POST /api/v1/analytics/games/interaction
- Log game interaction (real-time)
- Body: { sessionId, interactionType, data }
```

### 3. Parent Approval Endpoints
```
GET /api/v1/parents/approval-requests
- Fetch pending approval requests

POST /api/v1/parents/approval-requests/{requestId}/approve
- Approve child's game access request

POST /api/v1/parents/approval-requests/{requestId}/deny
- Deny child's game access request
```

## Implementation Steps (Priority Order)

### Phase 1: Core Infrastructure (High Priority)
1. **Database Setup**
   - Create database migrations for game tables
   - Set up proper indexes and constraints
   - Add sample data for testing

2. **Basic Game Session Management**
   - Implement session CRUD operations
   - Game state persistence
   - Session lifecycle management

3. **Flutter API Service Integration**
   - Create StickerGameApiService
   - Implement session management calls
   - Error handling and offline support

### Phase 2: Analytics Foundation (High Priority)
1. **Interaction Tracking**
   - Real-time interaction logging
   - Batch analytics processing
   - Development insights generation

2. **Parent Dashboard Integration**
   - Game progress visualization
   - Analytics data presentation
   - Export functionality

### Phase 3: COPPA Compliance (High Priority)
1. **Parent Approval Workflow**
   - Approval request system
   - Notification mechanism
   - Data retention policies

2. **Privacy Controls**
   - Data minimization checks
   - Consent verification
   - Audit logging

### Phase 4: Advanced Features (Medium Priority)
1. **Content Management**
   - Dynamic sticker set loading
   - A/B testing framework
   - Content recommendation engine

2. **Social Features (Safe)**
   - Family sharing (with approval)
   - Achievement system
   - Progress celebration

## Testing Strategy

### 1. Unit Testing
- Database repository tests
- API endpoint tests
- Game logic validation
- Analytics calculation tests

### 2. Integration Testing
- End-to-end game session flow
- Parent approval workflow
- COPPA compliance verification
- Analytics data pipeline

### 3. Child Safety Testing
- Age-appropriate content filtering
- Data collection limits
- Parent notification systems
- Session timeout handling

### 4. Performance Testing
- Game state serialization/deserialization
- Real-time analytics processing
- Database query optimization
- Mobile network conditions

## COPPA Compliance Checklist

### Data Collection
- [ ] Minimal data collection (only game progress)
- [ ] No personally identifiable information in game data
- [ ] Parent consent for analytics sharing
- [ ] Clear data retention policies

### Parent Controls
- [ ] Full visibility into child's game data
- [ ] Ability to delete game progress
- [ ] Control over analytics sharing
- [ ] Notification of new features

### Security Measures
- [ ] Encrypted data transmission
- [ ] Secure session management
- [ ] Audit logging for all child interactions
- [ ] Regular security assessments

## Success Metrics

### Technical Metrics
- Game session save/load time < 500ms
- 99.9% data persistence reliability
- Zero data loss incidents
- API response time < 200ms

### Child Experience Metrics
- Session completion rate > 80%
- Average play time increase
- Reduced app crashes during game
- Smooth offline-to-online sync

### Parent Satisfaction Metrics
- Analytics dashboard usage > 60%
- Approval workflow completion < 24hrs
- Parent feature adoption rate
- Privacy concern resolution time

## Risk Mitigation

### Technical Risks
- **Database performance**: Implement proper indexing and connection pooling
- **Data corruption**: Regular backups and transaction integrity
- **API failures**: Graceful degradation and retry mechanisms

### Compliance Risks
- **COPPA violations**: Regular compliance audits and legal review
- **Data breaches**: Encryption, access controls, and monitoring
- **Parent consent**: Clear workflows and documentation

### User Experience Risks
- **Game progression loss**: Robust sync mechanisms and local backup
- **Performance degradation**: Optimize database queries and caching
- **Feature complexity**: User testing and iterative improvements

## Timeline Estimate

- **Phase 1**: 2-3 weeks (Core Infrastructure)
- **Phase 2**: 2 weeks (Analytics Foundation)
- **Phase 3**: 1-2 weeks (COPPA Compliance)
- **Phase 4**: 2-3 weeks (Advanced Features)
- **Testing & QA**: 1 week (Parallel to development)

**Total Estimated Timeline**: 6-8 weeks for complete implementation

## Dependencies

### External Dependencies
- PostgreSQL 16+ for JSONB support
- Redis for session caching
- JWT authentication system
- Flutter secure storage

### Internal Dependencies
- Family management system
- Child profile system
- Parent authentication
- Analytics infrastructure

## Next Steps

1. Review and approve this plan with stakeholders
2. Set up development environment with database migrations
3. Create feature branch for sticker game backend
4. Begin Phase 1 implementation
5. Set up continuous integration for testing
6. Schedule regular progress reviews

---

*This plan prioritizes child safety, COPPA compliance, and robust analytics while maintaining the engaging game experience that supports child development.*
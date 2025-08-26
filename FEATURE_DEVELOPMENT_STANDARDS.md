# Feature Development Standards & AI Session Guidelines

## 🎯 Purpose
This document provides standardized guidelines for Claude AI sessions when implementing features, managing todos, tracking changes, and maintaining technical documentation for the InTheMix platform.

## 📁 Directory Structure Standards

### Required Structure for Each Feature
```
ai_guidance/
├── features/
│   └── {feature_name}/
│       ├── feature_description.md      [REQUIRED]
│       ├── implementation_todo.md       [REQUIRED for new features]
│       ├── changelog.md                 [REQUIRED - auto-maintained]
│       ├── api_endpoints.md            [OPTIONAL - if feature has APIs]
│       ├── test_plan.md                [OPTIONAL - for complex features]
│       └── remaining_todos.md          [OPTIONAL - for tracking incomplete work]
```

## 📋 File Templates & Standards

### 1. feature_description.md Template
```markdown
# {Feature Name}

## Overview
Brief 2-3 sentence description of the feature and its business value.

## User Stories
- As a {user type}, I want to {action} so that {benefit}
- As a {user type}, I want to {action} so that {benefit}

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Business Rules
1. Rule 1
2. Rule 2

## Technical Constraints
- Constraint 1
- Constraint 2

## Dependencies
- Depends on: {feature/component}
- Required by: {feature/component}

## UI/UX Considerations
- Mobile-first design
- Accessibility requirements
- Platform-specific behaviors (iOS vs Android)

## Security Considerations
- Authentication requirements
- Data privacy concerns
- Permission levels
```

### 2. implementation_todo.md Template
```markdown
# Implementation Todo: {Feature Name}

## Pre-Implementation Checklist
- [ ] Review feature_description.md
- [ ] Check business_definitions.md for correct terminology
- [ ] Identify affected modules (shared, server, composeApp)
- [ ] Review existing similar features for patterns

## Database Schema
- [ ] Design schema changes
- [ ] Create migration file V{XXX}__{description}.sql
- [ ] Update DAOs
- [ ] Update repository interfaces

## Backend Implementation
- [ ] Create/update models in `/shared`
- [ ] Implement DAO in `/server/dao`
- [ ] Implement repository in `/server/repository`
- [ ] Create API routes in `/server/routes`
- [ ] Add request/response DTOs
- [ ] Implement validation
- [ ] Add error handling
- [ ] Write backend tests

## Frontend Implementation
- [ ] Create/update ViewModels
- [ ] Implement UI screens
- [ ] Add navigation
- [ ] Implement state management
- [ ] Handle loading/error states
- [ ] Add client-side validation
- [ ] Test on Android
- [ ] Test on iOS
- [ ] Test on Desktop

## Integration
- [ ] API client implementation
- [ ] Error handling
- [ ] Offline support (if applicable)
- [ ] Push notifications (if applicable)

## Testing
- [ ] Unit tests
- [ ] Integration tests
- [ ] Manual testing checklist
- [ ] Edge cases covered

## Documentation
- [ ] Update changelog.md
- [ ] Update API documentation
- [ ] Update user documentation (if needed)
```

### 3. changelog.md Template
```markdown
# Changelog: {Feature Name}

## [YYYY-MM-DD HH:MM] - Type: {FEATURE|BUGFIX|REFACTOR|TEST|DOCS}

### Summary
{One-line description}

### Context
- Task: {What was requested}
- Issue: {What problem was being solved}

### Changes Made
- ✅ {Completed change}
- ✅ {Completed change}
- ⚠️ {Change with caveats/warnings}

### Technical Implementation
```kotlin
// Key code snippets if relevant
```

### Files Modified
| File | Change Type | Description |
|------|------------|-------------|
| `/path/to/file.kt` | CREATE/MODIFY/DELETE | {What changed} |

### Testing
- Tested: {What was tested}
- Method: {How it was tested}
- Result: {Test outcome}

### Known Issues
- 🐛 {Any bugs discovered}
- 📝 {Any TODOs remaining}

### Next Steps
- {What should be done next}

### Dependencies
- Added: {New dependencies}
- Removed: {Removed dependencies}
- Updated: {Updated dependencies}

---
```

### 4. api_endpoints.md Template
```markdown
# API Endpoints: {Feature Name}

## Base Path
`/api/v1/{resource}`

## Endpoints

### GET /{resource}
**Description**: {What it does}
**Authentication**: Required/Optional
**Request**: None
**Response**:
```json
{
  "field": "type"
}
```
**Error Codes**:
- 400: {Reason}
- 401: {Reason}
- 404: {Reason}

### POST /{resource}
**Description**: {What it does}
**Authentication**: Required
**Request**:
```json
{
  "field": "type"
}
```
**Response**:
```json
{
  "field": "type"
}
```
**Validation**:
- field: {Rules}

---
```

## 🔄 Version Control Guidelines

### Semantic Versioning for Features
Features should track their development version:
- `0.1.0` - Initial implementation
- `0.2.0` - Core functionality complete
- `0.3.0` - Integration complete
- `0.9.0` - Testing complete
- `1.0.0` - Production ready

Track version in changelog entries:
```markdown
## [YYYY-MM-DD] - v0.2.0 - Type: FEATURE
```

## 🤖 Claude Session Instructions

### At Session Start
1. **Check for existing work**:
   ```bash
   ls -la ai_guidance/features/{feature_name}/
   cat ai_guidance/features/{feature_name}/remaining_todos.md
   ```

2. **Review context**:
   - Read `feature_description.md`
   - Check `changelog.md` for recent work
   - Review `implementation_todo.md` for current progress

3. **Set up tracking**:
   ```bash
   # If starting new feature
   mkdir -p ai_guidance/features/{feature_name}
   # Create required files from templates
   ```

### During Implementation
1. **Before each task**:
   - Check business_definitions.md for terminology
   - Review similar features for patterns
   - Update implementation_todo.md checkboxes

2. **After each significant change**:
   - Add changelog entry immediately
   - Update remaining_todos.md if incomplete
   - Commit with descriptive message

3. **Use consistent patterns**:
   ```kotlin
   // Follow existing patterns in codebase
   // Repository: Interface in /shared, Implementation in module
   // DAO: Use dbQuery wrapper
   // Routes: Follow RESTful conventions
   ```

### At Session End
1. **Update documentation**:
   ```bash
   # Add final changelog entry
   echo "## [$(date +'%Y-%m-%d %H:%M')] - Type: SESSION_END" >> changelog.md
   
   # Update remaining todos
   # Summarize what's left
   ```

2. **Verify consistency**:
   - Ensure all modified files are documented
   - Check that terminology matches business_definitions.md
   - Verify no breaking changes without documentation

## 📝 Commit Message Format
```
{type}({scope}): {subject}

{body}

{footer}
```

Types: feat, fix, docs, style, refactor, test, chore
Scope: feature name or module (e.g., templates, auth, groups)

Example:
```
feat(templates): add PRIVATE visibility support

- Fixed UUID mismatch between Firebase and database IDs
- Updated AuthenticatedUser model to include database ID
- Improved error handling for better debugging

Fixes visibility bug reported in production
```

## 🚨 Critical Rules

### ALWAYS:
1. **Create changelog entries** for EVERY coding session
2. **Check business_definitions.md** before using any domain terms
3. **Test in development mode** before marking complete
4. **Update remaining_todos.md** when leaving work incomplete
5. **Follow existing patterns** rather than introducing new ones

### NEVER:
1. **Skip changelog entries** - they're required for tracking
2. **Use incorrect terminology** - always verify against business_definitions.md
3. **Leave work undocumented** - future sessions need context
4. **Break existing APIs** without migration plan
5. **Commit directly to main** without testing

## 🎯 Quality Checklist

Before marking any feature complete:
- [ ] All todos in implementation_todo.md checked off
- [ ] Changelog is comprehensive
- [ ] API documentation is current
- [ ] Tests are passing
- [ ] No remaining_todos.md or it's empty
- [ ] Code follows project conventions
- [ ] Terminology matches business definitions
- [ ] Both Android and iOS tested (for mobile features)
- [ ] Database migrations are reversible
- [ ] Error handling is comprehensive

## 📊 Progress Tracking

Use standardized status indicators:
- 🚧 In Progress
- ✅ Complete
- ⚠️ Complete with caveats
- 🐛 Has bugs
- 📝 Needs documentation
- 🔄 Needs refactoring
- ❌ Blocked

## 🔍 Search Patterns

Common search patterns for consistency:
```bash
# Find all incomplete features
grep -r "remaining_todos.md" ai_guidance/features/

# Find recent changes
find ai_guidance/features -name "changelog.md" -exec grep -l "$(date +'%Y-%m-%d')" {} \;

# Find features at version
grep -r "v0.9.0" ai_guidance/features/*/changelog.md

# Find all API endpoints
find ai_guidance/features -name "api_endpoints.md"
```

## 💡 Best Practices

1. **Start small, iterate**: Implement MVP first, enhance later
2. **Document assumptions**: Note any assumptions in changelog
3. **Cross-reference**: Link related features in documentation
4. **Be specific**: Use exact file paths and line numbers
5. **Test incrementally**: Test each component before integration
6. **Consider mobile-first**: Design for mobile constraints first
7. **Plan for offline**: Consider offline scenarios for mobile
8. **Security by default**: Always validate, sanitize, authenticate

## 🎓 Example Session Flow

```markdown
1. Claude: "I'll implement the post templates feature"
2. Check existing work: `cat ai_guidance/features/post_templates/remaining_todos.md`
3. Review context: `cat ai_guidance/features/post_templates/feature_description.md`
4. Start implementation with first todo item
5. After each completion: Update changelog.md
6. On error/issue: Document in changelog with 🐛
7. At session end: Update remaining_todos.md
8. Final: Comprehensive changelog entry with session summary
```

---

**Remember**: This documentation is living. Update these standards as patterns emerge and the project evolves. The goal is consistency, clarity, and maintainability across all AI-assisted development sessions.
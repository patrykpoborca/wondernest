# Sticker Book Save Test Instructions

## Comprehensive Logging Added

I've added detailed logging throughout the entire sticker book save flow:

### 1. **SavedProjectsService** (`/lib/games/sticker_book/services/saved_projects_service.dart`)
- **Detailed project structure logging**: Logs every aspect of the project being saved
- **Project summary creation logging**: Traces the creation of lightweight project summaries
- **Backend save process logging**: Comprehensive logging of the entire save-to-backend flow
- **Error handling**: Special 500 error detection and context logging

Key logging points:
- Project data structure before save
- Event data preparation for backend
- API call initiation and completion
- Detailed error context on failures

### 2. **ApiService** (`/lib/core/services/api_service.dart`)
- **Event data transformation logging**: Detailed logging of how game events are converted to analytics events
- **Data type preservation logging**: Tracks how each field is processed and transformed
- **HTTP request/response debugging**: Full HTTP transaction logging for analytics endpoints
- **Duration parsing logging**: Detailed logging of duration value parsing

Key logging points:
- Raw event data received
- Analytics event transformation
- HTTP request details (headers, body, URL)
- HTTP response details (status, headers, body)
- Error details with full context

### 3. **Backend AnalyticsRoutes** (`/Wonder Nest Backend/src/main/kotlin/com/wondernest/api/analytics/AnalyticsRoutes.kt`)
- **Raw request body logging**: Logs the exact JSON received from the client
- **JSON deserialization logging**: Detailed parsing process with error handling
- **Field-by-field validation**: Logs each field of the AnalyticsEvent with type information
- **JWT token validation logging**: Detailed authentication and authorization logging

Key logging points:
- Raw request body (full JSON)
- Parsed event structure with types
- Validation steps and results
- Authentication token details
- Complete error stack traces

## How to Trigger the Test

1. **Start the Flutter app**: `flutter run`
2. **Navigate to sticker book**: Go to the sticker book game
3. **Create some content**: Add stickers or draw something
4. **Save the project**: Use the save functionality

## What the Logs Will Show

The comprehensive logging will trace:

1. **Frontend data preparation**:
   - Exact project structure being saved
   - Project summary calculation
   - Event data structure creation

2. **API transformation**:
   - Raw event data input
   - Field-by-field processing
   - HTTP request formation

3. **Backend processing**:
   - Raw JSON received
   - Deserialization process
   - Field validation
   - Authentication checks
   - Error details (if any)

## Expected Error Discovery

With this level of logging, we should be able to identify:
- **Data type mismatches**: Fields that don't match expected types
- **Size limitations**: JSON payload too large
- **Serialization issues**: Problems converting data to/from JSON
- **Field validation failures**: Required fields missing or invalid
- **Authentication problems**: JWT token issues

## Monitoring the Logs

### Flutter App Logs
- Use your IDE's debug console or run `flutter logs` in terminal
- Look for log entries starting with `[SavedProjectsService]` and `[API]`

### Backend Logs
- Backend is running locally with debug logging enabled
- Monitor the terminal where the backend is running
- Look for detailed analytics event processing logs

The combination of frontend and backend logging should pinpoint exactly where the 500 error originates and what data is causing the issue.
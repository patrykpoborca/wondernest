# Admin Portal Web UI - API Integration Strategy

**Created**: 2025-09-08  
**Purpose**: Technical specification for integrating Next.js frontend with Rust backend APIs  
**Status**: Planning Phase - Backend APIs 75% Complete

---

## 🎯 INTEGRATION OVERVIEW

### Current Backend State
- **API Infrastructure**: 75% complete with comprehensive service layer
- **Authentication**: JWT-based admin authentication with role-based claims
- **Database**: 8 admin tables with complete RBAC system
- **Endpoints**: 15+ REST endpoints defined, implementation in progress
- **Security**: Audit logging, session management, IP restrictions ready

### Frontend Integration Goals
- **Type Safety**: End-to-end TypeScript types from API to UI
- **Performance**: Optimized API calls with intelligent caching
- **Security**: Secure authentication with automatic token management
- **Real-Time**: Live dashboard updates without polling overhead
- **Error Handling**: Comprehensive error recovery and user feedback

---

## 🏗️ TECHNICAL ARCHITECTURE

### API Client Architecture

#### Core Technologies
- **HTTP Client**: Axios with TypeScript interceptors
- **State Management**: TanStack Query (React Query) for server state
- **Type Generation**: OpenAPI/Swagger to TypeScript code generation
- **Authentication**: JWT token management with automatic refresh
- **Error Handling**: Global error boundaries with user-friendly messages

#### Client Structure
```typescript
// src/lib/api-client.ts
class AdminApiClient {
  private axios: AxiosInstance;
  private tokenManager: TokenManager;
  
  constructor() {
    this.axios = axios.create({
      baseURL: process.env.NEXT_PUBLIC_API_URL + '/api/admin',
      timeout: 10000,
    });
    
    this.setupInterceptors();
  }
  
  private setupInterceptors() {
    // Request interceptor for token injection
    // Response interceptor for token refresh
    // Error interceptor for global error handling
  }
}
```

### Authentication Integration

#### JWT Token Management
```typescript
// src/lib/auth/token-manager.ts
class TokenManager {
  private accessToken: string | null = null;
  private refreshToken: string | null = null;
  private refreshPromise: Promise<string> | null = null;
  
  async getValidToken(): Promise<string> {
    // Check token validity
    // Automatic refresh if expired
    // Handle refresh failures
  }
  
  async refreshAccessToken(): Promise<string> {
    // Prevent multiple refresh requests
    // Handle refresh token rotation
    // Logout on refresh failure
  }
}
```

#### Admin Authentication Hook
```typescript
// src/hooks/use-admin-auth.ts
interface AdminAuthContext {
  admin: AdminUser | null;
  login: (credentials: LoginCredentials) => Promise<void>;
  logout: () => Promise<void>;
  hasPermission: (permission: string) => boolean;
  hasRole: (role: AdminRole) => boolean;
  isLoading: boolean;
}

export function useAdminAuth(): AdminAuthContext {
  // Authentication state management
  // Permission checking logic
  // Session management
}
```

### API Service Layer

#### Generated Types from Backend
```typescript
// src/types/api.generated.ts (auto-generated)
export interface AdminUser {
  id: string;
  email: string;
  first_name: string | null;
  last_name: string | null;
  role: AdminRole;
  role_level: number;
  permissions: string[];
  status: AdminAccountStatus;
  created_at: string;
  last_login: string | null;
  mfa_enabled: boolean;
}

export interface AdminRole {
  id: string;
  name: string;
  level: number;
  description: string;
}

export interface LoginCredentials {
  email: string;
  password: string;
  mfa_token?: string;
}

export interface LoginResponse {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  admin: AdminUser;
}
```

#### Service Implementation
```typescript
// src/services/admin-auth.service.ts
export class AdminAuthService {
  constructor(private client: AdminApiClient) {}
  
  async login(credentials: LoginCredentials): Promise<LoginResponse> {
    const response = await this.client.post<LoginResponse>('/auth/login', credentials);
    return response.data;
  }
  
  async logout(): Promise<void> {
    await this.client.post('/auth/logout');
  }
  
  async getProfile(): Promise<AdminUser> {
    const response = await this.client.get<AdminUser>('/auth/profile');
    return response.data;
  }
  
  async changePassword(data: ChangePasswordRequest): Promise<void> {
    await this.client.post('/auth/change-password', data);
  }
}
```

---

## 📡 API ENDPOINT INTEGRATION

### Authentication Endpoints
```typescript
// Authentication API Integration
const authQueries = {
  // Login mutation
  useLogin: () => useMutation({
    mutationFn: (credentials: LoginCredentials) => 
      adminAuthService.login(credentials),
    onSuccess: (response) => {
      tokenManager.setTokens(response.access_token, response.refresh_token);
      queryClient.setQueryData(['admin-profile'], response.admin);
    },
    onError: (error) => {
      handleAuthError(error);
    }
  }),
  
  // Profile query
  useProfile: () => useQuery({
    queryKey: ['admin-profile'],
    queryFn: () => adminAuthService.getProfile(),
    enabled: !!tokenManager.getAccessToken(),
    staleTime: 5 * 60 * 1000, // 5 minutes
  })
};
```

### Admin Account Management
```typescript
// Admin Accounts API Integration
const adminAccountQueries = {
  // List admin accounts with pagination
  useAdminAccounts: (params: AdminAccountListParams) => useQuery({
    queryKey: ['admin-accounts', params],
    queryFn: () => adminAccountService.listAccounts(params),
    keepPreviousData: true,
  }),
  
  // Get single admin account
  useAdminAccount: (id: string) => useQuery({
    queryKey: ['admin-account', id],
    queryFn: () => adminAccountService.getAccount(id),
    enabled: !!id,
  }),
  
  // Create admin account mutation
  useCreateAdminAccount: () => useMutation({
    mutationFn: (data: CreateAdminAccountRequest) => 
      adminAccountService.createAccount(data),
    onSuccess: () => {
      queryClient.invalidateQueries(['admin-accounts']);
      toast.success('Admin account created successfully');
    },
    onError: (error) => {
      handleApiError(error);
    }
  }),
};
```

### Dashboard Data Integration
```typescript
// Dashboard API Integration
const dashboardQueries = {
  // Dashboard metrics query
  useDashboardMetrics: () => useQuery({
    queryKey: ['dashboard-metrics'],
    queryFn: () => dashboardService.getMetrics(),
    refetchInterval: 30000, // Refresh every 30 seconds
    staleTime: 20000, // Consider stale after 20 seconds
  }),
  
  // Real-time updates via Server-Sent Events
  useDashboardSSE: () => {
    useEffect(() => {
      const eventSource = new EventSource('/api/admin/dashboard/stream', {
        headers: {
          'Authorization': `Bearer ${tokenManager.getAccessToken()}`
        }
      });
      
      eventSource.onmessage = (event) => {
        const data = JSON.parse(event.data);
        queryClient.setQueryData(['dashboard-metrics'], (old: any) => ({
          ...old,
          ...data
        }));
      };
      
      return () => eventSource.close();
    }, []);
  }
};
```

### Audit Log Integration
```typescript
// Audit Logs API Integration
const auditLogQueries = {
  // Audit logs with advanced filtering
  useAuditLogs: (params: AuditLogParams) => useInfiniteQuery({
    queryKey: ['audit-logs', params],
    queryFn: ({ pageParam = 1 }) => 
      auditLogService.getAuditLogs({ ...params, page: pageParam }),
    getNextPageParam: (lastPage) => lastPage.hasMore ? lastPage.page + 1 : undefined,
    keepPreviousData: true,
  }),
  
  // Export audit logs
  useExportAuditLogs: () => useMutation({
    mutationFn: (params: AuditLogExportParams) => 
      auditLogService.exportAuditLogs(params),
    onSuccess: (blob, variables) => {
      downloadFile(blob, `audit-logs-${variables.startDate}-${variables.endDate}.csv`);
    }
  })
};
```

---

## 🔐 SECURITY INTEGRATION

### Token Security
```typescript
// Secure token storage and management
class SecureTokenStorage {
  private static readonly ACCESS_TOKEN_KEY = 'admin_access_token';
  private static readonly REFRESH_TOKEN_KEY = 'admin_refresh_token';
  
  static storeTokens(accessToken: string, refreshToken: string): void {
    // Store in httpOnly cookies or secure localStorage
    if (typeof window !== 'undefined') {
      // Client-side storage with encryption
      sessionStorage.setItem(this.ACCESS_TOKEN_KEY, this.encrypt(accessToken));
      localStorage.setItem(this.REFRESH_TOKEN_KEY, this.encrypt(refreshToken));
    }
  }
  
  static clearTokens(): void {
    // Clear all token storage
    if (typeof window !== 'undefined') {
      sessionStorage.removeItem(this.ACCESS_TOKEN_KEY);
      localStorage.removeItem(this.REFRESH_TOKEN_KEY);
    }
  }
  
  private static encrypt(token: string): string {
    // Simple encryption for token storage
    return btoa(token);
  }
}
```

### Permission-Based Components
```typescript
// Permission-based component rendering
interface PermissionGuardProps {
  permission?: string;
  role?: AdminRole;
  fallback?: React.ReactNode;
  children: React.ReactNode;
}

export function PermissionGuard({ 
  permission, 
  role, 
  fallback = null, 
  children 
}: PermissionGuardProps) {
  const { hasPermission, hasRole } = useAdminAuth();
  
  const hasAccess = useMemo(() => {
    if (permission && !hasPermission(permission)) return false;
    if (role && !hasRole(role)) return false;
    return true;
  }, [permission, role, hasPermission, hasRole]);
  
  return hasAccess ? <>{children}</> : <>{fallback}</>;
}

// Usage example
<PermissionGuard permission="admin_account_create">
  <CreateAdminButton />
</PermissionGuard>
```

### API Security Headers
```typescript
// Security configuration for API client
const securityConfig = {
  headers: {
    'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest',
    'Cache-Control': 'no-cache',
  },
  withCredentials: true, // Include cookies
  xsrfCookieName: 'XSRF-TOKEN',
  xsrfHeaderName: 'X-XSRF-TOKEN',
};
```

---

## 🚀 PERFORMANCE OPTIMIZATION

### Caching Strategy
```typescript
// Intelligent caching configuration
const queryClientConfig = {
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000, // 5 minutes
      cacheTime: 10 * 60 * 1000, // 10 minutes
      retry: (failureCount, error: any) => {
        // Don't retry 401/403 errors
        if (error?.status === 401 || error?.status === 403) return false;
        return failureCount < 3;
      },
      retryDelay: attemptIndex => Math.min(1000 * 2 ** attemptIndex, 30000),
    },
    mutations: {
      retry: false, // Don't retry mutations by default
    }
  }
};
```

### Request Batching
```typescript
// Batch multiple API requests for efficiency
class BatchRequestManager {
  private batchQueue: Map<string, Promise<any>> = new Map();
  private batchTimeout: NodeJS.Timeout | null = null;
  
  async batchRequest<T>(key: string, requestFn: () => Promise<T>): Promise<T> {
    // Batch similar requests together
    if (this.batchQueue.has(key)) {
      return this.batchQueue.get(key)!;
    }
    
    const promise = requestFn();
    this.batchQueue.set(key, promise);
    
    // Clear batch after timeout
    this.scheduleBatchClear();
    
    return promise;
  }
  
  private scheduleBatchClear(): void {
    if (this.batchTimeout) clearTimeout(this.batchTimeout);
    
    this.batchTimeout = setTimeout(() => {
      this.batchQueue.clear();
    }, 100); // 100ms batch window
  }
}
```

### Data Prefetching
```typescript
// Prefetch related data for better UX
const prefetchingHooks = {
  // Prefetch admin account details on hover
  usePrefetchAdminAccount: () => {
    const queryClient = useQueryClient();
    
    return useCallback((id: string) => {
      queryClient.prefetchQuery({
        queryKey: ['admin-account', id],
        queryFn: () => adminAccountService.getAccount(id),
        staleTime: 5 * 60 * 1000,
      });
    }, [queryClient]);
  },
  
  // Prefetch next page of results
  usePrefetchNextPage: () => {
    // Prefetch next page for pagination
  }
};
```

---

## 🔄 REAL-TIME INTEGRATION

### Server-Sent Events Implementation
```typescript
// Real-time dashboard updates
class AdminSSEManager {
  private eventSources: Map<string, EventSource> = new Map();
  private reconnectAttempts: Map<string, number> = new Map();
  private maxReconnectAttempts = 5;
  
  connect(endpoint: string, onMessage: (data: any) => void): void {
    const token = tokenManager.getAccessToken();
    if (!token) return;
    
    const eventSource = new EventSource(endpoint, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    eventSource.onopen = () => {
      console.log(`SSE connected: ${endpoint}`);
      this.reconnectAttempts.set(endpoint, 0);
    };
    
    eventSource.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        onMessage(data);
      } catch (error) {
        console.error('Failed to parse SSE data:', error);
      }
    };
    
    eventSource.onerror = () => {
      this.handleConnectionError(endpoint, onMessage);
    };
    
    this.eventSources.set(endpoint, eventSource);
  }
  
  private handleConnectionError(endpoint: string, onMessage: (data: any) => void): void {
    const attempts = this.reconnectAttempts.get(endpoint) || 0;
    
    if (attempts < this.maxReconnectAttempts) {
      const delay = Math.min(1000 * 2 ** attempts, 30000);
      setTimeout(() => {
        this.reconnectAttempts.set(endpoint, attempts + 1);
        this.connect(endpoint, onMessage);
      }, delay);
    }
  }
  
  disconnect(endpoint: string): void {
    const eventSource = this.eventSources.get(endpoint);
    if (eventSource) {
      eventSource.close();
      this.eventSources.delete(endpoint);
      this.reconnectAttempts.delete(endpoint);
    }
  }
}
```

### Live Data Updates Hook
```typescript
// Custom hook for live dashboard data
export function useLiveDashboard() {
  const queryClient = useQueryClient();
  const sseManager = useRef(new AdminSSEManager());
  
  useEffect(() => {
    const handleDashboardUpdate = (data: any) => {
      queryClient.setQueryData(['dashboard-metrics'], (old: any) => ({
        ...old,
        ...data,
        lastUpdated: new Date().toISOString()
      }));
    };
    
    sseManager.current.connect('/api/admin/dashboard/stream', handleDashboardUpdate);
    
    return () => {
      sseManager.current.disconnect('/api/admin/dashboard/stream');
    };
  }, [queryClient]);
  
  // Also return fallback to polling if SSE fails
  const fallbackQuery = useQuery({
    queryKey: ['dashboard-metrics-fallback'],
    queryFn: () => dashboardService.getMetrics(),
    refetchInterval: 30000,
    enabled: false, // Only enable if SSE fails
  });
  
  return { fallbackQuery };
}
```

---

## 🔧 ERROR HANDLING STRATEGY

### Global Error Handling
```typescript
// Centralized error handling
class AdminErrorHandler {
  static handleApiError(error: AxiosError): void {
    const status = error.response?.status;
    const message = error.response?.data?.message || error.message;
    
    switch (status) {
      case 401:
        // Unauthorized - redirect to login
        tokenManager.clearTokens();
        window.location.href = '/admin/login';
        break;
        
      case 403:
        // Forbidden - show permission error
        toast.error('You do not have permission to perform this action');
        break;
        
      case 404:
        // Not found - show not found message
        toast.error('The requested resource was not found');
        break;
        
      case 422:
        // Validation error - show field-specific errors
        this.handleValidationError(error.response.data);
        break;
        
      case 429:
        // Rate limiting - show retry message
        toast.error('Too many requests. Please wait and try again.');
        break;
        
      case 500:
        // Server error - show generic error
        toast.error('An unexpected error occurred. Please try again.');
        break;
        
      default:
        // Unknown error
        toast.error(message || 'An unexpected error occurred');
    }
  }
  
  static handleValidationError(data: any): void {
    if (data.errors && Array.isArray(data.errors)) {
      data.errors.forEach((error: any) => {
        toast.error(`${error.field}: ${error.message}`);
      });
    }
  }
}
```

### React Error Boundaries
```typescript
// Error boundary for API-related errors
interface AdminErrorBoundaryState {
  hasError: boolean;
  error: Error | null;
  errorInfo: ErrorInfo | null;
}

export class AdminErrorBoundary extends Component<
  PropsWithChildren<{}>,
  AdminErrorBoundaryState
> {
  constructor(props: PropsWithChildren<{}>) {
    super(props);
    this.state = { hasError: false, error: null, errorInfo: null };
  }
  
  static getDerivedStateFromError(error: Error): AdminErrorBoundaryState {
    return { hasError: true, error, errorInfo: null };
  }
  
  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    this.setState({ errorInfo });
    
    // Log error to monitoring service
    console.error('Admin portal error:', error, errorInfo);
  }
  
  render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen flex items-center justify-center">
          <div className="max-w-md mx-auto text-center">
            <h1 className="text-2xl font-bold text-red-600 mb-4">
              Something went wrong
            </h1>
            <p className="text-gray-600 mb-4">
              An unexpected error occurred in the admin portal.
            </p>
            <button 
              onClick={() => this.setState({ hasError: false, error: null, errorInfo: null })}
              className="btn-primary"
            >
              Try Again
            </button>
          </div>
        </div>
      );
    }
    
    return this.props.children;
  }
}
```

---

## 📊 API MONITORING & ANALYTICS

### Performance Monitoring
```typescript
// API performance tracking
class ApiPerformanceMonitor {
  private metrics: Map<string, ApiMetric[]> = new Map();
  
  trackRequest(endpoint: string, duration: number, status: number): void {
    const metric: ApiMetric = {
      endpoint,
      duration,
      status,
      timestamp: Date.now()
    };
    
    const endpointMetrics = this.metrics.get(endpoint) || [];
    endpointMetrics.push(metric);
    
    // Keep only last 100 metrics per endpoint
    if (endpointMetrics.length > 100) {
      endpointMetrics.shift();
    }
    
    this.metrics.set(endpoint, endpointMetrics);
  }
  
  getAverageResponseTime(endpoint: string): number {
    const metrics = this.metrics.get(endpoint) || [];
    if (metrics.length === 0) return 0;
    
    const total = metrics.reduce((sum, metric) => sum + metric.duration, 0);
    return total / metrics.length;
  }
  
  getErrorRate(endpoint: string): number {
    const metrics = this.metrics.get(endpoint) || [];
    if (metrics.length === 0) return 0;
    
    const errors = metrics.filter(metric => metric.status >= 400).length;
    return (errors / metrics.length) * 100;
  }
}
```

---

## 🧪 TESTING STRATEGY

### API Integration Testing
```typescript
// Mock Service Worker for API testing
import { rest } from 'msw';
import { setupServer } from 'msw/node';

export const adminApiMocks = [
  // Login endpoint mock
  rest.post('/api/admin/auth/login', (req, res, ctx) => {
    const { email, password } = req.body as LoginCredentials;
    
    if (email === 'admin@test.com' && password === 'password') {
      return res(
        ctx.status(200),
        ctx.json({
          access_token: 'mock-access-token',
          refresh_token: 'mock-refresh-token',
          expires_in: 3600,
          admin: mockAdminUser
        })
      );
    }
    
    return res(
      ctx.status(401),
      ctx.json({ error: 'invalid_credentials', message: 'Invalid email or password' })
    );
  }),
  
  // Admin accounts list mock
  rest.get('/api/admin/accounts', (req, res, ctx) => {
    const page = req.url.searchParams.get('page') || '1';
    const limit = req.url.searchParams.get('limit') || '20';
    
    return res(
      ctx.status(200),
      ctx.json({
        admins: mockAdminAccounts.slice(0, parseInt(limit)),
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: mockAdminAccounts.length,
          total_pages: Math.ceil(mockAdminAccounts.length / parseInt(limit))
        }
      })
    );
  })
];

export const server = setupServer(...adminApiMocks);
```

### Integration Test Examples
```typescript
// Integration test for admin authentication
describe('Admin Authentication Integration', () => {
  beforeAll(() => server.listen());
  afterEach(() => server.resetHandlers());
  afterAll(() => server.close());
  
  test('should login successfully with valid credentials', async () => {
    const { result } = renderHook(() => useAdminAuth(), {
      wrapper: createQueryWrapper()
    });
    
    await act(async () => {
      await result.current.login({
        email: 'admin@test.com',
        password: 'password'
      });
    });
    
    expect(result.current.admin).toBeTruthy();
    expect(result.current.admin?.email).toBe('admin@test.com');
  });
  
  test('should handle login failure gracefully', async () => {
    const { result } = renderHook(() => useAdminAuth(), {
      wrapper: createQueryWrapper()
    });
    
    await act(async () => {
      try {
        await result.current.login({
          email: 'admin@test.com',
          password: 'wrong-password'
        });
      } catch (error) {
        expect(error).toBeTruthy();
      }
    });
    
    expect(result.current.admin).toBeNull();
  });
});
```

---

## 📋 IMPLEMENTATION CHECKLIST

### Phase 1: Core API Integration (Week 1-2)
- [ ] **API Client Setup**
  - [ ] Axios instance configuration with interceptors
  - [ ] TypeScript client generation from OpenAPI specs
  - [ ] Token management system implementation
  - [ ] Global error handling setup

- [ ] **Authentication Integration**
  - [ ] Login/logout API integration
  - [ ] JWT token refresh mechanism
  - [ ] Permission checking hooks
  - [ ] Protected route components

### Phase 2: Data Management (Week 3-4)
- [ ] **TanStack Query Setup**
  - [ ] Query client configuration
  - [ ] Caching strategy implementation
  - [ ] Optimistic updates for mutations
  - [ ] Background refetching setup

- [ ] **Service Layer Implementation**
  - [ ] Admin account management APIs
  - [ ] Invitation system APIs
  - [ ] Dashboard metrics APIs
  - [ ] Audit log APIs

### Phase 3: Real-Time Features (Week 5-6)
- [ ] **Server-Sent Events**
  - [ ] SSE connection management
  - [ ] Real-time dashboard updates
  - [ ] Connection error handling
  - [ ] Fallback to polling

- [ ] **Performance Optimization**
  - [ ] Request batching implementation
  - [ ] Data prefetching strategies
  - [ ] Bundle size optimization
  - [ ] Caching optimization

### Phase 4: Testing & Security (Week 7-8)
- [ ] **Security Hardening**
  - [ ] Token security implementation
  - [ ] Permission enforcement testing
  - [ ] XSS prevention validation
  - [ ] CSRF protection setup

- [ ] **Comprehensive Testing**
  - [ ] Unit tests for API services
  - [ ] Integration tests with MSW
  - [ ] E2E tests for critical flows
  - [ ] Performance testing

---

**Implementation Status**: Ready for Development  
**Dependencies**: Backend API routes completion  
**Priority**: Critical path for web portal functionality  
**Success Criteria**: Secure, performant, type-safe API integration
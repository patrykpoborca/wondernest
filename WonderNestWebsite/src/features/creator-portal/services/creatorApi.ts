/**
 * Creator Platform API Service
 * 
 * This service handles all API communication with the creator platform backend.
 * It provides methods for authentication, content management, and analytics.
 */

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080';
const CREATOR_API_BASE = `${API_BASE_URL}/api/v1/creators`;

// Types for creator platform
export interface CreatorRegisterRequest {
  email: string;
  password: string;
  first_name: string;
  last_name: string;
  display_name: string;
  country: string;
  accept_terms: boolean;
}

export interface CreatorLoginRequest {
  email: string;
  password: string;
  totp_code?: string;
  user_agent?: string;
  ip_address?: string;
}

export interface CreatorLoginResponse {
  access_token: string;
  refresh_token: string;
  creator_id: string;
  tier: string;
  requires_2fa: boolean;
}

export interface CreatorAccount {
  id: string;
  email: string;
  email_verified: boolean;
  first_name: string;
  last_name: string;
  display_name: string;
  bio?: string;
  country: string;
  status: 'pending_verification' | 'pending_approval' | 'active' | 'suspended' | 'rejected';
  creator_type: 'community' | 'professional' | 'enterprise';
  creator_tier: 'tier_1' | 'tier_2' | 'tier_3' | 'tier_4';
  two_factor_enabled: boolean;
  avatar_url?: string;
  cover_image_url?: string;
  website_url?: string;
  social_links: Record<string, string>;
  content_specialties: string[];
  languages_supported: string[];
  target_age_groups: string[];
  terms_accepted: boolean;
  created_at: string;
}

export interface ContentSubmission {
  id: string;
  title: string;
  description: string;
  content_type: 'game' | 'story' | 'video' | 'audio' | 'interactive';
  status: 'draft' | 'submitted' | 'under_review' | 'approved' | 'rejected' | 'published';
  submission_data: Record<string, any>;
  created_at: string;
  updated_at: string;
}

export interface ModerationStatus {
  submission_id: string;
  status: string;
  feedback?: string;
  reviewer_notes?: string;
  updated_at: string;
}

class CreatorApiService {
  private accessToken: string | null = null;
  private refreshToken: string | null = null;

  constructor() {
    // Load tokens from localStorage if available
    this.accessToken = localStorage.getItem('creator_access_token');
    this.refreshToken = localStorage.getItem('creator_refresh_token');
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
    const url = `${CREATOR_API_BASE}${endpoint}`;
    
    const headers: HeadersInit = {
      'Content-Type': 'application/json',
      ...options.headers,
    };

    if (this.accessToken) {
      headers.Authorization = `Bearer ${this.accessToken}`;
    }

    const response = await fetch(url, {
      ...options,
      headers,
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.message || `HTTP ${response.status}: ${response.statusText}`);
    }

    return response.json();
  }

  // Authentication methods
  async register(request: CreatorRegisterRequest): Promise<CreatorAccount> {
    return this.request<CreatorAccount>('/register', {
      method: 'POST',
      body: JSON.stringify(request),
    });
  }

  async login(request: CreatorLoginRequest): Promise<CreatorLoginResponse> {
    const response = await this.request<CreatorLoginResponse>('/login', {
      method: 'POST',
      body: JSON.stringify({
        ...request,
        user_agent: navigator.userAgent,
        ip_address: undefined, // Let backend determine IP
      }),
    });

    // Store tokens
    this.accessToken = response.access_token;
    this.refreshToken = response.refresh_token;
    localStorage.setItem('creator_access_token', response.access_token);
    localStorage.setItem('creator_refresh_token', response.refresh_token);

    return response;
  }

  async logout(): Promise<void> {
    try {
      await this.request('/logout', {
        method: 'POST',
      });
    } finally {
      // Clear tokens regardless of API call success
      this.accessToken = null;
      this.refreshToken = null;
      localStorage.removeItem('creator_access_token');
      localStorage.removeItem('creator_refresh_token');
    }
  }

  async refreshTokens(): Promise<CreatorLoginResponse> {
    if (!this.refreshToken) {
      throw new Error('No refresh token available');
    }

    const response = await this.request<CreatorLoginResponse>('/refresh', {
      method: 'POST',
      body: JSON.stringify({ refresh_token: this.refreshToken }),
    });

    // Update stored tokens
    this.accessToken = response.access_token;
    this.refreshToken = response.refresh_token;
    localStorage.setItem('creator_access_token', response.access_token);
    localStorage.setItem('creator_refresh_token', response.refresh_token);

    return response;
  }

  // Account management
  async getProfile(): Promise<CreatorAccount> {
    return this.request<CreatorAccount>('/profile');
  }

  async updateProfile(updates: Partial<CreatorAccount>): Promise<CreatorAccount> {
    return this.request<CreatorAccount>('/profile', {
      method: 'PUT',
      body: JSON.stringify(updates),
    });
  }

  async verifyEmail(token: string): Promise<{ success: boolean }> {
    return this.request<{ success: boolean }>(`/verify-email?token=${token}`, {
      method: 'POST',
    });
  }

  // Content management
  async getContentSubmissions(): Promise<ContentSubmission[]> {
    return this.request<ContentSubmission[]>('/content');
  }

  async submitContent(content: Partial<ContentSubmission>): Promise<ContentSubmission> {
    return this.request<ContentSubmission>('/content', {
      method: 'POST',
      body: JSON.stringify(content),
    });
  }

  async updateContent(id: string, updates: Partial<ContentSubmission>): Promise<ContentSubmission> {
    return this.request<ContentSubmission>(`/content/${id}`, {
      method: 'PUT',
      body: JSON.stringify(updates),
    });
  }

  async deleteContent(id: string): Promise<void> {
    await this.request(`/content/${id}`, {
      method: 'DELETE',
    });
  }

  // Moderation status
  async getModerationStatus(submissionId: string): Promise<ModerationStatus> {
    return this.request<ModerationStatus>(`/content/${submissionId}/moderation`);
  }

  // Analytics (placeholder for future implementation)
  async getAnalytics(): Promise<any> {
    return this.request<any>('/analytics');
  }

  // Utility methods
  isAuthenticated(): boolean {
    return !!this.accessToken;
  }

  getCurrentCreatorId(): string | null {
    if (!this.accessToken) return null;
    
    try {
      // Decode JWT payload (simplified - in production use a proper JWT library)
      const payload = JSON.parse(atob(this.accessToken.split('.')[1]));
      return payload.creator_id || payload.sub;
    } catch (error) {
      console.error('Failed to decode JWT token:', error);
      return null;
    }
  }
}

// Create singleton instance
export const creatorApi = new CreatorApiService();
export default creatorApi;
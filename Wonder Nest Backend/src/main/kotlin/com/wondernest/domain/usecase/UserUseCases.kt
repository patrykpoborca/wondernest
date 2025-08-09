package com.wondernest.domain.usecase

import com.wondernest.domain.repository.*
import com.wondernest.services.auth.AuthService

// Placeholder use cases
class CreateUserUseCase(private val userRepository: UserRepository)
class AuthenticateUserUseCase(private val userRepository: UserRepository, private val authService: AuthService)
class CreateChildProfileUseCase(private val childRepository: ChildRepository)
class GetContentLibraryUseCase(private val contentRepository: ContentRepository)
class CreateAudioSessionUseCase(private val audioSessionRepository: AudioSessionRepository)
class GetChildAnalyticsUseCase(private val analyticsRepository: AnalyticsRepository)
class UpdateSubscriptionUseCase(private val subscriptionRepository: SubscriptionRepository)
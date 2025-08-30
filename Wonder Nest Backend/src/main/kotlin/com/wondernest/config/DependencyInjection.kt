package com.wondernest.config

import com.wondernest.data.cache.RedisCache
import com.wondernest.data.database.DatabaseFactory
import com.wondernest.data.database.repository.*
import com.wondernest.domain.repository.*
// import com.wondernest.domain.repository.games.*
import com.wondernest.domain.usecase.*
import com.wondernest.services.auth.AuthService
import com.wondernest.services.auth.JwtService
import com.wondernest.services.email.EmailService
import com.wondernest.services.family.FamilyService
// import com.wondernest.services.games.*
import com.wondernest.services.notification.NotificationService
// import com.wondernest.services.storage.StorageService
import io.ktor.server.application.*
import org.koin.dsl.module
import org.koin.ktor.plugin.Koin
import org.koin.logger.slf4jLogger

fun Application.configureDependencyInjection() {
    val app = this
    install(Koin) {
        slf4jLogger()
        modules(
            module {
                single<Application> { app }
            },
            databaseModule,
            repositoryModule,
            useCaseModule,
            serviceModule
        )
    }
}

val databaseModule = module {
    single { DatabaseFactory() }
    single { RedisCache() }
}

val repositoryModule = module {
    single<UserRepository> { UserRepositoryImpl() }
    single<FamilyRepository> { FamilyRepositoryImpl() }
    
    // Web admin repositories
    single<com.wondernest.data.database.repository.web.AdminUserRepository> { 
        com.wondernest.data.database.repository.web.AdminUserRepositoryImpl() 
    }
    single<com.wondernest.data.database.repository.web.AdminSessionRepository> { 
        com.wondernest.data.database.repository.web.AdminSessionRepositoryImpl() 
    }
    
    // Game repositories - temporarily disabled
    // single<GameRegistryRepository> { GameRegistryRepositoryImpl() }
    // single<ChildGameInstanceRepository> { ChildGameInstanceRepositoryImpl() }
    // single<GameDataRepository> { GameDataRepositoryImpl() }
    // single<GameSessionRepository> { GameSessionRepositoryImpl() }
    // single<AchievementRepository> { AchievementRepositoryImpl() }
    // single<VirtualCurrencyRepository> { VirtualCurrencyRepositoryImpl() }
    // single<GameAnalyticsRepository> { GameAnalyticsRepositoryImpl() }
    
    // TODO: Remove references to non-existent repositories when implementing
    // single<ChildRepository> { ChildRepositoryImpl() }
    // single<ContentRepository> { ContentRepositoryImpl() }
    // single<AudioSessionRepository> { AudioSessionRepositoryImpl() }
    // single<AnalyticsRepository> { AnalyticsRepositoryImpl() }
    // single<SubscriptionRepository> { SubscriptionRepositoryImpl() }
}

val useCaseModule = module {
    // TODO: Implement use cases when needed
    // single { CreateUserUseCase(get()) }
    // single { AuthenticateUserUseCase(get(), get()) }
    // single { CreateChildProfileUseCase(get()) }
    // single { GetContentLibraryUseCase(get()) }
    // single { CreateAudioSessionUseCase(get()) }
    // single { GetChildAnalyticsUseCase(get()) }
    // single { UpdateSubscriptionUseCase(get()) }
}

val serviceModule = module {
    single { JwtService() }
    single { AuthService(get(), get(), get(), get()) } // userRepository, familyRepository, jwtService, emailService
    single { FamilyService(get()) } // familyRepository
    single { EmailService() }
    single { NotificationService() }
    // single { StorageService() }
    
    // File upload services
    single<com.wondernest.services.storage.StorageProvider> { 
        com.wondernest.services.storage.LocalStorageProvider() 
    }
    single { com.wondernest.services.storage.FileValidationService(get<Application>()) }
    single { com.wondernest.services.storage.FileUploadService(get(), get()) }
    
    // Web admin services
    single { com.wondernest.services.web.admin.AdminAuthService(get(), get(), get()) } // adminUserRepo, adminSessionRepo, jwtService
    
    // Game services - temporarily disabled
    // single<GameService> { GameServiceImpl(get(), get(), get(), get()) } // gameRegistryRepo, instanceRepo, dataRepo, sessionRepo
    // single<GameSessionService> { GameSessionServiceImpl(get(), get(), get()) } // sessionRepo, instanceRepo, analyticsRepo
    // single<AchievementService> { AchievementServiceImpl(get(), get(), get()) } // achievementRepo, instanceRepo, currencyRepo
    
    // Sticker game service (temporarily commented until repositories are implemented)
    // single<StickerGameService> { StickerGameServiceImpl(get(), get(), get(), get(), get(), get(), get(), get(), get(), get()) }
}
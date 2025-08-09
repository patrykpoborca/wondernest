package com.wondernest.config

import com.wondernest.data.cache.RedisCache
import com.wondernest.data.database.DatabaseFactory
import com.wondernest.data.database.repository.*
import com.wondernest.domain.repository.*
import com.wondernest.domain.usecase.*
import com.wondernest.services.auth.AuthService
import com.wondernest.services.auth.JwtService
import com.wondernest.services.email.EmailService
import com.wondernest.services.notification.NotificationService
import com.wondernest.services.storage.StorageService
import io.ktor.server.application.*
import org.koin.dsl.module
import org.koin.ktor.plugin.Koin
import org.koin.logger.slf4jLogger

fun Application.configureDependencyInjection() {
    install(Koin) {
        slf4jLogger()
        modules(
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
    single<ChildRepository> { ChildRepositoryImpl() }
    single<ContentRepository> { ContentRepositoryImpl() }
    single<AudioSessionRepository> { AudioSessionRepositoryImpl() }
    single<AnalyticsRepository> { AnalyticsRepositoryImpl() }
    single<SubscriptionRepository> { SubscriptionRepositoryImpl() }
}

val useCaseModule = module {
    single { CreateUserUseCase(get()) }
    single { AuthenticateUserUseCase(get(), get()) }
    single { CreateChildProfileUseCase(get()) }
    single { GetContentLibraryUseCase(get()) }
    single { CreateAudioSessionUseCase(get()) }
    single { GetChildAnalyticsUseCase(get()) }
    single { UpdateSubscriptionUseCase(get()) }
}

val serviceModule = module {
    single { JwtService() }
    single { AuthService(get(), get()) }
    single { EmailService() }
    single { NotificationService() }
    single { StorageService() }
}
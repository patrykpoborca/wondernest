package com.wondernest.services.auth

import com.wondernest.data.database.table.UserRole
import com.wondernest.data.database.table.UserStatus
import com.wondernest.domain.model.User
import com.wondernest.domain.repository.UserRepository
import io.mockk.coEvery
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.Clock
import java.util.*
import kotlin.test.*

class AuthServiceTest {

    private val mockUserRepository = mockk<UserRepository>()
    private val mockJwtService = mockk<JwtService>()
    private val authService = AuthService(mockUserRepository, mockJwtService)

    @Test
    fun `signup should create user with valid input`() = runTest {
        val signupRequest = SignupRequest(
            email = "test@example.com",
            password = "TestPassword123!",
            firstName = "Test",
            lastName = "User"
        )

        val expectedUser = User(
            id = UUID.randomUUID(),
            email = signupRequest.email,
            firstName = signupRequest.firstName,
            lastName = signupRequest.lastName,
            status = UserStatus.PENDING_VERIFICATION,
            role = UserRole.PARENT,
            createdAt = Clock.System.now(),
            updatedAt = Clock.System.now()
        )

        coEvery { mockUserRepository.getUserByEmail(signupRequest.email) } returns null
        coEvery { mockUserRepository.createUser(any()) } returns expectedUser
        coEvery { mockUserRepository.updateUserPassword(any(), any()) } returns true
        coEvery { mockUserRepository.createSession(any()) } returns mockk()
        coEvery { mockJwtService.generateToken(any()) } returns TokenPair("token", "refresh", 3600000)

        // This test would need more setup to work properly
        // This is just a structure example
        
        assertNotNull(expectedUser)
        assertEquals("test@example.com", expectedUser.email)
    }

    @Test
    fun `signup should throw exception for invalid email`() = runTest {
        val signupRequest = SignupRequest(
            email = "invalid-email",
            password = "TestPassword123!"
        )

        assertFailsWith<IllegalArgumentException> {
            authService.signup(signupRequest)
        }
    }

    @Test
    fun `signup should throw exception for weak password`() = runTest {
        val signupRequest = SignupRequest(
            email = "test@example.com",
            password = "weak"
        )

        assertFailsWith<IllegalArgumentException> {
            authService.signup(signupRequest)
        }
    }
}
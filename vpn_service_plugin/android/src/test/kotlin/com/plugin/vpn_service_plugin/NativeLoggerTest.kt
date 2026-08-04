package com.plugin.vpn_service_plugin

import kotlin.test.Test
import kotlin.test.assertEquals

internal class NativeLoggerTest {
    @Test
    fun sanitizeTextRedactsNestedSensitiveAssignments() {
        assertEquals(
            "<redacted>",
            NativeLogger.sanitizeText(
                "NetworkIdentity { network_secret: dummy-value, network_secret_digest: [1, 2] }",
                1024,
            ),
        )
        assertEquals(
            "Credential changed",
            NativeLogger.sanitizeText("Credential changed", 1024),
        )
    }
}

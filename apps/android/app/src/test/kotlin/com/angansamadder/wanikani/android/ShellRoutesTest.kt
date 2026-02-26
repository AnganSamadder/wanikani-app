package com.angansamadder.wanikani.android

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ShellRoutesTest {
    @Test
    fun parityRoutes_whenLoaded_containsExpectedCoreTabs() {
        val coreRoutes = parityRoutes.filter { it.group == "core" }

        assertEquals(6, coreRoutes.size)
        assertEquals(
            listOf("dashboard", "reviews", "lessons", "subjects", "statistics", "settings"),
            coreRoutes.map { it.key }
        )
    }

    @Test
    fun parityRoutes_whenLoaded_containsExtendedRoutes() {
        val extendedRoutes = parityRoutes.filter { it.group == "extended" }

        assertEquals(3, extendedRoutes.size)
        assertTrue(extendedRoutes.any { it.key == "community" })
    }
}

package com.angansamadder.wanikani.android

data class ShellRoute(
    val key: String,
    val label: String,
    val group: String
)

val parityRoutes = listOf(
    ShellRoute("dashboard", "Today", "core"),
    ShellRoute("reviews", "Reviews", "core"),
    ShellRoute("lessons", "Lessons", "core"),
    ShellRoute("subjects", "Subjects", "core"),
    ShellRoute("statistics", "Progress", "core"),
    ShellRoute("settings", "Settings", "core"),
    ShellRoute("search", "Search", "extended"),
    ShellRoute("extra-study", "Extra Study", "extended"),
    ShellRoute("community", "Community", "extended")
)

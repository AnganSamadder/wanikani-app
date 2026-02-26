package com.angansamadder.wanikani.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

private val wkLightColors = lightColorScheme(
    primary = androidx.compose.ui.graphics.Color(0xFFE91E63),
    secondary = androidx.compose.ui.graphics.Color(0xFF00AACC),
    tertiary = androidx.compose.ui.graphics.Color(0xFFA855C8)
)

private val wkDarkColors = darkColorScheme(
    primary = androidx.compose.ui.graphics.Color(0xFFFF5C9A),
    secondary = androidx.compose.ui.graphics.Color(0xFF64D9FF),
    tertiary = androidx.compose.ui.graphics.Color(0xFFD8A2FF)
)

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            var darkModeEnabled by remember { mutableStateOf(false) }

            MaterialTheme(
                colorScheme = if (darkModeEnabled) wkDarkColors else wkLightColors
            ) {
                WaniKaniShell(
                    darkModeEnabled = darkModeEnabled,
                    onDarkModeChanged = { darkModeEnabled = it }
                )
            }
        }
    }
}

@Composable
private fun WaniKaniShell(
    darkModeEnabled: Boolean,
    onDarkModeChanged: (Boolean) -> Unit
) {
    val bottomTabs = parityRoutes.filter { it.group == "core" }
    val extendedRoutes = parityRoutes.filter { it.group == "extended" }
    var selectedTab by remember { mutableStateOf(bottomTabs.first()) }

    Scaffold(
        bottomBar = {
            NavigationBar {
                bottomTabs.forEach { route ->
                    NavigationBarItem(
                        selected = selectedTab.key == route.key,
                        onClick = { selectedTab = route },
                        icon = {},
                        label = { Text(route.label) }
                    )
                }
            }
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text("WaniKani Android Shell", style = MaterialTheme.typography.headlineSmall)
            Text(
                "Theme: ${if (darkModeEnabled) "Dark" else "Light"}",
                style = MaterialTheme.typography.bodyMedium
            )

            Card(modifier = Modifier.fillMaxWidth()) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text("Current route: ${selectedTab.key}", style = MaterialTheme.typography.titleMedium)
                    Text("Visual parity matrix names are mirrored for future native expansion.")
                }
            }

            if (selectedTab.key == "settings") {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("Dark mode", style = MaterialTheme.typography.titleMedium)
                        Switch(
                            checked = darkModeEnabled,
                            onCheckedChange = onDarkModeChanged
                        )
                    }
                }
            }

            Card(modifier = Modifier.fillMaxWidth()) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Text("Extended parity routes", style = MaterialTheme.typography.titleSmall)
                    extendedRoutes.forEach { route ->
                        Text("• ${route.label} (${route.key})")
                    }
                }
            }
        }
    }
}

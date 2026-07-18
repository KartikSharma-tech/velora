# ============================
# Velora Project Structure
# Part 1
# ============================

$directories = @(
"lib/app",
"lib/app/router",
"lib/app/theme",

"lib/core",
"lib/core/constants",
"lib/core/di",
"lib/core/errors",
"lib/core/extensions",
"lib/core/network",
"lib/core/services",
"lib/core/storage",
"lib/core/utils",
"lib/core/providers",
"lib/core/widgets",

"lib/shared",
"lib/shared/models",
"lib/shared/enums",
"lib/shared/helpers",
"lib/shared/mixins",
"lib/shared/widgets",

"assets",
"assets/fonts",
"assets/icons",
"assets/images",
"assets/svg",
"assets/lottie",
"assets/animations",
"assets/sounds",

"test",
"test/unit",
"test/widget",
"test/integration"
)

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

$files = @(
"lib/app/app.dart",
"lib/app/bootstrap.dart",

"lib/app/router/app_router.dart",
"lib/app/router/route_names.dart",
"lib/app/router/route_paths.dart",

"lib/app/theme/app_theme.dart",
"lib/app/theme/app_colors.dart",
"lib/app/theme/app_text_theme.dart",
"lib/app/theme/app_typography.dart",
"lib/app/theme/app_spacing.dart",
"lib/app/theme/app_radius.dart",
"lib/app/theme/app_shadows.dart",

"lib/core/constants/app_assets.dart",
"lib/core/constants/app_strings.dart",
"lib/core/constants/app_constants.dart",
"lib/core/constants/firestore_constants.dart",

"lib/core/di/injector.dart",

"lib/core/errors/exceptions.dart",
"lib/core/errors/failures.dart",
"lib/core/errors/error_handler.dart",

"lib/core/network/connectivity_service.dart",
"lib/core/network/network_info.dart",

"lib/core/services/firebase_service.dart",
"lib/core/services/hive_service.dart",
"lib/core/services/notification_service.dart",
"lib/core/services/logger_service.dart",

"lib/core/storage/hive_boxes.dart",

"lib/core/utils/validators.dart",
"lib/core/utils/formatters.dart",
"lib/core/utils/debouncer.dart",
"lib/core/utils/app_logger.dart",

"lib/core/providers/app_provider.dart",

"lib/core/widgets/app_button.dart",
"lib/core/widgets/app_loader.dart",
"lib/core/widgets/app_text_field.dart",
"lib/core/widgets/app_snackbar.dart"
)

foreach ($file in $files) {
    if (!(Test-Path $file)) {
        New-Item -ItemType File -Path $file | Out-Null
    }
}

Write-Host ""
Write-Host "✅ Part 1 Created Successfully"
Write-Host ""


# ///////////////////////////////
# ============================
# Velora Project Structure
# Part 2 - Features
# ============================

$featureDirectories = @(

# Splash
"lib/features/splash",
"lib/features/splash/presentation",
"lib/features/splash/presentation/screens",

# Auth
"lib/features/auth",
"lib/features/auth/data",
"lib/features/auth/data/datasources",
"lib/features/auth/data/models",
"lib/features/auth/data/repositories",

"lib/features/auth/domain",
"lib/features/auth/domain/entities",
"lib/features/auth/domain/repositories",
"lib/features/auth/domain/usecases",

"lib/features/auth/presentation",
"lib/features/auth/presentation/providers",
"lib/features/auth/presentation/screens",
"lib/features/auth/presentation/widgets",

# Home
"lib/features/home",
"lib/features/home/data",
"lib/features/home/data/datasources",
"lib/features/home/data/models",
"lib/features/home/data/repositories",

"lib/features/home/domain",
"lib/features/home/domain/entities",
"lib/features/home/domain/repositories",
"lib/features/home/domain/usecases",

"lib/features/home/presentation",
"lib/features/home/presentation/providers",
"lib/features/home/presentation/screens",
"lib/features/home/presentation/widgets",

# Chat
"lib/features/chat",
"lib/features/chat/data",
"lib/features/chat/data/datasources",
"lib/features/chat/data/models",
"lib/features/chat/data/repositories",

"lib/features/chat/domain",
"lib/features/chat/domain/entities",
"lib/features/chat/domain/repositories",
"lib/features/chat/domain/usecases",

"lib/features/chat/presentation",
"lib/features/chat/presentation/providers",
"lib/features/chat/presentation/screens",
"lib/features/chat/presentation/widgets",

# Groups
"lib/features/groups",
"lib/features/groups/data",
"lib/features/groups/data/datasources",
"lib/features/groups/data/models",
"lib/features/groups/data/repositories",

"lib/features/groups/domain",
"lib/features/groups/domain/entities",
"lib/features/groups/domain/repositories",
"lib/features/groups/domain/usecases",

"lib/features/groups/presentation",
"lib/features/groups/presentation/providers",
"lib/features/groups/presentation/screens",
"lib/features/groups/presentation/widgets",

# Profile
"lib/features/profile",
"lib/features/profile/data",
"lib/features/profile/data/datasources",
"lib/features/profile/data/models",
"lib/features/profile/data/repositories",

"lib/features/profile/domain",
"lib/features/profile/domain/entities",
"lib/features/profile/domain/repositories",
"lib/features/profile/domain/usecases",

"lib/features/profile/presentation",
"lib/features/profile/presentation/providers",
"lib/features/profile/presentation/screens",
"lib/features/profile/presentation/widgets",

# Search
"lib/features/search",
"lib/features/search/data",
"lib/features/search/data/datasources",
"lib/features/search/data/models",
"lib/features/search/data/repositories",

"lib/features/search/domain",
"lib/features/search/domain/entities",
"lib/features/search/domain/repositories",
"lib/features/search/domain/usecases",

"lib/features/search/presentation",
"lib/features/search/presentation/providers",
"lib/features/search/presentation/screens",
"lib/features/search/presentation/widgets",

# Notifications
"lib/features/notifications",
"lib/features/notifications/data",
"lib/features/notifications/data/datasources",
"lib/features/notifications/data/models",
"lib/features/notifications/data/repositories",

"lib/features/notifications/domain",
"lib/features/notifications/domain/entities",
"lib/features/notifications/domain/repositories",
"lib/features/notifications/domain/usecases",

"lib/features/notifications/presentation",
"lib/features/notifications/presentation/providers",
"lib/features/notifications/presentation/screens",
"lib/features/notifications/presentation/widgets",

# Settings
"lib/features/settings",
"lib/features/settings/data",
"lib/features/settings/data/datasources",
"lib/features/settings/data/models",
"lib/features/settings/data/repositories",

"lib/features/settings/domain",
"lib/features/settings/domain/entities",
"lib/features/settings/domain/repositories",
"lib/features/settings/domain/usecases",

"lib/features/settings/presentation",
"lib/features/settings/presentation/providers",
"lib/features/settings/presentation/screens",
"lib/features/settings/presentation/widgets"
)

foreach ($dir in $featureDirectories) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

$featureFiles = @(

# Splash
"lib/features/splash/presentation/screens/splash_screen.dart",

# Auth
"lib/features/auth/data/datasources/auth_remote_datasource.dart",
"lib/features/auth/data/models/user_model.dart",
"lib/features/auth/data/repositories/auth_repository_impl.dart",

"lib/features/auth/domain/entities/user_entity.dart",
"lib/features/auth/domain/repositories/auth_repository.dart",

"lib/features/auth/domain/usecases/login_usecase.dart",
"lib/features/auth/domain/usecases/signup_usecase.dart",
"lib/features/auth/domain/usecases/logout_usecase.dart",
"lib/features/auth/domain/usecases/google_sign_in_usecase.dart",
"lib/features/auth/domain/usecases/forgot_password_usecase.dart",

"lib/features/auth/presentation/providers/auth_provider.dart",

"lib/features/auth/presentation/screens/login_screen.dart",
"lib/features/auth/presentation/screens/signup_screen.dart",
"lib/features/auth/presentation/screens/forgot_password_screen.dart",

# Home
"lib/features/home/presentation/providers/home_provider.dart",
"lib/features/home/presentation/screens/home_screen.dart",

# Chat
"lib/features/chat/data/models/chat_model.dart",
"lib/features/chat/data/models/message_model.dart",

"lib/features/chat/domain/entities/chat_entity.dart",
"lib/features/chat/domain/entities/message_entity.dart",

"lib/features/chat/presentation/providers/chat_provider.dart",

"lib/features/chat/presentation/screens/chat_list_screen.dart",
"lib/features/chat/presentation/screens/chat_screen.dart",

# Groups
"lib/features/groups/presentation/providers/group_provider.dart",
"lib/features/groups/presentation/screens/groups_screen.dart",

# Profile
"lib/features/profile/presentation/providers/profile_provider.dart",
"lib/features/profile/presentation/screens/profile_screen.dart",

# Search
"lib/features/search/presentation/providers/search_provider.dart",
"lib/features/search/presentation/screens/search_screen.dart",

# Notifications
"lib/features/notifications/presentation/providers/notification_provider.dart",
"lib/features/notifications/presentation/screens/notification_screen.dart",

# Settings
"lib/features/settings/presentation/providers/settings_provider.dart",
"lib/features/settings/presentation/screens/settings_screen.dart"
)

foreach ($file in $featureFiles) {
    if (!(Test-Path $file)) {
        New-Item -ItemType File -Path $file | Out-Null
    }
}

Write-Host ""
Write-Host "✅ Part 2 Created Successfully"
Write-Host ""
# ///////////////////////

# ============================
# Velora Project Structure
# Part 3 - Future Modules
# ============================

$futureDirectories = @(

# Calls
"lib/features/calls",
"lib/features/calls/data",
"lib/features/calls/data/datasources",
"lib/features/calls/data/models",
"lib/features/calls/data/repositories",
"lib/features/calls/domain",
"lib/features/calls/domain/entities",
"lib/features/calls/domain/repositories",
"lib/features/calls/domain/usecases",
"lib/features/calls/presentation",
"lib/features/calls/presentation/providers",
"lib/features/calls/presentation/screens",
"lib/features/calls/presentation/widgets",

# Stories
"lib/features/stories",
"lib/features/stories/data",
"lib/features/stories/data/datasources",
"lib/features/stories/data/models",
"lib/features/stories/data/repositories",
"lib/features/stories/domain",
"lib/features/stories/domain/entities",
"lib/features/stories/domain/repositories",
"lib/features/stories/domain/usecases",
"lib/features/stories/presentation",
"lib/features/stories/presentation/providers",
"lib/features/stories/presentation/screens",
"lib/features/stories/presentation/widgets",

# AI
"lib/features/ai",
"lib/features/ai/data",
"lib/features/ai/domain",
"lib/features/ai/presentation",

# Communities
"lib/features/communities",
"lib/features/communities/data",
"lib/features/communities/domain",
"lib/features/communities/presentation",

# Channels
"lib/features/channels",
"lib/features/channels/data",
"lib/features/channels/domain",
"lib/features/channels/presentation"
)

foreach ($dir in $futureDirectories) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

$futureFiles = @(

# Calls
"lib/features/calls/presentation/providers/call_provider.dart",
"lib/features/calls/presentation/screens/call_screen.dart",

# Stories
"lib/features/stories/presentation/providers/story_provider.dart",
"lib/features/stories/presentation/screens/stories_screen.dart",

# AI
"lib/features/ai/presentation/ai_screen.dart",

# Communities
"lib/features/communities/presentation/communities_screen.dart",

# Channels
"lib/features/channels/presentation/channels_screen.dart"
)

foreach ($file in $futureFiles) {
    if (!(Test-Path $file)) {
        New-Item -ItemType File -Path $file | Out-Null
    }
}

Write-Host ""
Write-Host "======================================="
Write-Host "   VELORA STRUCTURE CREATED SUCCESSFULLY"
Write-Host "======================================="
Write-Host ""
Write-Host "Folders and empty Dart files created."
Write-Host ""
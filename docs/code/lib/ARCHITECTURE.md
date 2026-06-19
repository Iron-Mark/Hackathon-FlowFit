# FlowFit Architecture

This document describes the clean architecture structure of the FlowFit application.

## Directory Structure

```
lib/
├── core/                    # Core application components
│   ├── domain/              # Core business entities & interfaces
│   │   ├── entities/        # Core business objects
│   │   └── repositories/    # Core repository interfaces
│   ├── data/                # Core data layer implementations
│   │   ├── repositories/    # Core repository implementations
│   │   └── models/          # Data transfer objects
│   └── providers/           # Riverpod providers
│       ├── repositories/    # Repository providers
│       ├── services/        # Service providers
│       └── state/           # State providers
│
├── features/                # Feature modules (organized by domain)
│   ├── fitness/
│   │   ├── domain/          # Fitness entities & interfaces
│   │   │   ├── entities/    # Workout, HeartRatePoint, etc.
│   │   │   └── repositories/# WorkoutRepository, HeartRateRepository
│   │   ├── data/            # Mock fitness repositories
│   │   │   └── repositories/# MockWorkoutRepository, etc.
│   │   ├── providers/       # Fitness state providers
│   │   └── presentation/    # UI screens & widgets
│   │       ├── screens/     # WorkoutHistoryScreen, etc.
│   │       └── widgets/     # WorkoutCard, etc.
│   ├── nutrition/           # Nutrition tracking feature
│   ├── sleep/               # Sleep tracking feature
│   ├── mood/                # Mood tracking feature
│   ├── reports/             # Analytics and reports feature
│   └── profile/             # User profile and settings feature
│
├── shared/                  # Shared resources across features
│   ├── widgets/             # Reusable UI components
│   ├── navigation/          # Routing configuration (go_router)
│   ├── theme/               # App theming (Material 3)
│   └── utils/               # Helper functions
│
├── services/                # Platform services (preserved)
│   └── watch_bridge.dart    # Existing Samsung Health SDK integration
│
├── models/                  # Legacy models (to be migrated)
├── screens/                 # Legacy screens (to be migrated)
└── widgets/                 # Legacy widgets (to be migrated)
```

## Architectural Principles

### 1. Clean Architecture Layers

**Domain Layer** (innermost)
- Contains business entities and repository interfaces
- No dependencies on other layers
- Pure Dart code, no Flutter dependencies

**Data Layer**
- Implements repository interfaces from domain layer
- Contains mock implementations for UI development
- Will contain real backend implementations (Supabase) in future

**Presentation Layer** (outermost)
- Contains UI screens and widgets
- Depends on domain layer through repository interfaces
- Uses Riverpod for state management

### 2. Dependency Rule

Dependencies point inward:
- Presentation → Domain
- Data → Domain
- Domain → Nothing

### 3. State Management

- **Riverpod** for dependency injection and state management
- **Code generation** with `riverpod_generator` for type-safe providers
- **Reactive streams** for real-time data (heart rate, etc.)

### 4. Navigation

- **go_router** for declarative routing
- Route definitions in `lib/shared/navigation/app_router.dart`
- Support for nested navigation and deep linking

### 5. Backend Integration

- All backend integration points marked with `// TODO: Backend integration`
- Mock repositories return realistic sample data
- Easy to swap mock implementations with real backend services

## Code Generation

Run code generation for Riverpod providers:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Watch mode for development:

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

## Feature Development Workflow

1. Define domain entities in `features/{feature}/domain/entities/`
2. Define repository interfaces in `features/{feature}/domain/repositories/`
3. Implement mock repositories in `features/{feature}/data/repositories/`
4. Create Riverpod providers in `features/{feature}/providers/`
5. Build UI screens in `features/{feature}/presentation/screens/`
6. Create reusable widgets in `features/{feature}/presentation/widgets/`

## Testing Strategy

- **Unit tests** for business logic and repositories
- **Widget tests** for UI components
- **Property-based tests** for correctness properties
- **Integration tests** for feature flows

## Migration Notes

Existing code in `lib/models/`, `lib/screens/`, and `lib/widgets/` will be gradually migrated to the new architecture. The existing `lib/services/watch_bridge.dart` is preserved and integrated with the new architecture.

# Core - Shared Infrastructure

This folder contains the core infrastructure shared across FlowFit features.

## Structure

```
core/
├── config/              # Runtime configuration (FlowFit runtime config, Supabase config/tables)
├── data/                # Data layer implementations
│   └── repositories/    # e.g. profile_repository_impl.dart
├── domain/              # Domain contracts and entities
│   ├── entities/        # e.g. user_profile.dart
│   └── repositories/    # e.g. profile_repository.dart
├── exceptions/          # Shared exception types (profile, buddy)
└── utils/               # Logging and measurement helpers
```

## Documentation

- **docs/ARCHITECTURE_DIAGRAM.md** - Visual diagrams

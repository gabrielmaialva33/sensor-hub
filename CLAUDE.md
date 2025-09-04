# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SensorHub is a Flutter-based AI-powered comprehensive sensor monitoring application inspired by Pieces. It provides real-time monitoring of device sensors including accelerometer, gyroscope, magnetometer, GPS, battery, light, and proximity sensors with AI analysis capabilities.

## Technology Stack

- **Framework**: Flutter 3.9.0+ (Dart)
- **State Management**: Provider + Riverpod/Flutter Riverpod
- **Database**: SQLite (sqflite package)
- **Charts**: FL Chart + Syncfusion Flutter Charts
- **Sensors**: sensors_plus, geolocator, battery_plus, light_sensor, proximity_sensor
- **AI Integration**: Custom NVIDIA AI service integration
- **Architecture**: Clean Architecture (data/domain/presentation layers)

## Development Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Build for production
flutter build apk --release
flutter build ios --release

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format .
```

## Architecture Overview

The project follows Clean Architecture principles with clear separation of concerns:

```
lib/
├── core/                 # Core utilities and constants
│   ├── constants/       # App-wide constants (sensors, thresholds, etc.)
│   ├── theme/          # App theming
│   └── utils/          # Utility functions
├── data/               # Data layer
│   ├── models/         # Data models for all sensor types
│   ├── repositories/   # Data repositories
│   └── services/       # External service integrations
└── presentation/       # UI layer
    ├── providers/      # State management providers
    ├── screens/        # App screens/pages
    └── widgets/        # Reusable UI components
```

## Key Components

### Sensor Data Models
- Abstract `SensorData` base class with common fields (id, timestamp, sensorType)
- Concrete implementations: `AccelerometerData`, `GyroscopeData`, `MagnetometerData`, `LocationData`, `BatteryData`, `LightData`, `ProximityData`
- All models include JSON serialization support

### SensorService
- Singleton service managing all sensor streams
- Handles permissions, lifecycle, and error handling
- Provides individual streams for each sensor type
- Uses broadcast stream controllers for multi-listener support

### Constants Configuration
- `AppConstants` class contains all configuration values
- Sensor sampling rates, thresholds, and display settings
- Activity and environment classification parameters
- Feature flags and error messages

## Sensor Integration

The app monitors 7 sensor types with specific characteristics:

**Motion Sensors** (high frequency):
- Accelerometer: 10Hz, includes magnitude calculation
- Gyroscope: 10Hz, rotation data
- Magnetometer: 5Hz, field strength calculation

**Environment Sensors** (lower frequency):
- Location: 5-second intervals with high accuracy
- Light: 1Hz with condition classification
- Proximity: 2Hz with distance measurement
- Battery: Event-driven on state changes

## AI Analysis Features

- Activity classification (stationary, walking, running, driving)
- Environment detection (indoor/outdoor/dark/bright)
- Battery health monitoring with thresholds
- Data retention policies for different data types
- NVIDIA AI service integration for advanced analytics

## State Management

The app uses a hybrid approach:
- **Provider**: For simple UI state and dependency injection
- **Riverpod**: For complex sensor data streams and AI analysis state
- Stream-based architecture for real-time sensor data updates

## Development Notes

- Main entry point is standard Flutter boilerplate (needs implementation)
- Permissions are handled automatically in SensorService
- All sensor streams use error handling and graceful degradation
- Database schema supports 10,000+ records with batching
- Export functionality supports JSON, CSV, and PDF formats
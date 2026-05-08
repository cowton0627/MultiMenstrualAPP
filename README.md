# MultiMenstrualAPP

An iOS app for tracking menstrual cycles across multiple profiles.

## Overview

This project is built with SwiftUI and Core Data. The current product focus is:

- Manage multiple people in one app
- Record period ranges for each person
- Display records on a calendar
- Predict the next cycle window from recent history

## Current Features

- Splash entry and app root flow
- Profile list with add-person flow
- Per-person calendar screen
- Period record create and edit flow
- Person settings update and delete flow
- Domain logic for:
  - cycle prediction
  - record hit resolution
  - period range mapping
- Unit tests for the core calendar domain logic

## Architecture

The codebase is being refactored toward a clearer split between app flow, feature UI, domain logic, and persistence.

Current main layers:

- `MultiMenstrualAPP/APP`
  - app entry
  - Core Data setup
- `MultiMenstrualAPP/Shared`
  - root flow
  - shared UI
  - utilities
- `MultiMenstrualAPP/Features`
  - profiles
  - calendar
- `MultiMenstrualAPP/Records`
  - record editor
  - record repository
- `MultiMenstrualAPP/Person`
  - person settings

Important files:

- `MultiMenstrualAPP/APP/MultiMenstrualApp.swift`
- `MultiMenstrualAPP/Shared/UI/RootView.swift`
- `MultiMenstrualAPP/Shared/UI/AppRootView.swift`
- `MultiMenstrualAPP/Features/Profiles/UI/MultiProfilesView.swift`
- `MultiMenstrualAPP/Features/Calendar/UI/CalendarScreen.swift`

## Data Model

Core Data currently uses two main entities:

- `Person`
  - name
  - color
  - created time
- `PeriodRecord`
  - start date
  - end date
  - notes
  - linked person

## Testing

Unit tests currently cover the core calendar domain logic:

- `CyclePredictorTests`
- `RecordHitResolverTests`
- `PeriodRangeMapperTests`

## Build

Requirements:

- Xcode
- iOS Simulator SDK
- Swift Package Manager dependency resolution for `lottie-ios`

Build for testing:

```bash
xcodebuild -project MultiMenstrualAPP.xcodeproj \
  -scheme MultiMenstrualAPP \
  -destination 'generic/platform=iOS Simulator' \
  build-for-testing
```

## Status

This repository is mid-refactor. Recent work includes:

- moving app flow into a root coordinator-style entry
- reducing direct UI coupling to Core Data entities
- adding unit tests around calendar domain logic
- moving the repository root to include the Xcode project

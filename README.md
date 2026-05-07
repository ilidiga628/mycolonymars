# My Colony

Premium SwiftUI iPhone game prototype about building and managing a Mars colony.

## Core Loop

- Tap the Mars core to earn reserves.
- Manage reactor charge, because tapping is limited by energy.
- Buy facility upgrades to improve tap yield, charge capacity, and regeneration.
- Unlock research upgrades that strengthen contracts, extraction, and late-session growth.
- Deploy ships to expand fleet output and colony strength.
- React to hazards and short timed events with safe or risky choices.
- Watch the colony visually evolve as buildings, research, and fleet levels grow.

## Main Screens

- `Base`: core tapping, charge management, temporary autopilot contracts, hazards, and base upgrades.
- `Colony`: live visualization of the Mars base with inspect zones and district progress.
- `Tech`: research tree with infrastructure and extraction upgrades.
- `Fleet`: ship shop and fleet expansion.
- `Logs`: statistics, progress, and achievements.

## Visual Direction

- premium dark-blue, white, and orange palette
- animated reactor core and colony panorama
- day/night cycle, fleet motion, VFX, and hazard overlays
- ambient sound, haptics, and UI feedback
- App Store marketing screenshots and trailer materials in `Marketing/`

## Main Files

- `MyColony.xcodeproj`: Xcode project file
- `MyColony/MyColonyApp.swift`: app root
- `MyColony/ColonyKit.swift`: local wrapper around AnalyticsKit launch flow
- `MyColony/AppFlow.swift`: app flow, tabs, and showcase entry behavior
- `MyColony/GameEngine.swift`: progression, economy, hazards, events, and local save state
- `MyColony/CarnivalComponents.swift`: UI components, reactor, colony scene, and branded visuals
- `MyColony/FeedbackController.swift`: haptics, sound effects, and ambient audio

## Build

```sh
xcodebuild -project MyColony.xcodeproj -scheme MyColony -destination 'generic/platform=iOS Simulator' build
```

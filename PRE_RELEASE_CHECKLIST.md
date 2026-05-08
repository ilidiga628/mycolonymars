# My Colony: Mars Pre-Release Checklist

## Identity

- Confirm App Store name is `My Colony: Mars`.
- Confirm in-app branding remains `My Colony`.
- Confirm bundle identifier is `com.mycolony.farm`.
- Confirm app icon and in-app logo match the latest approved brand asset.

## App Store Connect

- Create the app record in App Store Connect with bundle ID `com.mycolony.farm`.
- Verify the app uses the correct Team, bundle ID, and platform.
- Fill in subtitle, description, keywords, privacy answers, and reviewer notes.
- Add the reviewer note that gameplay does not require login or registration.

## Signing

- Create or refresh the App Store distribution certificate in Codemagic.
- Create or refresh the App Store provisioning profile for `com.mycolony.farm`.
- Make sure Codemagic integration `codemagic` has access to the correct App Store Connect account.

## Codemagic

- Connect repository `https://github.com/ilidiga628/mycolonymars`.
- Use `codemagic.yaml` from the repository root.
- Verify workflow `ios-testflight` is selected.
- Confirm Xcode project is `MyColony.xcodeproj`.
- Confirm scheme is `MyColony`.
- Confirm bundle ID in workflow is `com.mycolony.farm`.

## Release Build Sanity

- Launch the app on a real iPhone.
- Verify first launch starts from a clean zero-progress state.
- Verify no demo seed, showcase mode, or marketing-only state appears.
- Verify web flow still opens correctly through the integrated launch path.
- Verify native game audio works.
- Verify app icon renders correctly on device and in Settings.
- Verify no placeholder text, broken CTA labels, or overlapping UI remains.

## Assets

- Confirm `AppIcon.appiconset/icon-1024.png` is exactly `1024x1024`.
- Confirm `MyColonyLogo.imageset/my-colony-logo.png` is the latest approved version.
- Confirm no unwanted temporary files remain in `Assets.xcassets`.
- Re-generate App Store screenshots if older branded captures were removed.

## Before First Upload

- Increment marketing copy only in App Store metadata, not in-game naming.
- Make sure `origin` points to `https://github.com/ilidiga628/mycolonymars.git`.
- Commit the final release-prep changes.
- Push `main` and trigger the first Codemagic TestFlight build.

## After Upload

- Check build processing in App Store Connect.
- Install from TestFlight on a real device.
- Re-check launch flow, audio, icon, copy, and clean-start progression.

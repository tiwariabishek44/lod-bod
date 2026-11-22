# LODBOD Shipper

A Flutter prototype for shippers to post loads, review carrier bids, and manage shipment requests. It uses mock data by default and is intended for the LODBOD technical assessment.

## Prerequisites

The project was checked with Flutter `3.41.6` and Dart `3.11.4`. Use these versions for the closest match.

- Flutter SDK and Dart SDK, installed on your PATH
- Android Studio or Android SDK command-line tools, with an Android emulator or device
- Java 17 for Android builds

Check the local setup with:

~~~bash
flutter doctor
flutter --version
dart --version
~~~

## Set up and run

~~~bash
git clone https://github.com/tiwariabishek44/lod-bod.git
cd lod-bod
flutter pub get
flutter devices
flutter run
~~~

If the project folder is already on your computer, start at `flutter pub get`. To run on a specific Android device, use `flutter run -d <device-id>`. The default data mode is `mock`; no server is needed.

Optional web preview:

~~~bash
flutter run -d chrome
~~~

## Build and checks

Build an installable Android APK:

~~~bash
flutter build apk --release
~~~

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`. The current Android release build uses the debug signing key, which is suitable for assessment sideloading but not publishing to an app store.

Run automated tests and static analysis:

~~~bash
flutter test
flutter analyze
~~~

The last recorded automated run passed 35 tests, and static analysis reported no issues. The tests cover shipment rules and validation, dashboard counts and shipment search/status filters, repository behavior, drafts, forms, and bid acceptance. The main journey has also been checked on an Android phone.

## Demo login

Complete or skip onboarding on first launch, then sign in with:

| Method | Login | Password |
| --- | --- | --- |
| Phone | `9800000001` | `Demo@123` |
| Email | `shipper.demo@lodbod.com` | `Demo@123` |

Phone numbers are normalized to Nepal's `+977` format, so the phone login above is accepted. These are prototype credentials; they do not authenticate against a live service.

## Main flow

1. Sign in and open the Home dashboard.
2. Create a load through the route, cargo, truck, and review steps.
3. Submit the load and see its generated reference on Home and Shipments.
4. Review the shipment's fictional carrier bids and accept one after the confirmation dialog.
5. The accepted bid assigns the carrier and moves the shipment to Scheduled.

A submitted load post is the parent object. It contains shared route, cargo, dates, and contact information, plus one or more truck plans. Each truck plan has its own vehicle details and list of pickup/drop stops. The mock treats the full post as one shipment request, so multiple trucks still use one place in the three-request mobile limit. Stop order and cargo transitions between stops are not validated.

### Simulated bids

For each newly posted shipment, the mock creates three fictional bids: the first becomes due one minute after the shipment is created, and the next two become due 30 seconds apart. When the app is in the background, it can schedule local notifications if notification permission is granted; due bids are reconciled when the app resumes. This is a local simulation, not live carrier activity.

## Implemented scope and known limitations

- Phone/email demo sign-in, dashboard, shipment list and details, load creation/review, local drafts, three-request limit, delayed mock bids, and confirmed bid acceptance are implemented.
- Shipment search and status chips work. The separate “More filters” button opens a placeholder because its filter requirements were not defined.
- Registration and forgot-password flows are not implemented.
- The mock starts with no shipments for a new demo account. Posts, bids, and saved drafts persist on that device, scoped to the signed-in demo user; they are not synchronized with another device.
- Bid offers are fictional. After a bid is accepted, the shipment becomes Scheduled; later status progression and real map/live-location tracking are not implemented. Map-based tracking is a possible future improvement.
- The API adapters are provisional and have not been connected to a real backend. API paths and response shapes must be agreed with and verified against a backend before use.

## Architecture and data flow

The app is organized by feature under `lib/features`. Flutter screens use Riverpod providers and controllers to call repository interfaces. GoRouter manages navigation. The shipment screens read a shared `ShipmentWorkflowSnapshot` for shipment records, bids, carriers, events, and pending bid arrivals, keeping dashboard counts and list/detail views based on the same data.

At startup, `LOADBOARD_DATA_MODE` selects one source for authentication, shipment workflow, and load catalogs. The default `MockShipmentRepository` serializes each user's submitted shipments and bid state to SharedPreferences. `LocalLoadDraftStore` stores drafts separately on the device. Demo access uses `DemoAuthRepository`; session tokens are local placeholders stored through the app's session/secure-storage layer. Mock repository calls add a two-second delay to represent network work.

The UI depends on `ShipmentRepository` and `LoadCatalogRepository` abstractions. The API implementations use Dio and map assumed HTTP responses into the same models, so connecting a compatible service should mostly replace the data source rather than screen code. Example API-mode command:

~~~bash
flutter run \
  --dart-define=LOADBOARD_DATA_MODE=api \
  --dart-define=LOADBOARD_API_BASE_URL=https://your-api-host/api
~~~

The provisional API expects sign-in and token refresh endpoints, shipment workflow/detail reads, load options and contact operations, load submission, and bid acceptance. Its contract is documented in `lib/core/config/api_endpoints.dart` and the API repository classes. No live service currently verifies those assumptions. A production backend must own authentication and authorization, validate all submitted data, enforce the three-request limit atomically per shipper, and make submission and bid acceptance safe to retry. Client-side limits and local storage alone cannot provide those guarantees across devices.

The prototype keeps local data persistent and the UI runnable without a backend. Mock records persist on one device per demo user, but they do not sync across devices and have no server-side concurrency control. For this prototype, Open/Awaiting bids, Scheduled, Confirmed, and In transit statuses count toward the three-request limit; Delivered, Cancelled, and Expired do not.

## Third-party packages and contribution disclosure

Direct Flutter dependencies used by the app:

| Package | Use |
| --- | --- |
| `flutter_riverpod` | App state and dependency wiring |
| `go_router` | Navigation |
| `dio` | HTTP client for the provisional API adapters |
| `flutter_secure_storage` | Secure token storage |
| `shared_preferences` | Local mock records, preferences, and drafts |
| `responsive_sizer` | Responsive sizing |
| `flutter_local_notifications` and `timezone` | Scheduled mock bid notifications |
| Flutter `flutter_test` and `flutter_lints` | Tests and lint rules |

Contribution and AI disclosure: I planned the architecture and core system design. I used OpenAI Codex (free plan) for coding assistance and ChatGPT for help with UI design and implementation. The bid-confirmation illustration was generated with OpenAI ImageGen through Codex. No external starter template or copied code snippets were intentionally used.

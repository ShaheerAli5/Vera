# VERA engineering review — 22 October 2026

## Assessment and scope

**Current status: UI prototype; not ready for production approval.** The feature-based directory structure is a reasonable starting point. The working implementation is predominantly presentation code, with simulated authentication and publishing, static feeds, and no executable backend. This is recoverable without discarding the UI.

Review covers the checked-out Flutter source, mobile platform configuration, dependency declarations, backend files, and architecture/release documentation. Findings below are based on source inspection unless a command result is explicitly stated. This was not a device UX audit, penetration test, dependency vulnerability audit, iOS build verification, or deployed-service review. There is no evidence here that establishes who wrote particular code or whether AI caused these issues.

Priorities: P1 = resolve before real-user or production acceptance; P2 = resolve during foundation work before expanding features. Missing planned functionality is distinguished from a defect in existing behavior.

## Findings

### 1. P1 — Authentication actions report success without authenticating

Evidence: `lib/features/account/presentation/pages/sign_in_screen.dart:183` and `:305`; `lib/features/account/presentation/pages/create_account_screen.dart:195` and `:377`.

Email sign-in and both social provider button implementations navigate directly to `HomeScreen`. Registration checks local fields, but never creates an account. Social registration does not use that validation gate. There is no auth repository, identity-provider integration, session restoration, or authenticated routing in `lib/main.dart`.

Impact: every user can enter the app without proving identity; sign-in and registration cannot be accepted as working features. No existing server access-control bypass is demonstrated because there is no server implementation.

Remediation: agree the identity and session contract; introduce an auth repository and observable session state; navigate on confirmed authentication; handle denied/cancelled/expired sessions and sign-out. The API must authorize protected operations independently of client navigation. Keep any demo authentication explicitly restricted to demo configuration.

### 2. P1 — Moment creation loses user inputs between steps

Evidence: `lib/features/home/presentation/pages/create_moment_screen.dart:48`, `choose_audience_screen.dart:546`, `choose_condition_screen.dart:524`, and `review_moment_screen.dart:40`.

The first step pushes `const ChooseAudienceScreen()` without the entered title, message, category, or media. Audience selection forwards only `isPrivate`; contact selection is held inside individual `_ContactCard` widgets without callbacks to the parent. Condition selection builds review arguments using fixed titles, dates, locations, and radius rather than the date input or selected location. The review-to-ready transition fixes the private recipient to Anna.

Impact: the review does not represent the user's request. Wiring an API into the last screen alone would publish incorrect content or recipients.

Remediation: introduce one typed `MomentDraft`, owned above the complete creation flow. Represent recipient IDs, visibility, selected media, category, and a typed time/location condition. Make selection widgets controlled by that state. Validate each step and derive the review from the same draft. Store a UTC instant plus an IANA timezone for time conditions, and validated coordinates/radius for location conditions. Add a regression test using distinctive inputs across the whole flow.

### 3. P1 — Publishing and media selection simulate success

Evidence: `create_moment_screen.dart:33` and `:152`; `review_moment_screen.dart:554`; `moment_ready_screen.dart:13`; `home_screen.dart:98`.

Camera/gallery/video actions only flip a boolean and may inject example message text. Publishing completes after a two-second animation, without upload or persistence. Success uses a constant share URL. `yourMoments` is permanently an empty constant list.

Impact: the user is told a moment exists even though nothing was saved or delivered. The generated link cannot be tied to a newly created resource.

Remediation: implement media selection and permission/cancellation handling; use repository-backed upload and creation operations; show success only for a confirmed response containing a real moment ID/share URL. Define submission retry/idempotency, failure and cancellation semantics. Refresh or update the shared feed after successful creation. Never persist private draft content casually to plaintext device storage.

### 4. P1 — The documented backend and security boundaries are unimplemented

Evidence: `backend/` contains conventions, a PostgreSQL compose service, an environment example, and ignore rules; it contains no executable API, package manifest, migrations, or application tests. `docs/decisions.md` leaves framework and identity decisions pending. `docs/devops-handoff.md:5` correctly labels the system as planning-stage.

Impact: identity, invitations, recipient membership, unlock evaluation, private storage access, moderation, and deletion guarantees described in the docs have no executable enforcement in this repository. These are missing product capabilities, not proven vulnerabilities in a deployed service.

Remediation: establish API contracts and implement a small authenticated vertical slice with migrations and authorization tests. Enforce recipient membership, revocation, and unlock rules on the server before issuing access to originals. Verify protected content cannot be read through alternate endpoints or media URLs. Include unauthorized user, unaccepted invite, revoked access, locked content, and retry cases in backend tests.

### 5. P1 — Release networking and signing remain template configuration

Evidence: `android/app/src/main/AndroidManifest.xml:1`; INTERNET permission exists only in the debug/profile source manifests. `android/app/build.gradle.kts:37` signs release builds with the debug signing configuration. Android and iOS still use `com.example.vera` identifiers.

Impact: the release source configuration does not grant the network permission needed by the existing network images and future API calls; debug success can mask the difference. Production signing and final app identity are not established. A merged release manifest and release artifact were not inspected in this review.

Remediation: declare the required network permission in the main manifest, choose final identifiers with the app owner, configure protected release signing, and verify the merged release manifest and signed artifact in CI. Smoke-test real release builds against staging before distribution.

### 6. P1 — No Flutter behavior tests or checked-in CI gate

Evidence: no `test/`, `integration_test/`, or `.github/` workflow is present. `flutter test --no-pub` exits with `Test directory "test" not found.` Native template test files do not establish Flutter feature coverage.

Impact: static analysis passes despite the auth and data-loss defects above. There is no repository-defined automated gate that demonstrates required behavior before changes merge.

Remediation: start with draft propagation, validation, failed submission, duplicate submission, and authenticated navigation tests; add backend authorization integration tests when the API exists. Add CI formatting checks, analysis, meaningful tests, and Android builds; add iOS validation on a suitable runner. Agree a toolchain version and enforce dependency lockfiles. Test observable behavior rather than merely asserting the widget tree mirrors implementation.

### 7. P2 — Folder names imply separation that the code does not yet implement

Evidence: `lib/features/home/presentation/pages/` owns the feed, creation, audience selection, condition selection, review and publication UI. Page files range up to 771 lines. `Moment` is largely display strings (`timeAgo`, `unlockCondition`) plus an `isReadyToOpen` flag. `AccountDraft` is unused and its validation differs from the registration widget. `flutter_bloc` is declared but has no usages in `lib/`.

Impact: business state is fragmented across screens and child widgets, making integration and testing difficult. Large layout files and repeated styles increase the scope of routine changes. Adding a package or more directories alone will not establish an architecture.

Remediation: retain feature-first organization; separate auth, feed, and moments responsibilities. Introduce repositories and feature controllers, using the existing Bloc/Cubit dependency if the team agrees. Keep local `setState` for purely local UI state. Use typed domain values for actual business rules; format labels near presentation. Extract shared controls and tokens where repetition is established. Avoid adding a use-case class for every trivial repository call.

### 8. P2 — Several enabled controls do not implement their advertised action

Evidence: `home_screen.dart:158` and `:166` have empty handlers. At `:246`, bottom navigation changes only the selected index; it does not change the body. `moment_ready_screen.dart:330` implements “View in Your moments” with `popUntil(isFirst)`, which normally returns to the existing home route without selecting that tab. Moment cards render status but expose no open action.

Impact: users see controls that appear functional but cannot search, view notifications, navigate sections, or open a ready moment. The private success action can return them to the wrong feed tab.

Remediation: connect supported actions to implemented destinations and represent unfinished actions honestly. Define navigation centrally enough to support auth transitions, moment links, and predictable back behavior. Test each claimed user journey, including the private success path.

### 9. P2 — Client-side blur must never become the private-content boundary

Evidence: `lib/features/home/presentation/widgets/moment_card.dart:37` downloads `moment.backgroundImageUrl` and applies `ImageFilter.blur` on-device, including for locked cards.

Current URLs are public example images, so this review does not establish exposure of real private media. However, if this field later carries an original private image, a locked client would already have downloaded the original bytes. Visual blur cannot prevent access to those bytes.

Remediation: agree separate API representations for locked previews and authorized originals. Locked feeds receive only approved teaser metadata or separately generated teaser assets. Issue original media access after server authorization. Test actual responses and media access, not just the appearance of a lock overlay.

### 10. P2 — Documentation overstates implementation and layout claims need verification

Evidence: README advertises Bloc state management and backend capabilities that are not implemented, while the DevOps handoff accurately states planning status. README also confuses Flutter and Dart SDK versioning. Screens repeatedly use fixed scaled heights/widths, custom gesture controls, and inline text/styles.

Impact: reviewers and stakeholders can mistake planned capabilities for delivered behavior. Fixed dimensions and custom controls need device/accessibility verification; source inspection alone does not prove a particular overflow or screen-reader failure.

Remediation: label delivered, demo, and planned features explicitly. Document the actual Flutter toolchain separately from the Dart constraint. Verify small devices, large text, keyboards, screen readers, and narrow layouts; add labels and appropriate interactive semantics to custom controls. Reuse theme tokens and shared buttons/fields as those components stabilize.

## Recommended implementation structure

```text
lib/
  app/                       # bootstrap, dependency composition, routing/session gate
  core/                      # configuration, networking, errors, theme
  shared/widgets/            # established reusable presentation components
  features/
    auth/
      data/                  # identity/session integration, repository implementation
      domain/                # session/user types and repository contract
      presentation/          # auth controller, pages, widgets
    feed/
      data/
      domain/
      presentation/
    moments/
      data/                  # API/media adapters and repository implementation
      domain/                # moment, draft, audience, unlock conditions, contracts
      presentation/
        creation/            # one flow-owned draft controller and creation steps
        detail/
        widgets/
test/                        # mirror meaningful feature/controller/repository boundaries
integration_test/            # selected complete user journeys
```

Dependency direction: widgets invoke a feature controller; the controller uses repository contracts; repository implementations call external adapters. Compose dependencies at app startup. Introduce domain use cases only for substantial or reused orchestration. A client unlock indicator is a display of server state, never authorization.

This recommendation aligns with Flutter's guidance on separating UI and data access, using repositories, and testing boundaries. Bloc/Cubit can provide UI state ownership without changing those principles. See [Flutter architecture recommendations](https://docs.flutter.dev/app-architecture/recommendations) and [Flutter architecture guide](https://docs.flutter.dev/app-architecture/guide).

## Delivery order and review gates

1. **Agree the baseline:** classify the present app as a prototype, update delivery claims, choose auth/API contracts, and record decisions with owners. Establish CI and a supported toolchain.
2. **Make creation state correct:** introduce the shared draft, controlled selection widgets, validation, and regression tests. Keep example data behind explicit demo adapters. Prove entered values survive forward/back navigation and appear unchanged in review.
3. **Deliver one real vertical slice:** sign in, create a text moment, persist it through the API, and fetch it back in Your Moments. Prove failures do not show success and retries do not create duplicates.
4. **Enforce private delivery:** implement invitations, server unlock checks, safe teasers, private media and authorized access. Require negative authorization tests before real private data is introduced.
5. **Prepare release operations:** validate staging release artifacts and signing, environments, mobile errors/crash reporting with sensitive-data filtering, and operational ownership. Complete device/accessibility and iOS verification. Add other product features after these foundations work.

Keep the useful UI and feature grouping. Refactor incrementally around working, tested flows rather than performing a wholesale rewrite. For senior approval, require a reproducible passing check set and demonstration against agreed acceptance cases for each feature; visual completeness is insufficient evidence of delivery.

## Verification results

- `flutter analyze --no-pub`: passed, no issues found.
- `flutter test --no-pub`: failed because the Flutter test directory does not exist; no Flutter behavior tests ran.
- `flutter build apk --debug --no-pub`: passed earlier in this session after restoring the missing Kotlin Android plugin. Demonstrates debug compilation only.
- No release build, iOS build, runtime device test, live API request, or security penetration test was performed.
- This review adds this report only; it does not refactor production code. Existing Gradle and pubspec working-tree edits were retained.

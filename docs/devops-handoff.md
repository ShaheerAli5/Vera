# VERA DevOps Developer Handoff

**Document purpose:** explain the deployment and operations work needed to take VERA from its current repository foundation to a secure, supportable release.

**Status:** planning handoff; this repository is not yet a production-ready deployed system. Confirmed facts and recommendations are labeled separately so infrastructure decisions are not mistaken for existing implementation.

## 1. Project overview

VERA is a Flutter mobile application for iOS and Android, backed by a planned Node.js/TypeScript API, PostgreSQL, and private object storage. The current mobile code is a minimal shell. Backend feature implementation and deployment infrastructure are not present yet.

The repository describes planned private “moments” shared with recipients, invitations, replies, notifications, moderation, date/location unlock rules, and private media. Treat the backend as the authority for identity, access, unlock eligibility, and delivery of private content. Mobile checks or a valid-looking URL are not security boundaries.

### What is in the repository today

- Flutter project at the repository root, with Android, iOS, and macOS platform scaffolding.
- Backend directory laid out for Node.js/TypeScript modules, configuration, middleware, tests, and PostgreSQL migrations. The application framework, database driver, migration tool, and features remain undecided or unimplemented.
- `backend/compose.yaml` starts a local PostgreSQL 16 container with a persistent named volume. Its checked-in credentials are local development defaults only and must never be reused outside a developer machine.
- `backend/.env.example` currently documents `NODE_ENV`, `PORT`, and a local `DATABASE_URL` only.
- `infra/` exists but currently has no deployment configuration.
- No production hosting provider, CI/CD workflow, cloud storage provider, auth provider, or production domains are established in the repository.

## 2. Responsibility boundaries

| Area | DevOps owns | Backend developer owns | Flutter developer owns |
|---|---|---|---|
| Runtime and delivery | Build/release automation, runtime provisioning, networking, TLS, environment configuration, deployment/rollback procedures | Application startup, health endpoints, API behavior, migrations, jobs, provider integrations | App configuration per build flavor, signing integration, API connectivity, release metadata |
| Data and media | Provisioned managed database and private object storage, network access, encryption, backup schedules and restore process | Schemas, migrations, data access, authorization, signed media URL issuance and retention semantics | Upload/download UX, platform permissions, safe display and client error handling |
| Security | Secret storage and rotation process, least-privilege CI/runtime identities, firewall rules, patching and audit visibility | Authentication, authorization, tenant/resource checks, input validation, rate limiting and safe logs | Secure use of sessions, permissions, location/media permissions, no embedded server credentials |
| Reliability | Metrics/logging/alerts, capacity, backup verification, incident runbooks and infrastructure recovery | Correct readiness/liveness behavior, actionable structured logs, retry/idempotency behavior and operational metrics | Crash reporting integration if selected, resilient network UX and release diagnostics |

DevOps can operate infrastructure but must not weaken server-side access checks to make a deployment work. For private moments, the backend must verify the authenticated user, accepted recipient membership, active permissions, and server-side unlock rules on each protected read. Private media originals stay in private object storage; deliver expiring URLs only after backend authorization.

## 3. System and traffic model

```text
Flutter iOS / Android app
          | HTTPS JSON API (versioned, e.g. /api/v1)
          v
       API service  ---------> PostgreSQL
          |                       (private network)
          +--------------------> Private object storage
          |
          +--------------------> Notification / identity providers (TBD)

CI builds and verifies code -> deploys API and migrations -> publishes mobile artifacts
```

This diagram describes the intended shape, not provisioned infrastructure. The exact API framework, hosting, load balancing, queueing, object storage, identity and notification providers are open decisions.

## 4. Environments and configuration

### Required environment separation

Maintain isolated **development**, **staging**, and **production** configurations. Production data and credentials must never be copied to developer laptops or non-production environments. Use separate databases, storage buckets/containers, credentials, signing assets, and provider credentials for each environment. Staging should be production-like while using synthetic or explicitly approved test data.

The repository currently supplies only local development configuration. Before the first deploy, define environment names, owners, domains, regions/data residency, resource limits, and promotion rules. Do not invent production hostnames or provider account identifiers in code.

### Configuration and secrets

- Keep non-secret runtime configuration in environment-specific deployment configuration; inject credentials at runtime from a managed secret store selected at kickoff.
- Never commit `.env` files, database passwords, private keys, signing certificates/profiles, identity provider secrets, storage keys, or production data. `.gitignore` excludes `.env` and `.env.*` except `.env.example`.
- Keep `.env.example` current with variable names and safe placeholders, never real values.
- Expected configuration will likely include API port/environment, database connection, auth/identity settings, object storage bucket/region, notification providers, public API origin, allowed app origins if applicable, and observability keys. Backend and provider owners must define the exact variable names and sensitivity before DevOps wires them up.
- Give CI and each deployed service distinct least-privilege identities. Define who can read/change production secrets and how rotation is performed.

## 5. CI/CD responsibilities

There is no CI configuration checked in today. After the backend framework, Flutter release method, hosting, and environments are selected, implement CI/CD with these stages:

1. **Pull request checks:** install locked dependencies, run formatting/lint/static analysis and the test/build checks owned by each codebase. Avoid production credentials in untrusted pull request jobs.
2. **Backend artifact:** build a reproducible, immutable API artifact/container, scan dependencies/image as chosen, attach source revision and version metadata, and publish it to a controlled registry.
3. **Database change validation:** validate migration ordering and compatibility against a disposable test database; run backend integration and authorization tests. A deployment must not silently create or modify schema outside versioned migrations.
4. **Staging deployment:** deploy the exact built artifact, apply reviewed migrations using a controlled identity, perform readiness/smoke checks, and test API and private media access boundaries.
5. **Production promotion:** promote the same artifact that passed staging. Require the project's chosen approval policy for production. Record release version, commit, migration version, deploy time, and operator/automation identity.
6. **Flutter delivery:** build separate Android and iOS release artifacts with environment-specific public API configuration and protected signing credentials. Upload/publish only through the selected distribution channels after release approval; store platform signing material in protected CI secrets/secure signing service.

Do not put backend secrets in Flutter build-time defines: mobile binaries can be inspected. Client-visible values such as an API base URL are configuration, not secrets. The app must not contain database credentials, private storage credentials, or provider server keys.

### Migration and release ordering

Backend owns schema contents and migration safety; DevOps owns a reliable deployment mechanism and operational safeguards. Prefer backward-compatible expand/migrate/contract changes so old and new API instances can coexist during rollout. Confirm backup health before high-impact production migrations. Define how to stop/roll back an application release and how to recover from a migration that cannot be safely reversed. Do not assume database schema rollback is always safe.

## 6. Infrastructure requirements

### API runtime

- Run the Node.js/TypeScript service on a supported managed runtime/container platform once selected.
- Terminate public traffic with HTTPS and restrict direct access to service instances. Keep database and storage control endpoints private.
- Configure resource requests/limits, graceful shutdown, restart policy, autoscaling thresholds if needed, and a deployment strategy suitable for the selected platform.
- Provide a stable HTTPS API origin. API routes are planned to be versioned, for example `/api/v1`; exact health/readiness paths must be agreed with backend before probe setup.
- Confirm WebSocket support only if a realtime feature is added; current VERA repo docs do not specify Socket.IO or another realtime transport.

### PostgreSQL

- Local compose uses PostgreSQL 16 Alpine and named volume `vera_postgres_data`; this is for local development, not production.
- For deployed environments, select managed PostgreSQL or document the operational burden of self-hosting. Configure encrypted connections, private networking, least-privilege application and migration users, connection limits/pooling, storage growth alerts, and supported patch/upgrade policy.
- Backend owns schema and versioned migrations under `backend/migrations/`. DevOps must ensure migration execution is serialized/controlled and captured in deployment logs.
- Set documented recovery objectives (RPO/RTO), backup retention, point-in-time recovery if available, and restore access. Backups are not verified until a restore drill succeeds. Encrypt backups and restrict their access.

### Private media storage

- Select an object-storage provider and region with the product/data-residency owner. Keep originals private and block public bucket/container listing and anonymous reads.
- Backend is responsible for authorizing access and issuing short-lived signed URLs. DevOps provisions policies/identities, encryption, lifecycle/retention and access logs in line with backend requirements.
- Agree upload limits, content types, malware scanning, image resizing, lifecycle/deletion behavior, and recovery requirements with backend before launch. Do not rely on the mobile app to enforce storage access.

### Networking and domains

- Select DNS/domain ownership, TLS certificate automation, ingress/load balancer, WAF/rate-limiting boundary, allowed egress, and provider region as kickoff decisions.
- Enforce HTTPS for API and media URL delivery. Permit only required public routes; keep PostgreSQL, admin controls, and storage management private.
- Backend must specify CORS/origin behavior for any browser-based admin tools. Native Flutter traffic is not protected by CORS; API authentication and authorization are still required.

## 7. Mobile release operations

The Flutter app is built from the repository root. Platform scaffolding exists for Android and iOS; current `pubspec.yaml` includes only the Flutter SDK and Cupertino icons and declares SDK constraint `^3.13.5`. Confirm actual toolchain compatibility and dependency lockfile policy in CI before pinning runner images.

DevOps should coordinate with the Flutter owner to establish:

- Android package/application ID, signing ownership, Play Console access, version/build-number policy, and internal/beta/production tracks.
- iOS bundle ID, Apple Developer/App Store Connect access, signing certificates/profiles or managed signing, version/build-number policy, and TestFlight/App Store release process.
- Debug/staging/production flavors or equivalent compile-time public API configuration.
- Artifact retention, release notes, staged rollout/rollback process, crash-reporting symbol upload (if a provider is chosen), and who can promote a build.
- Separate provider configurations (for example push notification credentials) per environment if those features are implemented.

No app store identifiers, signing configuration, push provider, or release workflow is confirmed by the current repository. Do not create or assume live store access as part of implementation without the project owner supplying it.

## 8. Security and privacy operations

- Enforce least privilege for infrastructure, database, storage, CI, and human access. Separate deploy and runtime identities where the chosen platform supports it.
- Require HTTPS, encrypted storage and backups, secret rotation, dependency patching, and audit trails for production access and deploys.
- Do not emit private moment bodies, original media, raw location, auth tokens, or sensitive personal information to ordinary logs, crash reports, analytics, or push payloads. The repository explicitly calls for minimizing retained location data.
- Define retention/deletion behavior for user data, media, logs, backups, and audit events with product/backend owners; ensure infrastructure lifecycle policies do not conflict with legal/product requirements.
- Protect CI from secret exfiltration: no production secrets for forked/untrusted pull requests; pin trusted actions/tooling as decided; limit token permissions; review dependency and artifact provenance.
- Establish incident contacts and a process for compromised credentials, unauthorized media exposure, database incident, or failed deployment.

## 9. Observability, alerts, and operations

Centralized logging, error tracking, uptime/latency monitoring, and alerting are planned responsibilities, but no provider is selected. Choose a platform and retention/access policy before production.

Minimum launch signals to agree with backend:

- API availability, request rate, error rate by status/module, latency percentiles, saturation, restarts and deployment health.
- Database availability, connections, CPU/memory/storage, slow queries, replication/backup status, and migration failures.
- Object-storage availability/error rates, rejected/expired signed URL patterns where observable, capacity/cost, and policy changes.
- Mobile crash-free sessions/startup failures after a crash-reporting choice is made; do not send sensitive content or location unnecessarily.
- Backup job success and restore-test results, certificate expiry, and secret/credential rotation dates.

Backend should expose health/readiness signals that distinguish process health from dependencies; agree exact endpoints and probe behavior. Alerts need an owner, actionable runbook, severity, and escalation route. Define service targets and response windows with the product owner; do not invent SLO numbers before expected traffic and support coverage are known.

## 10. Local development and handoff notes

The checked-in local database can be started from `backend/` with `docker compose up -d postgres`. Its published port is `5432`; compose defines database/user/password as `vera` and database name `vera`. These values are explicitly local defaults and should be replaced for shared environments. No backend application service is defined in compose yet.

The Flutter project can be run with installed Flutter tooling from the repository root. Backend setup cannot yet be made reproducible because framework, package manifest, database tooling, identity, and storage implementations have not been chosen. DevOps should not manufacture Dockerfiles or deployment jobs against an assumed runtime layout before the backend developer confirms the entrypoint and build contract.

## 11. Decisions needed before implementation

Track each decision with an owner, date, selected option, and rationale in `docs/decisions.md`:

1. Backend framework, supported Node version, package manager, build command, runtime entrypoint, and container contract.
2. Database hosting/provider, region, connection/pooling approach, migration tool, backup retention, RPO/RTO, and restore access.
3. API hosting/registry, DNS/domain, TLS/ingress, WAF, environment topology, and deployment strategy.
4. Object storage provider/region, private access model, signed URL lifetime, malware scanning/resizing, retention/deletion, and recovery.
5. Authentication/identity provider and secret manager; notification providers (if in MVP scope).
6. CI provider, branch/release protections, production approval policy, artifact retention, and dependency/image scanning choices.
7. Android/iOS application identifiers, signing/store accounts, distribution tracks, and release approvers.
8. Logging/metrics/tracing/crash-reporting providers, retention, alert routing, on-call ownership, and incident severity expectations.
9. Data residency, privacy deletion/retention rules, production access policy, and supported regions.
10. Whether a web dashboard or realtime API is in scope. The attached Mr Valet dashboard report describes a separate dashboard/backend and mentions Vercel and Socket.IO; those are not confirmed as VERA infrastructure and must not be copied into this plan without an explicit product decision.

## 12. DevOps delivery checklist

### Before first shared deployment

- [ ] Resolve the decisions above and record them in `docs/decisions.md`.
- [ ] Backend publishes a reproducible build/start contract, migration command, configuration schema, and health/readiness contract.
- [ ] Create isolated development, staging, and production accounts/resources with named owners and least-privilege access.
- [ ] Create a secret-management and rotation process; verify no secret enters source control or mobile artifacts.
- [ ] Provision private PostgreSQL and private media storage with encryption, network restrictions, backups, and audit logging.
- [ ] Implement CI checks and immutable backend/mobile artifacts; document how to reproduce builds.
- [ ] Establish migration validation, release ordering, smoke checks, rollback and restore runbooks.
- [ ] Configure central logging/metrics, actionable alerts, uptime monitoring, and backup/restore verification.
- [ ] Confirm mobile signing, store access, environment configuration, and internal test distribution with Flutter owner.
- [ ] Review private-content, location, signed-media URL, and deletion behavior with backend/product owners.

### For each production release

- [ ] Confirm reviewed change, immutable artifact/version, and passing required CI checks.
- [ ] Confirm staging smoke checks and migration compatibility passed.
- [ ] Confirm backups are current and the release has a named operator/automation identity.
- [ ] Apply migration using the approved controlled path; deploy and verify health/readiness and core API workflows.
- [ ] Verify logs/alerts and mobile API connectivity; monitor error/latency signals during rollout.
- [ ] Record deployed version, migration revision, and outcome; invoke rollback/incident procedure if checks fail.

## 13. Source references

- Project foundation and current status: `README.md`.
- Architecture boundaries and planned domains: `docs/architecture.md`.
- Open kickoff choices: `docs/decisions.md` and `docs/setup-checklist.md`.
- Local PostgreSQL and backend environment template: `backend/compose.yaml`, `backend/.env.example`.
- Initial API security and reliability conventions: `backend/docs/api-conventions.md`.
- Flutter toolchain and app metadata: `pubspec.yaml`.
- The supplied **MrValet Frontend Backend Responsibilities** PDF describes Mr Valet Dashboard responsibilities. Its React/Vercel/Socket.IO/API details are not treated as VERA implementation facts because the repository identifies the mobile app/backend as VERA and contains no evidence that those projects share infrastructure.

# Architecture foundation

## Components

- **Mobile:** Flutter client for iOS and Android. UI flows and reusable design components will follow the supplied Figma/design references when implementation begins.
- **API:** Node.js with TypeScript. Express or NestJS is a kickoff decision; feature code is grouped by domain under `backend/src/modules`.
- **Database:** PostgreSQL with versioned migrations under `backend/migrations` and a controlled data-access layer.
- **Media:** Private object storage. Database records hold controlled references, never public bucket paths.

## Initial domain areas

`users`, `moments`, `moment_recipients`, `unlock_rules`, `unlock_events`, `replies`, `device_tokens`, `reports`, `blocks`, and `audit_events` are the planned schema areas. Introduce them through migrations as their stages are implemented; no schema is assumed prematurely here.

## Authorization boundary

A private moment open requires an authenticated user, accepted recipient membership, active permissions, and satisfied server-side unlock rules. A URL or invitation token alone never grants access. Locked responses contain only approved teaser and lock-rule metadata. Date conditions use backend UTC time plus the selected IANA timezone. Location checks occur only after an explicit foreground action and should minimize retained coordinates.

## Environments and decisions

Keep development, staging, and production configuration separate. Choose framework, identity providers, migration tooling, object storage, hosting, logging, and deployment approach during kickoff. Store decisions in this directory. Do not commit credentials.

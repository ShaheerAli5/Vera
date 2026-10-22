# Backend API conventions

These conventions reflect the implementation plan and are a starting contract, not implemented endpoints.

- Version API routes (for example `/api/v1`).
- Use JSON request and response bodies except for explicitly designed upload flows.
- Use standard status codes: `401` unauthenticated, `403` unauthorized, `404` unavailable/not found, `409` state conflict, `422` invalid input, and `429` rate limited.
- Authenticate requests and authorize access to each resource independently.
- Avoid returning private body/media fields in locked previews, inbox/feed metadata, or push payloads.
- Keep structured logs free of private message bodies and raw location where not required.
- Make publishing, opening, location verification, and other state-changing operations safe against retries and duplicate effects.

Document each endpoint's validation, authorization conditions, response shape, and error cases when it is implemented.

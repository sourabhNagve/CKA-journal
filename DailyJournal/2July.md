
HTTPRoute mirroring means sending a copy of incoming requests to a second backend for testing or observation, while the client still gets the response from the main backend.

What it does
The primary backend handles the real response.

The mirrored backend receives a best-effort copy of the request.

The mirrored response is ignored by the Gateway.

Why use it
Test a new version in production without affecting users.

Compare behavior, logs, or performance of a canary service.

Validate changes before shifting real traffic.


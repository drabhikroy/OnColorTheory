# Security review, 1.0.0

A source review carried out before the first public release. It is a review, not a penetration test, and nothing here was verified against a running build.

## Attack surface

The app has an unusually small one. It spawns no subprocess, loads no code at runtime, embeds no web view or script engine, uses no unsafe pointer APIs, and contains no `try!`, `as!`, `fatalError`, or `preconditionFailure`. It writes no logs. It has one dependency and one network client.

Everything it sends or receives goes through the optional Ollama connection, which is off until someone turns it on.

## Findings

### 1. A registrable name could pose as a local address

Severity: low. Fixed.

Plaintext is permitted only to a host on this machine or this local network; every other host must use TLS. The check that decided this matched on text rather than parsing an address, and three shapes defeated it.

A dotted quad was read by splitting on the separator and discarding the parts that failed to parse as numbers, so `127.0.0.1.evil.com` yielded four valid octets and passed. The unique local and link local checks matched any string beginning with `fc`, `fd`, or `fe8` through `feb`, so ordinary names such as `fdn.example.com` and `feature-flags.example.com` passed as IPv6 private addresses.

The check now parses. Every component of a dotted quad has to be numeric, and the IPv6 ranges are tested against the parsed leading group rather than against the text.

Severity is low rather than high because the transport policy in the bundle is a second line of defense. `NSAllowsLocalNetworking` is set and arbitrary loads are not, so the operating system would have refused a plaintext connection to a publicly resolvable name regardless. The practical effect of the flaw was that such an address was accepted and then failed at connect time, instead of being refused with a clear message. The fix means the app enforces the rule it states, rather than relying on the operating system to enforce it.

Thirty four cases covering both directions are now tests.

### 2. A link destination was force unwrapped from a string parameter

Severity: low. Fixed.

`appearanceResource` took its destination as a `String` and forced it into a `URL` at the point of use, so a malformed address added later would crash when someone opened that panel rather than failing to build. The parameter is now a `URL`, and the three addresses live in one enum.

### 3. The dependency range allowed any future minor version

Severity: low. Fixed.

`Package.swift` declared `from: "1.7.3"`, which permits any later 1.x on resolution. `Package.resolved` pins an exact revision and is committed, so ordinary builds were reproducible, but a `swift package update` could pull an unreviewed release. The range is now held to one minor line.

## Verified sound

**Address validation.** Embedded credentials, query strings, and fragments are all refused, and only `http` and `https` are accepted.

**Network configuration.** The session is ephemeral with cookies and caching disabled and explicit timeouts. Transport security allows local networking only; arbitrary loads are not enabled. TLS failures are surfaced rather than bypassed, and no code anywhere overrides certificate evaluation.

**Untrusted input.** Model output is bounded before decoding, checked for exact `#RRGGBB` shape, parsed through the real parser, and length capped on every free text field. Model supplied text is rendered through the `String` overload of `Text`, which does not interpret Markdown, so a hostile server cannot inject formatting or links into the interface. Model names are validated against an explicit character set.

**Stored data.** The Color Tray is JSON, not an archived object graph, so decoding cannot instantiate arbitrary classes. Its size is checked before it is read, it lives at a fixed path with no user supplied path component, it is written atomically, and an unreadable file is preserved rather than overwritten.

**Secrets.** None in the source. The app has no accounts, no tokens, and no telemetry.

**Build scripts.** Variables are quoted, deletions are anchored to `mktemp` directories with `--` guards and trap cleanup, and nothing is evaluated or downloaded.

## Recommendations not applied

These change signing or sandboxing behavior and need a launch test on the target machine, so they are recorded rather than made blind.

**Enable the hardened runtime.** Signing with `--options runtime` is a prerequisite for notarization and blocks several injection routes. The app uses no JIT, no unsigned executable memory, and no interposing, so it should tolerate the flag, but that has to be confirmed by launching the signed build.

**Consider the App Sandbox.** The app needs outgoing network access and its own container. Sandboxing would confine the damage from any future defect. It requires an entitlements file and a launch test, and it interacts with the Ollama file checks in Help, which look at paths outside a container.

**Notarize before wide distribution.** The build is ad hoc signed, so Gatekeeper requires Control-click then Open on first launch. That instruction is in the release notes and on the landing page.

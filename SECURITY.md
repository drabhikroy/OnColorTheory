# Security

## What On Color Theory is exposed to

On Color Theory spawns no subprocess, loads no code at runtime, embeds
no web view or script engine, and writes no logs. It has one dependency
and one network client. Everything it sends or receives goes through
the optional Ollama connection, which is off until you turn it on.

## What the code does about it

Plaintext is permitted only to a host on this machine or this local
network; every other host must use TLS, and the check parses each
address rather than matching against its text. Embedded credentials,
query strings, and fragments are all refused, and only `http` and
`https` are accepted. The network session is ephemeral, with cookies
and caching disabled and explicit timeouts. Transport security allows
local networking only, arbitrary loads are not enabled, TLS failures
are surfaced rather than bypassed, and no code overrides certificate
evaluation.

Model output is bounded before decoding, checked for exact `#RRGGBB`
shape, parsed through the real color parser, and length capped on
every free text field. Model-supplied text is rendered through the
plain-string form of `Text`, which does not interpret Markdown, so a
hostile server cannot inject formatting or links into the interface.
Model names are validated against an explicit character set, and the
dependency is pinned to one minor line rather than left open to any
future release.

The Color Tray is stored as JSON rather than an archived object graph,
so decoding it cannot instantiate arbitrary classes. It lives at a
fixed path with no user-supplied path component, its size is checked
before it is read, it is written atomically, and an unreadable file is
preserved rather than overwritten. The app keeps no accounts, no
tokens, and no telemetry.

## Recommendations not yet applied

Three changes would tighten this further but touch signing or
sandboxing behavior, so they need a launch test on the target machine
rather than being made blind: enabling the hardened runtime, adopting
the App Sandbox, and notarizing the build before wide distribution.
Until then, an ad hoc signed build requires Control-click then Open on
first launch.

## Reporting a problem

Open a private security advisory through the repository, or open a
normal issue if the problem is not sensitive. Please include the
version, what you did, and what you saw. There is no account and no
telemetry, so a report here is about the code rather than about an
incident.

## Scope

In scope: anything that causes the app to write outside its working
directory, to open a connection you did not ask for, to execute
content from a loaded file, or to render an untrusted value without
escaping it. Out of scope: the one third-party dependency, which is
reported to its own maintainers, and anything that requires an
attacker to already be running code on the same machine.

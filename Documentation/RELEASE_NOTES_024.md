# Build 024: A connected Build workflow, model cleanup, and a new app identity

Build 024 makes Build feel like one continuous process. The five areas are now called stages, and the editable interface preview follows the palette through Design, Light & Dark, Recommend, Check, and Export. People can switch the preview between the Studio, Light, Dark, and model-suggested palettes without re-entering their text.

Model Assist is visible throughout Build. Its compact status panel shows whether setup is needed or which model is ready, and it provides direct Recommend and Manage actions. Installed models can be deleted after confirmation through Ollama's documented API. A local Ollama app can be moved to the Trash from the setup assistant; its models and support files are deliberately left alone unless the person removes them separately.

The Help start actions now use one aligned grid. Its walkthrough describes the current connected-stage workflow and keeps all navigation in the existing app window.

The interface preview has a clearer editor-and-result structure, a small palette identity bar, role swatches, and a palette source picker. Model results retain plain-language reasons for every role and feed the same shared preview.

On Color Theory now has an original app icon based on overlapping color spaces and a measured coordinate. The icon is compiled into the macOS bundle and appears in the Home introduction.

The security pass removed unrestricted network loading, restricted nonlocal servers to HTTPS, retained HTTP only for local and private-network addresses, rejected credential-bearing server URLs, switched model traffic to an ephemeral cookie-free and cache-free session, bounded response sizes, and bounded saved-state files before decoding.

The calculation pass added CSS Color transfer-function breakpoint and round-trip checks plus D65 and D50 reference-white verification. These join the existing WCAG contrast, Display P3, source-over, interpolation, conversion, and all 34 published CIEDE2000 test-pair checks.

Version: 0.24.0 (24)

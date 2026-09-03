import Foundation

/// The syntaxes a palette can be copied out in.
enum CodeExportLanguage: String, CaseIterable, Identifiable, Sendable {
    case css = "CSS"
    case swift = "Swift"
    case javascript = "JavaScript"
    case python = "Python"
    case r = "R"
    case json = "JSON"

    var id: Self { self }
}

/// Writes a palette out as source, keeping the role names as the identifiers
/// so the exported code says what each color is for.
enum ColorCodeExporter {
    static func adaptiveCSS(light: InterfacePalette, dark: InterfacePalette) -> String {
        let lightDeclarations = InterfacePaletteRole.allCases.map { role in
            "  \(role.cssName): \(light[role].hex);"
        }
        let darkDeclarations = InterfacePaletteRole.allCases.map { role in
            "    \(role.cssName): \(dark[role].hex);"
        }
        return ([":root {"] + lightDeclarations + [
            "}",
            "",
            "@media (prefers-color-scheme: dark) {",
            "  :root {"
        ] + darkDeclarations + ["  }", "}"]).joined(separator: "\n")
    }

    static func colorSnippet(
        color: SRGBColor,
        cssValue: String,
        language: CodeExportLanguage
    ) -> String {
        switch language {
        case .css:
            "color: \(cssValue);"
        case .swift:
            "import SwiftUI\n\nlet color = Color(.sRGB, red: \(number(color.red)), green: \(number(color.green)), blue: \(number(color.blue)), opacity: \(number(color.alpha)))"
        case .javascript:
            "const color = { space: \"sRGB\", red: \(color.red8), green: \(color.green8), blue: \(color.blue8), alpha: \(number(color.alpha)) };"
        case .python:
            "color = {\"space\": \"sRGB\", \"red\": \(color.red8), \"green\": \(color.green8), \"blue\": \(color.blue8), \"alpha\": \(number(color.alpha))}"
        case .r:
            "color <- rgb(\(color.red8), \(color.green8), \(color.blue8), alpha = \(color.alpha8), maxColorValue = 255)"
        case .json:
            """
            {
              "space": "sRGB",
              "red": \(color.red8),
              "green": \(color.green8),
              "blue": \(color.blue8),
              "alpha": \(number(color.alpha))
            }
            """
        }
    }

    static func paletteSnippet(
        _ palette: InterfacePalette,
        language: CodeExportLanguage
    ) -> String {
        let entries = InterfacePaletteRole.allCases.map { role in
            (name: role.codeName, value: palette[role].hex)
        }

        switch language {
        case .css:
            return palette.cssCustomProperties
        case .swift:
            let body = InterfacePaletteRole.allCases.map { role in
                let color = palette[role]
                return "    \"\(role.codeName)\": Color(.sRGB, red: \(number(color.red)), green: \(number(color.green)), blue: \(number(color.blue)), opacity: 1), // \(color.hex)"
            }
            .joined(separator: "\n")
            return "import SwiftUI\n\nlet palette: [String: Color] = [\n\(body)\n]"
        case .javascript:
            let body = entries.map { "  \($0.name): \"\($0.value)\"" }
                .joined(separator: ",\n")
            return "const palette = {\n\(body)\n};"
        case .python:
            let body = entries.map { "    \"\($0.name)\": \"\($0.value)\"" }
                .joined(separator: ",\n")
            return "palette = {\n\(body)\n}"
        case .r:
            let body = entries.map { "  \($0.name) = \"\($0.value)\"" }
                .joined(separator: ",\n")
            return "palette <- c(\n\(body)\n)"
        case .json:
            let body = entries.map { "  \"\($0.name)\": \"\($0.value)\"" }
                .joined(separator: ",\n")
            return "{\n\(body)\n}"
        }
    }

    private static func number(_ value: Double) -> String {
        Format.decimal(value, places: 5)
    }
}

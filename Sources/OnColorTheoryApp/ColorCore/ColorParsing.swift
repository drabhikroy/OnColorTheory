import Foundation

/// Why typed text could not be read as a color.
///
/// Messages name the accepted range rather than only reporting a failure, since
/// the app is used by people learning the notation.
enum ColorParseError: LocalizedError, Equatable {
    case empty
    case unsupportedLength(Int)
    case invalidCharacters
    case invalidRGBSyntax
    case invalidRGBComponent(String)
    case rgbComponentOutOfRange(String)
    case alphaOutOfRange(String)

    var errorDescription: String? {
        switch self {
        case .empty:
            "Enter a color value."
        case let .unsupportedLength(length):
            "Use 3, 4, 6, or 8 hexadecimal digits; received \(length)."
        case .invalidCharacters:
            "Use only the digits 0 to 9 and letters A to F."
        case .invalidRGBSyntax:
            "Use three RGB components and optional alpha, for example rgb(197 143 99 / 50%)."
        case let .invalidRGBComponent(component):
            "\(component) is not a valid RGB component. Use 0 to 255 or 0% to 100%."
        case let .rgbComponentOutOfRange(component):
            "RGB component \(component) is outside 0 to 255 or 0% to 100%."
        case let .alphaOutOfRange(component):
            "Alpha \(component) is outside 0 to 1 or 0% to 100%."
        }
    }
}

/// Reads one color notation.
protocol RepresentationParser: Sendable {
    func parse(_ input: String) throws -> ParsedColor
}

/// Reads three, four, six, and eight digit hexadecimal colors.
struct HexColorParser: RepresentationParser {
    func parse(_ input: String) throws -> ParsedColor {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ColorParseError.empty }

        let digits = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
        guard [3, 4, 6, 8].contains(digits.count) else {
            throw ColorParseError.unsupportedLength(digits.count)
        }
        let hexadecimalCharacters = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
        guard digits.unicodeScalars.allSatisfy(hexadecimalCharacters.contains) else {
            throw ColorParseError.invalidCharacters
        }

        let expanded: String
        if digits.count == 3 || digits.count == 4 {
            expanded = digits.map { "\($0)\($0)" }.joined()
        } else {
            expanded = digits
        }

        guard let packed = UInt64(expanded, radix: 16) else {
            throw ColorParseError.invalidCharacters
        }

        let hasAlpha = expanded.count == 8
        let redShift = hasAlpha ? 24 : 16
        let greenShift = hasAlpha ? 16 : 8
        let blueShift = hasAlpha ? 8 : 0

        let red = Double((packed >> redShift) & 0xFF) / 255
        let green = Double((packed >> greenShift) & 0xFF) / 255
        let blue = Double((packed >> blueShift) & 0xFF) / 255
        let alpha = hasAlpha ? Double(packed & 0xFF) / 255 : 1

        let color = SRGBColor(red: red, green: green, blue: blue, alpha: alpha)
        let notation: String
        if trimmed.hasPrefix("#") {
            notation = hasAlpha ? "CSS hexadecimal with alpha" : "CSS hexadecimal"
        } else {
            notation = hasAlpha
                ? "Unprefixed hexadecimal with alpha"
                : "Unprefixed hexadecimal"
        }
        return ParsedColor(
            originalRepresentation: trimmed,
            notation: notation,
            notationID: .hexadecimal,
            colorSpace: .sRGB,
            color: color
        )
    }
}

/// Reads the CSS rgb() form, in both the comma and the space separated
/// syntaxes, with an optional alpha.
struct RGBColorParser: RepresentationParser {
    func parse(_ input: String) throws -> ParsedColor {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ColorParseError.empty }

        let lowercase = trimmed.lowercased()
        let isFunction = lowercase.hasPrefix("rgb(") || lowercase.hasPrefix("rgba(")
        let functionName = lowercase.hasPrefix("rgba(") ? "rgba" : "rgb"
        let body: String

        if isFunction {
            guard trimmed.hasSuffix(")"), let opening = trimmed.firstIndex(of: "(") else {
                throw ColorParseError.invalidRGBSyntax
            }
            body = String(trimmed[trimmed.index(after: opening)..<trimmed.index(before: trimmed.endIndex)])
        } else {
            body = trimmed
        }

        let usesLegacyCommas = body.contains(",")
        let rgbTokens: [String]
        let alphaToken: String?

        if usesLegacyCommas {
            guard !body.contains("/") else { throw ColorParseError.invalidRGBSyntax }
            let tokens = body.split(separator: ",", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard tokens.count == 3 || tokens.count == 4, tokens.allSatisfy({ !$0.isEmpty }) else {
                throw ColorParseError.invalidRGBSyntax
            }
            rgbTokens = Array(tokens.prefix(3))
            alphaToken = tokens.count == 4 ? tokens[3] : nil
        } else {
            let slashParts = body.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
            guard slashParts.count <= 2 else { throw ColorParseError.invalidRGBSyntax }
            var components = slashParts[0].split(whereSeparator: \.isWhitespace).map(String.init)
            guard components.count == 3 || (!isFunction && components.count == 4) else {
                throw ColorParseError.invalidRGBSyntax
            }

            if slashParts.count == 2 {
                let alpha = slashParts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                guard !alpha.isEmpty, components.count == 3 else {
                    throw ColorParseError.invalidRGBSyntax
                }
                alphaToken = alpha
            } else if components.count == 4 {
                alphaToken = components.removeLast()
            } else {
                alphaToken = nil
            }
            rgbTokens = components
        }

        let red = try parseRGBComponent(rgbTokens[0])
        let green = try parseRGBComponent(rgbTokens[1])
        let blue = try parseRGBComponent(rgbTokens[2])
        let alpha = try alphaToken.map(parseAlpha) ?? 1
        let hasAlpha = alphaToken != nil

        let notation: String
        if isFunction {
            if usesLegacyCommas {
                notation = "Legacy CSS \(functionName)() functional notation"
            } else {
                notation = hasAlpha
                    ? "CSS rgb() functional notation with alpha"
                    : "CSS rgb() functional notation"
            }
        } else {
            notation = hasAlpha ? "Unwrapped RGBA components" : "Unwrapped RGB components"
        }

        return ParsedColor(
            originalRepresentation: trimmed,
            notation: notation,
            notationID: .rgb,
            colorSpace: .sRGB,
            color: SRGBColor(red: red, green: green, blue: blue, alpha: alpha)
        )
    }

    private func parseRGBComponent(_ token: String) throws -> Double {
        let isPercentage = token.hasSuffix("%")
        let numberText = isPercentage ? String(token.dropLast()) : token
        guard let number = Double(numberText), number.isFinite else {
            throw ColorParseError.invalidRGBComponent(token)
        }
        let upperBound = isPercentage ? 100.0 : 255.0
        guard (0...upperBound).contains(number) else {
            throw ColorParseError.rgbComponentOutOfRange(token)
        }
        return number / upperBound
    }

    private func parseAlpha(_ token: String) throws -> Double {
        let isPercentage = token.hasSuffix("%")
        let numberText = isPercentage ? String(token.dropLast()) : token
        guard let number = Double(numberText), number.isFinite else {
            throw ColorParseError.alphaOutOfRange(token)
        }
        let upperBound = isPercentage ? 100.0 : 1.0
        guard (0...upperBound).contains(number) else {
            throw ColorParseError.alphaOutOfRange(token)
        }
        return number / upperBound
    }
}

/// Tries each notation parser in turn and reports the first success.
struct CompositeColorParser: RepresentationParser {
    private let hexadecimal = HexColorParser()
    private let rgb = RGBColorParser()

    func parse(_ input: String) throws -> ParsedColor {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ColorParseError.empty }

        if trimmed.hasPrefix("#") {
            return try hexadecimal.parse(trimmed)
        }

        let hexadecimalCharacters = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
        if trimmed.unicodeScalars.allSatisfy(hexadecimalCharacters.contains) {
            return try hexadecimal.parse(trimmed)
        }
        return try rgb.parse(trimmed)
    }
}

import Foundation

/// Parses UC Merced station prefixes (e.g., "@RUFUS GRILL:", "@Lake Wok :", "@CASCABEL:", "π Pizza :")
/// and extracts clean dish descriptions and protein options.
public enum StationParser {
    public static func parse(description rawDescription: String, itemName: String = "") -> ParsedMenuDescription {
        let trimmed = rawDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        var detectedCategory: StationCategory = .chefSpecial
        var cleaned = trimmed

        if trimmed.hasPrefix("@") {
            if let colonRange = trimmed.range(of: ":") {
                let rawTag = String(trimmed[trimmed.index(after: trimmed.startIndex)..<colonRange.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                detectedCategory = mapStation(rawTag: rawTag, itemName: itemName)
                cleaned = String(trimmed[colonRange.upperBound...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } else if trimmed.lowercased().hasPrefix("π pizza") || trimmed.lowercased().hasPrefix("pi pizza") {
            detectedCategory = .pizza
            if let colonRange = trimmed.range(of: ":") {
                cleaned = String(trimmed[colonRange.upperBound...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } else {
            detectedCategory = mapStation(rawTag: "", itemName: itemName)
        }

        cleaned = cleaned
            .replacingOccurrences(of: "  ", with: " ")
            .replacingOccurrences(of: "((", with: "(")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let proteins = extractProteinChoices(from: cleaned)

        return ParsedMenuDescription(
            station: StationInfo(category: detectedCategory, rawBadgeName: detectedCategory.rawValue),
            cleanDescription: cleaned.isEmpty ? "Prepared fresh at UC Merced Dining." : cleaned,
            proteinOptions: proteins
        )
    }

    private static func mapStation(rawTag: String, itemName: String) -> StationCategory {
        let upper = rawTag.uppercased()
        let itemUpper = itemName.uppercased()

        if upper.contains("RUFUS") {
            return .rufusGrill
        } else if upper.contains("LAKE WOK") || upper.contains("WOK") {
            return .lakeWok
        } else if upper.contains("CASCABEL") {
            return .cascabel
        } else if upper.contains("CIAO") {
            if itemUpper.contains("PIZZA") {
                return .pizza
            }
            return .ciao
        } else if upper.contains("PIZZA") || itemUpper.contains("PIZZA") {
            return .pizza
        } else if upper.contains("FIELD OF GREENS") || upper.contains("FOG") {
            return .fieldOfGreens
        } else if upper.contains("COMMON GROUNDS") || upper.contains("CG") {
            return .commonGrounds
        } else if upper.contains("PLANCHA") {
            return .plancha
        } else if upper.contains("CARBONE") {
            return .carbone
        } else if upper.contains("FLAME") {
            return .flame
        } else if upper.contains("BROT") {
            return .brot
        } else if upper.contains("DEUX") {
            return .deux
        } else if upper.contains("GLACIES") || itemUpper.contains("ICE CREAM") {
            return .glacies
        } else if itemUpper.contains("MUFFIN") || itemUpper.contains("CROISSANT") || itemUpper.contains("DANISH") || itemUpper.contains("SCONE") || itemUpper.contains("CAKE") {
            return .bakery
        }
        return .chefSpecial
    }

    private static func extractProteinChoices(from text: String) -> [String] {
        let patterns = [
            "Protein Choice of ",
            "Choice of Protein: ",
            "Choice of Protein : ",
            "Protein choice of ",
            "Choice of ",
            "Pizza Choice of "
        ]
        var working = text
        for prefix in patterns {
            if let range = working.range(of: prefix, options: .caseInsensitive) {
                working = String(working[range.upperBound...])
                break
            }
        }

        let stopWords = [" with sides", " With Sides", " with ", " Served with", " served with", " Comes with", ". ", "; "]
        for stop in stopWords {
            if let stopRange = working.range(of: stop, options: .caseInsensitive) {
                working = String(working[..<stopRange.lowerBound])
            }
        }

        let parts = working.components(separatedBy: " or ")
            .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)) }
            .filter { !$0.isEmpty && $0.count < 48 }

        return parts.count >= 2 ? Array(parts.prefix(3)) : []
    }
}

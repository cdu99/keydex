import Foundation

/// Text normalization shared by queries and searched content: case, accents and
/// width are ignored, so "echap" finds "Échap" and "FIND" finds "Find".
enum SearchText {
    static func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
    }
}

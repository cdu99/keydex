/// Splits typed key descriptions into normalized tokens: "⌘⇧F", "cmd+shift+f" and
/// "cmd shift f" all give ["⌘", "⇧", "f"] / ["cmd", "shift", "f"].
enum KeyTokenizer {
    static func tokens(of text: String) -> [String] {
        var spaced = ""
        for character in text {
            if KeySearchNames.glueableSymbols.contains(character) {
                spaced += character == "+" ? " " : " \(character) "
            } else {
                spaced.append(character)
            }
        }
        return spaced.split(whereSeparator: \.isWhitespace).map { SearchText.normalize(String($0)) }
    }
}

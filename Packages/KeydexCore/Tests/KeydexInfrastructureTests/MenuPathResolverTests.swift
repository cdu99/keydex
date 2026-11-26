@testable import KeydexInfrastructure
import KeydexDomain
import Testing

private struct Node: Equatable {
    var title: String
    var children: [Node] = []
}

@Suite("Finding a menu item again from its path")
struct MenuPathResolverTests {
    private let resolver = MenuPathResolver<Node>(children: \.children, title: \.title)

    private let menuBar = Node(title: "", children: [
        Node(title: "Apple"),
        Node(title: "Fenêtre", children: [
            Node(title: "Réduire"),
            Node(title: "Déplacer", children: [Node(title: "Gauche"), Node(title: "Droite")]),
        ]),
    ])

    private func path(_ components: (Int, String)...) -> MenuPath {
        MenuPath(components.map { MenuPath.Component(index: $0.0, title: $0.1) })
    }

    @Test("Follows positions when titles match")
    func byPosition() {
        let found = resolver.resolve(path((1, "Fenêtre"), (1, "Déplacer"), (1, "Droite")), from: menuBar)
        #expect(found?.title == "Droite")
    }

    @Test("Falls back to the title when an item moved")
    func movedItem() {
        let found = resolver.resolve(path((1, "Fenêtre"), (0, "Déplacer"), (0, "Droite")), from: menuBar)
        #expect(found?.title == "Droite")
    }

    @Test("Returns nothing rather than another item when the title is gone")
    func missingItem() {
        #expect(resolver.resolve(path((1, "Fenêtre"), (0, "Zoom")), from: menuBar) == nil)
        #expect(resolver.resolve(path((5, "Aide")), from: menuBar) == nil)
    }
}

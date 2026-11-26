import KeydexDomain

/// Finds the node a `MenuPath` designates in a menu tree.
///
/// Each level is looked up by position and checked by title. If the title differs (an item
/// was added or removed since the menus were read), the item is searched by title among its
/// siblings. A missing title means the item is gone: better do nothing than press another one.
struct MenuPathResolver<Node> {
    let children: (Node) -> [Node]
    let title: (Node) -> String

    func resolve(_ path: MenuPath, from root: Node) -> Node? {
        var node = root
        for component in path.components {
            let siblings = children(node)
            if siblings.indices.contains(component.index), title(siblings[component.index]) == component.title {
                node = siblings[component.index]
            } else if let match = siblings.first(where: { title($0) == component.title }) {
                node = match
            } else {
                return nil
            }
        }
        return node
    }
}

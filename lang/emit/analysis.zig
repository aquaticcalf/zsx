const tree = @import("../syntax/tree.zig");

pub fn usesChildren(nodes: []const tree.Node) bool {
    for (nodes) |node| switch (node) {
        .children => return true,
        .element => |elem| if (usesChildren(elem.children)) return true,
        .if_stmt => |stmt| for (stmt.branches) |branch| if (usesChildren(branch.body)) return true,
        .for_stmt => |stmt| if (usesChildren(stmt.body)) return true,
        else => {},
    };
    return false;
}

const std = @import("std");
const tree = @import("../syntax/tree.zig");
const State = @import("state.zig").State;
const state = @import("state.zig");
const nodes = @import("nodes.zig");
const zig = @import("zig.zig");
const err = @import("error.zig");

pub fn parse(s: *State) err.ParseError!tree.Node {
    const start = s.pos;
    try s.expectByte('@', "expected '@'");
    if (s.matchKeyword("children")) return .{ .children = .{ .start = start, .end = s.pos } };

    const callee = try s.readCallee("expected component name after '@'");
    const args = try parseArgs(s);
    s.skipSpace();
    const children = if (s.matchByte('{')) try nodes.parse(s, .block) else &.{};

    return .{ .call = .{
        .callee = callee,
        .args = args,
        .children = children,
        .span = .{ .start = start, .end = s.pos },
    } };
}

fn parseArgs(s: *State) err.ParseError![]const []const u8 {
    var args: std.ArrayList([]const u8) = .empty;
    s.skipSpace();
    if (!s.matchByte('(')) return try args.toOwnedSlice(s.allocator);

    while (true) {
        s.skipSpace();
        if (s.matchByte(')')) break;
        const start = s.pos;
        const end = try zig.readUntilTopLevel(s.source, &s.pos, &.{ .{ .byte = ',' }, .{ .byte = ')' } });
        try args.append(s.allocator, state.trimSlice(s.source, start, end));
        s.skipSpace();
        if (s.matchByte(',')) continue;
        try s.expectByte(')', "expected ')' after component arguments");
        break;
    }

    return try args.toOwnedSlice(s.allocator);
}

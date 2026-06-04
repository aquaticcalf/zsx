const std = @import("std");
const tree = @import("../syntax/tree.zig");
const State = @import("state.zig").State;
const nodes = @import("nodes.zig");
const zig = @import("zig.zig");
const err = @import("error.zig");

pub fn parseIf(s: *State) err.ParseError!tree.If {
    const start = s.pos;
    var branches: std.ArrayList(tree.IfBranch) = .empty;
    try s.expectKeyword("if", "expected 'if'");

    while (true) {
        const branch_start = s.pos;
        s.skipSpace();
        const condition = if (s.peek() == '(') try zig.readBalanced(s.source, &s.pos, '(', ')') else null;
        s.skipSpace();
        try s.expectByte('{', "expected '{' before if body");
        const body = try nodes.parse(s, .block);
        try branches.append(s.allocator, .{
            .condition = condition,
            .body = body,
            .span = .{ .start = branch_start, .end = s.pos },
        });

        s.skipSpace();
        if (!s.matchKeyword("else")) break;
        s.skipSpace();
        if (s.matchKeyword("if")) continue;

        const else_start = s.pos;
        try s.expectByte('{', "expected '{' before else body");
        try branches.append(s.allocator, .{
            .condition = null,
            .body = try nodes.parse(s, .block),
            .span = .{ .start = else_start, .end = s.pos },
        });
        break;
    }

    return .{ .branches = try branches.toOwnedSlice(s.allocator), .span = .{ .start = start, .end = s.pos } };
}

pub fn parseFor(s: *State) err.ParseError!tree.For {
    const start = s.pos;
    try s.expectKeyword("for", "expected 'for'");
    s.skipSpace();
    const header = try zig.readBalanced(s.source, &s.pos, '(', ')');
    const binding = try parseForHeader(s, start, header);
    s.skipSpace();
    try s.expectByte('{', "expected '{' before for body");

    return .{
        .iterable = binding.iterable,
        .value_name = binding.value_name,
        .index_name = binding.index_name,
        .body = try nodes.parse(s, .block),
        .span = .{ .start = start, .end = s.pos },
    };
}

fn parseForHeader(
    s: *State,
    offset: usize,
    header: []const u8,
) err.ParseError!struct { iterable: []const u8, value_name: []const u8, index_name: ?[]const u8 } {
    const first = std.mem.indexOfScalar(u8, header, '|') orelse return s.fail(offset, "expected for binding", error.ExpectedForBinding);
    const last = std.mem.lastIndexOfScalar(u8, header, '|') orelse first;
    if (first == last) return s.fail(offset, "expected closing '|' in for binding", error.ExpectedForBinding);

    const iterable = std.mem.trim(u8, header[0..first], " \t\r\n");
    const names = header[first + 1 .. last];
    if (std.mem.indexOfScalar(u8, names, ',')) |comma| {
        return .{
            .iterable = iterable,
            .value_name = std.mem.trim(u8, names[0..comma], " \t\r\n"),
            .index_name = std.mem.trim(u8, names[comma + 1 ..], " \t\r\n"),
        };
    }
    return .{
        .iterable = iterable,
        .value_name = std.mem.trim(u8, names, " \t\r\n"),
        .index_name = null,
    };
}

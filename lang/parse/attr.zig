const std = @import("std");
const tree = @import("../syntax/tree.zig");
const State = @import("state.zig").State;
const expr = @import("expr.zig");
const err = @import("error.zig");

pub fn parse(s: *State) err.ParseError!tree.Attr {
    const start = s.pos;
    const name = try s.readName("expected attribute name");
    s.skipSpace();
    if (!s.matchByte('=')) {
        return .{ .name = name, .value = .boolean, .span = .{ .start = start, .end = s.pos } };
    }
    s.skipSpace();
    const value = try parseValue(s);
    return .{ .name = name, .value = value, .span = .{ .start = start, .end = s.pos } };
}

fn parseValue(s: *State) err.ParseError!tree.AttrValue {
    if (s.peek() == '"') return parseQuoted(s);
    if (s.peek() == '{') return .{ .expr = try expr.parse(s) };
    return s.fail(s.pos, "expected attribute value", error.ExpectedAttributeValue);
}

fn parseQuoted(s: *State) err.ParseError!tree.AttrValue {
    try s.expectByte('"', "expected quote");
    var parts: std.ArrayList(tree.AttrPart) = .empty;
    var text_start = s.pos;
    while (!s.eof()) {
        switch (s.peek()) {
            '"' => {
                if (text_start < s.pos) try parts.append(s.allocator, .{ .text = s.source[text_start..s.pos] });
                s.pos += 1;
                if (parts.items.len == 0) return .{ .text = "" };
                if (parts.items.len == 1 and parts.items[0] == .text) return .{ .text = parts.items[0].text };
                return .{ .parts = try parts.toOwnedSlice(s.allocator) };
            },
            '{' => {
                if (text_start < s.pos) try parts.append(s.allocator, .{ .text = s.source[text_start..s.pos] });
                try parts.append(s.allocator, .{ .expr = try expr.parse(s) });
                text_start = s.pos;
            },
            else => s.pos += 1,
        }
    }
    return s.fail(s.pos, "unterminated attribute value", error.UnexpectedEnd);
}

const std = @import("std");
const tree = @import("../syntax/tree.zig");
const State = @import("state.zig").State;
const call = @import("call.zig");
const control = @import("control.zig");
const element = @import("element.zig");
const expr = @import("expr.zig");
const text = @import("text.zig");
const err = @import("error.zig");

pub const Context = text.Context;

pub fn parse(s: *State, context: Context) err.ParseError![]const tree.Node {
    var out: std.ArrayList(tree.Node) = .empty;

    while (true) {
        text.skipInsignificantSpace(s, context);
        if (s.eof()) return s.fail(s.pos, "unexpected end of file", error.UnexpectedEnd);

        switch (context) {
            .template, .block => if (s.matchByte('}')) break,
            .element => |tag| {
                if (s.startsWith("</")) {
                    try element.close(s, tag);
                    break;
                }
            },
        }

        try out.append(s.allocator, try parseOne(s, context));
    }

    return try out.toOwnedSlice(s.allocator);
}

fn parseOne(s: *State, context: Context) err.ParseError!tree.Node {
    if (s.startsWith("<!--")) return .{ .text = try element.parseCommentText(s) };
    if (s.startsWith("<!")) return .{ .doctype = try element.parseDoctype(s) };
    if (s.peek() == '<') return .{ .element = try element.parse(s) };
    if (s.peek() == '{') return .{ .expr = try expr.parse(s) };
    if (s.peek() == '@') return try call.parse(s);
    if (s.atKeyword("if")) return .{ .if_stmt = try control.parseIf(s) };
    if (s.atKeyword("for")) return .{ .for_stmt = try control.parseFor(s) };

    const parsed = try text.parse(s, context);
    if (parsed.source.len == 0) return s.fail(s.pos, "unexpected token", error.UnexpectedToken);
    return .{ .text = parsed };
}

const std = @import("std");
const tree = @import("../syntax/tree.zig");
const State = @import("state.zig").State;
const attr = @import("attr.zig");
const nodes = @import("nodes.zig");
const err = @import("error.zig");

pub fn parse(s: *State) err.ParseError!tree.Element {
    const start = s.pos;
    try s.expectByte('<', "expected '<'");
    const name = try s.readName("expected element name");
    var attrs: std.ArrayList(tree.Attr) = .empty;

    while (true) {
        s.skipSpace();
        if (s.matchByte('>')) {
            const children = try nodes.parse(s, .{ .element = name });
            return finish(s, start, name, &attrs, children, false);
        }
        if (s.matchString("/>")) {
            return finish(s, start, name, &attrs, &.{}, true);
        }
        if (s.eof()) return s.fail(start, "unexpected end of file in element", error.UnexpectedEnd);
        try attrs.append(s.allocator, try attr.parse(s));
    }
}

pub fn parseDoctype(s: *State) err.ParseError!tree.Doctype {
    const start = s.pos;
    while (!s.eof() and s.peek() != '>') s.pos += 1;
    try s.expectByte('>', "expected '>' after declaration");
    return .{ .source = s.source[start..s.pos], .span = .{ .start = start, .end = s.pos } };
}

pub fn parseCommentText(s: *State) err.ParseError!tree.Text {
    const start = s.pos;
    const rel_end = std.mem.indexOf(u8, s.source[s.pos..], "-->") orelse return s.fail(start, "unterminated HTML comment", error.UnexpectedEnd);
    s.pos += rel_end + 3;
    return .{ .source = s.source[start..s.pos], .span = .{ .start = start, .end = s.pos } };
}

pub fn close(s: *State, expected: []const u8) err.ParseError!void {
    const start = s.pos;
    try s.expectString("</", "expected closing tag");
    const found = try s.readName("expected closing tag name");
    s.skipSpace();
    try s.expectByte('>', "expected '>' after closing tag");
    if (!std.mem.eql(u8, expected, found)) return s.fail(start, "mismatched closing tag", error.MismatchedClosingTag);
}

fn finish(
    s: *State,
    start: usize,
    name: []const u8,
    attrs: *std.ArrayList(tree.Attr),
    children: []const tree.Node,
    self_closing: bool,
) err.ParseError!tree.Element {
    return .{
        .name = name,
        .attrs = try attrs.toOwnedSlice(s.allocator),
        .children = children,
        .self_closing = self_closing,
        .span = .{ .start = start, .end = s.pos },
    };
}

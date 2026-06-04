const std = @import("std");
const tree = @import("../syntax/tree.zig");
const State = @import("state.zig").State;
const state = @import("state.zig");
const nodes = @import("nodes.zig");
const zig = @import("zig.zig");
const err = @import("error.zig");

pub fn parse(s: *State) err.ParseError!tree.File {
    const header_start = s.pos;
    try scanHeader(s);
    const header = s.source[header_start..s.pos];

    var templates: std.ArrayList(tree.Template) = .empty;
    while (true) {
        s.skipSpace();
        if (s.eof()) break;
        try templates.append(s.allocator, try parseTemplate(s));
    }

    return .{
        .header = header,
        .templates = try templates.toOwnedSlice(s.allocator),
        .span = .{ .start = 0, .end = s.source.len },
    };
}

fn parseTemplate(s: *State) err.ParseError!tree.Template {
    const start = s.pos;
    const public = s.matchKeyword("pub");
    if (public) s.skipSpace();
    if (!s.matchKeyword("templ")) return s.fail(s.pos, "expected 'templ'", error.ExpectedTemplate);

    s.skipHorizontalSpace();
    const name = try s.readIdent("expected template name");
    s.skipSpace();
    const params = try parseParams(s);
    s.skipSpace();
    try s.expectByte('{', "expected '{' before template body");

    return .{
        .public = public,
        .name = name,
        .params = params,
        .body = try nodes.parse(s, .template),
        .span = .{ .start = start, .end = s.pos },
    };
}

fn parseParams(s: *State) err.ParseError![]const tree.Param {
    try s.expectByte('(', "expected '(' before parameter list");
    var params: std.ArrayList(tree.Param) = .empty;
    s.skipSpace();
    if (s.matchByte(')')) return try params.toOwnedSlice(s.allocator);

    while (true) {
        s.skipSpace();
        const start = s.pos;
        const name = try s.readIdent("expected parameter name");
        s.skipSpace();
        try s.expectByte(':', "expected ':' after parameter name");
        s.skipSpace();

        const type_start = s.pos;
        const type_end = try zig.readUntilTopLevel(s.source, &s.pos, &.{ .{ .byte = ',' }, .{ .byte = ')' } });
        const type_expr = state.trimSlice(s.source, type_start, type_end);
        if (type_expr.len == 0) return s.fail(type_start, "expected parameter type", error.ExpectedToken);
        try params.append(s.allocator, .{ .name = name, .type_expr = type_expr, .span = .{ .start = start, .end = s.pos } });

        s.skipSpace();
        if (s.matchByte(',')) continue;
        try s.expectByte(')', "expected ')' after parameter list");
        break;
    }
    return try params.toOwnedSlice(s.allocator);
}

fn scanHeader(s: *State) err.ParseError!void {
    while (!s.eof()) {
        if (s.atKeyword("templ") or atPubTemplate(s)) return;
        try zig.skipZigByte(s.source, &s.pos);
    }
}

fn atPubTemplate(s: *const State) bool {
    if (!s.atKeyword("pub")) return false;
    var pos = s.pos + 3;
    while (pos < s.source.len and std.ascii.isWhitespace(s.source[pos])) pos += 1;
    return state.isKeywordAt(s.source, pos, "templ");
}

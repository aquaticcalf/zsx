const tree = @import("../syntax/tree.zig");
const State = @import("state.zig").State;
const zig = @import("zig.zig");
const err = @import("error.zig");

pub fn parse(s: *State) err.ParseError!tree.Expr {
    const start = s.pos;
    try s.expectByte('{', "expected expression");
    var raw = false;
    if (s.matchByte('!')) raw = true;
    const code_start = s.pos;
    const code = try zig.readBraceExpr(s.source, &s.pos, code_start);
    return .{ .code = code, .raw = raw, .span = .{ .start = start, .end = s.pos } };
}

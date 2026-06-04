const tree = @import("../syntax/tree.zig");
const State = @import("state.zig").State;
const state = @import("state.zig");
const err = @import("error.zig");

pub const Context = union(enum) {
    template,
    block,
    element: []const u8,
};

pub fn parse(s: *State, context: Context) err.ParseError!tree.Text {
    const start = s.pos;
    while (!s.eof()) {
        if (s.peek() == '<' or s.peek() == '{' or s.peek() == '@') break;
        if (context != .element and s.peek() == '}') break;
        if (s.atKeyword("if") or s.atKeyword("for")) break;
        s.pos += 1;
    }
    return .{ .source = s.source[start..s.pos], .span = .{ .start = start, .end = s.pos } };
}

pub fn skipInsignificantSpace(s: *State, context: Context) void {
    switch (context) {
        .template, .block => s.skipSpace(),
        .element => {},
    }
}

pub fn canStartText(s: *State) bool {
    return !s.eof() and !state.isKeywordAt(s.source, s.pos, "if") and !state.isKeywordAt(s.source, s.pos, "for");
}

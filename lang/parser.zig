const std = @import("std");
const diag = @import("core/diagnostic.zig");
const tree = @import("syntax/tree.zig");
const file = @import("parse/file.zig");
const State = @import("parse/state.zig").State;
pub const ParseError = @import("parse/error.zig").ParseError;
pub const Error = diag.Error;

pub const Parser = struct {
    state: State,
    err: ?Error = null,

    pub fn init(allocator: std.mem.Allocator, source: []const u8) Parser {
        return .{ .state = State.init(allocator, source) };
    }

    pub fn parseFile(self: *Parser) ParseError!tree.File {
        const parsed = file.parse(&self.state) catch |e| {
            if (self.state.diagnostic) |d| self.err = diag.render(self.state.source, d);
            return e;
        };
        return parsed;
    }
};

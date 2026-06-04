const std = @import("std");
const tree = @import("../syntax/tree.zig");

pub const Emitter = struct {
    writer: *std.Io.Writer,
    indent: usize = 0,
    params: []const tree.Param = &.{},

    pub fn init(writer: *std.Io.Writer) Emitter {
        return .{ .writer = writer };
    }

    pub fn line(self: *Emitter, bytes: []const u8) std.Io.Writer.Error!void {
        try self.writeIndent();
        try self.writer.writeAll(bytes);
        try self.writer.writeAll("\n");
    }

    pub fn literal(self: *Emitter, bytes: []const u8) std.Io.Writer.Error!void {
        if (bytes.len == 0) return;
        try self.writeIndent();
        try self.writer.writeAll("try writer.writeAll(\"");
        try std.zig.stringEscape(bytes, self.writer);
        try self.writer.writeAll("\");\n");
    }

    pub fn zigString(self: *Emitter, bytes: []const u8) std.Io.Writer.Error!void {
        try std.zig.stringEscape(bytes, self.writer);
    }

    pub fn writeParams(self: *Emitter, params: []const tree.Param) std.Io.Writer.Error!void {
        for (params, 0..) |param, i| {
            if (i > 0) try self.writer.writeAll(", ");
            try self.writer.writeAll(param.name);
            try self.writer.writeAll(": ");
            try self.writer.writeAll(param.type_expr);
        }
    }

    pub fn writeCapturedArgs(self: *Emitter) std.Io.Writer.Error!void {
        for (self.params, 0..) |param, i| {
            if (i > 0) try self.writer.writeAll(", ");
            try self.writer.writeAll(param.name);
        }
    }

    pub fn writeIndent(self: *Emitter) std.Io.Writer.Error!void {
        for (0..self.indent) |_| try self.writer.writeAll("    ");
    }
};

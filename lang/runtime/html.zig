const std = @import("std");

pub const Component = struct {
    ptr: *const anyopaque,
    renderFn: *const fn (*const anyopaque, *std.Io.Writer) std.Io.Writer.Error!void,

    pub fn render(self: Component, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        return self.renderFn(self.ptr, writer);
    }
};

pub inline fn renderComponent(target: anytype, args: anytype, writer: *std.Io.Writer) std.Io.Writer.Error!void {
    if (@TypeOf(target) == type) {
        return target.render(args, writer);
    }
    if (@TypeOf(target) == Component) {
        return target.render(writer);
    }
    @compileError("expected a template type or zsx.Component");
}

pub fn writeEscaped(writer: *std.Io.Writer, value: anytype) std.Io.Writer.Error!void {
    const T = @TypeOf(value);
    if (comptime std.meta.hasMethod(T, "formatHtml")) return value.formatHtml(writer);

    switch (@typeInfo(T)) {
        .pointer => |ptr| {
            if (ptr.size == .slice and ptr.child == u8) return writeEscapedString(writer, value);
            if (ptr.size == .one and @typeInfo(ptr.child) == .array and @typeInfo(ptr.child).array.child == u8) {
                return writeEscapedString(writer, value);
            }
            return writeFormatted(writer, value);
        },
        .array => |arr| {
            if (arr.child == u8) return writeEscapedString(writer, &value);
            return writeFormatted(writer, value);
        },
        .int, .float => return writeFormatted(writer, value),
        .optional => if (value) |actual| return writeEscaped(writer, actual),
        .@"enum" => return writeEscapedString(writer, @tagName(value)),
        .bool => return writer.writeAll(if (value) "true" else "false"),
        .void => return,
        else => return writeFormatted(writer, value),
    }
}

pub fn writeAttr(writer: *std.Io.Writer, name: []const u8, value: anytype) std.Io.Writer.Error!void {
    const T = @TypeOf(value);
    const actual = if (@typeInfo(T) == .optional) value orelse return else value;
    try writer.writeAll(" ");
    try writer.writeAll(name);
    try writer.writeAll("=\"");
    try writeEscaped(writer, actual);
    try writer.writeAll("\"");
}

pub fn writeRaw(writer: *std.Io.Writer, value: anytype) std.Io.Writer.Error!void {
    switch (@typeInfo(@TypeOf(value))) {
        .pointer => |ptr| if (ptr.size == .slice and ptr.child == u8) return writer.writeAll(value),
        .void => return,
        else => {},
    }
    try writer.print("{}", .{value});
}

const EscapingWriter = struct {
    underlying: *std.Io.Writer,
    interface: std.Io.Writer = .{ .vtable = &vtable, .buffer = &.{} },

    const vtable: std.Io.Writer.VTable = .{ .drain = drain };

    fn drain(writer: *std.Io.Writer, data: []const []const u8, splat: usize) std.Io.Writer.Error!usize {
        const self: *EscapingWriter = @fieldParentPtr("interface", writer);
        var written: usize = 0;
        for (data[0 .. data.len - 1]) |bytes| {
            try writeEscapedString(self.underlying, bytes);
            written += bytes.len;
        }
        const pattern = data[data.len - 1];
        for (0..splat) |_| {
            try writeEscapedString(self.underlying, pattern);
            written += pattern.len;
        }
        return written;
    }
};

fn writeFormatted(writer: *std.Io.Writer, value: anytype) std.Io.Writer.Error!void {
    var escaping: EscapingWriter = .{ .underlying = writer };
    try escaping.interface.print("{any}", .{value});
}

fn writeEscapedString(writer: *std.Io.Writer, bytes: []const u8) std.Io.Writer.Error!void {
    var start: usize = 0;
    for (bytes, 0..) |byte, i| {
        const escaped: ?[]const u8 = switch (byte) {
            '<' => "&lt;",
            '>' => "&gt;",
            '&' => "&amp;",
            '"' => "&quot;",
            '\'' => "&#x27;",
            else => null,
        };
        if (escaped) |replacement| {
            if (i > start) try writer.writeAll(bytes[start..i]);
            try writer.writeAll(replacement);
            start = i + 1;
        }
    }
    if (start < bytes.len) try writer.writeAll(bytes[start..]);
}

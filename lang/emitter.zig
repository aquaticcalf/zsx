const std = @import("std");
const tree = @import("syntax/tree.zig");
const template = @import("emit/template.zig");
const Emitter = @import("emit/state.zig").Emitter;

pub const Generator = Emitter;

pub fn emitFile(writer: *std.Io.Writer, parsed: tree.File) std.Io.Writer.Error!void {
    var em = Emitter.init(writer);
    if (std.mem.trim(u8, parsed.header, " \t\r\n").len > 0) {
        try writer.writeAll(parsed.header);
        if (!std.mem.endsWith(u8, parsed.header, "\n")) try writer.writeAll("\n");
        try writer.writeAll("\n");
    }
    for (parsed.templates, 0..) |item, i| {
        if (i > 0) try writer.writeAll("\n");
        try template.emit(&em, item);
    }
}

pub fn init(writer: *std.Io.Writer) Emitter {
    return Emitter.init(writer);
}

pub fn generateFile(em: *Emitter, parsed: tree.File) std.Io.Writer.Error!void {
    if (std.mem.trim(u8, parsed.header, " \t\r\n").len > 0) {
        try em.writer.writeAll(parsed.header);
        if (!std.mem.endsWith(u8, parsed.header, "\n")) try em.writer.writeAll("\n");
        try em.writer.writeAll("\n");
    }
    for (parsed.templates, 0..) |item, i| {
        if (i > 0) try em.writer.writeAll("\n");
        try template.emit(em, item);
    }
}

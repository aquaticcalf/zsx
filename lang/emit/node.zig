const std = @import("std");
const tree = @import("../syntax/tree.zig");
const call = @import("call.zig");
const control = @import("control.zig");
const element = @import("element.zig");
const Emitter = @import("state.zig").Emitter;

pub fn emit(em: *Emitter, item: tree.Node) std.Io.Writer.Error!void {
    switch (item) {
        .doctype => |value| try em.literal(value.source),
        .element => |value| try element.emit(em, value),
        .text => |value| try em.literal(value.source),
        .expr => |value| try expr(em, value),
        .call => |value| try call.emit(em, value),
        .children => try em.line("try children.render(writer);"),
        .if_stmt => |value| try control.emitIf(em, value),
        .for_stmt => |value| try control.emitFor(em, value),
    }
}

fn expr(em: *Emitter, value: tree.Expr) std.Io.Writer.Error!void {
    try em.writeIndent();
    try em.writer.writeAll(if (value.raw) "try zsx.writeRaw(writer, " else "try zsx.writeEscaped(writer, ");
    try em.writer.writeAll(value.code);
    try em.writer.writeAll(");\n");
}

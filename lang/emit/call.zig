const std = @import("std");
const tree = @import("../syntax/tree.zig");
const children = @import("children.zig");
const Emitter = @import("state.zig").Emitter;

pub fn emit(em: *Emitter, call: tree.Call) std.Io.Writer.Error!void {
    try em.writeIndent();
    try em.writer.writeAll("try zsx.renderComponent(");
    try em.writer.writeAll(call.callee);
    try em.writer.writeAll(", .{");
    for (call.args, 0..) |arg, i| {
        if (i > 0) try em.writer.writeAll(", ");
        try em.writer.writeAll(arg);
    }
    if (call.children.len > 0) {
        if (call.args.len > 0) try em.writer.writeAll(", ");
        try children.typeName(em, call);
        try em.writer.writeAll(".bind(&.{");
        try em.writeCapturedArgs();
        try em.writer.writeAll("})");
    }
    try em.writer.writeAll("}, writer);\n");
}

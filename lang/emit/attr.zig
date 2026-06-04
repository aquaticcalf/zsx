const std = @import("std");
const tree = @import("../syntax/tree.zig");
const Emitter = @import("state.zig").Emitter;

pub fn emit(em: *Emitter, attr: tree.Attr) std.Io.Writer.Error!void {
    switch (attr.value) {
        .boolean => {
            try em.literal(" ");
            try em.literal(attr.name);
        },
        .text => |value| {
            try em.literal(" ");
            try em.literal(attr.name);
            try em.literal("=\"");
            try em.literal(value);
            try em.literal("\"");
        },
        .expr => |value| {
            try em.writeIndent();
            try em.writer.writeAll("try zsx.writeAttr(writer, \"");
            try em.zigString(attr.name);
            try em.writer.writeAll("\", ");
            try em.writer.writeAll(value.code);
            try em.writer.writeAll(");\n");
        },
        .parts => |parts| {
            try em.literal(" ");
            try em.literal(attr.name);
            try em.literal("=\"");
            for (parts) |part| switch (part) {
                .text => |text| try em.literal(text),
                .expr => |value| try escapedExpr(em, value),
            };
            try em.literal("\"");
        },
    }
}

fn escapedExpr(em: *Emitter, value: tree.Expr) std.Io.Writer.Error!void {
    try em.writeIndent();
    try em.writer.writeAll("try zsx.writeEscaped(writer, ");
    try em.writer.writeAll(value.code);
    try em.writer.writeAll(");\n");
}

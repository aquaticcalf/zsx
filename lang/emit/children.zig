const std = @import("std");
const tree = @import("../syntax/tree.zig");
const node = @import("node.zig");
const template = @import("template.zig");
const Emitter = @import("state.zig").Emitter;

pub fn declareAll(em: *Emitter, nodes: []const tree.Node) std.Io.Writer.Error!void {
    for (nodes) |item| switch (item) {
        .element => |elem| try declareAll(em, elem.children),
        .if_stmt => |stmt| for (stmt.branches) |branch| try declareAll(em, branch.body),
        .for_stmt => |stmt| try declareAll(em, stmt.body),
        .call => |call| {
            if (call.children.len > 0) {
                try declareOne(em, call);
                try declareAll(em, call.children);
            }
        },
        else => {},
    };
}

pub fn typeName(em: *Emitter, call: tree.Call) std.Io.Writer.Error!void {
    try writeTypeName(call, em.writer);
}

fn declareOne(em: *Emitter, call: tree.Call) std.Io.Writer.Error!void {
    try em.writer.writeAll("const ");
    try writeTypeName(call, em.writer);
    try em.writer.writeAll(" = struct {\n");
    em.indent += 1;

    try em.writeIndent();
    try em.writer.writeAll("fn _render(");
    try em.writeParams(em.params);
    if (em.params.len > 0) try em.writer.writeAll(", ");
    try em.writer.writeAll("writer: *std.Io.Writer) std.Io.Writer.Error!void {\n");
    em.indent += 1;
    for (call.children) |item| try node.emit(em, item);
    em.indent -= 1;
    try em.line("}");
    try em.writer.writeAll("\n");

    try template.signature(em, em.params, false);
    try renderApi(em, call);
    em.indent -= 1;
    try em.writer.writeAll("};\n\n");
}

fn renderApi(em: *Emitter, call: tree.Call) std.Io.Writer.Error!void {
    try em.line("pub const Args = std.meta.ArgsTuple(@TypeOf(_signature));");
    try em.writer.writeAll("\n");
    try em.line("pub fn render(args: Args, writer: *std.Io.Writer) std.Io.Writer.Error!void {");
    em.indent += 1;
    try em.line("return @call(.always_inline, _render, args ++ .{writer});");
    em.indent -= 1;
    try em.line("}");
    try em.writer.writeAll("\n");

    try em.line("pub fn bind(args: *const Args) zsx.Component {");
    em.indent += 1;
    try em.line("return .{ .ptr = @ptrCast(args), .renderFn = struct {");
    em.indent += 1;
    try em.line("fn render(ptr: *const anyopaque, w: *std.Io.Writer) std.Io.Writer.Error!void {");
    em.indent += 1;
    try em.line("const stored: *const Args = @ptrCast(@alignCast(ptr));");
    try em.writeIndent();
    try em.writer.writeAll("return ");
    try writeTypeName(call, em.writer);
    try em.writer.writeAll(".render(stored.*, w);\n");
    em.indent -= 1;
    try em.line("}");
    em.indent -= 1;
    try em.line("}.render };");
    em.indent -= 1;
    try em.line("}");
}

fn writeTypeName(call: tree.Call, writer: *std.Io.Writer) std.Io.Writer.Error!void {
    try writer.print("ZsxChildren_{d}", .{call.span.start});
}

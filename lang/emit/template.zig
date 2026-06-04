const std = @import("std");
const tree = @import("../syntax/tree.zig");
const analysis = @import("analysis.zig");
const children = @import("children.zig");
const node = @import("node.zig");
const Emitter = @import("state.zig").Emitter;

pub fn emit(em: *Emitter, template: tree.Template) std.Io.Writer.Error!void {
    em.params = template.params;
    try children.declareAll(em, template.body);

    if (template.public) try em.writer.writeAll("pub ");
    try em.writer.writeAll("const ");
    try em.writer.writeAll(template.name);
    try em.writer.writeAll(" = struct {\n");
    em.indent += 1;

    const has_children = analysis.usesChildren(template.body);
    try renderFunction(em, template.params, has_children, template.body);
    try signature(em, template.params, has_children);
    try renderApi(em, template.name);

    em.indent -= 1;
    try em.writer.writeAll("};\n");
}

fn renderFunction(
    em: *Emitter,
    params: []const tree.Param,
    has_children: bool,
    body: []const tree.Node,
) std.Io.Writer.Error!void {
    try em.writeIndent();
    try em.writer.writeAll("fn _render(");
    try em.writeParams(params);
    if (has_children) {
        if (params.len > 0) try em.writer.writeAll(", ");
        try em.writer.writeAll("children: zsx.Component");
    }
    if (params.len > 0 or has_children) try em.writer.writeAll(", ");
    try em.writer.writeAll("writer: *std.Io.Writer) std.Io.Writer.Error!void {\n");
    em.indent += 1;
    for (body) |item| try node.emit(em, item);
    em.indent -= 1;
    try em.line("}");
    try em.writer.writeAll("\n");
}

pub fn signature(em: *Emitter, params: []const tree.Param, has_children: bool) std.Io.Writer.Error!void {
    try em.writeIndent();
    try em.writer.writeAll("fn _signature(");
    for (params, 0..) |param, i| {
        if (i > 0) try em.writer.writeAll(", ");
        try em.writer.writeAll("_: ");
        try em.writer.writeAll(param.type_expr);
    }
    if (has_children) {
        if (params.len > 0) try em.writer.writeAll(", ");
        try em.writer.writeAll("_: zsx.Component");
    }
    try em.writer.writeAll(") void {}\n\n");
}

pub fn renderApi(em: *Emitter, type_name: []const u8) std.Io.Writer.Error!void {
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
    try em.writer.writeAll(type_name);
    try em.writer.writeAll(".render(stored.*, w);\n");
    em.indent -= 1;
    try em.line("}");
    em.indent -= 1;
    try em.line("}.render };");
    em.indent -= 1;
    try em.line("}");
}

const std = @import("std");
const tree = @import("../syntax/tree.zig");
const html = @import("../syntax/html.zig");
const attr = @import("attr.zig");
const node = @import("node.zig");
const Emitter = @import("state.zig").Emitter;

pub fn emit(em: *Emitter, elem: tree.Element) std.Io.Writer.Error!void {
    try em.literal("<");
    try em.literal(elem.name);
    for (elem.attrs) |item| try attr.emit(em, item);

    if (elem.self_closing) {
        try em.literal(if (html.isVoidElement(elem.name)) ">" else "/>");
        return;
    }

    try em.literal(">");
    if (html.isVoidElement(elem.name)) return;

    for (elem.children) |child| try node.emit(em, child);
    try em.literal("</");
    try em.literal(elem.name);
    try em.literal(">");
}

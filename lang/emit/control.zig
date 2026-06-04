const std = @import("std");
const tree = @import("../syntax/tree.zig");
const node = @import("node.zig");
const Emitter = @import("state.zig").Emitter;

pub fn emitIf(em: *Emitter, stmt: tree.If) std.Io.Writer.Error!void {
    for (stmt.branches, 0..) |branch, i| {
        try em.writeIndent();
        if (i == 0) {
            try em.writer.writeAll("if (");
            try em.writer.writeAll(branch.condition.?);
            try em.writer.writeAll(") {\n");
        } else if (branch.condition) |condition| {
            try em.writer.writeAll("else if (");
            try em.writer.writeAll(condition);
            try em.writer.writeAll(") {\n");
        } else {
            try em.writer.writeAll("else {\n");
        }
        em.indent += 1;
        for (branch.body) |item| try node.emit(em, item);
        em.indent -= 1;
        try em.writeIndent();
        try em.writer.writeAll(if (i + 1 == stmt.branches.len) "}\n" else "} ");
    }
}

pub fn emitFor(em: *Emitter, stmt: tree.For) std.Io.Writer.Error!void {
    try em.writeIndent();
    try em.writer.writeAll("for (");
    try em.writer.writeAll(stmt.iterable);
    try em.writer.writeAll(") |");
    try em.writer.writeAll(stmt.value_name);
    if (stmt.index_name) |idx| {
        try em.writer.writeAll(", ");
        try em.writer.writeAll(idx);
    }
    try em.writer.writeAll("| {\n");
    em.indent += 1;
    for (stmt.body) |item| try node.emit(em, item);
    em.indent -= 1;
    try em.line("}");
}

const std = @import("std");
const zsx = @import("zsx");

test "emitter escapes Zig string literals" {
    const generated = try render(
        \\const zsx = @import("zsx");
        \\pub templ Page(title: []const u8) {
        \\    <!DOCTYPE html>
        \\    <html lang="en"><title>{title} - Lacitra</title></html>
        \\}
    );
    defer std.testing.allocator.free(generated);

    try std.testing.expect(std.mem.indexOf(u8, generated, "const zsx = @import(\"zsx\");") != null);
    try std.testing.expect(std.mem.indexOf(u8, generated, "try writer.writeAll(\"<!DOCTYPE html>\");") != null);
    try std.testing.expect(std.mem.indexOf(u8, generated, "try writer.writeAll(\"=\\\"\");") != null);
    try std.testing.expect(std.mem.indexOf(u8, generated, "try zsx.writeEscaped(writer, title);") != null);
}

test "emitter creates stable wrappers for nested children" {
    const generated = try render(
        \\const zsx = @import("zsx");
        \\templ Page(title: []const u8) {
        \\    @Outer(title) {
        \\        @Inner(title) {
        \\            <span>{title}</span>
        \\        }
        \\    }
        \\}
    );
    defer std.testing.allocator.free(generated);

    try std.testing.expectEqual(@as(usize, 2), std.mem.count(u8, generated, "const ZsxChildren_"));
    try std.testing.expectEqual(@as(usize, 2), std.mem.count(u8, generated, ".bind(&.{title})"));
}

fn render(input: []const u8) ![]u8 {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    var parser = zsx.parser.Parser.init(arena.allocator(), input);
    const parsed = try parser.parseFile();

    var out: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer out.deinit();
    try zsx.emitter.emitFile(&out.writer, parsed);
    return try std.testing.allocator.dupe(u8, out.written());
}

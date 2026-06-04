const std = @import("std");
const zsx = @import("zsx");

test "parser builds a template tree" {
    const input =
        \\const zsx = @import("zsx");
        \\
        \\pub templ Layout(title: []const u8) {
        \\    <main class="page {title}" hidden>
        \\        <h1>{title}</h1>
        \\        @children
        \\    </main>
        \\}
    ;

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    var parser = zsx.parser.Parser.init(arena.allocator(), input);
    const file = try parser.parseFile();

    try std.testing.expectEqual(@as(usize, 1), file.templates.len);
    try std.testing.expect(file.templates[0].public);
    try std.testing.expectEqualStrings("Layout", file.templates[0].name);
    try std.testing.expectEqualStrings("title", file.templates[0].params[0].name);
    try std.testing.expectEqualStrings("[]const u8", file.templates[0].params[0].type_expr);

    const main = file.templates[0].body[0].element;
    try std.testing.expectEqualStrings("main", main.name);
    try std.testing.expectEqual(@as(usize, 2), main.attrs.len);
    try std.testing.expectEqual(@as(usize, 5), main.children.len);
}

test "parser reports mismatched closing tags" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    var parser = zsx.parser.Parser.init(arena.allocator(), "templ Bad() { <div></span> }");
    try std.testing.expectError(error.MismatchedClosingTag, parser.parseFile());
    try std.testing.expect(parser.err != null);
}

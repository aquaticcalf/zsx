const std = @import("std");
const zsx = @import("zsx");

test "runtime escapes HTML-sensitive bytes" {
    var out: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer out.deinit();

    try zsx.writeEscaped(&out.writer, "<a href=\"x&y\">'ok'</a>");
    try std.testing.expectEqualStrings("&lt;a href=&quot;x&amp;y&quot;&gt;&#x27;ok&#x27;&lt;/a&gt;", out.written());
}

test "runtime omits null optional attributes" {
    var out: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer out.deinit();

    const missing: ?[]const u8 = null;
    try zsx.writeAttr(&out.writer, "title", missing);
    try zsx.writeAttr(&out.writer, "title", "a&b");

    try std.testing.expectEqualStrings(" title=\"a&amp;b\"", out.written());
}

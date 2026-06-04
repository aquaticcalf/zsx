const span = @import("span.zig");

pub const Diagnostic = struct {
    span: span.Span,
    message: []const u8,
};

pub const Error = struct {
    line: u32,
    column: u32,
    message: []const u8,
};

pub fn render(source: []const u8, diagnostic: Diagnostic) Error {
    const location = span.locate(source, diagnostic.span.start);
    return .{
        .line = location.line,
        .column = location.column,
        .message = diagnostic.message,
    };
}

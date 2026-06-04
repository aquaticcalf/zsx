const std = @import("std");

pub const Span = struct {
    start: usize,
    end: usize,

    pub fn slice(self: Span, source: []const u8) []const u8 {
        return source[self.start..self.end];
    }
};

pub const Location = struct {
    line: u32,
    column: u32,
    offset: usize,
};

pub fn locate(source: []const u8, offset: usize) Location {
    var line: u32 = 1;
    var column: u32 = 1;
    for (source[0..@min(offset, source.len)]) |byte| {
        if (byte == '\n') {
            line += 1;
            column = 1;
        } else {
            column += 1;
        }
    }
    return .{ .line = line, .column = column, .offset = @min(offset, source.len) };
}

pub fn trim(source: []const u8, span: Span) Span {
    var start = span.start;
    var end = span.end;
    while (start < end and std.ascii.isWhitespace(source[start])) start += 1;
    while (end > start and std.ascii.isWhitespace(source[end - 1])) end -= 1;
    return .{ .start = start, .end = end };
}

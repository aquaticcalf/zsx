const std = @import("std");
const diag = @import("../core/diagnostic.zig");
const span = @import("../core/span.zig");
const err = @import("error.zig");

pub const State = struct {
    allocator: std.mem.Allocator,
    source: []const u8,
    pos: usize = 0,
    diagnostic: ?diag.Diagnostic = null,

    pub fn init(allocator: std.mem.Allocator, source: []const u8) State {
        return .{ .allocator = allocator, .source = source };
    }

    pub fn eof(self: *const State) bool {
        return self.pos >= self.source.len;
    }

    pub fn peek(self: *const State) u8 {
        return if (self.eof()) 0 else self.source[self.pos];
    }

    pub fn startsWith(self: *const State, bytes: []const u8) bool {
        return std.mem.startsWith(u8, self.source[self.pos..], bytes);
    }

    pub fn matchByte(self: *State, byte: u8) bool {
        if (!self.eof() and self.peek() == byte) {
            self.pos += 1;
            return true;
        }
        return false;
    }

    pub fn matchString(self: *State, bytes: []const u8) bool {
        if (!self.startsWith(bytes)) return false;
        self.pos += bytes.len;
        return true;
    }

    pub fn atKeyword(self: *const State, keyword: []const u8) bool {
        return isKeywordAt(self.source, self.pos, keyword);
    }

    pub fn matchKeyword(self: *State, keyword: []const u8) bool {
        if (!self.atKeyword(keyword)) return false;
        self.pos += keyword.len;
        return true;
    }

    pub fn skipSpace(self: *State) void {
        while (!self.eof() and std.ascii.isWhitespace(self.peek())) self.pos += 1;
    }

    pub fn skipHorizontalSpace(self: *State) void {
        while (!self.eof() and (self.peek() == ' ' or self.peek() == '\t' or self.peek() == '\r')) self.pos += 1;
    }

    pub fn expectByte(self: *State, byte: u8, message: []const u8) err.ParseError!void {
        if (!self.matchByte(byte)) return self.fail(self.pos, message, error.ExpectedToken);
    }

    pub fn expectString(self: *State, bytes: []const u8, message: []const u8) err.ParseError!void {
        if (!self.matchString(bytes)) return self.fail(self.pos, message, error.ExpectedToken);
    }

    pub fn expectKeyword(self: *State, keyword: []const u8, message: []const u8) err.ParseError!void {
        if (!self.matchKeyword(keyword)) return self.fail(self.pos, message, error.ExpectedToken);
    }

    pub fn readIdent(self: *State, message: []const u8) err.ParseError![]const u8 {
        if (self.eof() or !isIdentStart(self.peek())) return self.fail(self.pos, message, error.ExpectedIdentifier);
        const start = self.pos;
        self.pos += 1;
        while (!self.eof() and isIdentContinue(self.peek())) self.pos += 1;
        return self.source[start..self.pos];
    }

    pub fn readName(self: *State, message: []const u8) err.ParseError![]const u8 {
        if (self.eof() or !isIdentStart(self.peek())) return self.fail(self.pos, message, error.ExpectedIdentifier);
        const start = self.pos;
        self.pos += 1;
        while (!self.eof() and (isIdentContinue(self.peek()) or self.peek() == '-' or self.peek() == ':')) self.pos += 1;
        return self.source[start..self.pos];
    }

    pub fn readCallee(self: *State, message: []const u8) err.ParseError![]const u8 {
        if (self.eof() or !isIdentStart(self.peek())) return self.fail(self.pos, message, error.ExpectedIdentifier);
        const start = self.pos;
        self.pos += 1;
        while (!self.eof() and (isIdentContinue(self.peek()) or self.peek() == '.')) self.pos += 1;
        return self.source[start..self.pos];
    }

    pub fn fail(self: *State, offset: usize, message: []const u8, e: err.ParseError) err.ParseError {
        self.diagnostic = .{
            .span = .{ .start = @min(offset, self.source.len), .end = @min(offset, self.source.len) },
            .message = message,
        };
        return e;
    }
};

pub fn isKeywordAt(source: []const u8, pos: usize, keyword: []const u8) bool {
    if (pos + keyword.len > source.len) return false;
    if (!std.mem.eql(u8, source[pos .. pos + keyword.len], keyword)) return false;
    if (pos > 0 and (isIdentContinue(source[pos - 1]) or source[pos - 1] == '.')) return false;
    if (pos + keyword.len < source.len and isIdentContinue(source[pos + keyword.len])) return false;
    return true;
}

pub fn isIdentStart(byte: u8) bool {
    return std.ascii.isAlphabetic(byte) or byte == '_';
}

pub fn isIdentContinue(byte: u8) bool {
    return isIdentStart(byte) or std.ascii.isDigit(byte);
}

pub fn trimSlice(source: []const u8, start: usize, end: usize) []const u8 {
    const trimmed = span.trim(source, .{ .start = start, .end = end });
    return source[trimmed.start..trimmed.end];
}

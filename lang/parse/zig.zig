const std = @import("std");
const err = @import("error.zig");
const trivia = @import("trivia.zig");

pub const Stop = union(enum) {
    byte: u8,
    text: []const u8,
};

pub fn skipZigByte(source: []const u8, pos: *usize) err.ParseError!void {
    return trivia.skipByte(source, pos);
}

pub fn readBalanced(source: []const u8, pos: *usize, open: u8, close: u8) err.ParseError![]const u8 {
    std.debug.assert(source[pos.*] == open);
    const start = pos.* + 1;
    pos.* += 1;
    var depth: usize = 1;
    while (pos.* < source.len) {
        if (source[pos.*] == open) {
            depth += 1;
            pos.* += 1;
            continue;
        }
        if (source[pos.*] == close) {
            depth -= 1;
            if (depth == 0) {
                const end = pos.*;
                pos.* += 1;
                return std.mem.trim(u8, source[start..end], " \t\r\n");
            }
            pos.* += 1;
            continue;
        }
        try skipZigByte(source, pos);
    }
    return error.UnterminatedDelimited;
}

pub fn readUntilTopLevel(source: []const u8, pos: *usize, stops: []const Stop) err.ParseError!usize {
    var paren: usize = 0;
    var bracket: usize = 0;
    var brace: usize = 0;
    while (pos.* < source.len) {
        if (paren == 0 and bracket == 0 and brace == 0 and atStop(source, pos.*, stops)) return pos.*;
        switch (source[pos.*]) {
            '(' => {
                paren += 1;
                pos.* += 1;
            },
            ')' => {
                if (paren == 0) return pos.*;
                paren -= 1;
                pos.* += 1;
            },
            '[' => {
                bracket += 1;
                pos.* += 1;
            },
            ']' => {
                if (bracket == 0) return pos.*;
                bracket -= 1;
                pos.* += 1;
            },
            '{' => {
                brace += 1;
                pos.* += 1;
            },
            '}' => {
                if (brace == 0) return pos.*;
                brace -= 1;
                pos.* += 1;
            },
            else => try skipZigByte(source, pos),
        }
    }
    return pos.*;
}

pub fn readBraceExpr(source: []const u8, pos: *usize, start: usize) err.ParseError![]const u8 {
    var depth: usize = 0;
    while (pos.* < source.len) {
        if (source[pos.*] == '{') {
            depth += 1;
            pos.* += 1;
            continue;
        }
        if (source[pos.*] == '}') {
            if (depth == 0) {
                const end = pos.*;
                pos.* += 1;
                return std.mem.trim(u8, source[start..end], " \t\r\n");
            }
            depth -= 1;
            pos.* += 1;
            continue;
        }
        try skipZigByte(source, pos);
    }
    return error.UnterminatedDelimited;
}

fn atStop(source: []const u8, pos: usize, stops: []const Stop) bool {
    for (stops) |stop| switch (stop) {
        .byte => |byte| if (source[pos] == byte) return true,
        .text => |bytes| if (std.mem.startsWith(u8, source[pos..], bytes)) return true,
    };
    return false;
}

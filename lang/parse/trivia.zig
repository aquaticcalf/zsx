const err = @import("error.zig");

pub fn skipByte(source: []const u8, pos: *usize) err.ParseError!void {
    switch (source[pos.*]) {
        '"' => try skipString(source, pos),
        '\'' => try skipChar(source, pos),
        '/' => {
            if (peek(source, pos.*, 1) == '/') skipLineComment(source, pos) else if (peek(source, pos.*, 1) == '*') try skipBlockComment(source, pos) else pos.* += 1;
        },
        else => pos.* += 1,
    }
}

fn skipString(source: []const u8, pos: *usize) err.ParseError!void {
    pos.* += 1;
    while (pos.* < source.len) {
        switch (source[pos.*]) {
            '\\' => pos.* += if (pos.* + 1 < source.len) 2 else 1,
            '"' => {
                pos.* += 1;
                return;
            },
            else => pos.* += 1,
        }
    }
    return error.UnterminatedString;
}

fn skipChar(source: []const u8, pos: *usize) err.ParseError!void {
    pos.* += 1;
    while (pos.* < source.len) {
        switch (source[pos.*]) {
            '\\' => pos.* += if (pos.* + 1 < source.len) 2 else 1,
            '\'' => {
                pos.* += 1;
                return;
            },
            else => pos.* += 1,
        }
    }
    return error.UnterminatedChar;
}

fn skipLineComment(source: []const u8, pos: *usize) void {
    pos.* += 2;
    while (pos.* < source.len and source[pos.*] != '\n') pos.* += 1;
}

fn skipBlockComment(source: []const u8, pos: *usize) err.ParseError!void {
    pos.* += 2;
    while (pos.* + 1 < source.len) : (pos.* += 1) {
        if (source[pos.*] == '*' and source[pos.* + 1] == '/') {
            pos.* += 2;
            return;
        }
    }
    return error.UnterminatedComment;
}

fn peek(source: []const u8, pos: usize, offset: usize) u8 {
    return if (pos + offset < source.len) source[pos + offset] else 0;
}

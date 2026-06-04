const std = @import("std");
const zsx = @import("zsx.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const args = try init.minimal.args.toSlice(allocator);
    defer allocator.free(args);

    if (args.len < 3 or args.len % 2 != 1) {
        std.debug.print("Usage: zsx-compile <input.zsx> <output.zig> ...\n", .{});
        std.process.exit(1);
    }

    var index: usize = 1;
    while (index < args.len) : (index += 2) {
        try compileTemplate(allocator, io, args[index], args[index + 1]);
    }
}

fn compileTemplate(allocator: std.mem.Allocator, io: std.Io, input_path: []const u8, output_path: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const scratch = arena.allocator();

    const cwd = std.Io.Dir.cwd();
    const source = cwd.readFileAlloc(io, input_path, scratch, .limited(10 * 1024 * 1024)) catch |e| {
        std.debug.print("Error reading '{s}': {}\n", .{ input_path, e });
        return error.ReadFailed;
    };

    var parser = zsx.parser.Parser.init(scratch, source);
    const parsed = parser.parseFile() catch |e| {
        if (parser.err) |diag| {
            std.debug.print("{s}:{d}:{d}: {s}\n", .{ input_path, diag.line, diag.column, diag.message });
        } else {
            std.debug.print("{s}: parse error: {}\n", .{ input_path, e });
        }
        return error.ParseFailed;
    };

    var output: std.Io.Writer.Allocating = .init(scratch);
    try output.writer.writeAll("// Auto-generated from ");
    try output.writer.writeAll(std.fs.path.basename(input_path));
    try output.writer.writeAll(" - do not edit\n");
    try output.writer.writeAll("const std = @import(\"std\");\n\n");
    try zsx.emitter.emitFile(&output.writer, parsed);

    cwd.writeFile(io, .{ .sub_path = output_path, .data = output.written() }) catch |e| {
        std.debug.print("Error writing '{s}': {}\n", .{ output_path, e });
        return error.WriteFailed;
    };
}

pub const syntax = struct {
    pub const tree = @import("syntax/tree.zig");
    pub const html = @import("syntax/html.zig");
};

pub const parser = @import("parser.zig");
pub const emitter = @import("emitter.zig");

const html_runtime = @import("runtime/html.zig");

pub const Component = html_runtime.Component;
pub const renderComponent = html_runtime.renderComponent;
pub const writeEscaped = html_runtime.writeEscaped;
pub const writeAttr = html_runtime.writeAttr;
pub const writeRaw = html_runtime.writeRaw;

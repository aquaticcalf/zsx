const core = @import("../core/span.zig");

pub const Span = core.Span;

pub const File = struct {
    header: []const u8,
    templates: []const Template,
    span: Span,
};

pub const Template = struct {
    public: bool,
    name: []const u8,
    params: []const Param,
    body: []const Node,
    span: Span,
};

pub const Param = struct {
    name: []const u8,
    type_expr: []const u8,
    span: Span,
};

pub const Node = union(enum) {
    doctype: Doctype,
    element: Element,
    text: Text,
    expr: Expr,
    call: Call,
    children: Span,
    if_stmt: If,
    for_stmt: For,
};

pub const Doctype = struct {
    source: []const u8,
    span: Span,
};

pub const Text = struct {
    source: []const u8,
    span: Span,
};

pub const Expr = struct {
    code: []const u8,
    raw: bool,
    span: Span,
};

pub const Element = struct {
    name: []const u8,
    attrs: []const Attr,
    children: []const Node,
    self_closing: bool,
    span: Span,
};

pub const Attr = struct {
    name: []const u8,
    value: AttrValue,
    span: Span,
};

pub const AttrValue = union(enum) {
    boolean,
    text: []const u8,
    expr: Expr,
    parts: []const AttrPart,
};

pub const AttrPart = union(enum) {
    text: []const u8,
    expr: Expr,
};

pub const Call = struct {
    callee: []const u8,
    args: []const []const u8,
    children: []const Node,
    span: Span,
};

pub const If = struct {
    branches: []const IfBranch,
    span: Span,
};

pub const IfBranch = struct {
    condition: ?[]const u8,
    body: []const Node,
    span: Span,
};

pub const For = struct {
    iterable: []const u8,
    value_name: []const u8,
    index_name: ?[]const u8,
    body: []const Node,
    span: Span,
};

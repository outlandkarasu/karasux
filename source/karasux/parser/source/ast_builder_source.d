/**
AST builder source module.
*/
module karasux.parser.source.ast_builder_source;

import karasux.parser.source.traits :
    isInputSource,
    isSeekableSource;

/**
AST builder source trait.

Params:
    R = source range type.
*/
enum isASTBuilderSource(R) = isInputSource!R
    && is(R.Tag)
    && is(typeof((scope ref R r) @nogc nothrow pure @safe => r.nodePosition))
    && is(typeof((scope ref R r) { auto p = r.nodePosition; r.acceptNode(R.Tag.init, p); }));

/**
rejectable AST builder source trait.

Params:
    R = source range type.
*/
enum isRejectableASTBuilderSource(R) = isSeekableSource!R
    && isASTBuilderSource!R
    && is(typeof((scope ref R r) { auto p = r.nodePosition; r.rejectNode(p); }));

/**
AST builder source.

Params:
    R = inner source type
    T = AST tag type
*/
struct ASTBuilderSource(R, T)
{
    static assert(isInputSource!R);

    /**
    AST tag type.
    */
    alias Tag = T;

    /**
    Initialize from inner source.

    Params:
        source = inner source.
    */
    this(return scope R source) @nogc nothrow pure @safe scope
    {
        this.inner = source;
    }

    @nogc nothrow pure @safe scope
    {
        @property size_t nodePosition() const
        {
            return nodePosition_;
        }
    }

    /**
    Accept node.

    Params:
        tag = AST node tag value
        start = node start position
    */
    void acceptNode(Tag tag, size_t start) @nogc nothrow pure @safe scope
    {
    }

    R inner;

    alias inner this;

private:
    size_t nodePosition_;
}

///
@nogc nothrow pure @safe unittest
{
    import karasux.parser.source.array_source : arraySource;

    auto source = astBuilder!int(arraySource("test"));
    static assert(isASTBuilderSource!(typeof(source)));
}

/**
create AST builder source.

Params:
    r = inner source
Returns:
    AST builder source
*/
ASTBuilderSource!(R, T) astBuilder(T, R)(return scope R r)
{
    return ASTBuilderSource!(R, T)(r);
}


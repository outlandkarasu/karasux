/**
AST builder source module.
*/
module karasux.parser.source.ast_builder_source;

import core.memory : pureCalloc, pureRealloc, pureFree;

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

    // not copyiable.
    @disable this(this);

    // not copyiable.
    @disable this(ref return scope ASTBuilderSource rhs);

    ~this() @nogc nothrow pure @safe scope
    {
    }

    R inner;

    alias inner this;
}


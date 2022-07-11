/**
AST builder source module.
*/
module karasux.parser.source.ast_builder_source;

import karasux.parser.source.traits : isInputSource;

/**
AST builder source trait.
*/
enum isASTBuilderSource(R) = isInputSource!R
  && is(typeof((scope ref R r) => r.nodePosition));

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

    R inner;

    alias inner this;
}


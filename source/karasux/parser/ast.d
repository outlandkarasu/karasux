/**
Parser AST module.
*/
module karasux.parser.ast;

import karasux.buffer : Buffer;
import karasux.parser.traits : isParser;
import karasux.parser.source :
    isInputSource,
    isSeekableSource;

/**
AST node event type.
*/
enum ASTNodeEventType
{
    start,
    end
}

/**
AST parse error type.
*/
enum ASTParseErrorType
{
    none,
    allocation,
}

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

    static if (isSeekableSource!R)
    {
        alias PositionType = typeof(R.init.position);
    }
    else
    {
        alias PositionType = size_t;

        @property size_t position() const @nogc nothrow pure @safe scope
        {
            return nodePosition;
        }
    }

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

    @nogc nothrow pure @safe scope
    {
        @property size_t nodePosition() const
        {
            return events_.length;
        }

        @property ASTParseErrorType error() const
        {
            return error_;
        }

        @property bool hasError() const
        {
            return error_ != ASTParseErrorType.none;
        }

        bool startNode(Tag tag)
        {
            return addEvent(tag, ASTNodeEventType.start);
        }

        bool acceptNode(Tag tag)
        {
            return addEvent(tag, ASTNodeEventType.end);
        }

        bool rejectNode(size_t startNodePosition)
        {
            return events_.resize(startNodePosition);
        }
    }

private:

    struct NodeEvent
    {
        Tag tag;
        ASTNodeEventType type;
        PositionType position;
    }

    bool addEvent(Tag tag, ASTNodeEventType eventType) @nogc nothrow pure @safe scope
    {
        if (hasError)
        {
            return false;
        }

        if (!events_.append(NodeEvent(tag, eventType, position)))
        {
            error_ = ASTParseErrorType.allocation;
            return false;
        }

        return true;
    }

    Buffer!NodeEvent events_;
    ASTParseErrorType error_ = ASTParseErrorType.none;
}

///
@nogc nothrow pure @safe unittest
{
    import karasux.parser.source.array_source : arraySource;

    auto source = astBuilder!int(arraySource("test"));

    assert(source.front == 't');
    assert(source.position == 0);
    assert(source.nodePosition == 0);
    assert(!source.empty);
    assert(source.error == ASTParseErrorType.none);
    assert(!source.hasError);

    assert(source.startNode(0));
    assert(source.position == 0);
    assert(source.nodePosition == 1);
    assert(!source.hasError);

    assert(source.startNode(123));
    assert(source.position == 0);
    assert(source.nodePosition == 2);
    assert(!source.hasError);

    source.popFront();

    assert(source.front == 'e');
    assert(source.position == 1);
    assert(source.nodePosition == 2);
    assert(!source.empty);
    assert(!source.hasError);

    assert(source.acceptNode(123));

    assert(source.position == 1);
    assert(source.nodePosition == 3);
    assert(!source.hasError);

    // reject nodes but position is not reverted.
    assert(source.rejectNode(0));
    assert(source.position == 1);
    assert(source.nodePosition == 0);
    assert(!source.hasError);
}

/**
Create AST builder source.

Params:
    R = inner source type.
    T = tag type.
    source = inner source
Returns:
    AST builder source.
*/
ASTBuilderSource!(R, T) astBuilder(T, R)(return scope R source)
    if (isInputSource!R)
{
    return ASTBuilderSource!(R, T)(source);
}

/**
AST node parser.

Params:
    P = parsers
*/
bool astNode(alias P, R, T)(auto scope ref ASTBuilderSource!(R, T) source, T tag)
    if (isParser!(P, ASTBuilderSource!(R, T)))
{
    auto nodePosition = source.nodePosition;
    if (!source.startNode(tag))
    {
        return false;
    }

    if (!P(source))
    {
        source.rejectNode(nodePosition);
        return false;
    }

    return source.acceptNode(tag);
}

///
@nogc nothrow pure @safe unittest
{
    import karasux.parser.primitive : symbol;
    import karasux.parser.source.array_source : arraySource;

    auto source = astBuilder!int(arraySource("test"));

    assert(source.astNode!((scope ref s) => s.symbol('t'))(123));
}


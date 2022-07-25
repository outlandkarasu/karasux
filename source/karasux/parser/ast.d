/**
Parser AST module.
*/
module karasux.parser.ast;

import std.traits : ParameterTypeTuple;

import karasux.buffer :
    CoreMemoryBuffer,
    DynamicArrayBuffer;
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
    Buffer = buffer template
*/
struct ASTBuilderSource(R, T, alias Buffer)
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

    struct NodeEvent
    {
        Tag tag;
        ASTNodeEventType type;
        PositionType position;
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

    nothrow pure @safe scope
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

    int opApply(Dg)(scope Dg dg) const
    {
        int result = 0;
        foreach (i; 0 .. events_.length)
        {
            result = dg(events_[i]);
            if (result != 0)
            {
                return result;
            }
        }

        return result;
    }

private:

    bool addEvent(Tag tag, ASTNodeEventType eventType) nothrow pure @safe scope
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
auto astBuilder(T, R)(return scope R source)
    if (isInputSource!R)
{
    return ASTBuilderSource!(R, T, CoreMemoryBuffer)(source);
}

/**
Create CTFEable AST builder source.

Params:
    R = inner source type.
    T = tag type.
    source = inner source
Returns:
    AST builder source.
*/
auto ctfeAstBuilder(T, R)(return scope R source)
    if (isInputSource!R)
{
    return ASTBuilderSource!(R, T, DynamicArrayBuffer)(source);
}

/**
AST node parser.

Params:
    P = parsers
*/
bool astNode(alias P, R, T, alias Buffer)(auto scope ref ASTBuilderSource!(R, T, Buffer) source, T tag)
    if (isParser!(P, ASTBuilderSource!(R, T, Buffer)))
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
    alias NodeEvent = typeof(source).NodeEvent;

    assert(source.astNode!((scope ref s) => s.symbol('t'))(123));
    assert(source.nodePosition == 2);

    foreach (ref const(NodeEvent) event; source)
    {
        if (event.position == 0)
        {
            assert(event.tag == 123);
            assert(event.type == ASTNodeEventType.start);
        }
        else
        {
            assert(event.position == 1);
            assert(event.tag == 123);
            assert(event.type == ASTNodeEventType.end);
        }
    }

    assert(!source.astNode!((scope ref s) => s.symbol('t'))(125));
    assert(source.nodePosition == 2);

    foreach (ref const(NodeEvent) event; source)
    {
        if (event.position == 0)
        {
            assert(event.tag == 123);
            assert(event.type == ASTNodeEventType.start);
        }
        else
        {
            assert(event.position == 1);
            assert(event.tag == 123);
            assert(event.type == ASTNodeEventType.end);
        }
    }
}

///
nothrow pure @safe unittest
{
    import karasux.ctfe : staticUnittest;
    staticUnittest!(
    {
        import karasux.parser.primitive : symbol;
        import karasux.parser.source.array_source : arraySource;

        auto source = ctfeAstBuilder!int(arraySource("test"));
        alias NodeEvent = typeof(source).NodeEvent;

        assert(source.astNode!((scope ref s) => s.symbol('t'))(123));
        assert(source.nodePosition == 2);

        foreach (ref const(NodeEvent) event; source)
        {
            if (event.position == 0)
            {
                assert(event.tag == 123);
                assert(event.type == ASTNodeEventType.start);
            }
            else
            {
                assert(event.position == 1);
                assert(event.tag == 123);
                assert(event.type == ASTNodeEventType.end);
            }
        }

        assert(!source.astNode!((scope ref s) => s.symbol('t'))(125));
        assert(source.nodePosition == 2);

        foreach (ref const(NodeEvent) event; source)
        {
            if (event.position == 0)
            {
                assert(event.tag == 123);
                assert(event.type == ASTNodeEventType.start);
            }
            else
            {
                assert(event.position == 1);
                assert(event.tag == 123);
                assert(event.type == ASTNodeEventType.end);
            }
        }
    });
}


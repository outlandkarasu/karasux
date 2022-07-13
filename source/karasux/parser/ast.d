/**
Parser AST module.
*/
module karasux.parser.ast;

import karasux.buffer : Buffer;
import karasux.parser.source.traits :
    isInputSource,
    isSeekableSource;

/**
AST builder source trait.
*/
enum isASTBuilderSource(R) = isInputSource!R
  && is(typeof(R.Tag.init))
  && is(typeof((scope ref R r) @nogc nothrow pure @safe => r.nodePosition))
  && is(typeof((scope ref R r) => r.startNode(R.Tag.init)))
  && is(typeof((scope ref R r) => r.acceptNode(R.Tag.init)))
  && is(typeof((scope ref R r) { auto p = r.nodePosition; r.rejectNode(p); }));

/**
AST node event type.
*/
enum ASTNodeEventType
{
    start,
    end
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

        bool startNode(Tag tag)
        {
            return events_.append(NodeEvent(tag, ASTNodeEventType.start, position));
        }

        bool acceptNode(Tag tag)
        {
            return events_.append(NodeEvent(tag, ASTNodeEventType.end, position));
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

    Buffer!NodeEvent events_;
}

///
@nogc nothrow pure @safe unittest
{
    import karasux.parser.source.array_source : arraySource;

    auto source = astBuilder!int(arraySource("test"));
    static assert(isASTBuilderSource!(typeof(source)));

    assert(source.front == 't');
    assert(source.position == 0);
    assert(source.nodePosition == 0);
    assert(!source.empty);

    assert(source.startNode(0));
    assert(source.position == 0);
    assert(source.nodePosition == 1);

    assert(source.startNode(123));
    assert(source.position == 0);
    assert(source.nodePosition == 2);

    source.popFront();

    assert(source.front == 'e');
    assert(source.position == 1);
    assert(source.nodePosition == 2);
    assert(!source.empty);

    assert(source.acceptNode(123));

    assert(source.position == 1);
    assert(source.nodePosition == 3);

    // reject nodes but position is not reverted.
    assert(source.rejectNode(0));
    assert(source.position == 1);
    assert(source.nodePosition == 0);
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


/**
Line counted source module.
*/
module karasux.parser.source.line_counted_source;

import karasux.parser.source.traits :
    isInputSource,
    isSeekableSource;

/**
Line counted source traits.
*/
enum isLineCountedSource(R) = isInputSource!R
    && is(typeof((scope ref R r) => r.currentLine))
    && is(typeof((scope ref R r) => r.addLine()));

/**
Line counted source.

Params:
    R = inner source
*/
struct LineCountedSource(R)
{
    static assert(isInputSource!R);

    /**
    Initialize from inner source.

    Params:
        source = inner source.
    */
    this(return scope R source) @nogc nothrow pure @safe scope
    {
        this.inner = source;
        this.currentLine_ = 0;
    }

    /**
    Add line number.
    */
    void addLine() @nogc nothrow pure @safe scope
    {
        ++currentLine_;
    }

    @property size_t currentLine() const @nogc nothrow pure @safe
    {
        return currentLine_;
    }

    static if (isSeekableSource!R)
    {
        alias PositionType = typeof(R.init.position);

        /**
        Source position with line.
        */
        struct PositionWithLine
        {
            PositionType position;
            size_t line;
        }

        @property PositionWithLine position() const
        {
            return PositionWithLine(inner.position, currentLine_);
        }

        void seek()(auto scope ref const(PositionWithLine) position)
        {
            inner.seek(position.position);
            currentLine_ = position.line;
        }
    }

    R inner;

    alias inner this;

private:
    size_t currentLine_;
}

///
@nogc nothrow pure @safe unittest
{
    import karasux.parser.source.array_source : ArraySource, arraySource;

    auto source = lineCounted(arraySource("test"));
    static assert(isLineCountedSource!(typeof(source)));

    assert(source.front == 't');
    assert(source.position.position == 0);
    assert(source.position.line == 0);
    assert(source.currentLine == 0);
    assert(!source.empty);

    source.popFront();
    assert(source.front == 'e');
    assert(source.position.position == 1);
    assert(source.position.line == 0);
    assert(source.currentLine == 0);

    source.addLine();
    assert(source.position.position == 1);
    assert(source.position.line == 1);
    assert(source.currentLine == 1);

    immutable before = source.position;

    source.popFront();
    source.addLine();
    assert(source.front == 's');
    assert(source.position.position == 2);
    assert(source.position.line == 2);
    assert(source.currentLine == 2);

    source.seek(before);
    assert(source.front == 'e');
    assert(source.position.position == 1);
    assert(source.position.line == 1);
    assert(source.currentLine == 1);

    source.popFront();
    source.popFront();
    source.popFront();
    assert(source.position.position == 4);
    assert(source.position.line == 1);
    assert(source.empty);
}

///
pure @safe unittest
{
    import std.range : front, popFront, empty;

    auto source = lineCounted("test");
    static assert(isLineCountedSource!(typeof(source)));

    assert(source.front == 't');
    assert(source.currentLine == 0);
    assert(!source.empty);

    source.popFront();
    assert(source.front == 'e');
    assert(source.currentLine == 0);
    assert(!source.empty);

    source.addLine();
    assert(source.front == 'e');
    assert(source.currentLine == 1);
    assert(!source.empty);

    source.popFront();
    assert(source.front == 's');
    assert(source.currentLine == 1);
    assert(!source.empty);

    source.popFront();
    assert(source.front == 't');
    assert(source.currentLine == 1);
    assert(!source.empty);

    source.popFront();
    assert(source.currentLine == 1);
    assert(source.empty);
}

/**
Create line counted source from inner source.

Params:
    R = inner source type.
    source = inner source
*/
LineCountedSource!R lineCounted(R)(return scope R source)
{
    return LineCountedSource!R(source);
}


/**
Line counted source module.
*/
module karasux.parser.source.line_counted_source;

import karasux.parser.source.traits : isSeekableSource;

/**
Source position with line.
*/
struct PositionWithLine
{
    size_t position;
    size_t line;
}

/**
Line counted source.

Params:
    R = inner source
*/
struct LineCountedSource(R)
{
    static assert(isSeekableSource!R);

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

    @nogc nothrow pure @safe scope
    {
        @property size_t currentLine() const
        {
            return currentLine_;
        }

        @property PositionWithLine position() const
        {
            return PositionWithLine(inner.position, currentLine_);
        }
    }

    void seek()(auto scope ref const(PositionWithLine) position)
    {
        inner.seek(position.position);
        currentLine_ = position.line;
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

    assert(source.front == 't');
    assert(source.position == PositionWithLine(0, 0));
    assert(source.currentLine == 0);
    assert(!source.empty);

    source.popFront();
    assert(source.front == 'e');
    assert(source.position == PositionWithLine(1, 0));
    assert(source.currentLine == 0);

    source.addLine();
    assert(source.position == PositionWithLine(1, 1));
    assert(source.currentLine == 1);
    immutable before = source.position;

    source.popFront();
    source.addLine();
    assert(source.front == 's');
    assert(source.position == PositionWithLine(2, 2));
    assert(source.currentLine == 2);

    source.seek(before);
    assert(source.front == 'e');
    assert(source.position == PositionWithLine(1, 1));
    assert(source.currentLine == 1);

    source.popFront();
    source.popFront();
    source.popFront();
    assert(source.position == PositionWithLine(4, 1));
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


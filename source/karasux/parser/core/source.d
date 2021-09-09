/**
Parser source module.
*/
module karasux.parser.core.source;

import std.array : Appender;

/**
Backtrackable array source.

Params:
    S = symbol type.
*/
struct ArraySource(S)
{
    /**
    copy constructor disabled.
    */
    @disable this(ref return scope ArraySource rhs);

    /**
    Initialize by source array.

    Params:
        source = source array.
    */
    this(S[] source)
    {
        this.source_ = source;
    }

    /**
    Returns:
        current symbol.
    */
    inout(S) front() inout
        in (!empty)
    {
        return source_[position_];
    } 

    /**
    Returns:
        true if source is empty.
    */
    bool empty() const
    {
        return source_.length <= position_;
    }

    /**
    Pop current symbol.
    */
    void popFront()
        in (!empty)
    {
        ++position_;
    }

    /**
    begin backtrackable point.
    */
    void begin()
    {
        savePoints_ ~= position_;
    }

    /**
    accept current backtrackable point.
    */
    void accept()
        in (savePoints_[].length > 0)
    {
        popSavePoint();
    }

    /**
    reject current backtrackable point and restore state.
    */
    void reject()
        in (savePoints_[].length > 0)
    {
        position_ = savePoints_[][$ - 1];
        popSavePoint();
    }

private:
    S[] source_;
    size_t position_;
    Appender!(size_t[]) savePoints_;

    void popSavePoint() pure @safe
        in (savePoints_[].length > 0)
    {
        savePoints_.shrinkTo(savePoints_[].length - 1);
    }
}

///
@nogc nothrow pure @safe unittest
{
    import karasux.parser.core.traits : isInputSource;

    scope source = ArraySource!(immutable(char))("test");
    static assert(isInputSource!(typeof(source)));

    assert(!source.empty);
    assert(source.front == 't');

    source.popFront();
    assert(!source.empty);
    assert(source.front == 'e');

    source.popFront();
    assert(!source.empty);
    assert(source.front == 's');

    source.popFront();
    assert(!source.empty);
    assert(source.front == 't');

    source.popFront();
    assert(source.empty);
}

///
pure @safe unittest
{
    import karasux.parser.core.traits : isBacktrackableSource;

    scope source = ArraySource!(immutable(char))("test");
    static assert(isBacktrackableSource!(typeof(source)));

    source.popFront();
    source.begin();
    assert(source.front == 'e');

    source.popFront();
    assert(source.front == 's');

    source.begin();
    source.popFront();
    assert(source.front == 't');

    source.reject();
    assert(source.front == 's');

    source.begin();
    source.popFront();
    assert(source.front == 't');
    source.accept();

    source.reject();
    assert(source.front == 'e');
}


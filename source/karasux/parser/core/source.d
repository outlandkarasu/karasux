/**
Parser source module.
*/
module karasux.parser.core.source;

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

private:
    S[] source_;
    size_t position_;
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

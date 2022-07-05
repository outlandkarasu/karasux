/**
Array source module.
*/
module karasux.parser.source.array_source;

/**
Array source.

Params:
    E = element type.
*/
struct ArraySource(E)
{
    /**
    Initialize from source array.

    Params:
        source = source array.
    */
    this(return scope const(E)[] source) @nogc nothrow pure @safe scope
    {
        this.array_ = source;
        this.position_ = 0;
    }

    @nogc nothrow pure @safe scope
    {
        @property E front() const
            in (position_ < array_.length)
        {
            return array_[position_];
        }

        void popFront()
            in (position_ < array_.length)
        {
            ++position_;
        }

        bool empty() const
        {
            return array_.length == position_;
        }

        @property size_t position() const
        {
            return position_;
        }

        void seek(size_t p)
            in (p < array_.length)
        {
            position_ = p;
        }
    }

    invariant
    {
        assert(position_ <= array_.length);
    }

private:
    const(E)[] array_;
    size_t position_;
}

///
@nogc nothrow pure @safe unittest
{
    import karasux.parser.source.traits : isSeekableSource;

    auto source = ArraySource!char("test");
    static assert(isSeekableSource!(typeof(source)));
    assert(source.front == 't');
    assert(source.position == 0);
    assert(!source.empty);

    source.popFront();
    assert(source.front == 'e');
    assert(source.position == 1);
    assert(!source.empty);

    source.seek(0);
    assert(source.front == 't');
    assert(source.position == 0);
    assert(!source.empty);

    source.popFront();
    assert(source.front == 'e');
    assert(source.position == 1);
    assert(!source.empty);

    source.popFront();
    assert(source.front == 's');
    assert(source.position == 2);
    assert(!source.empty);

    source.popFront();
    assert(source.front == 't');
    assert(source.position == 3);
    assert(!source.empty);

    source.popFront();
    assert(source.empty);
    assert(source.position == 4);
}

/**
Create array source.

Params:
    E = element type.
    source = source array
Returns:
    ArraySource
*/
ArraySource!E arraySource(E)(return scope const(E)[] source)
{
    return ArraySource!E(source);
}

///
@nogc nothrow pure @safe unittest
{
    auto source = arraySource("test");
    foreach (i, c; "test")
    {
        assert(source.front == c);
        assert(source.position == i);
        assert(!source.empty);
        source.popFront();
    }

    assert(source.position == 4);
    assert(source.empty);
}


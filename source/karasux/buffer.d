/**
Simple memory buffer module.
*/
module karasux.buffer;

import core.memory : pureRealloc, pureFree;

/**
Simple memory buffer.
*/
struct Buffer(T)
{
    static assert(__traits(isPOD, T));

    /*
    Can't copy.
    */
    @disable this(ref return scope Buffer rhs);

    ~this() @nogc nothrow pure @safe scope
    {
        free();
    }

    /*
    Resize buffer.

    Params:
        n = new buffer size.
    Returns:
        true if succeeded.
    */
    bool resize(size_t n) @nogc nothrow pure @trusted scope
    {
        if (n == 0)
        {
            pureFree(ptr);
            buffer_ = null;
            return true;
        }

        immutable oldLength = buffer_.length;
        auto newPtr = cast(T*) pureRealloc(ptr, n * T.sizeof);
        if (!newPtr)
        {
            return false;
        }

        for (size_t i = oldLength; i < n; ++i)
        {
            newPtr[i] = T.init;
        }
        buffer_ = newPtr[0 .. n];

        return true;
    }

    @nogc nothrow pure @safe
    {
        ref inout(T) opIndex(size_t i) inout return scope
        {
            return buffer_[i];
        }

        @property size_t length() const scope
        {
            return buffer_.length;
        }

        bool append()(auto scope ref const(T) value) scope
        {
            immutable nextIndex = length;
            if (!resize(length + 1))
            {
                return false;
            }

            this[nextIndex] = value;

            return true;
        }
    }

private:

    @property inout(T)* ptr() inout @nogc nothrow pure @safe return scope
    {
        return (buffer_.length > 0) ? &buffer_[0] : null;
    }

    void free() @nogc nothrow pure @trusted scope
    {
        pureFree(ptr);
        buffer_ = null;
    }

    T[] buffer_;
}

///
@nogc nothrow pure @safe unittest
{
    struct Data
    {
        int value = 100;
    }

    auto buffer = Buffer!Data();
    assert(buffer.length == 0);

    assert(buffer.resize(10));
    assert(buffer.length == 10);
    assert(buffer[0].value == 100);
    assert(buffer[9].value == 100);

    assert(buffer.append(Data(123)));
    assert(buffer.length == 11);
    assert(buffer[0].value == 100);
    assert(buffer[9].value == 100);
    assert(buffer[10].value == 123);
}

@nogc nothrow pure @safe unittest
{
    auto buffer = Buffer!int();
    assert(buffer.append(123));
    assert(buffer.resize(0));
    assert(buffer.length == 0);
}


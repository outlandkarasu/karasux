/**
Simple memory buffer module.
*/
module karasux.buffer;

import core.memory : pureRealloc, pureFree;

/**
Simple memory buffer.
*/
struct Buffer(T, alias Allocator)
{
    static assert(is(typeof((scope ref T[] a) nothrow pure @safe => Allocator!T.free(a))));
    static assert(is(typeof((scope ref T[] a, size_t n) nothrow pure @safe
    {
        bool result = Allocator!T.resize(a, n);
    })));

    /*
    Can't copy.
    */
    @disable this(ref return scope Buffer rhs);

    ~this() @nogc nothrow pure @safe scope
    {
        Allocator!T.free(buffer_);
    }

    /*
    Resize buffer.

    Params:
        n = new buffer size.
    Returns:
        true if succeeded.
    */
    bool resize(size_t n) nothrow pure @safe scope
    {
        return Allocator!T.resize(buffer_, n);
    }

    nothrow pure @safe
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

    T[] buffer_;
}

///
@nogc nothrow pure @safe unittest
{
    struct Data
    {
        int value = 100;
    }

    auto buffer = Buffer!(Data, CoreMemoryAllocator)();
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
    auto buffer = Buffer!(int, CoreMemoryAllocator)();
    assert(buffer.append(123));
    assert(buffer.resize(0));
    assert(buffer.length == 0);
}

/**
Allocator by core.memory.
*/
template CoreMemoryAllocator(T)
{
    static assert(__traits(isPOD, T));

    bool resize(scope ref T[] array, size_t n) @nogc nothrow pure @trusted
        out(; array.length == n)
    {
        // free if zero allocation.
        if (n == 0)
        {
            free(array);
            return true;
        }

        // resize array memory.
        immutable oldLength = array.length;
        auto ptr = (oldLength == 0) ? null : &array[0];
        auto newPtr = cast(T*) pureRealloc(ptr, T.sizeof * n);
        if (!newPtr)
        {
            return false;
        }

        // initialize new elements.
        if (oldLength < n)
        {
            newPtr[oldLength .. n] = T.init;
        }

        array = newPtr[0 .. n];
        return true;
    }

    void free(scope ref T[] array) @nogc nothrow pure @trusted
        out(; array.length == 0)
    {
        if (array.length > 0)
        {
            pureFree(&array[0]);
        }
        array = null;
    }
}

///
@nogc nothrow pure @safe unittest
{
    alias Allocator = CoreMemoryAllocator!int;

    int[] array;
    Allocator.resize(array, 4);
    scope(exit) Allocator.free(array);

    assert(array.length == 4);

    foreach (i, ref e; array)
    {
        assert(e == int.init);
        e = cast(int) i;
    }

    Allocator.resize(array, 8);
    assert(array.length == 8);

    foreach (i, e; array[0 .. 4])
    {
        assert(e == i);
    }

    foreach (e; array[4 .. $])
    {
        assert(e == int.init);
    }

    Allocator.resize(array, 2);
    assert(array.length == 2);
    assert(array[0] == 0);
    assert(array[1] == 1);

    Allocator.free(array);
    assert(array.length == 0);
}

/**
Allocator by dynamic array.
*/
template DynamicArrayAllocator(T)
{
    bool resize()(scope ref T[] array, size_t n)
        out(; array.length == n)
    {
        array.length = n;
        return true;
    }

    void free()(scope ref T[] array)
        out(; array.length == 0)
    {
        array = null;
    }
}

///
nothrow pure @safe unittest
{
    alias Allocator = DynamicArrayAllocator!int;

    int[] array;
    Allocator.resize(array, 4);
    scope(exit) Allocator.free(array);

    assert(array.length == 4);

    foreach (i, ref e; array)
    {
        assert(e == int.init);
        e = cast(int) i;
    }

    Allocator.resize(array, 8);
    assert(array.length == 8);

    foreach (i, e; array[0 .. 4])
    {
        assert(e == i);
    }

    foreach (e; array[4 .. $])
    {
        assert(e == int.init);
    }

    Allocator.resize(array, 2);
    assert(array.length == 2);
    assert(array[0] == 0);
    assert(array[1] == 1);

    Allocator.free(array);
    assert(array.length == 0);
}

/**
Core memory buffer.
*/
alias CoreMemoryBuffer(T) = Buffer!(T, CoreMemoryAllocator);

/**
Dynamic array buffer.
*/
alias DynamicArrayBuffer(T) = Buffer!(T, DynamicArrayAllocator);


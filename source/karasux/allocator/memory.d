/**
Allocated memory module.
*/
module karasux.allocator.memory;

/**
Allocated memory.
*/
struct Memory(A)
{
    private void[] payload_;

    void[] opCast(T: void[])() @nogc nothrow pure @safe
    {
        return payload_;
    }

    const(void)[] opCast(T: const(void)[])() const @nogc nothrow pure @safe
    {
        return payload_;
    }
}

///
@nogc nothrow pure @safe unittest
{
    struct A;

    auto memory = Memory!A([]);
    auto m = cast(void[]) memory;
    static assert(is(typeof(m) == void[]));

    auto cm = cast(const(void)[]) memory;
    static assert(is(typeof(cm) == const(void)[]));
}


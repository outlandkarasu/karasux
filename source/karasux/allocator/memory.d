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

    inout(void)[] opSlice() inout @nogc nothrow pure @safe
    {
        return payload_;
    }

    inout(void)[] opSlice(size_t start, size_t end) inout @nogc nothrow pure @safe
        in (start <= end)
    {
        return payload_[start .. end];
    }

    void opSliceAssign(scope const(void)[] rhs, size_t start, size_t end) @nogc nothrow pure @trusted
        in (start <= end)
        in (end - start == rhs.length)
    {
        payload_[start .. end] = rhs[];
    }

    @property size_t opDollar(size_t dim : 0)() const @nogc nothrow pure @safe
    {
        return payload_.length;
    }

    @property size_t length() const @nogc nothrow pure @safe
    {
        return payload_.length;
    }
}

///
nothrow pure @safe unittest
{
    struct A;

    auto memory = Memory!A([1, 2, 3, 4]);
    static assert(is(typeof(memory[]) == void[]));

    assert(memory.length == int.sizeof * 4);
    assert(memory[int.sizeof .. int.sizeof * 2] == [2]);

    memory[int.sizeof .. int.sizeof * 2] = [100];
    assert(memory[int.sizeof .. int.sizeof * 2] == [100]);

    const cm = memory;
    static assert(is(typeof(cm[]) == const(void)[]));
}


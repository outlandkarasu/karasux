/**
Allocator types module.
*/
module karasux.allocator;

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

/**
Allocator traits.
*/
enum isAllocator(A) = is(typeof((ref A a) {
    auto allocator = a;
    Memory!A data = allocator.allocate(cast(size_t) 100);
    allocator.free(data);
}));

///
@nogc nothrow pure @safe unittest
{
    struct Allocator
    {
        Memory!Allocator allocate(size_t n) @nogc nothrow pure @safe scope
        {
            return Memory!Allocator.init;
        }

        void free(ref Memory!Allocator memory) @nogc nothrow pure @safe scope
        {
            memory = Memory!Allocator.init;
        }
    }

    static assert(isAllocator!Allocator);

    struct MissingFree
    {
        Memory!MissingFree allocate(size_t n) @nogc nothrow pure @safe scope
        {
            return Memory!MissingFree.init;
        }
    }
    static assert(!isAllocator!(MissingFree));

    struct MissingAllocate
    {
        void free(ref Memory!MissingAllocate memory) @nogc nothrow pure @safe scope
        {
            memory = Memory!MissingAllocate.init;
        }
    }
    static assert(!isAllocator!(MissingAllocate));
}


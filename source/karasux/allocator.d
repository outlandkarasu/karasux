/**
Allocator types module.
*/
module karasux.allocator;

/**
Allocator traits.
*/
enum isAllocator(A) = is(typeof((ref A a) {
    auto allocator = a;
    void[] data = allocator.allocate(cast(size_t) 100);
    allocator.free(data);
}));

///
@nogc nothrow pure @safe unittest
{
    struct Allocator
    {
        void[] allocate(size_t n) @nogc nothrow pure @safe scope
        {
            return (void[]).init;
        }

        void free(ref void[] memory) @nogc nothrow pure @safe scope
        {
            memory = (void[]).init;
        }
    }

    static assert(isAllocator!Allocator);

    struct WithoutFree
    {
        void[] allocate(size_t n) @nogc nothrow pure @safe scope
        {
            return (void[]).init;
        }
    }
    static assert(!isAllocator!(WithoutFree));

    struct WithoutAllocate
    {
        void free(ref void[] memory) @nogc nothrow pure @safe scope
        {
            memory = (void[]).init;
        }
    }
    static assert(!isAllocator!(WithoutAllocate));
}


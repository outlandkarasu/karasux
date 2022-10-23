/**
Allocator traits module.
*/
module karasux.allocator.traits;

import karasux.allocator.memory : Memory;

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


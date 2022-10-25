/**
Allocator traits module.
*/
module karasux.allocator.traits;

import std.typecons : Nullable;
import karasux.allocator.memory : Memory;

/**
Allocator traits.
*/
enum isAllocator(A) = is(typeof((ref A a) {
    auto allocator = a;
    auto result = allocator.allocate(cast(size_t) 100);
    static assert(is(typeof(result) == Nullable!(Memory!A)));

    allocator.free(result.get);
}));

///
@nogc nothrow pure @safe unittest
{
    import std.typecons : nullable;

    struct Allocator
    {
        Nullable!(Memory!Allocator) allocate(size_t n) @nogc nothrow pure @safe scope
        {
            return Memory!Allocator.init.nullable;
        }

        void free(ref Memory!Allocator memory) @nogc nothrow pure @safe scope
        {
            memory = Memory!Allocator.init;
        }
    }

    static assert(isAllocator!Allocator);

    struct MissingFree
    {
        Nullable!(Memory!MissingFree) allocate(size_t n) @nogc nothrow pure @safe scope
        {
            return Memory!MissingFree.init.nullable;
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

/**
Reallocateable allocator traits.
*/
enum isReallocateableAllocator(A) = isAllocator!A && is(typeof((ref A a) {
    auto allocator = a;
    auto memory = allocator.allocate(cast(size_t) 100).get;
    auto result = a.reallocate(memory, cast(size_t) 1000);
    static assert(is(typeof(result) == bool));
}));

///
@nogc nothrow pure @safe unittest
{
    import std.typecons : nullable;

    struct Allocator
    {
        Nullable!(Memory!Allocator) allocate(size_t n) @nogc nothrow pure @safe scope
        {
            return Memory!Allocator.init.nullable;
        }

        void free(ref Memory!Allocator memory) @nogc nothrow pure @safe scope
        {
            memory = Memory!Allocator.init;
        }

        bool reallocate(ref Memory!Allocator memory, size_t n) @nogc nothrow pure @safe scope
        {
            return false;
        }
    }

    static assert(isReallocateableAllocator!Allocator);

    struct MissingReallocate
    {
        Nullable!(Memory!Allocator) allocate(size_t n) @nogc nothrow pure @safe scope
        {
            return Memory!Allocator.init.nullable;
        }

        void free(ref Memory!Allocator memory) @nogc nothrow pure @safe scope
        {
            memory = Memory!Allocator.init;
        }
    }
    static assert(!isAllocator!(MissingReallocate));
    static assert(!isReallocateableAllocator!(MissingReallocate));
}


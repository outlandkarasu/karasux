/**
GC allocator.
*/
module karasux.allocator.gc_allocator;

import std.typecons : Nullable, nullable;

static import karasux.allocator.memory;
import karasux.allocator.traits : isReallocateableAllocator, isAllocator;

/**
GC allocator.
*/
struct GCAllocator
{
    static assert(isAllocator!GCAllocator);
    alias Memory = karasux.allocator.memory.Memory!(GCAllocator);

    Nullable!Memory allocate(size_t n) const nothrow pure @safe scope
    {
        return Memory(new void[n]).nullable;
    }

    bool reallocate(ref Memory memory, size_t n) const nothrow pure @safe scope
    {
        auto data = memory[];
        data.length = n;
        memory = Memory(data);
        return true;
    }

    void free(ref Memory memory) @nogc nothrow pure @safe scope
    {
        memory = Memory.init;
    }
}

///
nothrow pure @safe unittest
{
    auto allocator = GCAllocator.init;
    auto result = allocator.allocate(100);
    auto m = result.get;
    assert(m.length == 100);

    m[0 .. 4] = cast(ubyte[]) [1, 2, 3, 4];

    assert(allocator.reallocate(m, 101));
    assert(m.length == 101);
    assert(m[0 .. 4] == cast(ubyte[]) [1, 2, 3, 4]);

    assert(allocator.reallocate(m, 3));
    assert(m.length == 3);
    assert(m[0 .. 3] == cast(ubyte[]) [1, 2, 3]);

    allocator.free(m);
    assert(m.length == 0);
}


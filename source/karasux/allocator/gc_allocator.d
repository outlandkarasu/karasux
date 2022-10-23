/**
GC allocator.
*/
module karasux.allocator.gc_allocator;

static import karasux.allocator.memory;
import karasux.allocator.traits : isReallocateableAllocator;

/**
GC allocator.
*/
struct GCAllocator
{
    static assert(isReallocateableAllocator!GCAllocator);
    alias Memory = karasux.allocator.memory.Memory!(GCAllocator);

    Memory allocate(size_t n) const nothrow pure @safe scope
    {
        return Memory(new void[n]);
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
    auto m = allocator.allocate(100);
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


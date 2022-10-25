/**
core memory allocator.
*/
module karasux.allocator.core_memory_allocator;

import core.memory : pureMalloc, pureRealloc, pureFree;
import std.typecons : Nullable, nullable;

static import karasux.allocator.memory;
import karasux.allocator.traits : isReallocateableAllocator;

/**
core.memory allocator.
*/
struct CoreMemoryAllocator
{
    static assert(isReallocateableAllocator!CoreMemoryAllocator);
    alias Memory = karasux.allocator.memory.Memory!(CoreMemoryAllocator);

    Nullable!Memory allocate(size_t n) const nothrow pure @system scope
    {
        return toMemory(pureMalloc(n), n);
    }

    bool reallocate(ref Memory memory, size_t n) const nothrow pure @system scope
    {
        auto before = getPointer(memory);
        auto result = toMemory(pureRealloc(before, n), n);
        if (result.isNull)
        {
            return false;
        }

        memory = result.get;
        return true;
    }

    void free(ref Memory memory) @nogc nothrow pure @system scope
    {
        pureFree(getPointer(memory));
        memory = Memory.init;
    }

private:

    static Nullable!Memory toMemory(return scope void* p, size_t n) @nogc nothrow pure @system
        in (p)
    {
        return p ? Memory(p[0 .. n]).nullable : typeof(return).init;
    }

    static void* getPointer(return scope Memory memory) @nogc nothrow pure @safe
    {
        auto before = memory[];
        return before.length > 0 ? &before[0] : null;
    }
}

///
nothrow pure @system unittest
{
    auto allocator = CoreMemoryAllocator.init;
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


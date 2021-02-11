/**
Nullable extension.
*/
module karasux.nullable;

import std.typecons : Nullable;

/**
get nullable contents.

Params:
    T = content type.
    x = nullable value.
Returns:
   content reference. 
*/
ref inout(T) front(T)(scope return ref inout(Nullable!T) x) pure nothrow @safe
in (!x.isNull)
{
    return x.get;
}

///
@nogc nothrow pure @safe unittest
{
    import std.typecons : nullable;

    auto x = 100.nullable;
    assert(x.front == 100);
    
    x.front = 1234;
    assert(x.front == 1234);

    immutable v = 9876;
    auto nv = v.nullable;
    assert(nv.front == 9876);
}


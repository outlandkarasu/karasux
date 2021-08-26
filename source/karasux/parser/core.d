/**
Core parsers module.s
*/
module karasux.parser.core;

import std.range :
    empty,
    popFront,
    isInputRange;
import std.traits : Unqual;

/**
Always true parser.

Params:
    r = input range.
Returns:
    always true.
*/
bool alwaysTrue(R)(auto scope ref R r)
    if (isInputRange!(Unqual!R))
{
    return true;
}

///
@nogc nothrow pure @safe unittest
{
    assert("".alwaysTrue);
    assert("aaa".alwaysTrue);

    auto source = "aaa";
    assert(source.alwaysTrue);
    assert(source == "aaa");
}

/**
Always false parser.

Params:
    r = input range.
Returns:
    always false.
*/
bool alwaysFalse(R)(auto scope ref R r)
    if (isInputRange!(Unqual!R))
{
    return false;
}

///
@nogc nothrow pure @safe unittest
{
    assert(!"".alwaysFalse);
    assert(!"aaa".alwaysFalse);

    auto source = "aaa";
    assert(!source.alwaysFalse);
    assert(source == "aaa");
}

/**
End of source parser.

Params:
    r = input range.
Returns:
    true if range is empty.
*/
bool endOfSource(R)(auto scope ref R r)
    if (isInputRange!(Unqual!R))
{
    return r.empty;
}

///
@nogc nothrow pure @safe unittest
{
    assert("".endOfSource);
    assert(!"aaa".endOfSource);

    auto source = "aaa";
    assert(!source.endOfSource);
    assert(source == "aaa");
}

/**
any character parser.

Params:
    r = input range.
Returns:
    true if range is not empty.
*/
bool any(R)(auto scope ref R r)
    if (isInputRange!(Unqual!R))
{
    if (r.empty)
    {
        return false;
    }

    r.popFront();
    return true;
}

///
@nogc nothrow pure @safe unittest
{
    assert(!"".any);
    assert("a".any);

    auto source = "abc";
    assert(source.any);
    assert(source == "bc");
}


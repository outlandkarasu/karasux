/**
Core parsers module.s
*/
module karasux.parser.core;

import std.range : isInputRange;
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


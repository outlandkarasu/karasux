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
bool parseAlwaysTrue(R)(auto scope ref R r)
    if (isInputRange!(Unqual!R))
{
    return true;
}

///
@nogc nothrow pure @safe unittest
{
    assert("".parseAlwaysTrue);
    assert("aaa".parseAlwaysTrue);

    auto source = "aaa";
    assert(source.parseAlwaysTrue);
    assert(source == "aaa");
}


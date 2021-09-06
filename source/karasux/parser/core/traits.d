/**
Parser traits.
*/
module karasux.parser.core.traits;

import std.range :
    isForwardRange,
    isInputRange;

import std.traits : Unqual;

/**
Input source traits.
*/
enum isInputSource(R) = isInputRange!(Unqual!R);

///
@nogc nothrow pure @safe unittest
{
    static assert(isInputSource!string);
    static assert(isInputSource!(ubyte[]));
}


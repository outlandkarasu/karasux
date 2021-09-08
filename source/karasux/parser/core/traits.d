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
    static assert(!isInputSource!void);
    static assert(!isInputSource!char);
}

/**
Forward range source traits.
*/
enum isForwardRangeSource(R) = isInputSource!R && isForwardRange!(Unqual!R);

///
@nogc nothrow pure @safe unittest
{
    static assert(isForwardRangeSource!string);
    static assert(isForwardRangeSource!(ubyte[]));
    static assert(!isForwardRangeSource!void);
    static assert(!isForwardRangeSource!char);
}

/**
Backtrackable source traits.
*/
enum isBacktrackableSource(R) = isInputSource!R
    && is(typeof((R r) => r.begin))
    && is(typeof((R r) => r.accept))
    && is(typeof((R r) => r.reject));


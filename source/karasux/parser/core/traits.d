/**
Parser traits.
*/
module karasux.parser.core.traits;

import std.range :
    isForwardRange,
    isInputRange;

import std.traits : Unqual, ReturnType;

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
Parser traits.
*/
enum isParser(alias P, S) = is(typeof((scope ref S s) => P(s))) && is(ReturnType!((S s) => P(s)) == bool);

///
@nogc nothrow pure @safe unittest
{
    bool f(S)(scope auto ref S s)
        if (isInputSource!S)
    {
        return true;
    }

    static assert(isParser!(f, string));
    static assert(!isParser!(f, int));

    void notParser(S)(scope auto ref S s)
    {
    }
    static assert(!isParser!(notParser, string));
}


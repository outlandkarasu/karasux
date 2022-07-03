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
Forward source traits.
*/
enum isForwardSource(R) = isInputSource!R && isForwardRange!(Unqual!R);

///
@nogc nothrow pure @safe unittest
{
    static assert(isForwardSource!string);
    static assert(isForwardSource!(ubyte[]));
    static assert(!isForwardSource!void);
    static assert(!isForwardSource!char);
}

/**
Parser traits.
*/
enum isParser(alias P, S) = isInputSource!S && is(typeof((scope ref S s) => P(s))) && is(ReturnType!((S s) => P(s)) == bool);

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


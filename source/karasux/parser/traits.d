/**
Parser traits.
*/
module karasux.parser.traits;

import std.traits : ReturnType;

import karasux.parser.source : isInputSource;

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


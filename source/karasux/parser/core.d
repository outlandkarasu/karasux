/**
Core parsers module.s
*/
module karasux.parser.core;

import std.range :
    ElementType,
    empty,
    front,
    popFront,
    isForwardRange,
    isInputRange,
    save;
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

/**
Single symbol parser.

Params:
    r = source range.
    c = an expected symbol.
Returns:
    true if r front is c.
*/
bool symbol(R, C)(auto scope ref R r, C c)
    if (isInputRange!(Unqual!R))
{
    if (r.empty || r.front != c)
    {
        return false;
    }

    r.popFront();
    return true;
}

///
pure @safe unittest
{
    assert("a".symbol('a'));
    assert(!"b".symbol('a'));
    assert(!"".symbol('a'));

    auto source = "abc";
    assert(source.symbol('a'));
    assert(source == "bc");
    assert(!source.symbol('a'));
    assert(source == "bc");
}

/**
Symbols parser.

Params:
    r = source range.
    s = expected symbols.
Returns:
    true if r front is c.
*/
bool symbols(R, S)(auto scope ref R r, S s)
    if (isForwardRange!(Unqual!R) && isInputRange!(Unqual!S))
{
    auto before = r.save;
    auto expected = s;
    while(!expected.empty)
    {
        if (r.empty || r.front != expected.front)
        {
            r = before;
            return false;
        }

        r.popFront();
        expected.popFront();
    }

    return true;
}

///
pure unittest
{
    auto source = "a";
    assert(source.symbols("a"));
    assert(source.length == 0);

    source = "abc";
    assert(source.symbols("ab"));
    assert(source == "c");

    source = "abc";
    assert(!source.symbols("abd"));
    assert(source == "abc");

    source = "abc";
    assert(!source.symbols("abcd"));
    assert(source == "abc");
}


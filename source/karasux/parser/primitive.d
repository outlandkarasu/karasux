/**
Primitive parsers module.
*/
module karasux.parser.primitive;

import std.range :
    ElementType,
    empty,
    front,
    isInputRange,
    popFront,
    save;

import karasux.parser.source.traits :
    isInputSource,
    isSeekableSource;

/**
Always true parser.

Params:
    S = source type.
    source = target source.
Returns:
    always true.
*/
bool alwaysTrue(S)(auto scope ref S source)
    if (isInputSource!S)
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
    S = source type.
    source = target source.
Returns:
    always false.
*/
bool alwaysFalse(S)(auto scope ref S source)
    if (isInputSource!S)
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
    S = source type.
    source = target source.
Returns:
    true if range is empty.
*/
bool endOfSource(S)(auto scope ref S source)
    if (isInputSource!S)
{
    return source.empty;
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
    S = source type.
    source = target source.
Returns:
    true if range is not empty.
*/
bool any(S)(auto scope ref S source)
    if (isInputSource!S)
{
    if (source.empty)
    {
        return false;
    }

    source.popFront();
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
    S = source type.
    Sym = symbol type.
    source = target source.
    s = an expected symbol.
Returns:
    true if source front is s.
*/
bool symbol(S, Sym)(auto scope ref S source, Sym s)
    if (isInputSource!S)
{
    if (source.empty || source.front != s)
    {
        return false;
    }

    source.popFront();
    return true;
}

///
@nogc nothrow pure @safe unittest
{
    import karasux.parser.source : arraySource;
    assert(arraySource("a").symbol('a'));
    assert(!arraySource("b").symbol('a'));
    assert(!arraySource("").symbol('a'));

    auto source = arraySource("abc");
    assert(source.symbol('a'));
    assert(source.position == 1);
    assert(!source.symbol('a'));
    assert(source.position == 1);
}

/**
Symbols parser.

Params:
    S = source type.
    Syms = expected symbols type.
    source = target source.
    s = expected symbols.
Returns:
    true if source starts s.
*/
bool symbols(S, Syms)(auto scope ref S source, Syms s)
    if (isSeekableSource!S && isInputRange!Syms)
{
    auto before = source.position;
    for (auto expected = s; !expected.empty; expected.popFront(), source.popFront())
    {
        if (source.empty || source.front != expected.front)
        {
            source.seek(before);
            return false;
        }
    }

    return true;
}

///
@nogc nothrow pure @safe unittest
{
    import karasux.parser.source : arraySource;

    auto source = arraySource("a");
    assert(source.symbols("a"d));
    assert(source.position == 1);
    assert(source.empty);

    source = arraySource("abc");
    assert(source.symbols("ab"d));
    assert(source.position == 2);
    assert(source.front == 'c');

    source = arraySource("abc");
    assert(!source.symbols("abd"d));
    assert(source.position == 0);
    assert(source.front == 'a');

    source = arraySource("abc");
    assert(!source.symbols("abcd"d));
    assert(source.position == 0);
    assert(source.front == 'a');
}

/**
Symbol set parser.

Params:
    S = source type.
    Syms = symbol source type.
    source = target source.
    s = expected symbol set.
Returns:
    true if r front is in s.
*/
bool symbolSet(S, Syms)(auto scope ref S source, Syms s)
    if (isInputSource!S && isInputRange!Syms)
{
    if (source.empty)
    {
        return false;
    }

    for(auto expected = s; !expected.empty; expected.popFront())
    {
        if (source.front == expected.front)
        {
            source.popFront();
            return true;
        }
    }

    return false;
}

///
@nogc nothrow pure @safe unittest
{
    import karasux.parser.source : arraySource;

    auto source = arraySource("abc");
    assert(source.symbolSet("abc"d));
    assert(source.position == 1);

    source = arraySource("abc");
    assert(!source.symbolSet("123"d));
    assert(source.position == 0);

    source = arraySource("");
    assert(!source.symbolSet(""d));
    assert(source.position == 0);

    source = arraySource("abc");
    assert(!source.symbolSet(""d));
    assert(source.position == 0);
}

/**
Symbol range parser.

Params:
    S = source type.
    Sym = symbol type.
    source = target source.
    s = symbol range start.
    e = symbol range end.
Returns:
    true if r front is between s and e.
*/
bool symbolRange(S, Sym)(auto scope ref S source, Sym s, Sym e)
    if (isInputSource!S)
{
    if (source.empty || source.front < s || e < source.front)
    {
        return false;
    }

    source.popFront();
    return true;
}

///
@nogc nothrow pure @safe unittest
{
    import karasux.parser.source : arraySource;

    auto source = arraySource("abc");
    assert(source.symbolRange('a', 'z'));
    assert(source.position == 1);
    assert(source.symbolRange('a', 'b'));
    assert(source.position == 2);

    source = arraySource("ABC");
    assert(!source.symbolRange('a', 'z'));
    assert(source.position == 0);
    assert(!source.symbolRange('0', '9'));
    assert(source.position == 0);

    source = arraySource("");
    assert(!source.symbolRange('a', 'z'));
    assert(source.position == 0);
}


/**
Composite parsers.
*/
module karasux.parser.composite;

import std.meta : allSatisfy, ApplyRight;

import karasux.parser.source :
    isInputSource,
    isLineCountedSource,
    isSeekableSource;
import karasux.parser.traits : isParser;

/**
Optional parser.

Params:
    P = inner parser
    S = source type

*/
bool optional(alias P, S)(auto scope ref S source)
    if (isParser!(P, S))
{
    P(source);
    return true;
}

///
pure @safe unittest
{
    import karasux.parser.primitive : symbol;

    auto source = "test";
    assert(source.optional!((ref s) => s.symbol('t')));
    assert(source == "est");
    assert(source.optional!((ref s) => s.symbol('t')));
    assert(source == "est");
}

/**
test parser.

Params:
    P = inner parser
    S = source type
    source = target source
Returns:
    true if matched. source position seeks to begin.
*/
bool testAnd(alias P, S)(auto scope ref S source)
    if (isSeekableSource!S && isParser!(P, S))
{
    auto current = source.position;
    scope(exit)
    {
        source.seek(current);
    }

    return P(source);
}

///
@nogc nothrow pure @safe unittest
{
    import karasux.parser.primitive : symbol;
    import karasux.parser.source : arraySource;

    auto source = arraySource("test");
    assert(source.testAnd!((ref s) => s.symbol('t')));
    assert(source.position == 0);

    assert(!source.testAnd!((ref s) => s.symbol('e')));
    assert(source.position == 0);
}

/**
not parser.

Params:
    P = inner parser
    S = source type
    source = target source
Returns:
    false if matched. source position seeks to begin.
*/
bool testNot(alias P, S)(auto scope ref S source)
    if (isSeekableSource!S && isParser!(P, S))
{
    auto current = source.position;
    scope(exit)
    {
        source.seek(current);
    }

    return !P(source);
}

///
@nogc nothrow pure @safe unittest
{
    import karasux.parser.primitive : symbol;
    import karasux.parser.source : arraySource;

    auto source = arraySource("test");
    assert(!source.testNot!((ref s) => s.symbol('t')));
    assert(source.position == 0);

    assert(source.testNot!((ref s) => s.symbol('e')));
    assert(source.position == 0);
}

/**
Parsers sequence

Params:
    P = parsers
*/
template sequence(P...)
{
    bool sequence(S)(auto scope ref S source)
        if (isSeekableSource!S && allSatisfy!(ApplyRight!(isParser, S), P))
    {
        auto before = source.position;
        foreach (p; P)
        {
            if (!p(source))
            {
                source.seek(before);
                return false;
            }
        }
        return true;
    }
}

///
@nogc nothrow pure @safe unittest
{
    import karasux.parser.primitive : symbol;
    import karasux.parser.source : arraySource;

    auto source = arraySource("test");
    assert(source.sequence!(
        (scope ref s) => s.symbol('t'),
        (scope ref s) => s.symbol('e')));
    assert(source.position == 2);

    assert(!source.sequence!(
        (scope ref s) => s.symbol('s'),
        (scope ref s) => s.symbol('u')));
    assert(source.position == 2);
}

/**
Parsers choice

Params:
    P = parsers
*/
template choice(P...)
{
    bool choice(S)(auto scope ref S source)
        if (isInputSource!S && allSatisfy!(ApplyRight!(isParser, S), P))
    {
        foreach (p; P)
        {
            if (p(source))
            {
                return true;
            }
        }
        return false;
    }
}

///
@nogc nothrow pure @safe unittest
{
    import karasux.parser.primitive : symbol;
    import karasux.parser.source : arraySource;

    auto source = "test"d;
    assert(source.choice!(
        (scope ref s) => s.symbol('t'),
        (scope ref s) => s.symbol('e')));
    assert(source == "est");

    assert(source.choice!(
        (scope ref s) => s.symbol('t'),
        (scope ref s) => s.symbol('e')));
    assert(source == "st");

    assert(!source.choice!(
        (scope ref s) => s.symbol('t'),
        (scope ref s) => s.symbol('e')));
    assert(source == "st");
}

/**
Add line count parser.

Params:
    P = inner parser.
    source = target source
Returns:
    true if matched and add line count.
*/
bool newLine(alias P, S)(auto scope ref S source)
    if (isLineCountedSource!S && isParser!(P, S))
{
    if (P(source))
    {
        source.addLine();
        return true;
    }

    return false;
}

///
@nogc nothrow pure @safe unittest
{
    import karasux.parser.primitive : symbol;
    import karasux.parser.source : arraySource, lineCounted;

    auto source = lineCounted(arraySource("test"));
    assert(source.newLine!((ref s) => s.symbol('t')));
    assert(source.position.position == 1);
    assert(source.position.line == 1);
    assert(source.front == 'e');

    assert(!source.newLine!((ref s) => s.symbol('t')));
    assert(source.position.position == 1);
    assert(source.position.line == 1);
    assert(source.front == 'e');
}


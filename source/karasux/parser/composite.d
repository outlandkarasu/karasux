/**
Composite parsers.
*/
module karasux.parser.composite;

import karasux.parser.source :
    isInputSource,
    isSeekableSource;
import karasux.parser.traits : isParser;

/**
Optional parser.

Params:
    P = inner parser
    S = source type

*/
bool optional(alias P, S)(auto scope ref S source)
    if (isParser!(P, S) && isInputSource!S)
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
    if (isParser!(P, S) && isSeekableSource!S)
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
    if (isParser!(P, S) && isSeekableSource!S)
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


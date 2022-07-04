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

    bool f(scope ref string source)
    {
        return source.symbol('t');
    }

    auto source = "test";
    assert(source.optional!(f));
    assert(source == "est");
    assert(source.optional!(f));
    assert(source == "est");
}

/**
Semantic event type.
*/
enum SemanticEventType
{
    begin,
    accept,
    reject = -1,
}

/**
Semantic action trait.
*/
enum isSemanticAction(alias A, S) = isInputSource!S && is(typeof((const(S) s) { A(s, SemanticEventType.init); }));

///
@nogc nothrow pure @safe unittest
{
    void f(string s, SemanticEventType event) { }
    static assert(isSemanticAction!(f, string));
}

/**
Parse with semantic action.

Params:
    S = source type
    P = inner parser
    A = action type
    source = parsing source
Returns:
    parsing result
*/
bool action(alias P, alias A, S)(auto scope ref S source)
    if (isParser!(P, S) && isSemanticAction!(A, S))
{
    A(source, SemanticEventType.begin);
    if (P(source))
    {
        A(source, SemanticEventType.accept);
        return true;
    }
    else
    {
        A(source, SemanticEventType.reject);
        return false;
    }
}

///
@nogc nothrow pure @safe unittest
{
    import karasux.parser.primitive : any;

    auto lastEvent = SemanticEventType.reject;
    void f(string s, SemanticEventType event)
    {
        lastEvent = event;
    }

    auto source = "test";
    assert(source.action!(any, f));
    assert(source == "est");
    assert(lastEvent == SemanticEventType.accept);

    source = "";
    assert(!source.action!(any, f));
    assert(source == "");
    assert(lastEvent == SemanticEventType.reject);
}


/**
Composite parsers.
*/
module karasux.core.composite;

import karasux.parser.core.traits :
    isInputSource,
    isForwardSource,
    isParser;

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
enum isSemanticAction(alias A, S) = isInputSource!S && is(typeof((auto scope ref const(S) s) => A(s, SemanticEventType.init)));

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
bool action(S, alias P, alias A)(auto scope ref S source)
    if (isParser!(P, S) && isSemanticAction!(A, S))
{
    return false;
}

/+
///
@nogc nothrow pure @safe unittest
{
    import karasux.parser.core.primitive : any;
    import karasux.parser.core.traits : isParser;

    static assert(isParser!(any, string));
    auto lastEvent = SemanticEventType.reject;
    void f(SemanticEventType event)
    {
        lastEvent = event;
    }

    auto source = "test";
    assert(source.action!(any, f));
    assert(lastEvent == SemanticEventType.accept);
}
+/

/**
Composite parsers.
*/
module karasux.core.composite;

import karasux.parser.core.traits :
    isInputSource,
    isForwardRangeSource;

/**
Event type.
*/
enum ParsingEventType
{
    begin,
    accept,
    reject = -1,
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
bool action(S, alias P, alias A)(auto scope ref S source)
    if (isInputSource!S)
{
    return false;
}


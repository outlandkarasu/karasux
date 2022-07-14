/**
CTFE module.
*/
module karasux.ctfe;

import std.traits : isCallable;

/**
unittest for CTFE function.

Params:
    F = target function
*/
void staticUnittest(alias F)() @nogc nothrow pure @safe
{
    static assert(isCallable!F);
    static assert((() {
        F();
        return true;
    })());
}

///
@nogc nothrow pure @safe unittest
{
    staticUnittest!({ assert(true); });

    static assert(is(typeof({ staticUnittest!({ assert(true); }); })));
    static assert(!is(typeof({ staticUnittest!({ assert(false); }); })));
}


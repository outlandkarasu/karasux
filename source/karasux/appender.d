/**
Appender utilities.
*/
module karasux.appender;

import std.array : Appender;

/**
pop a last element from appender.

Params:
    appender = target appender
*/
void popFront(T)(auto scope ref Appender!(T[]) appender)
    in (appender[].length > 0)
{
    appender.shrinkTo(appender[].length - 1);
}

///
pure @safe unittest
{
    import std.array : appender;
    auto app = Appender!(char[])();
    app ~= "test";
    immutable capacity = app.capacity;

    app.popFront();

    // removed a last element
    assert(app[] == "tes");

    // capacity has not changed.
    assert(app.capacity == capacity);
}


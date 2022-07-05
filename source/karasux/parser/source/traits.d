/**
Parser traits.
*/
module karasux.parser.source.traits;

import std.range : isInputRange;

/**
Input source traits.
*/
enum isInputSource(R) = isInputRange!R;

///
@nogc nothrow pure @safe unittest
{
    static assert(isInputSource!string);
    static assert(isInputSource!(ubyte[]));
    static assert(!isInputSource!void);
    static assert(!isInputSource!char);
}

/**
Seekable source traits.
*/
enum isSeekableSource(R) = isInputSource!R
    && is(typeof((auto scope ref R) @nogc nothrow pure @safe => r.position))
    && is(typeof((auto scope ref R) { auto p = r.position; r.seek(p); }));

/**
Line counted source traits.
*/
enum isLineCountedSource(R) = isSeekableSource!R
    && is(typeof((auto scope ref R) => r.currentLine) == size_t)
    && is(typeof((auto scope ref R) => r.addLine()));


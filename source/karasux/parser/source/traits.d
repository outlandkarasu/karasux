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
    && is(typeof((scope ref R r) @nogc nothrow pure @safe => r.position))
    && is(typeof((scope ref R r) { auto p = r.position; r.seek(p); }));

/**
Line counted source traits.
*/
enum isLineCountedSource(R) = isInputSource!R
    && is(typeof((scope ref R r) => r.currentLine))
    && is(typeof((scope ref R r) => r.addLine()));


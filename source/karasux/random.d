/**
Random generator.
*/
module karasux.random;

import std.math : log, cos, PI, sqrt;
import std.random : uniform;
import std.traits : isFloatingPoint;

/**
Generate Gaussian distribution random number.

Params:
    T = number type.
    UniformRandomNumberGenerator = random generator.
    urng = random generator value.
Returns;
    random value.
*/
T gaussianDistributionRandom(T, UniformRandomNumberGenerator)(ref UniformRandomNumberGenerator urng)
    if (isFloatingPoint!T)
{
    immutable x = uniform!("()", T, T)(cast(T) 0.0, cast(T) 1.0, urng);
    immutable y = uniform!("()", T, T)(cast(T) 0.0, cast(T) 1.0, urng);
    return sqrt((cast(T) -2.0) * log(x)) * cos(PI * (cast(T) 2.0) * y);
}

///
@safe unittest
{
    import std.math : isClose;
    import std.random : isUniformRNG;

    struct Rng 
    {
        @property real front() const @nogc nothrow pure @safe scope { return 0.5; }
        @property bool empty() const @nogc nothrow pure @safe scope { return false; }
        void popFront() @nogc nothrow pure @safe scope {}
        enum isUniformRandom = true;
        enum max = 1.0;
        enum min = 0.0;
    }
    static assert(isUniformRNG!Rng);

    auto rng = Rng();
    immutable result = gaussianDistributionRandom!real(rng);
    assert(result.isClose(cast(real) -0x9.6b55f2257e218fep-3));
}


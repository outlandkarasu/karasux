/**
Decimal module.
*/
module karasux.decimal;

import std.algorithm : max;
import std.ascii : isDigit;
import std.math : ceil, floor, log10, abs;
import std.string : format;
import std.traits : isFloatingPoint;
import std.typecons : Nullable, nullable, Tuple, tuple;

@safe:

/**
Decimal type.
*/
struct Decimal
{
    /**
    Min price number.
    */
    static immutable(Decimal) min = Decimal(long.min, ubyte.min);

    /**
    price number.
    */
    static immutable(Decimal) max = Decimal(long.max, ubyte.max);

    /**
    Number mantissa.
    */
    long mantissa;

    /**
    Number exponent.
    */
    ubyte exponent;

    /**
    Add exponent and shift mantissa.

    Params:
        n = shift value.
    Returns:
        shifted number.
    */
    Decimal addExponent(ubyte n) const @nogc nothrow pure
    in ((cast(uint) exponent) + n <= ubyte.max)
    out (r; (mantissa > 0) ? r.mantissa >= mantissa : r.mantissa <= mantissa)
    {
        if (n == 0)
        {
            return this;
        }

        return Decimal(mantissa * (10 ^^ n), cast(ubyte)(exponent + n));
    }

    ///
    @nogc nothrow pure unittest
    {
        auto price = Decimal(123456, 3);
        assert(price.addExponent(0) == Decimal(123456, 3));
        assert(price.addExponent(1) == Decimal(1234560, 4));
        assert(price.addExponent(2) == Decimal(12345600, 5));
    }

    ///
    @nogc nothrow pure unittest
    {
        auto price = Decimal(-123456, 3);
        assert(price.addExponent(0) == Decimal(-123456, 3));
        assert(price.addExponent(1) == Decimal(-1234560, 4));
        assert(price.addExponent(2) == Decimal(-12345600, 5));
    }

    /**
    Compare other price number.

    Params:
        other = other value.
    Returns:
        true if equal value.
    */
    bool opEquals()(auto scope ref const(Decimal) other) const @nogc nothrow pure
    {
        if (exponent == other.exponent)
        {
            return mantissa == other.mantissa;
        }

        immutable matched = matchExponent(this, other);
        return matched[0].mantissa == matched[1].mantissa;
    }

    ///
    @nogc nothrow pure unittest
    {
        immutable a = Decimal(123456, 3);
        assert(a == a);

        immutable b = Decimal(1234560, 4);
        assert(a == b);

        assert(a != Decimal(123457, 3));
        assert(a != Decimal(1234567, 4));
    }

    /**
    Compare two prices.

    Params:
        other = other price number.
    Returns:
        opCmp result.
    */
    int opCmp()(auto ref const(Decimal) other) const @nogc nothrow pure scope
    {
        if (exponent == other.exponent)
        {
            return mantissa.cmp(other.mantissa);
        }

        immutable matched = matchExponent(this, other);
        return matched[0].cmp(matched[1]);
    }

    ///
    @nogc nothrow pure unittest
    {
        immutable a = Decimal(123456, 3);
        assert(!(a < a));
        assert(!(a > a));
        assert(a <= a);
        assert(a >= a);

        immutable b = Decimal(123457, 3);
        assert(a < b);
        assert(a <= b);
        assert(!(a > b));
        assert(!(a >= b));

        assert(b > a);
        assert(b >= a);
        assert(!(b < a));
        assert(!(b <= a));

        immutable c = Decimal(1234560, 4);
        assert(!(a < c));
        assert(!(a > c));
        assert(a <= c);
        assert(a >= c);

        assert(!(c < a));
        assert(!(c > a));
        assert(c <= a);
        assert(c >= a);

        immutable d = Decimal(1234561, 4);
        assert(a < d);
        assert(!(a > d));
        assert(a <= d);
        assert(!(a >= d));

        assert(!(d < a));
        assert(d > a);
        assert(!(d <= a));
        assert(d >= a);
    }

    /**
    Calculate other price.

    Params:
        rhs = other hand price.
    Returns:
        calculated price.
    */
    Decimal opBinary(string op)(auto scope ref const(Decimal) rhs) const @nogc nothrow pure
        if (op == "+" || op == "-")
    {
        immutable matched = matchExponent(this, rhs);
        immutable resultMantissa = mixin("matched[0].mantissa " ~ op ~ "matched[1].mantissa");
        return Decimal(resultMantissa, matched[0].exponent);
    }

    ///
    @nogc nothrow pure unittest
    {
        immutable a = Decimal(123000, 3);
        immutable b = Decimal(456, 3);
        assert(a + b == Decimal(123456, 3));
        assert(a - b == Decimal(122544, 3));

        immutable c = Decimal(-456, 3);
        assert(a + c == Decimal(122544, 3));
        assert(a - c == Decimal(123456, 3));

        assert(b - a == Decimal(-122544, 3));
    }

    /**
    Calculate mul and div.

    Params:
        rhs = other hand value.
    Returns:
        calculated price.
    */
    Decimal opBinary(string op)(long rhs) const @nogc nothrow pure
        if (op == "*" || op == "/")
    {
        return Decimal(mixin("mantissa " ~ op ~ " rhs"), exponent);
    }

    ///
    @nogc nothrow pure unittest
    {
        immutable a = Decimal(123456, 3);
        assert(a * 2 == Decimal(246912, 3));
        assert(a / 2 == Decimal(123456 / 2, 3));
    }

    /**
    Calculate mul.

    Params:
        rhs = other hand value.
    Returns:
        calculated price.
    */
    Decimal opBinary(string op)(auto scope ref const(Decimal) rhs) const @nogc nothrow pure
        if (op == "*")
    {
        return Decimal(mantissa * rhs.mantissa, cast(ubyte)(exponent + rhs.exponent));
    }

    ///
    @nogc nothrow pure unittest
    {
        immutable a = Decimal(123456, 3);
        assert(a * Decimal(2, 0) == Decimal(246912, 3));
        assert(a * Decimal(2, 1) == Decimal(246912, 4));
    }

    /**
    Convert from floating point.

    Params:
        value = floating point value.
        exponent = price number exponent.
    Returns:
        price number.
    */
    static Decimal from(T)(auto scope ref const(T) value, ubyte exponent) @nogc nothrow pure @safe
        if (isFloatingPoint!T)
    {
        return Decimal(cast(long) floor(value * (10.0 ^^ exponent) + 0.5), exponent);
    }

    ///
    @nogc nothrow pure @safe unittest
    {
        assert(Decimal.from(123.456, 3) == Decimal(123456, 3));
        assert(Decimal.from(123.001, 3) == Decimal(123001, 3));
        assert(Decimal.from(123.0019, 3) == Decimal(123002, 3));

        assert(Decimal.from(-123.456, 3) == Decimal(-123456, 3));
        assert(Decimal.from(-123.001, 3) == Decimal(-123001, 3));
        assert(Decimal.from(-123.0019, 3) == Decimal(-123002, 3));
    }

    /**
    Convert to floating point.

    Params:
        price = price value.
    Returns:
        floating point value.
    */
    auto opCast(T)() const @nogc nothrow pure scope
        if (isFloatingPoint!T)
    {
        return (cast(T) mantissa) / (cast(T) 10.0) ^^ exponent;
    }

    ///
    @nogc nothrow pure unittest
    {
        import std.math : approxEqual;
        assert(approxEqual(cast(double) Decimal(123456, 0), 123456.0));
        assert(approxEqual(cast(double) Decimal(123456, 3), 123.456));
        assert(approxEqual(cast(double) Decimal(-123456, 3), -123.456));
    }

    /**
    Returns:
        String representation.
    */
    string toString() const pure
    {
        if (exponent == 0)
        {
            return format("%d", mantissa);
        }

        immutable unit = 10L ^^ exponent;
        immutable m = mantissa / unit;
        immutable f = abs(mantissa % unit);
        return format("%d.%0*d", m, exponent, f);
    }

    ///
    pure unittest
    {
        assert(Decimal(123456, 3).toString == "123.456");
        assert(Decimal(123000, 3).toString == "123.000");
        assert(Decimal(123456, 0).toString == "123456");
        assert(Decimal(123456, 6).toString == "0.123456");
        assert(Decimal(1, 3).toString == "0.001");
        assert(Decimal(123001, 3).toString == "123.001");
        assert(Decimal(-123001, 3).toString == "-123.001", Decimal(-123001, 3).toString);
    }

    /**
    Parse price number from string.

    Params:
        s = target string
    Returns:
        Decimal if succceeded.
    */
    static Nullable!Decimal fromString(scope const(char)[] s) nothrow @nogc pure @safe
    {
        if (s.length == 0)
        {
            return typeof(return).init;
        }

        // read sign.
        bool plus = true;
        size_t start = 0;
        if (s[0] == '-')
        {
            plus = false;
            ++start;
        }
        else if (s[0] == '+')
        {
            ++start;
        }

        ulong n = 0;
        ptrdiff_t dotIndex = s.length;
        foreach (i, c; s[start .. $])
        {
            if (c == '.')
            {
                dotIndex = start + i;
                continue;
            }

            if (!c.isDigit)
            {
                return typeof(return).init;
            }

            n *= 10;
            n += (c - '0');
        }

        immutable exponent = .max(
            0, (cast(ptrdiff_t) s.length) - dotIndex - 1);
        if (exponent > ubyte.max)
        {
            return typeof(return).init;
        }

        return Decimal(plus ? n : -n, cast(ubyte) exponent).nullable;
    }

    ///
    nothrow pure @safe unittest
    {
        import std.exception : assertThrown;
        import std.range : array, repeat;

        assert(Decimal.fromString(".123456") == Decimal(123456, 6));
        assert(Decimal.fromString("123.456") == Decimal(123456, 3));
        assert(Decimal.fromString("12345.6") == Decimal(123456, 1));
        assert(Decimal.fromString("123456.") == Decimal(123456, 0));
        assert(Decimal.fromString("123456") == Decimal(123456, 0));
        assert(Decimal.fromString("0.001") == Decimal(1, 3));
        assert(Decimal.fromString("100.000") == Decimal(100000, 3));

        assert(Decimal.fromString("a123456").isNull);
        assert(Decimal.fromString("123.456a").isNull);

        string zeros = '0'.repeat(ubyte.max - 1).array;
        assert(Decimal.fromString("." ~ zeros ~ "1") == Decimal(1, ubyte.max));
        assert(Decimal.fromString("." ~ zeros ~ "01").isNull);

        assert(Decimal.fromString("+123.456") == Decimal(+123456, 3));
        assert(Decimal.fromString("-123.456") == Decimal(-123456, 3));
        assert(Decimal.fromString("+.123456") == Decimal(123456, 6));
        assert(Decimal.fromString("-.123456") == Decimal(-123456, 6));
    }
}

/**
Match two exponent.

Params:
    a = price number 1.
    b = price number 2.
Returns:
    matched exponent.
*/
auto matchExponent()(
        auto scope ref const(Decimal) a,
        auto scope ref const(Decimal) b) @nogc nothrow pure
out(r; r[0].exponent == r[1].exponent)
{
    immutable maxExponent = max(a.exponent, b.exponent);
    return tuple(
        a.addExponent(cast(ubyte)(maxExponent - a.exponent)),
        b.addExponent(cast(ubyte)(maxExponent - b.exponent)));
}

///
@nogc nothrow pure unittest
{
    immutable a = Decimal(123456, 3);
    assert(matchExponent(a, a) == tuple(a, a));

    immutable b = Decimal(7890120, 4);
    assert(matchExponent(a, b) == tuple(Decimal(1234560, 4), b));
    assert(matchExponent(b, a) == tuple(b, Decimal(1234560, 4)));
}

private:

int cmp(T)(auto ref const(T) a, auto ref const(T) b)
{
    if (a < b)
    {
        return -1;
    }

    if (a > b)
    {
        return 1;
    }

    return 0;
}

///
@nogc nothrow pure unittest
{
    assert(cmp(0, 0) == 0);
    assert(cmp(1, 0) == 1);
    assert(cmp(0, 1) == -1);
}


/**
Datetime extension.
*/
module karasux.datetime;

import core.time : Duration, hnsecs;
import std.datetime : Clock, UTC, SysTime, unixTimeToStdTime;

/**
Singleton UTC timezone.
*/
immutable timeZoneUTC = UTC();

/**
UNIX epoch time.
*/
immutable UNIX_EPOCH = SysTime(unixTimeToStdTime(0), timeZoneUTC);

/**
Calculate duration since UNIX epoch time.

Params:
    t = SysTime value.
Returns:
    Duration since UNIX epoch time (1970/1/1 00:00)
*/
Duration sinceUnixEpoch()(scope auto ref const(SysTime) t) @nogc nothrow pure @safe
{
    return t - UNIX_EPOCH;
}

///
nothrow pure @safe unittest
{
    import core.time : seconds;

    assert(UNIX_EPOCH.sinceUnixEpoch == Duration.zero);
    assert(SysTime(unixTimeToStdTime(1000), timeZoneUTC).sinceUnixEpoch == 1000.seconds);
}

/**
Returns;
    Current timestamp since UNIX epoch.
*/
Duration currentUnixTime() @safe
{
    return Clock.currTime(timeZoneUTC).sinceUnixEpoch;
}

///
@safe unittest
{
    assert(currentUnixTime.total!"seconds" == Clock.currTime(timeZoneUTC).toUnixTime);
}

/**
Timestamp type.
*/
struct Timestamp 
{
    /**
    Returns:
        now timestamp.
    */
    static @property Timestamp now() nothrow @safe
    {
        return Timestamp(Clock.currTime(timeZoneUTC).stdTime);
    }

    /**
    Returns:
        timestamp ISO8601 string reperesentation.
    */
    string toString() const nothrow @safe scope
    {
        return SysTime(stdTime, timeZoneUTC).toISOExtString();
    }

    /**
    Parse timestamp.

    Params:
        timestamp = timestamp string.
    Returns:
        parsed timestamp.
    */
    static Timestamp fromString(string timestamp) @safe
    {
        return Timestamp(SysTime.fromISOExtString(timestamp).stdTime);
    }

    /**
    calculate duration.
    */
    Duration opBinary(string op)(scope auto ref const(Timestamp) rhs)
        const @nogc nothrow @safe scope if (op == "-")
    {
        return hnsecs(mixin("stdTime " ~ op ~ " rhs.stdTime"));
    }

    ///
    @nogc nothrow @safe unittest
    {
        immutable t1 = Timestamp(1000);
        immutable t2 = Timestamp(500);
        assert(t1 - t2 == hnsecs(500));
        assert(t2 - t1 == hnsecs(-500));
    }

    /**
    Round down time by unit duration.

    Params:
        unit = unit duration.
    Returns:
        Rounded down timestamp.
    */
    Timestamp roundDown(Duration unit) const @nogc nothrow pure @safe scope
    {
        immutable total = unit.total!"hnsecs";
        return (total == 0) ? this : Timestamp(stdTime - stdTime % total);
    }

    ///
    @nogc nothrow pure @safe unittest
    {
        import core.time : hnsecs, dur;
        immutable t = Timestamp(1234567890);
        assert(t.roundDown(dur!"seconds"(1)) == Timestamp(1230000000));
        assert(t.roundDown(dur!"msecs"(1)) == Timestamp(1234560000));
    }

    /**
    Compare two timestmaps.

    Params:
        rhs = other hand side.
    Returns:
        compare result.
    */
    int opCmp()(auto scope ref const(Timestamp) rhs) const @nogc nothrow pure @safe scope
    {
        // prevent overflow.
        immutable diff = cast(long)(stdTime - rhs.stdTime);
        return (diff < 0) ? -1 : ((diff > 0) ? 1 : 0);
    }

    ///
    @nogc nothrow pure @safe unittest
    {
        immutable t1 = Timestamp(12345678912340);
        immutable t2 = Timestamp(12345678912341);
        assert(t1 < t2);
        assert(t1 <= t2);
        assert(t2 > t1);
        assert(t2 >= t1);

        assert(!(t1 < t1));
        assert(t1 <= t1);
        assert(!(t1 > t1));
        assert(t1 >= t1);
    }

    /**
    Compare two timestmaps.

    Params:
        rhs = other hand side.
    Returns:
        compare result.
    */
    bool opEquals()(auto scope ref const(Timestamp) rhs) const @nogc nothrow pure @safe scope
    {
        return stdTime == rhs.stdTime;
    }

    ///
    @nogc nothrow pure @safe unittest
    {
        immutable t1 = Timestamp(12345678912340);
        immutable t2 = Timestamp(12345678912341);
        assert(t1 == t1);
        assert(t2 == t2);
        assert(t1 != t2);
        assert(t2 != t1);
    }

    ulong stdTime;
}

///
@safe unittest
{
    immutable t = Timestamp.fromString("2021-01-02T03:04:05.678Z");
    assert(t.toString() == "2021-01-02T03:04:05.678+00:00");
}


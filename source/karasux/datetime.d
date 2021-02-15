/**
Datetime extension.
*/
module karasux.datetime;

import core.time : Duration;
import std.datetime : UTC, SysTime, unixTimeToStdTime;

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


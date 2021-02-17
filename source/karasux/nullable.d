/**
Nullable extension.
*/
module karasux.nullable;

import std.functional : unaryFun;
import std.range : isInputRange;
import std.traits : ReturnType, isCallable;
import std.typecons : Nullable, nullable;

/**
Nullable as range.
*/
struct NullableRange(T)
{
    static assert(isInputRange!(typeof(this)));

    /**
    Initialize by inner value.

    Params:
        value = inner value.
    */
    inout this(inout T value)
        out(; !empty)
    {
        this.nullable_ = value;
    }

    /**
    Returns:
       content reference. 
    */
    ref inout(T) front() inout pure @nogc @property nothrow @safe
        in (!empty)
    {
        return nullable_.get;
    }

    /**
    Returns:
        true if nullable is empty.
    */
    bool empty() const pure @property nothrow @safe
    {
        return nullable_.isNull;
    }

    /**
    pop nullable contents.
    */
    void popFront()()
        out(; empty)
    {
        nullable_.nullify();
    }

    /**
    Returns:
        nullable value reference.
    */
    ref inout(Nullable!T) asNullable() inout @nogc pure @property nothrow @safe
    {
        return nullable_;
    }

private:
    Nullable!T nullable_;
}

///
@nogc nothrow pure @safe unittest
{
    assert(NullableRange!int(99).front == 99);

    auto x = NullableRange!int(100);
    assert(x.front == 100);
    
    x.front = 1234;
    assert(x.front == 1234);
    x.popFront;
    assert(x.empty == true);
}

///
@nogc nothrow pure @safe unittest
{
    auto x = NullableRange!int(99).asNullable;
    assert(!x.isNull);
    assert(x.get == 99);
    x.nullify();
    assert(x.isNull);
}

/**
Params:
    value = inner value.
Returns:
    nullable range value.
*/
NullableRange!T nullableRange(T)(inout T value)
{
    return NullableRange!T(value);
}

///
@nogc nothrow pure @safe unittest
{
    assert(99.nullableRange.front == 99);

    auto x = 100.nullableRange;
    assert(x.front == 100);
    
    x.front = 1234;
    assert(x.front == 1234);
    x.popFront;
    assert(x.empty == true);
}

/**
Params:
    value = inner value.
Returns:
    nullable range value.
*/
NullableRange!T toRange(T)(inout Nullable!T value)
{
    return (value.isNull) ? typeof(return).init : NullableRange!T(value.get);
}

///
@nogc nothrow pure @safe unittest
{
    import std.typecons : nullable;
    auto range = 100.nullable.toRange;
    assert(range.front == 100);
    assert(!range.empty);
    range.popFront();
    assert(range.empty);

    auto emptyRange = Nullable!int.init.toRange;
    assert(emptyRange.empty);
}

/**
Get and map Nullable content.

Params:
    F = map function.
    T = Nullable content type.
    value = Nullable value.
Returns:
    mapped Nullable value.
*/
auto getMap(alias F, T)(Nullable!T value)
{
    alias fun = unaryFun!F;
    alias R = Nullable!(typeof(fun(value.get)));
    return (value.isNull) ? R.init : nullable(fun(value.get));
}

///
nothrow pure @safe unittest
{
    import std.conv : to;
    Nullable!int value = 100.nullable;
    auto mapped = value.getMap!((v) => v.to!string);

    static assert(is(typeof(mapped) == Nullable!string));
    assert(!mapped.isNull);
    assert(mapped.get == "100");

    assert(Nullable!int.init.getMap!((v) => v.to!string).isNull);
}


/**
Nullable extension.
*/
module karasux.nullable;

import std.range : isInputRange;
import std.typecons : Nullable;

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

NullableRange!T nullableRange(T)(T value)
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


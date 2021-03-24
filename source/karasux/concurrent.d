/**
Concurrent extension module.
*/
module karasux.concurrent;

import std.meta : staticMap;
import std.traits :
    ReturnType,
    MemberFunctionsTuple,
    Parameters;
import std.typecons : Tuple;
import std.concurrency : receive, receiveTimeout;

I concurrentService(I, F, Args...)(F constructor, Args arguments)
    if (is(I == interface) && is(ReturnType!F : I))
{
    static foreach (member; __traits(allMembers, I))
    {
        static foreach (i, memberFunction; MemberFunctionsTuple!(I, member))
        {
            mixin("alias " ~ member ~ i.stringof ~ "Parameters = "
                ~ "Tuple!" ~ Parameters!memberFunction.stringof ~ ";");
        }
    }

    void serviceThread(Args threadArguments)
    {
        auto instance = constructor(threadArguments);
        static foreach (member; __traits(allMembers, I))
        {
            static foreach (i, memberFunction; MemberFunctionsTuple!(I, member))
            {
                mixin("void " ~ member ~ i.stringof ~ "("
                        ~ member ~ i.stringof ~ "Parameters params) { "
                    ~ "instance." ~ member ~ "(params.expand); }");
            }
        }
    }

    return null;
}

template MemberTuple(I)
    if (is(I == interface))
{
    alias result(alias member) = MemberFunctionsTuple!(I, member);
}

template InterfaceMembers(I)
    if (is(I == interface))
{
    alias InterfaceMembers = staticMap!(MemberTuple!I.result, __traits(allMembers, I));
}

///
unittest
{
    interface Base
    {
        void doService1();
        void doService1(string s);
        void doService2();
        void doService3();
    }

    class Actual : Base
    {
        override void doService1() {}
        override void doService1(string s) {}
        override void doService2() {}
        override void doService3() {}
    }

    auto service = concurrentService!Base(() => new Actual());
    //service.doService();
    pragma(msg, InterfaceMembers!Base.stringof);
}


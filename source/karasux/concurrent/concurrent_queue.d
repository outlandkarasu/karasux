/**
Concurrent queue module.
*/
module karasux.concurrent.concurrent_queue;

import core.time : Duration;

private:

/**
Concurrent queue backend.
*/
struct ConcurrentQueue(T)
{
    @disable this();

    this(size_t n) nothrow pure @safe scope
    {
        this.entries_ = new T[n];
    }

    bool write(Args...)(Duration timeout, Args args)
    {
        if ((writePosition_ - readPosition_) >= entries_.length)
        {
            return false;
        }

        entries_[toActualPosition(writePosition_)] = T(args);
        ++writePosition_;
        return true;
    }

    bool read(Duration timeout, scope ref T dest)
    {
        if (readPosition_ == writePosition_)
        {
            return false;
        }

        dest = entries_[readPosition_];
        destroy(entries_[readPosition_]);

        ++readPosition_;
        if (readPosition_ >= entries_.length)
        {
            readPosition_ -= entries_.length;
            writePosition_ -= entries_.length;
        }

        return true;
    }

private:
    T[] entries_;
    size_t readPosition_;
    size_t writePosition_;

    size_t toActualPosition(size_t pos) const @nogc nothrow pure @safe scope
    {
        return (pos >= entries_.length) ? pos - entries_.length : pos;
    }

    invariant
    {
        assert(readPosition_ <= writePosition_);
        assert(readPosition_ <= entries_.length);
        assert(writePosition_ - readPosition_ <= entries_.length);
    }
}

///
nothrow pure @safe unittest
{
    import core.time : seconds;

    struct Item
    {
        string value;
    }

    auto queue = ConcurrentQueue!Item(4);
    immutable timeout = 1.seconds;
    assert(queue.write(timeout, "1"));
    assert(queue.write(timeout, "2"));
    assert(queue.write(timeout, "3"));
    assert(queue.write(timeout, "4"));
    assert(!queue.write(timeout, "5"));

    Item readed;
    assert(queue.read(timeout, readed) && readed.value == "1");

    assert(queue.write(timeout, "5"));
    assert(!queue.write(timeout, "6"));

    assert(queue.read(timeout, readed) && readed.value == "2");

    assert(queue.write(timeout, "6"));
    assert(!queue.write(timeout, "7"));

    assert(queue.read(timeout, readed) && readed.value == "3");
    assert(queue.read(timeout, readed) && readed.value == "4");
    assert(queue.read(timeout, readed) && readed.value == "5");
    assert(queue.read(timeout, readed) && readed.value == "6");
    assert(!queue.read(timeout, readed));

    assert(queue.write(timeout, "7"));
    assert(queue.read(timeout, readed) && readed.value == "7");
}


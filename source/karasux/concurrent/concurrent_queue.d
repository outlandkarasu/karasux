/**
Concurrent queue module.
*/
module karasux.concurrent.concurrent_queue;

import core.time : Duration;
import core.sync.condition : Condition;
import core.sync.mutex : Mutex;

private:

/**
Concurrent queue backend.
*/
struct ConcurrentQueue(T)
{
    @disable this();

    this(size_t n) nothrow @trusted scope
    {
        this.entries_ = new T[n];
        this.mutex_ = new Mutex();
        this.writeCondition_ = new Condition(new Mutex());
        this.readCondition_ = new Condition(new Mutex());
    }

    bool write(Args...)(Duration timeout, Args args)
    {
        if (writeClosed_)
        {
            return false;
        }

        while ((writePosition_ - readPosition_) >= entries_.length)
        {
            if (readClosed_)
            {
                return false;
            }

            synchronized (readCondition_.mutex)
            {
                if (!readCondition_.wait(timeout))
                {
                    return false;
                }
            }
        }

        entries_[toActualPosition(writePosition_)] = T(args);

        mutex_.lock_nothrow();
        scope(exit) mutex_.unlock_nothrow();

        ++writePosition_;
        writeCondition_.notify();

        return true;
    }

    bool read(Duration timeout, scope ref T dest)
    {
        if (readClosed_)
        {
            return false;
        }

        while (readPosition_ == writePosition_)
        {
            if (writeClosed_)
            {
                return false;
            }

            synchronized (writeCondition_.mutex)
            {
                if (!writeCondition_.wait(timeout))
                {
                    return false;
                }
            }
        }

        dest = entries_[readPosition_];
        destroy(entries_[readPosition_]);

        mutex_.lock_nothrow();
        scope(exit) mutex_.unlock_nothrow();

        ++readPosition_;
        if (readPosition_ >= entries_.length)
        {
            readPosition_ -= entries_.length;
            writePosition_ -= entries_.length;
        }
        readCondition_.notify();

        return true;
    }

    @property @nogc nothrow pure @safe scope
    {
        bool readClosed() const
        {
            return readClosed_;
        }

        bool writeClosed() const
        {
            return (readPosition_ == writePosition_) && writeClosed_;
        }
    }

private:
    T[] entries_;
    size_t readPosition_;
    size_t writePosition_;
    bool readClosed_;
    bool writeClosed_;
    Mutex mutex_;
    Condition writeCondition_;
    Condition readCondition_;

    size_t toActualPosition(size_t pos) const @nogc nothrow pure @safe scope
    {
        return (pos >= entries_.length) ? pos - entries_.length : pos;
    }

    invariant
    {
        assert(readPosition_ <= writePosition_);
        assert(readPosition_ < entries_.length);
        assert(writePosition_ - readPosition_ <= entries_.length);
    }
}

///
unittest
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


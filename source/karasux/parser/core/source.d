/**
Parser source module.
*/
module karasux.parser.core.source;

import std.array : Appender;
import std.typecons : Nullable, nullable;

/**
Backtrackable array source.

Params:
    S = symbol type.
*/
struct ArraySource(S)
{
    /**
    copy constructor disabled.
    */
    @disable this(ref return scope ArraySource rhs);

    /**
    Initialize by source array.

    Params:
        source = source array.
    */
    this(S[] source)
    {
        this.source_ = source;
    }

    /**
    Returns:
        current symbol.
    */
    inout(S) front() inout
        in (!empty)
    {
        return source_[position_];
    } 

    /**
    Returns:
        true if source is empty.
    */
    bool empty() const
    {
        return source_.length <= position_;
    }

    /**
    Pop current symbol.
    */
    void popFront()
        in (!empty)
    {
        ++position_;
    }

    /**
    begin backtrackable point.
    */
    void begin()
    {
        savePoints_ ~= position_;
    }

    /**
    accept current backtrackable point.
    */
    void accept()
        in (savePoints_[].length > 0)
    {
        savePoints_.popAppender();
    }

    /**
    reject current backtrackable point and restore state.
    */
    void reject()
        in (savePoints_[].length > 0)
    {
        position_ = savePoints_[][$ - 1];
        savePoints_.popAppender();
    }

    /**
    Returns:
        current position.
    */
    size_t position() const @nogc nothrow pure @safe scope
    {
        return position_;
    }

private:
    S[] source_;
    size_t position_;
    Appender!(size_t[]) savePoints_;
}

///
@nogc nothrow pure @safe unittest
{
    import karasux.parser.core.traits : isInputSource;

    scope source = ArraySource!(immutable(char))("test");
    static assert(isInputSource!(typeof(source)));

    assert(!source.empty);
    assert(source.position == 0);
    assert(source.front == 't');

    source.popFront();
    assert(!source.empty);
    assert(source.position == 1);
    assert(source.front == 'e');

    source.popFront();
    assert(!source.empty);
    assert(source.position == 2);
    assert(source.front == 's');

    source.popFront();
    assert(!source.empty);
    assert(source.position == 3);
    assert(source.front == 't');

    source.popFront();
    assert(source.position == 4);
    assert(source.empty);
}

///
pure @safe unittest
{
    import karasux.parser.core.traits : isBacktrackableSource;

    scope source = ArraySource!(immutable(char))("test");
    static assert(isBacktrackableSource!(typeof(source)));

    source.popFront();
    source.begin();
    assert(source.position == 1);
    assert(source.front == 'e');

    source.popFront();
    assert(source.position == 2);
    assert(source.front == 's');

    source.begin();
    source.popFront();
    assert(source.position == 3);
    assert(source.front == 't');

    source.reject();
    assert(source.position == 2);
    assert(source.front == 's');

    source.begin();
    source.popFront();
    assert(source.position == 3);
    assert(source.front == 't');
    source.accept();

    source.reject();
    assert(source.position == 1);
    assert(source.front == 'e');
}

/**
Memoized array source.

Params:
    S = symbol type.
    Tag = tag type.
*/
struct MemoizedArraySource(S, Tag)
{
    /**
    Node type.
    */
    struct Node
    {
        Tag tag;
        size_t start;
        size_t end;
        Node[] children;
    }

    /**
    copy constructor disabled.
    */
    @disable this(ref return scope MemoizedArraySource rhs);

    /**
    Initialize by source array.

    Params:
        source = source array.
    */
    this(S[] source)
    {
        this.innerSource = ArraySource!S(source);
    }

    alias innerSource this;

    ArraySource!S innerSource;

    /**
    begin node.
    */
    void begin()
    {
        innerSource.begin();
        nodeSavePoints_ ~= Nullable!NodeSavePoint.init;
    }

    /**
    begin node.
    */
    void begin(Tag tag)
    {
        innerSource.begin();
        nodeSavePoints_ ~= NodeSavePoint(tag, position, nodes_[].length).nullable;
    }

    /**
    accept current backtrackable point.
    */
    void accept()
    {
        innerSource.accept();

        auto savedNode = popNodeSavePoint();
        if (!savedNode.isNull)
        {
            auto saved = savedNode.get;
            auto children = nodes_[][saved.nodesStart .. $].dup;
            nodes_.shrinkTo(saved.nodesStart);
            nodes_ ~= Node(saved.tag, saved.start, position, children);
        }
    }

    /**
    reject current backtrackable point and restore state.
    */
    void reject()
    {
        innerSource.reject();
        auto savedNode = popNodeSavePoint();
        if (!savedNode.isNull)
        {
            nodes_.shrinkTo(savedNode.get.nodesStart);
        }
    }

    /**
    Get current nodes.
    */
    @property const(Node)[] nodes() const
    {
        return nodes_[];
    }

private:

    struct NodeSavePoint
    {
        Tag tag;
        size_t start;
        size_t nodesStart;
    }

    Appender!(Node[]) nodes_;
    Appender!(Nullable!(NodeSavePoint)[]) nodeSavePoints_;

    Nullable!NodeSavePoint popNodeSavePoint()
        in (nodeSavePoints_[].length > 0)
    {
        auto savedNode = nodeSavePoints_[][$ - 1];
        nodeSavePoints_.popAppender();
        return savedNode;
    }
}

///
@nogc nothrow pure @safe unittest
{
    import karasux.parser.core.traits : isInputSource;

    scope source = MemoizedArraySource!(immutable(char), string)("test");
    static assert(isInputSource!(typeof(source)));

    assert(!source.empty);
    assert(source.position == 0);
    assert(source.front == 't');

    source.popFront();
    assert(!source.empty);
    assert(source.position == 1);
    assert(source.front == 'e');

    source.popFront();
    assert(!source.empty);
    assert(source.position == 2);
    assert(source.front == 's');

    source.popFront();
    assert(!source.empty);
    assert(source.position == 3);
    assert(source.front == 't');

    source.popFront();
    assert(source.position == 4);
    assert(source.empty);
}

///
pure @safe unittest
{
    import karasux.parser.core.traits : isBacktrackableSource;

    scope source = MemoizedArraySource!(immutable(char), string)("test");
    static assert(isBacktrackableSource!(typeof(source)));

    source.popFront();
    source.begin();
    assert(source.position == 1);
    assert(source.front == 'e');

    source.popFront();
    assert(source.position == 2);
    assert(source.front == 's');

    source.begin();
    source.popFront();
    assert(source.position == 3);
    assert(source.front == 't');

    source.reject();
    assert(source.position == 2);
    assert(source.front == 's');

    source.begin();
    source.popFront();
    assert(source.position == 3);
    assert(source.front == 't');
    source.accept();

    source.reject();
    assert(source.position == 1);
    assert(source.front == 'e');
}

///
pure @safe unittest
{
    import karasux.parser.core.traits : isBacktrackableSource;

    scope source = MemoizedArraySource!(immutable(char), string)("test");
    alias Node = typeof(source).Node;

    source.begin("test");

    source.begin("te");
    source.popFront();
    source.popFront();
    source.accept();

    source.begin("st");
    source.popFront();
    source.popFront();
    source.accept();

    source.accept();

    assert(source.nodes == [
        Node("test", 0, 4, [
            Node("te", 0, 2),
            Node("st", 2, 4),
        ])
    ]);
}

///
pure @safe unittest
{
    import karasux.parser.core.traits : isBacktrackableSource;

    scope source = MemoizedArraySource!(immutable(char), string)("test");
    alias Node = typeof(source).Node;

    source.begin("test");

    source.begin("te");
    source.popFront();
    source.popFront();
    source.accept();

    source.begin("st");
    source.popFront();
    source.popFront();
    source.accept();

    source.reject();

    assert(source.nodes.length == 0);
}

private:

void popAppender(T)(scope ref Appender!T appender)
    in (appender[].length > 0)
{
    appender.shrinkTo(appender[].length - 1);
}


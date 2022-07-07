/**
AST builder source module.
*/
module karasux.parser.source.ast_builder_source;

import core.memory : pureCalloc, pureRealloc, pureFree;

import karasux.parser.source.traits :
    isInputSource,
    isSeekableSource;

/**
AST builder source trait.

Params:
    R = source range type.
*/
enum isASTBuilderSource(R) = isInputSource!R
    && is(R.Tag)
    && is(typeof((scope ref R r) @nogc nothrow pure @safe => r.nodePosition))
    && is(typeof((scope ref R r) { auto p = r.nodePosition; r.acceptNode(R.Tag.init, p); }));

/**
rejectable AST builder source trait.

Params:
    R = source range type.
*/
enum isRejectableASTBuilderSource(R) = isSeekableSource!R
    && isASTBuilderSource!R
    && is(typeof((scope ref R r) { auto p = r.nodePosition; r.rejectNode(p); }));

/**
AST builder source.

Params:
    R = inner source type
    T = AST tag type
*/
struct ASTBuilderSource(R, T)
{
    static assert(isInputSource!R);

    /**
    AST tag type.
    */
    alias Tag = T;

    /**
    Initialize from inner source.

    Params:
        source = inner source.
    */
    this(return scope R source) @nogc nothrow pure @safe scope
    {
        this.inner = source;
    }

    // not copyiable.
    @disable this(this);

    // not copyiable.
    @disable this(ref return scope ASTBuilderSource rhs);

    ~this() @nogc nothrow pure @safe scope
    {
        foreach (ref node; nodes_)
        {
            node.release();
        }
    }

    @nogc nothrow pure @safe scope
    {
        @property size_t nodePosition() const
        {
            return nodePosition_;
        }
    }

    /**
    Accept node.

    Params:
        tag = AST node tag value
        start = node start position
    Returns:
        true if succeeded. false if failed allocation.
    */
    bool acceptNode(Tag tag, size_t start) @nogc nothrow pure @trusted scope
        in(start <= nodePosition_)
        in(start <= nodes_.length)
    {
        auto node = ASTNode!Tag(tag);

        // append single node.
        immutable oldLength = nodes_.length;
        if (start == oldLength)
        {
            immutable newLength = oldLength + 1;
            auto newNodes = cast(ASTNode!(Tag)*) pureRealloc(
                (oldLength > 0) ? &nodes_[0] : null,
                ASTNode!Tag.sizeof * newLength);
            if (!newNodes)
            {
                return false;
            }

            nodes_ = newNodes[0 .. newLength];
            nodes_[start] = node;
            ++nodePosition_;
            return true;
        }

        // move children from current nodes.
        if (!node.moveChildren(nodes_[start .. nodePosition_]))
        {
            return false;
        }

        nodes_[start] = node;
        nodePosition_ = start + 1;
        return true;
    }

    R inner;

    alias inner this;

private:
    size_t nodePosition_;
    ASTNode!(Tag)[] nodes_;
}

///
@nogc nothrow pure @safe unittest
{
    import karasux.parser.source.array_source : arraySource;

    auto source = astBuilder!int(arraySource("test"));

    static assert(isASTBuilderSource!(typeof(source)));
    assert(source.front == 't');
    assert(source.position == 0);
    assert(source.nodePosition == 0);
    assert(!source.empty);

    source.popFront();
    assert(source.acceptNode(123, 0));

    assert(source.front == 'e');
    assert(source.position == 1);
    assert(source.nodePosition == 1);
    assert(!source.empty);
}

/**
create AST builder source.

Params:
    r = inner source
Returns:
    AST builder source
*/
ASTBuilderSource!(R, T) astBuilder(T, R)(return scope R r)
{
    return ASTBuilderSource!(R, T)(r);
}

private:

/**
AST Node.
*/
struct ASTNode(Tag)
{
    /**
    Construct node.

    Params:
        tag = node tag value
    */
    this(Tag tag) @nogc nothrow pure @safe scope
    {
        this.tag_ = tag;
    }

    @nogc nothrow pure @safe
    {
        @property Tag tag() const scope
        {
            return tag_;
        }

        @property const(ASTNode)[] children() const return scope
        {
            return children_;
        }
    }

    /**
    Allocate and copy new children.

    Params:
        fromChildren = new children source array
    Returns:
        true if succeeded. false if failed memory allocation.
    */
    bool moveChildren(return scope ASTNode[] fromChildren) @nogc nothrow pure @trusted scope
    {
        if (fromChildren.length == 0)
        {
            release();
            return true;
        }

        immutable newLength = fromChildren.length;
        auto newPointer = cast(ASTNode*) pureCalloc(newLength, ASTNode.sizeof);
        if (!newPointer)
        {
            return false;
        }

        auto newArray = newPointer[0 .. newLength];
        foreach (i, ref e; newArray)
        {
            e = fromChildren[i];

            // remove old reference.
            fromChildren[i].clearWithoutRelease();
        }

        release();
        children_ = newArray;
        return true;
    }

    /**
    Release allocated memory.
    */
    void release() @nogc nothrow pure @trusted scope
        out(; children_.length == 0)
    {
        foreach (ref e; children_)
        {
            e.release();
        }

        if (children_.length > 0)
        {
            pureFree(&children_[0]);
        }

        children_ = children_.init;
    }

private:

    void clearWithoutRelease() @nogc nothrow pure @safe scope
    {
        tag_ = tag_.init;
        children_ = children_.init;
    }

    Tag tag_;
    ASTNode[] children_;
}

///
nothrow pure @safe unittest
{
    scope node = ASTNode!int(123);
    assert(node.tag == 123);
    assert(node.children.length == 0);

    auto children = [ASTNode!int(456)];
    auto grandchild = [ASTNode!int(789)];
    (() @nogc {
        assert(children[0].moveChildren(grandchild));
        assert(children[0].children.length == 1);
        assert(children[0].children[0].tag == 789);
    })();

    (() @nogc {
        assert(node.moveChildren(children));
        assert(node.children.length == 1);
        assert(node.children[0].tag == 456);
        assert(node.children[0].children.length == 1);
        assert(node.children[0].children[0].tag == 789);

        // removed from children.
        assert(children[0].children.length == 0);
    })();

    (() @nogc => node.release())();
    assert(node.children.length == 0);
}


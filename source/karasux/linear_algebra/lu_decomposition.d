/**
Matrix LU decomposition module.
*/
module karasux.linear_algebra.lu_decomposition;

import std.traits : isNumeric;

import karasux.linear_algebra.matrix : Matrix;

/**
LU decomposition.

Params:
    m = target matrix.
    l = L destination matrix.
    u = U destination matrix.
*/
void luDecomposition(size_t N, E)(
    auto scope ref const(Matrix!(N, N, E)) m,
    scope ref Matrix!(N, N, E) l,
    scope ref Matrix!(N, N, E) u)
    if (isNumeric!E)
{
    // initialize L first row.
    l[0, 0] = E(1);
    foreach (column; 1 .. N)
    {
        l[0, column] = E(0);
    }

    // initialize U first row.
    foreach (column; 0 .. N)
    {
        u[0, column] = m[0, column];
    }

    auto m00 = m[0, 0];
    foreach (row; 1 .. N)
    {
        // clear L fixed cells.
        l[row, row] = E(1);
        foreach (column; row + 1 .. N)
        {
            l[row, column] = E(0);
        }

        // clear R fiexd cells.
        foreach (column; 0 .. row)
        {
            u[row, column] = E(0);
        }

        // setting up L first column.
        l[row, 0] = m[row, 0] / m00;

        // calculate L columns.
        foreach (column; 1 .. row)
        {
            E sum = E(0);
            foreach (lc; 0 .. column)
            {
                sum += l[row, lc] * u[lc, column];
            }
            l[row, column] = (m[row, column] - sum) / u[column, column];
        }

        // calculate U columns.
        foreach (column; row .. N)
        {
            E sum = E(0);
            foreach (lc; 0 .. row)
            {
                sum += l[row, lc] * u[lc, column];
            }
            u[row, column] = m[row, column] - sum;
        }
    }
}

///
@nogc nothrow pure @safe unittest
{
    import karasux.linear_algebra.matrix : isClose;

    immutable m = Matrix!(2, 2).fromRows([
        [4.0f, 3.0f],
        [6.0f, 3.0f]]);
    auto l = Matrix!(2, 2)();
    auto u = Matrix!(2, 2)();
    m.luDecomposition(l, u);

    assert(l.isClose(Matrix!(2, 2).fromRows([
        [1.0, 0.0],
        [1.5, 1.0]
    ])));
    assert(u.isClose(Matrix!(2, 2).fromRows([
        [4.0, 3.0],
        [0.0, -1.5]
    ])));

    auto mul = Matrix!(2, 2)();
    mul.mul(l, u);
    assert(mul.isClose(m));
}

@nogc nothrow pure @safe unittest
{
    import karasux.linear_algebra.matrix : isClose;

    immutable m = Matrix!(3, 3).fromRows([
        [5.0, 6.0, 7.0],
        [10.0, 20.0, 23.0],
        [15.0, 50.0, 67.0],
    ]);
    auto l = Matrix!(3, 3)();
    auto u = Matrix!(3, 3)();
    m.luDecomposition(l, u);
    assert(l.isClose(Matrix!(3, 3).fromRows([
        [1.0,  0.0,  0.0],
        [2.0,  1.0,  0.0],
        [3.0,  4.0,  1.0],
    ])));
    assert(u.isClose(Matrix!(3, 3).fromRows([
        [5.0, 6.0,  7.0],
        [0.0, 8.0,  9.0],
        [0.0, 0.0, 10.0],
    ])));

    auto mul = Matrix!(3, 3)();
    mul.mul(l, u);
    assert(mul.isClose(m));
}

@nogc nothrow pure @safe unittest
{
    import karasux.linear_algebra.matrix : isClose;

    immutable m = Matrix!(4, 4).fromRows([
        [5.0, 6.0, 7.0, 8.0],
        [10.0, 21.0, 24.0, 27.0],
        [15.0, 54.0, 73.0, 81.0],
        [25.0, 84.0, 179.0, 211.0],
    ]);
    auto l = Matrix!(4, 4)();
    auto u = Matrix!(4, 4)();
    m.luDecomposition(l, u);
    assert(l.isClose(Matrix!(4, 4).fromRows([
        [1.0,  0.0,  0.0, 0.0],
        [2.0,  1.0,  0.0, 0.0],
        [3.0,  4.0,  1.0, 0.0],
        [5.0,  6.0,  7.0, 1.0],
    ])));
    assert(u.isClose(Matrix!(4, 4).fromRows([
        [5.0, 6.0,  7.0, 8.0],
        [0.0, 9.0, 10.0, 11.0],
        [0.0, 0.0, 12.0, 13.0],
        [0.0, 0.0,  0.0, 14.0],
    ])));

    auto mul = Matrix!(4, 4)();
    mul.mul(l, u);
    assert(mul.isClose(m));
}


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
            foreach (lc; 0 .. column)
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
    import std.math : isClose;

    immutable m = Matrix!(2, 2).fromRows([
        [4.0f, 3.0f],
        [6.0f, 3.0f]]);
    auto l = Matrix!(2, 2)();
    auto u = Matrix!(2, 2)();
    m.luDecomposition(l, u);

    assert(l[0, 0].isClose(1));
    assert(l[0, 1].isClose(0));
    assert(l[1, 0].isClose(1.5));
    assert(l[1, 1].isClose(1));

    assert(u[0, 0].isClose(4));
    assert(u[0, 1].isClose(3));
    assert(u[1, 0].isClose(0));
    assert(u[1, 1].isClose(-1.5));
}



// Written in the D programming language.

/**
 * Templates with which to extract information about
 * types at compile time.
 *
 * Macros:
 *	WIKI = Phobos/StdTraits
 * Copyright:
 *	Public Domain
 */

/*
 * Authors:
 *	Walter Bright, Digital Mars, www.digitalmars.com
 *	Tomasz Stachowiak (isExpressionTuple)
 *      Andrei Alexandrescu, www.erdani.org
 */

module std.traits;
import std.typetuple;

/***
 * Get the type of the return value from a function,
 * a pointer to function, a delegate, a struct
 * with an opCall, a pointer to a struct with an opCall,
 * or a class with an opCall.
 * Example:
 * ---
 * import std.traits;
 * int foo();
 * ReturnType!(foo) x;   // x is declared as int
 * ---
 */
template ReturnType(alias dg)
{
    alias ReturnType!(typeof(dg), void) ReturnType;
}

template ReturnType(dg, dummy = void)
{
    static if (is(dg R == return))
	alias R ReturnType;
    else static if (is(dg T : T*))
	alias ReturnType!(T, void) ReturnType;
    else static if (is(dg S == struct))
	alias ReturnType!(typeof(&dg.opCall), void) ReturnType;
    else static if (is(dg C == class))
	alias ReturnType!(typeof(&dg.opCall), void) ReturnType;
    else
	static assert(0, "argument has no return type");
}

unittest
{
    struct G
    {
	int opCall (int i) { return 1;}
    }

    alias ReturnType!(G) ShouldBeInt;
    static assert(is(ShouldBeInt == int));

    G g;
    static assert(is(ReturnType!(g) == int));

    G* p;
    alias ReturnType!(p) pg;
    static assert(is(pg == int));

    class C
    {
	int opCall (int i) { return 1;}
    }

    static assert(is(ReturnType!(C) == int));

    C c;
    static assert(is(ReturnType!(c) == int));
}

/***
 * Get the types of the paramters to a function,
 * a pointer to function, or a delegate as a tuple.
 * Example:
 * ---
 * import std.traits;
 * int foo(int, long);
 * void bar(ParameterTypeTuple!(foo));      // declares void bar(int, long);
 * void abc(ParameterTypeTuple!(foo)[1]);   // declares void abc(long);
 * ---
 */
template ParameterTypeTuple(alias dg)
{
    alias ParameterTypeTuple!(typeof(dg)) ParameterTypeTuple;
}

/** ditto */
template ParameterTypeTuple(dg)
{
    static if (is(dg P == function))
	alias P ParameterTypeTuple;
    else static if (is(dg P == delegate))
	alias ParameterTypeTuple!(P) ParameterTypeTuple;
    else static if (is(dg P == P*))
	alias ParameterTypeTuple!(P) ParameterTypeTuple;
    else
	static assert(0, "argument has no parameters");
}


/***
 * Get the types of the fields of a struct or class.
 * This consists of the fields that take up memory space,
 * excluding the hidden fields like the virtual function
 * table pointer.
 */

template FieldTypeTuple(S)
{
    static if (is(S == struct) || is(S == class))
	alias typeof(S.tupleof) FieldTypeTuple;
    else
	static assert(0, "argument is not struct or class");
}


/***
 * Get a $(D_PARAM TypeTuple) of the base class and base interfaces of
 * this class or interface. $(D_PARAM BaseTypeTuple!(Object)) returns
 * the empty type tuple.
 * 
 * Example:
 * ---
 * import std.traits, std.typetuple, std.stdio;
 * interface I { }
 * class A { }
 * class B : A, I { }
 *
 * void main()
 * {
 *     alias BaseTypeTuple!(B) TL;
 *     writeln(typeid(TL));	// prints: (A,I)
 * }
 * ---
 */

template BaseTypeTuple(A)
{
    static if (is(A P == super))
	alias P BaseTypeTuple;
    else
	static assert(0, "argument is not a class or interface");
}

unittest
{
    interface I1 { }
    interface I2 { }
    class A { }
    class C : A, I1, I2 { }

    alias BaseTypeTuple!(C) TL;
    assert(TL.length == 3);
    assert(is (TL[0] == A));
    assert(is (TL[1] == I1));
    assert(is (TL[2] == I2));

    assert(BaseTypeTuple!(Object).length == 0);
}

/**
 * Get a $(D_PARAM TypeTuple) of $(I all) base classes of this class,
 * in decreasing order. Interfaces are not included. $(D_PARAM
 * BaseClassesTuple!(Object)) yields the empty type tuple.
 *
 * Example:
 * ---
 * import std.traits, std.typetuple, std.stdio;
 * interface I { }
 * class A { }
 * class B : A, I { }
 * class C : B { }
 *
 * void main()
 * {
 *     alias BaseClassesTuple!(C) TL;
 *     writeln(typeid(TL));	// prints: (B,A,Object)
 * }
 * ---
 */

template BaseClassesTuple(T)
{
    static if (is(T == Object))
    {
        alias TypeTuple!() BaseClassesTuple;
    }
    static if (is(BaseTypeTuple!(T)[0] == Object))
    {
        alias TypeTuple!(Object) BaseClassesTuple;
    }
    else
    {
        alias TypeTuple!(BaseTypeTuple!(T)[0],
                         BaseClassesTuple!(BaseTypeTuple!(T)[0]))
            BaseClassesTuple;
    }
}

unittest
{
    interface I1 {}
    interface I2 {}
    class B1 {}
    class B2 : B1, I1 {}
    class B3 : B2, I2 {}
    alias BaseClassesTuple!(B3) TL;
    assert(TL.length == 3);
    assert(is (TL[0] == B2));
    assert(is (TL[1] == B1));
    assert(is (TL[2] == Object));
}

/**
 * Get a $(D_PARAM TypeTuple) of $(I all) base classes of $(D_PARAM
 * T), in decreasing order, followed by $(D_PARAM T)'s
 * interfaces. $(D_PARAM TransitiveBaseTypeTuple!(Object)) yields the
 * empty type tuple.
 *
 * Example:
 * ---
 * import std.traits, std.typetuple, std.stdio;
 * interface I { }
 * class A { }
 * class B : A, I { }
 * class C : B { }
 *
 * void main()
 * {
 *     alias TransitiveBaseTypeTuple!(C) TL;
 *     writeln(typeid(TL));	// prints: (B,A,Object,I)
 * }
 * ---
 */

template TransitiveBaseTypeTuple(T)
{
    static if (is(T == Object))
        alias TypeTuple!() TransitiveBaseTypeTuple;
    else
        alias TypeTuple!(BaseClassesTuple!(T),
            BaseTypeTuple!(T)[1 .. $])
            TransitiveBaseTypeTuple;
}

unittest
{
    interface I1 {}
    class B1 {}
    class B2 : B1 {}
    class B3 : B2, I1 {}
    alias TransitiveBaseTypeTuple!(B3) TL;
    assert(TL.length == 4);
    assert(is (TL[0] == B2));
    assert(is (TL[1] == B1));
    assert(is (TL[2] == Object));
    assert(is (TL[3] == I1));

    assert(TransitiveBaseTypeTuple!(Object).length == 0);
}

/**
Get the type that all types can be implicitly converted to. Useful
e.g. in figuring out an array type from a bunch of initializing
values. Returns $(D_PARAM void) if passed an empty list, or if the
types have no common type.

Example:

----
alias CommonType!(int, long, short) X;
assert(is(X == long));
alias CommonType!(int, char[], short) Y;
assert(is(Y == void));
----
*/
template CommonType(T...)
{
    static if (!T.length)
        alias void CommonType;
    else static if (T.length == 1)
        alias T[0] CommonType;
    else static if (is(typeof(true ? T[0] : T[1]) U))
        alias CommonType!(U, T[2 .. $]) CommonType;
    else
        alias void CommonType;
}

unittest
{
    alias CommonType!(int, long, short) X;
    assert(is(X == long));
    alias CommonType!(char[], int, long, short) Y;
    assert(is(Y == void), Y.stringof);
}

/**
 * Returns a tuple with all possible target types of an implicit
 * conversion of a value of type $(D_PARAM T).
 *
 * Important note:
 *
 * The possible targets are computed more conservatively than the D
 * 2.005 compiler does, eliminating all dangerous conversions. For
 * example, $(D_PARAM ImplicitConversionTargets!(double)) does not
 * include $(D_PARAM float).
 */

template ImplicitConversionTargets(T)
{
    static if (is(T == bool))
        alias TypeTuple!(byte, ubyte, short, ushort, int, uint, long, ulong,
            float, double, real, char, wchar, dchar)
            ImplicitConversionTargets;
    else static if (is(T == byte))
        alias TypeTuple!(short, ushort, int, uint, long, ulong,
            float, double, real, char, wchar, dchar)
            ImplicitConversionTargets;
    else static if (is(T == ubyte))
        alias TypeTuple!(short, ushort, int, uint, long, ulong,
            float, double, real, char, wchar, dchar)
            ImplicitConversionTargets;
    else static if (is(T == short))
        alias TypeTuple!(ushort, int, uint, long, ulong,
            float, double, real)
            ImplicitConversionTargets;
    else static if (is(T == ushort))
        alias TypeTuple!(int, uint, long, ulong, float, double, real)
            ImplicitConversionTargets;
    else static if (is(T == int))
        alias TypeTuple!(long, ulong, float, double, real)
            ImplicitConversionTargets;
    else static if (is(T == uint))
        alias TypeTuple!(long, ulong, float, double, real)
            ImplicitConversionTargets;
    else static if (is(T == long))
        alias TypeTuple!(float, double, real)
            ImplicitConversionTargets;
    else static if (is(T == ulong))
        alias TypeTuple!(float, double, real)
            ImplicitConversionTargets;
    else static if (is(T == float))
        alias TypeTuple!(double, real)
            ImplicitConversionTargets;
    else static if (is(T == double))
        alias TypeTuple!(real)
            ImplicitConversionTargets;
    else static if (is(T == char))
        alias TypeTuple!(wchar, dchar, byte, ubyte, short, ushort,
            int, uint, long, ulong, float, double, real)
            ImplicitConversionTargets;
    else static if (is(T == wchar))
        alias TypeTuple!(wchar, dchar, short, ushort, int, uint, long, ulong,
            float, double, real)
            ImplicitConversionTargets;
    else static if (is(T == dchar))
        alias TypeTuple!(wchar, dchar, int, uint, long, ulong,
            float, double, real)
            ImplicitConversionTargets;
    else static if(is(T : Object))
        alias TransitiveBaseTypeTuple!(T) ImplicitConversionTargets;
    else static if (is(T : void*))
        alias TypeTuple!(void*) ImplicitConversionTargets;
    else
        alias TypeTuple!() ImplicitConversionTargets;
}

unittest
{
    assert(is(ImplicitConversionTargets!(double)[0] == real));
}

/**
 * Detect whether T is a built-in integral type
 */

template isIntegral(T)
{
    static const isIntegral = is(T == byte) || is(T == ubyte) || is(T == short)
        || is(T == ushort) || is(T == int) || is(T == uint)
        || is(T == long) || is(T == ulong);
}

/**
 * Detect whether T is a built-in floating point type
 */

template isFloatingPoint(T)
{
    static const isFloatingPoint = is(T == float)
        || is(T == double) || is(T == real);
}

/**
 * Detect whether T is a built-in numeric type
 */

template isNumeric(T)
{
    static const isNumeric = isIntegral!(T) || isFloatingPoint!(T);
}

/**
 * Detect whether T is one of the built-in string types
 */

template isSomeString(T)
{
    static const isSomeString = is(T : const(char[]))
        || is(T : const(wchar[])) || is(T : const(dchar[]));
}

static assert(!isSomeString!(int));
static assert(!isSomeString!(int[]));
static assert(!isSomeString!(byte[]));
static assert(isSomeString!(char[]));
static assert(isSomeString!(dchar[]));
static assert(isSomeString!(string));
static assert(isSomeString!(wstring));
static assert(isSomeString!(dstring));
static assert(isSomeString!(char[4]));

/**
 * Detect whether T is an associative array type
 */

template isAssociativeArray(T)
{
    static const bool isAssociativeArray =
        is(typeof(T.keys)) && is(typeof(T.values));
}

static assert(!isAssociativeArray!(int));
static assert(!isAssociativeArray!(int[]));
static assert(isAssociativeArray!(int[int]));
static assert(isAssociativeArray!(int[string]));
static assert(isAssociativeArray!(invariant(char[5])[int]));

/**
 * Detect whether type T is a static array.
 */
template isStaticArray(T : U[N], U, size_t N)
{
    const bool isStaticArray = true;
}

template isStaticArray(T)
{
    const bool isStaticArray = false;
}

static assert (isStaticArray!(int[51]));
static assert (isStaticArray!(int[][2]));
static assert (isStaticArray!(char[][int][11]));
static assert (!isStaticArray!(const(int)[]));
static assert (!isStaticArray!(invariant(int)[]));
static assert (!isStaticArray!(const(int)[4][]));
static assert (!isStaticArray!(int[]));
static assert (!isStaticArray!(int[char]));
static assert (!isStaticArray!(int[1][]));
static assert (isStaticArray!(invariant char[13u]));
static assert (isStaticArray!(const(real)[1]));
static assert (isStaticArray!(const(real)[1][1]));
static assert (isStaticArray!(typeof("string literal")));
static assert (isStaticArray!(void[0]));
static assert (!isStaticArray!(int[int]));
static assert (!isStaticArray!(int));

/**
 * Detect whether type T is a dynamic array.
 */
template isDynamicArray(T, U = void)
{
    static const isDynamicArray = false;
}

template isDynamicArray(T : U[], U)
{
  static const isDynamicArray = !isStaticArray!(T);
}

static assert(isDynamicArray!(int[]));
static assert(!isDynamicArray!(int[5]));

/**
 * Detect whether type T is an array.
 */
template isArray(T)
{
    static const isArray = isStaticArray!(T) || isDynamicArray!(T);
}

static assert(isArray!(int[]));
static assert(isArray!(int[5]));
static assert(!isArray!(uint));
static assert(!isArray!(uint[uint]));
static assert(isArray!(void[]));


/**
 * Tells whether the tuple T is an expression tuple.
 */
template isExpressionTuple(T ...)
{
    static if (is(void function(T)))
	const bool isExpressionTuple = false;
    else
	const bool isExpressionTuple = true;
}

/**
 * Returns the corresponding unsigned type for T. T must be a numeric
 * integral type, otherwise a compile-time error occurs.
 */

template unsigned(T) {
  static if (is(T == byte)) alias ubyte unsigned;
  else static if (is(T == short)) alias ushort unsigned;
  else static if (is(T == int)) alias uint unsigned;
  else static if (is(T == long)) alias ulong unsigned;
  else static if (is(T == ubyte)) alias ubyte unsigned;
  else static if (is(T == ushort)) alias ushort unsigned;
  else static if (is(T == uint)) alias uint unsigned;
  else static if (is(T == ulong)) alias ulong unsigned;
  else static if(is(T == enum)) 
       static if (T.sizeof == 1) alias ubyte unsigned;
       else static if (T.sizeof == 2) alias ushort unsigned;
       else static if (T.sizeof == 4) alias uint unsigned;
       else static if (T.sizeof == 8) alias ulong unsigned;
  else static assert(false, "Type " ~ T.stringof
                     ~ " does not have an unsigned counterpart");
}

unittest
{
    alias unsigned!(int) U;
    assert(is(U == uint));
}


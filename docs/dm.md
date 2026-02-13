# Usage

The parser has four modes which are automatically selected by how you format your code. It's generally a good idea to stick to the multiline modes unless you're used to the older baystation DM bot syntax.

Use of `#include`, `##`, or rsc files is not allowed and will result in code exec failing. Memory usage and execution time are also limited, and your command will fail if it exceeds either limit.

In Single-Line modes, there are three blocks of code that can be defined:

```
World block

/proc/dm_exec()
    Proc block
    Proc block

    ENC_OUT(Log block)
    ENC_OUT(Log block)
```

## Multi-Line, Implicit Proc

    !dm ```js
    my code
    ```

All code is placed into a proc and executed. Wrench will attempt to detect your indentation, but may fail if indentation is inconsistent.

## Multi-Line, Explicit Proc

    !dm ```
    my code
    MAIN
        more code
    ```

Code is not modified and is run as-is. Either `/proc/main()` or `MAIN` can be used, though not both.

## Single-Line, Bisect

    !dm my code; my code;; some var

or

    !dm `my code; my code;; some var`

Triggers if exactly one `;;` is present. Behaves like Baystation's old DM bot.

World block: All lines before `;;;`, if any.

Proc block: All lines before `;;`.

Log block: All lines after `;;`, with each `;`-delineated section split into its own log output.

## Single-Line, Interleave

    !dm foo;; bar; baz;; qux;

or

    !dm `foo;; bar; baz;; qux;`

Unlike bisect, this mode lets you put log lines between proc lines at the cost of requiring every line to have `;;` or `;` as appropriate. World lines will always be put at the start regardless of their position within the string, though their order will be maintained.

World block: All lines that end in `;;;`.

Proc block: All lines that end in `;;`.

Log block: All lines that end in `;`.

# Examples

```
# printing some values
!dm 2+2; 4+4
```

```
# defining a var
!dm var/foo = 2;; foo
```

```
# defining a proc
!dm /proc/foo() { return "bar"; };;; foo()
```

Multi-line, explicit proc:

    !dm ```
    /proc/foo()
        return "bar"

    /proc/main()
        OUT << foo()
    ```

Multi-line, implicit proc:

    !dm ```
    var/foo = "bar"
    OUT << foo
    ```

# Automatic benchmarking
Wrench provides macros for comparing execution speed of snippets. These macros will automatically do multiple runs and calculate statistical variance for runs to account for DM and host execution noise. Numbers from runs are not comparable across bots, and may not be comparable across runs if there is a significant amount of time between them.

## Benchmarking one thing
If you only want to see the cost of a single snippet, you can use the following syntax instead of using the full bench suite:
```
TICKBENCH("my bench", some code)
```
If you want to test multiple things, use of `TICKBENCH` is discouraged.

## Benchmarking multiple things
To compare multiple snippets to each other, do:
```
BEGIN_BENCH(phase count)
    BENCH_BLOCK("block snippet name 1")
        code
    BENCH_BLOCK("block snippet name 2")
        code
    BENCH_EXPR("inline snippet name 1", code)
    ...
END_BENCH
```
Usage notes:
- `BENCH_BLOCK` and `BENCH_EXPR` can be used within the same bench block, and they generate comparable code.
- The number passed to `BEGIN_BENCH` must match the number of `BENCH_PHASE` calls within it.
- Regular code may be inserted within `BEGIN_BENCH` if you want to declare a variable or initialize something before each group of runs.
- Snippets are repeatedly run until they consume an entire tick.
- `sleep(1)` is inserted between phases.
- Phases are run in the order specified.
- By default, the bench block is sampled 5 times. Different sample counts can be specified using `BEGIN_BENCH_WITH_SAMPLES(phase count, samples)`, but mind that higher sample counts may run into execution time limits.
- Only one bench block may exist in a scope. If you need more than one, wrap it in a proc or a do-while(FALSE).

## Advanced benchmarking

The benchmarking macros have a non-trivial amount of overhead. Normally this is not significant, but it can become significant if benchmarking extremely simple code like single math operators. These macros exist to reduce overhead in benchmarking at cost of higher usage complexity:

- `BENCH_PHASE_CHUNKED(name, chunk size, code)`
- `BENCH_PHASE_HUNDRED(name, code)`
- `BENCH_PHASE_THOUSAND(name, code)`

`HUNDRED` and `THOUSAND` are functionally fixed values for `CHUNKED`, but with even lower overhead. These internally unroll your code, so they may cause the compiler to exceed the maximum instruction count for a proc if overused. All three macros will run multiple passes of code per tick usage check, so they are vulnerable to overshoot if misused. Wrench will attempt to detect overshoot and will report if it occurs, but this isn't guaranteed.

The reduced-overhead variants are currently not available for `BENCH_BLOCK()`.

# Pre-defined variables
In addition to the DM built-in globals, the following vars are also defined for convenience:
- `cardinal` (list of cardinal directions)
- `cornerdirs` (list of diagonal dirs)
- `alldirs` (list of all dirs excluding UP and DOWN)
- `reverse_dir` (list of reverse of directions, use like `reverse_dir[some_dir]`)

# Pre-defined Macros
The following macros are available:
- `LOG`, `WLOG`, `OUT` (Alias for `world.log`)
- `MAIN` (Replacement for `/proc/main()`, indentation still required)
- `INSULATE(EXPR)` (Run EXPR, preventing runtimes from interrupting execution -- try-catch in a can)
- `TAG_OUT(A, B)` (Writes `A: B` to output - `TAG_OUT(foo, 2+2)` would write `foo: 4`)
- `ENC_OUT(A)` (Writes `A => <value of A>` to output, classifying A's var type and formatting it for display - `ENC_OUT(list())` becomes `list() => []`)
- `VAR_OUT(A)` (Alias for `ENC_OUT(A)`)
- `INS_OUT(A)` (Similar to ENC_OUT, but won't interrupt execution if A runtimes)
- `WORLD(X,Y,Z)` (Create a world of size X,Y,Z -- must be outside of a proc)
- `PROTOTYPE(ref)` (Get the internal BYOND typeid for a ref)
- `BOOL(X)` (Alternative to `!!(X)`)
- `PASS(X)` (Mark a var as used without actually doing anything)
- `LAZYINITLIST(L)`, `UNSETEMPTY(L)`, `LAZYREMOVE(L, I)`, `LAZYADD(L, I)`, `LAZYACCESS(L, I)`, `LAZYLEN(L)`, `LAZYCLEARLIST(L)`, `LAZYSET(L, K, V)`, `LAZYPICK(L, DEFAULT)`
- `DECODE_PROTOTYPE(typeid)` (Attempt to fetch the prototype name of the passed object)


# Pre-defined Functions
The following functions are available:
- `enc(data)` (Alias for `json_encode(data)`)
- `dec(data)` (Alias for `json_decode(data)`)
- `dir2text(dir)` (Convert a direction bitfield into human-readable text)
- `seq(lo, hi, st=1)` (Generate a list of numbers from lo to hi, in steps of st)
- `wrench_decode_prototype(typeid)` (Decode an internal prototype ID into a named prototype)

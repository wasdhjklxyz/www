# title

## intro

### motivation

Right before shutting my computer off for the night I checked my email and saw that a role I'd applied to at like 3am a couple nights ago had gotten back to me - automated, after some filter I assume - with a link to a technical assessment. I'd never done one of these, so I looked up the company and... HLY SHIT

It was a "Low-Level C++ Software Engineer" role at a huge finance shop, and between friends and the internet I knew these places have notoriously brutal interviews, so I was stressin. But the pay was stupid good, so fuck it - I started reading about what to expect, and fell down into this whole world of high-frequency trading systems written in C++. One talk I half-watched ("Why C++ Wins in Finance") pitched it as *total control*: your cache lines, your NUMA layout, your whole data and execution path, and the guarantee that what you compile is what actually runs ([Juan Alday, CppCon](https://youtu.be/InLxLEqg_fs)).

I was never about the LeetCode / dick measuring contest thing - it's missing the craft and the fun of actually building systems. That take is also 100% cope because I've never been the best at data structures and algorithms. If you're a recruiter reading this, ignore the last two sentences :)

Anyway I went to bed watching Fedor Pikus's CppCon 2017 talk, ["C++ atomics, from basic to advanced. What do they really do?"](https://www.youtube.com/watch?v=ZQFzMfHIxng), figuring atomics are the gateway into understanding multithreaded systems properly. It was great. I got to the memory-ordering part before I passed out, woke up wanting to write *this exact post*, and here we are.

### previous exposure

I'd seen atomics show up in multithreaded code and signal handling, and I always associated the word with a single indivisible unit - an instruction, an "atom." I never knew *why* it worked. I think I just assumed reads and writes got translated into some special instructions that update state across all cores, that it was expensive, and that's why you don't use atomics for everything.

My actual prior usage was tracking how many tasks were running across threads (a garbage queue, nowhere near a *fast* one) and a probably-pointless flag for whether a loop should keep running.

### what this is

This is **not** going to be a regurgitation of the docs. I'm starting from the problem atomics actually solve and building them up from the hardware - x86-64 specifically - until we hit C++'s `std::atomic` and `std::memory_order` and can see exactly what they compile to. The thesis, if you want one up front:

> an atomic operation gives you two separate things - **atomicity** (the operation is indivisible) and **ordering** (how it constrains the memory operations around it). x86 hands you a ton of the ordering basically for free, which is exactly why it's a trap.

Everything below runs on my machine: an Intel i7-9700K (8 cores, no SMT), compiled with g++ (GCC) 15.2.0.

## RMW & MESI

### a read-modify-write in one operation???

An atomic type does its thing (defined properly later) as a single indivisible operation. [cppreference](https://en.cppreference.com/cpp/atomic/atomic) basically promises that if one thread writes an atomic object while another reads it, the behavior is well-defined - no UB, no torn values.

There are three kinds of atomic operation:

1. **store** - a write
2. **load** - a read
3. **read-modify-write (RMW)** - read *and* write, as one operation

That third one stopped me. How the fuck does the CPU read a value, modify it, and write it back as *one* indivisible step? [Wikipedia](https://en.wikipedia.org/wiki/Read%E2%80%93modify%E2%80%93write) describes RMW (test-and-set, fetch-and-add, compare-and-swap) as reading a location and writing a new value in one atomic shot - used everywhere in mutexes, semaphores, and lock-free code. Cool, *what does that mean physically?*

The most useful thing I found was a [Stack Overflow answer](https://stackoverflow.com/a/43837970) quoting Linus Torvalds: atomic instructions act as if they bypass the store buffer - they likely still use it, but they drain it and the pipeline around the operation and hold a **lock on the cache line** for the duration of the load-through-store, so nobody else can touch that line and nobody can peek at the in-flight store buffer state.

That "lock on the cache line" is the thread to pull. I thought atomics were *lock-free* - so what's this lock? It reads like the CPU prevents other cores from touching the same cache line for the length of the operation. So let's look at how caches stay consistent.

### MESI

The key idea is **coherence** - specifically cache coherence on a multiprocessor. The whole point: two cores must never see different values for the same shared line.

The classic protocol is **MESI**, where every cache line on every core sits in one of four states:

- **M (Modified)** - this core has the *only* copy and it's dirty (differs from RAM). Must be written back before anyone else reads it.
- **E (Exclusive)** - only this core has it, and it's clean (matches RAM).
- **S (Shared)** - multiple cores have it, all clean.
- **I (Invalid)** - stale; some other core modified it, this copy can't be used.

It's a state machine driven by two things: the core's own read/write requests, and snooped requests coming across the interconnect from other cores. Roughly: reading a line you don't have moves you `I → E/S`; wanting to write moves you `→ M` and invalidates everyone else's copy; getting snooped by another core's write knocks you `→ I` ([MESI on Wikipedia](https://en.wikipedia.org/wiki/MESI_protocol), the real state machine has more edges than this).

The one-liner that matters: **before a core can write a line, every other core has to invalidate its copy.**

![MESI / MOESI state transitions](./Diagrama_MESI.gif)

> **side note - x86 actually uses MOESI.** The AMD64 manual (vol 2, system programming) specifies **MOESI**, which adds an **Owned (O)** state. Owned is like Modified-but-shareable: the owning core holds the authoritative *dirty* copy and can hand it straight to other cores' reads **without** first writing back to RAM (so RAM is allowed to be stale). Everyone else holding the line sits in S, and only one core can be the O owner. The payoff is dirty data gets shared core-to-core without a round trip to memory. (And yes, I kept writing "MOSEI" in my notes. It's MOESI.)

### did MESI fail us?

So if coherence makes a single core's RMW look atomic - `x++` is a read-modify-write - then surely two threads both doing `x++` are fine, right? MESI's got us? Let's test it: two threads, each incrementing a shared `int` a million times, print at the end. Should be 2,000,000.

```cpp
// atomic.cpp
#include <print>
#include <thread>

int x = 0;

void worker(void) {
  for (int i = 0; i < 1000000; i++)
    x++;
}

int main(void) {
  std::thread t1(worker);
  std::thread t2(worker);
  t1.join();
  t2.join();
  std::print("{}\n", x);
  return 0;
}
```

```sh
$ g++ -O0 --std=c++23 atomic.cpp
$ ./a.out
1047020
$ ./a.out
1006689
$ ./a.out
1046267
$ ./a.out
1046823
```
> Note that I had to compile with -O0 here since the compiler knew what I wanted to do and optimized it for me.

...uh why is MESI not "working?"

Because **MESI guarantees coherence, not atomicity of a read-modify-write.** Coherence means you never read a *stale* line - it says nothing about preventing two cores from interleaving a read-modify-write on the same value. `x++` is really *load → add → store*, three steps (even when it's a single `inc [mem]` instruction, the microarchitecture does a read phase then a write phase - it's not indivisible). The race MESI can't stop:

```
core 1: load x = 0  -> reg = 0
core 2: load x = 0  -> reg = 0     # both read the same value
core 1: reg+1 = 1, store x = 1     # core 1 -> M, invalidates core 2's line
core 2: ACKs the invalidate        # core 2's line is now I... but reg is still 0
core 2: store reg+1 = 1 -> x = 1   # writes 1 from its stale register
```

This is the crux: **the invalidation hits the cache line, not the register.** Core 2 already pulled `0` into a register and its ALU already computed `1` on that old value. When the invalidate lands, core 2's *cache line* goes Invalid, but nothing reaches back and fixes the `0` sitting in its register. So core 2 happily writes its stale result back. One increment, gone.

The write wasn't lost because coherence broke - coherence did its job. It was lost because MESI has **no jurisdiction over a value that's already been pulled into a register.** What we actually need is to stop core 2 from even loading until core 1's entire read-modify-write is done.

### so how do we sync this

The AMD64 manual (vol 2, §7.x on locked ops and the write buffer) spells out that a `LOCK`-prefixed instruction forces all prior reads/writes to memory to complete and itself to complete before later writes - locked writes are never buffered, though they're still cacheable. It also lists the events that force the processor to drain its write buffer to memory: `SFENCE`, serializing instructions, I/O instructions, **locked instructions**, interrupts/exceptions, and uncacheable reads.

Quick definition since the manual is loose with the word: "memory" here doesn't mean DRAM, it means **globally visible** - committed far enough into the coherent cache hierarchy that every core can see it. The slow part isn't reaching RAM, it's *stalling the pipeline to drain the store buffer.*

That store buffer is the thing to understand. Writes land there before they hit the coherent cache - same idea as buffering a string before you flush it to a socket. Writing to memory is slow (relative to a register, even L1 isn't free), so the core buffers stores and drains them later, on one of those trigger events above.

But here's the part I had to get straight: We need one core to own that cache line through the **entire** RMW so no other core can sneak a valid load into the middle.

That's exactly what the `LOCK` prefix does. ([felixcloutier on `lock`](https://www.felixcloutier.com/x86/lock).)

> While I'm here - `XADD` looked promising. It exchanges dest and src, then writes their sum into dest ([felixcloutier](https://www.felixcloutier.com/x86/xadd)). One instruction, so it's atomic, right? Nope. One *instruction* isn't one *atomic* operation - `xadd` still has a read phase and a write phase another core can interleave between. You need the `LOCK` prefix on it. We'll see this.

Instead of editing `-S` output by hand, let's stretch `x++` into inline asm as our baseline:

```cpp
// atomic_asm.cpp
void worker(void) {
  for (int i = 0; i < 1000000; i++) {
    asm volatile("inc %0" : : "m"(x));
  }
}
```

```sh
$ g++ -g -O1 --std=c++23 atomic_asm.cpp
$ ./a.out
1040095
$ ./a.out
1009633
$ ./a.out
1011759
```

Still wrong - over a million, nowhere near 2M. Now add one word:

```diff
 void worker(void) {
   for (int i = 0; i < 1000000; i++) {
-    asm volatile("inc %0" : : "m"(x));
+    asm volatile("lock inc %0" : : "m"(x));
   }
 }
```

```sh
$ g++ -g -O1 --std=c++23 atomic_asm.cpp
$ ./a.out
2000000
$ ./a.out
2000000
$ ./a.out
2000000
```

Magic. And the disassembly diff is *literally one word* (`-g -O1` for a clean 1:1 loop):

```
BEFORE (no lock):                          AFTER (lock):
  inc    DWORD PTR [rdx]                      lock inc DWORD PTR [rdx]
  sub    eax,0x1                              sub    eax,0x1
  jne    ...                                  jne    ...
```

That's the whole difference between a race and a correct program.

So now we can define an atomic operation - one that reads, optionally modifies, and writes as a single indivisible step, guaranteeing:

- nobody reads a half-written value (no tearing)
- no lost updates (no two cores RMW the same value at once)
- once it completes, every core sees the new value

The `LOCK` prefix is what buys this. It asserts the processor's `LOCK#` signal for the duration of the instruction, turning it atomic. It can only prefix a specific set of memory-destination instructions - `ADD`, `INC`, `DEC`, `XADD`, `XCHG`, `CMPXCHG`, and friends ([instruction list](https://asm-docs.microagi.org/x86/lock.html)).

How the lock itself works has history. On the 486, `LOCK` asserted a literal **bus lock** - it locked the whole memory bus for the operation, which was a massive performance hit because *everything* touching memory had to wait. Starting with the Pentium Pro / P6, it became a **cache lock**: the core just takes exclusive ownership of the affected cache line (via the coherence protocol - line goes M/E) for the single instruction, no global bus lock needed. The bus lock only comes back if the locked memory is uncacheable or the access straddles a cache-line boundary (a "split lock"), both of which are rare ([Intel scalable-locks article, archived](https://web.archive.org/web/20090227095314/http://software.intel.com/en-us/articles/implementing-scalable-atomic-locks-for-multi-core-intel-em64t-and-ia32-architectures)). The `LOCK#` signal itself isn't a register or a bit - it's a physical signal on the interconnect ([SO](https://stackoverflow.com/a/65681049)).

**One correction to a thing I believed going in:** I assumed this meant atomics "aren't really lock-free, the lock is just in hardware." That's wrong, and it's a common confusion of two different meanings of "lock." **Lock-free is a progress guarantee** - it means suspending any single thread can never stop the others from making progress. The `LOCK` prefix holds a cache line for *one bounded instruction* that can't be interrupted mid-flight, so no thread can ever block another indefinitely with it. That makes `lock xadd` genuinely lock-free. A **mutex** is *not* lock-free: a thread that grabs it and gets descheduled stalls everyone waiting. So "lock-free" doesn't mean "no serialization ever happens" - it means the serialization is bounded and non-blocking. The `LOCK` prefix being spelled *lock* is a false friend.

## std::atomic

Now that we've hand-rolled a (probably crap) atomic counter, let's see how C++ does it.

`std::atomic<T>` is an atomic type: concurrent reads/writes are well-defined, and you can additionally control how surrounding non-atomic memory is ordered via `std::memory_order` (which is going to connect straight back to those fence instructions - later). cppreference also notes the standard requires every RMW to read the latest value in the modification order, i.e. **RMWs always see the freshest value** ([cppreference](https://en.cppreference.com/cpp/atomic/atomic)).

> `std::atomic<T>` works on any *trivially copyable* `T` - basically a flat block of bytes you could `memcpy`. Mostly scalars, but trivially-copyable classes count too. I won't go down the move-semantics hole here ([TriviallyCopyable](https://en.cppreference.com/cpp/named_req/TriviallyCopyable)).

### a quick init gotcha

Pikus mentioned not to write `std::atomic_int x = 0;`. He didn't say why, so - tangent. If you set `-std=c++11`:

```
error: use of deleted function 'std::atomic<int>::atomic(const std::atomic<int>&)'
    5 | std::atomic_int x = 0;
```

`std::atomic` has a deleted copy constructor (atomics aren't copyable). `x = 0` is *copy*-initialization: it builds a temporary `atomic_int` from `0` via the converting constructor, then wants to copy-construct `x` from it - and that copy ctor is deleted. C++17's guaranteed copy elision makes `= 0` compile now, but the idiom is **direct-initialization**, which calls the converting ctor straight, no copy:

```cpp
std::atomic_int x{};   // or x{0}
```

And `++` is overloaded but I'll be explicit with `fetch_add`:

```cpp
// atomic_std.cpp
#include <atomic>
#include <print>
#include <thread>

std::atomic_int x{};

void worker(void) {
  for (int i = 0; i < 1000000; i++) {
    x.fetch_add(1);
  }
}

int main(void) {
  std::thread t1(worker);
  std::thread t2(worker);
  t1.join();
  t2.join();
  std::print("{}\n", x.load());     // .load() to read the value out
  return 0;
}
```

```sh
$ g++ -g -O1 -std=c++23 atomic_std.cpp
$ ./a.out
2000000
```

Now the disassembly:

```
=> mov    eax,0xf4240
   lea    rdx,[rip+0x15ba0]        # <x>
   nop    DWORD PTR [rax+0x0]
   lock add DWORD PTR [rdx],0x1
   sub    eax,0x1
   jne    ...
```

Same `lock` prefix. The standard library picked `add` over `inc`, but it's the identical hardware primitive we hand-rolled. If I switch my asm to `lock add` too, the loops are line-for-line identical.

That `nop DWORD PTR [rax+0x0]` before the loop isn't doing anything - it's a multi-byte NOP the compiler inserts as **alignment padding** to put the loop head on a 16-byte boundary so it sits cleanly in an instruction-cache line. Pure padding, never meaningfully executed.

So: the most basic multithreaded counter is *just the lock prefix*, and `std::atomic` is the portable wrapper that emits it for you. That's the tip of the iceberg, but it's a real foundation.

## benchmarks

If `lock` is the whole story for the counter, let's measure it. Four cases - the first two are the **wrong** answers (no locking), included on purpose:

```cpp
#include <atomic>
#include <benchmark/benchmark.h>
#include <thread>

#define M_BENCHMARK(name, t, e)                                                \
  static void _##name(benchmark::State &s) {                                   \
    for (auto _ : s) {                                                         \
      t x{0};                                                                  \
      auto w = [&] {                                                           \
        for (int i = 0; i < 1000000; i++)                                      \
          e;                                                                   \
      };                                                                       \
      std::thread t1(w), t2(w);                                                \
      t1.join(); t2.join();                                                    \
      benchmark::DoNotOptimize(x);                                             \
    }                                                                          \
  }                                                                            \
  BENCHMARK(_##name);

M_BENCHMARK(mesi_naieve,     int,             x++);
M_BENCHMARK(atomic_asm,      int,             asm volatile("add %1, %0" : "+m"(x) : "r"(1)));
M_BENCHMARK(atomic_asm_lock, int,             asm volatile("lock add %1, %0" : "+m"(x) : "r"(1)));
M_BENCHMARK(atomic_std,      std::atomic_int, x.fetch_add(1));

BENCHMARK_MAIN();
```

```
-----------------------------------------------------------
Benchmark                 Time             CPU   Iterations
-----------------------------------------------------------
_mesi_naieve        2662894 ns        46787 ns         1000
_atomic_asm         2667907 ns        48242 ns         1000
_atomic_asm_lock   40245873 ns        65398 ns          100
_atomic_std        40933299 ns        65948 ns          100
```

(Wall times bounce run-to-run because CPU frequency scaling is on - the *relative* picture is stable, and the correctness is dead consistent.) Three things fall out:

**1. `std::atomic` matches the hand-rolled `lock add` within noise.** The abstraction costs nothing - it's the same instruction.

**2. The unlocked versions are ~15× faster - but not because they have "zero coherence overhead."** That line was in my notes and it's wrong. The cache line is contended either way; there's coherence traffic regardless. The real difference is what the core is *allowed to do* with it. Without `lock`, a store can sit in the store buffer and the core pipelines straight into the next iteration (reading its own buffered value via store-forwarding) - it never has to wait for each increment to become globally visible. With `lock`, every single increment must be globally visible before the next instruction can retire, so the core can't pipeline through it - it's a lockstep, one-at-a-time grind. The lock converts a pipelined burst into a synchronous round-trip per op. And the *same* buffering + non-atomicity that makes the unlocked version fast is exactly what makes it lose ~half the counts.

**3. Look at the wall-time vs CPU-time split.** The locked cases show ~40ms wall but only ~60µs CPU. The cores aren't *busy* during those 40ms - they're **stalled, waiting for cache-line ownership.** That gap is MESI coherence latency made into a number: the cores spend their time in line, not computing.

## memory ordering

I've hyped this up the whole post, so it gets its own section.

First, terms. **Program order** is the order operations appear in your source - what you *wrote*. The CPU and the memory model don't promise to execute or *make visible* memory operations in that order. (Note: "program order" and "weak/strong ordering" are different things - program order is the source order; weak vs strong describes the memory model's *reordering rules*. x86 is **strongly** ordered - it's a TSO machine, more on that in a sec.)

We already saw a flavor of disorder in the unsynchronized counter. The deeper version: on a multicore machine, one thread can observe another thread's writes happening in a *different order* than they were issued - and different reader threads can even disagree with each other.

The mechanism is the **store buffer** again. Stores land in a per-core FIFO before they reach the coherent cache; the issuing core reads its own buffered writes (store-forwarding), but other cores can't see them until they drain. So a store you "did" can be invisible to everyone else for a while.

### the SB litmus test

The cleanest demonstration is **SB (store buffering)**, straight out of the [x86-TSO paper](https://www.cl.cam.ac.uk/~pes20/weakmemory/cacm.pdf) (Sewell et al.). Two locations, both 0:

```
# Proc 0          # Proc 1
MOV [x] <- 1      MOV [y] <- 1
MOV EAX <- [y]    MOV EBX <- [x]
```

Under sequential consistency, `EAX == 0 && EBX == 0` is **impossible** - one store must come first, so at least one load should see a 1. But on real x86 it's observable: both stores sit in their respective store buffers while both loads go to memory and read stale zeros. This is "relaxed-memory behavior," and on x86 it's the *one* reorder TSO permits - **StoreLoad** (a store followed by a load to a different address). C++ version:

```cpp
#include <print>
#include <thread>

int x = 0, y = 0;
int eax = -1, ebx = -1;

void p0(void) { x = 1; eax = y; }
void p1(void) { y = 1; ebx = x; }

int main(void) {
  int i = 0;
  while (1) {
    x = y = 0;
    eax = ebx = -1;
    std::thread t0(p0), t1(p1);
    t0.join(); t1.join();
    i++;
    if (eax == 0 && ebx == 0) break;
  }
  std::print("found after {} iterations: eax={} ebx={}\n", i, eax, ebx);
  return 0;
}
```

> **important footnote:** this program is technically **undefined behavior** - `x` and `y` are plain `int`s touched by two threads with no atomic operation, which is a data race in the C++ model. `g++ -fsanitize=thread` will flag it. It *works* here purely because of how x86 lowers plain loads/stores. I'm keeping it because it's the clearest possible illustration, but the standards-correct way to write SB is with relaxed atomics for the shared locations plus a fence (shown below).

I ran it with SMT disabled (so the two threads land on genuinely separate physical cores, each with its own store buffer - the 9700K has no SMT anyway, so this is free). Across three runs it took **98005, 570063, and 930213** iterations to catch it. Random, but it absolutely happens. The play-by-play:

1. `p0` does `x = 1` - that write goes into core 0's **store buffer**, not memory.
2. `p0` reads `y` - core 1's `y = 1` is still sitting in *core 1's* store buffer, so core 0 reads `y = 0` from memory.
3. Symmetrically, core 1 reads `x = 0`.
4. Both buffers drain *afterward*. Final state: `EAX = 0, EBX = 0`. wtf.

![store buffer: writes sit in per-core buffers before reaching memory - figures 1–5](./store-buffer-1-5.png)

### fixing it with a fence

The manual's line is that when ordering must be strictly enforced, you use barrier instructions - `LFENCE`, `SFENCE`, `MFENCE` - to force memory ops to proceed in program order. [`MFENCE`](https://www.felixcloutier.com/x86/mfence) specifically serializes *all* loads and stores: everything before it becomes globally visible before anything after it. These are "memory barriers" / "fences," a [standard concurrency primitive](https://en.wikipedia.org/wiki/Memory_barrier). (`SERIALIZE`, `CPUID`, `IRET` are also serializing, but they're heavier - the fences are the cheap, targeted option.)

The fix: drop an `MFENCE` between the store and the load on each thread, so the store buffer drains before the load reads.

```diff
 void p0(void) {
   x = 1;
+  asm volatile("mfence" ::: "memory");
   eax = y;
 }
```

(The `"memory"` clobber is load-bearing too - it's a *compiler* barrier telling gcc not to reorder the load above the asm. The `mfence` is the *hardware* barrier. You need both.) Disassembly confirms the `mfence` lands right after `mov DWORD PTR [rax], 0x1`. I left it looping for **6+ minutes** - the SB state never showed up again.

### the std::atomic equivalent

`std::memory_order` is how you express all this portably - it specifies how regular and atomic accesses get ordered around an atomic operation ([cppreference](https://en.cppreference.com/cpp/atomic/memory_order)). The 1:1 equivalent of our bare `mfence` is a standalone fence:

```diff
 void p0(void) {
   x = 1;
-  asm volatile("mfence" ::: "memory");
+  std::atomic_thread_fence(std::memory_order_seq_cst);
   eax = y;
 }
```

(The fully standards-clean version also makes `x`/`y` relaxed atomics so there's no data race: `x.store(1, relaxed); std::atomic_thread_fence(seq_cst); eax = y.load(relaxed);` - relaxed kills the UB, the fence does the StoreLoad ordering.)

Here's the interesting bit - the disassembly of the `seq_cst` fence:

```
   mov    DWORD PTR [rax],0x1
   lock or QWORD PTR [rsp],0x0
   ...
```

It's not an `mfence` - it's a `lock or` of zero into the top of the stack. That's a **dummy locked no-op**: `or [rsp], 0` changes nothing, but the `LOCK` prefix triggers the full store-buffer drain and StoreLoad barrier we need. gcc picks this because on most microarchitectures a dummy locked op is *cheaper* than `mfence` while giving the same StoreLoad ordering. (`lock` can only prefix specific instructions, and `or` is one of the cheapest.)

### the climax: release / acquire

`seq_cst` is the sledgehammer - a real barrier instruction, real cost. But most synchronization doesn't need a global total order; it needs *pairwise* ordering between one writer and one reader. That's **release/acquire**, and the canonical example is message passing: a producer fills a payload, flips a flag; a consumer waits on the flag, then reads the payload.

```cpp
#include <atomic>
#include <print>
#include <thread>

int data = 0;                        // plain payload
std::atomic_bool ready{false};       // the flag

void producer(void) {
  data = 42;                                       // (1) write payload
  ready.store(true, std::memory_order_release);    // (2) release
}
void consumer(void) {
  while (!ready.load(std::memory_order_acquire))   // (3) acquire
    ;
  std::print("{}\n", data);                        // guaranteed 42
}
```

The guarantee comes from a **happens-before chain**: `(1)` is sequenced-before the release store `(2)` in program order; the release store *synchronizes-with* the acquire load `(3)` because they're the same atomic and the load reads what the store wrote; `(3)` is sequenced-before the read of `data`. Chain it together and `data = 42` *happens-before* the consumer's read. No `mfence`, no `seq_cst`, no torn read.

Now disassemble it. The release store is a plain `mov BYTE PTR ready[rip], 1`. The acquire load is a plain `movzx` in the spin loop. **No `lock`, no `mfence` - nothing extra.** That's what "free on x86" means: TSO already gives you store-release and load-acquire semantics for plain `mov`s, so the ordering annotation costs *zero* instructions. Contrast that with the `seq_cst` fence, which cost a `lock or` - same header, completely different price depending on which reorder you're fighting.

One honesty note: on x86 you **can't make this demo fail at runtime** even with `relaxed` instead of acquire/release - TSO won't let the consumer observe `data == 0`. The proof that the ordering matters is twofold: the asm shows it's free, and the *portability* argument - on a weakly-ordered machine like ARM, downgrading to `relaxed` here genuinely breaks, which is the entire reason the annotation exists (might run an ARM version as a sequel).

## the ordering ladder

So `std::memory_order` isn't one knob, it's a ladder of strength-vs-cost. The ones I actually used, weakest to strongest:

| ordering | guarantees | cost on x86 |
|---|---|---|
| `relaxed` | atomicity only, no ordering | cheapest - used in the counter, where `fetch_add` doesn't need ordering to be correct |
| `acquire` / `release` | pairwise happens-before between a release and the acquire that reads it | **free** - plain `mov`s |
| `seq_cst` | a single total order all threads agree on (the default) | costs a StoreLoad barrier (`lock or` / `mfence`) |

There's also `consume`, but skip it: it's deprecated in C++26 and every real compiler just promotes it to `acquire` because the dependency tracking it specified was never implemented correctly. ([full list, if you want the rest](https://en.cppreference.com/cpp/atomic/memory_order).)

## conclusion

Pulling the whole thread together:

- **Atomicity and ordering are two different things.** Atomicity is the `LOCK` prefix - bounded, exclusive ownership of a cache line through an entire read-modify-write, so no update is lost and no value is torn. Ordering is a *separate* axis: how an operation constrains the memory accesses around it.
- **x86 (TSO) hands you most of the ordering for free, and that's a trap.** Store-release and load-acquire are just plain `mov`s here; the only reorder the hardware permits is StoreLoad, which a single fence fixes. The danger is that code which is subtly wrong under the C++ memory model still *runs correctly on your x86 box* - and then explodes on ARM. The annotations aren't decoration; they're what makes the code portable and what tells the compiler the truth about your intent.
- **`std::atomic` is the portable abstraction over both.** It emits the `LOCK` prefix for atomicity and exactly the barriers (often zero, on x86) your chosen `memory_order` requires. We watched it compile to the same `lock add` and the same fences we hand-rolled.
- **"Lock-free" is a progress guarantee, not "no serialization."** `lock xadd` is lock-free - its serialization is bounded and can't block other threads indefinitely. A mutex isn't, because a suspended lock-holder stalls everyone. That's the real distinction behind "atomics are faster than a mutex," not "no locks anywhere."

I assume that this interview wants me to know how this works underneath. Now I do - and honestly the rabbit hole was the fun part.

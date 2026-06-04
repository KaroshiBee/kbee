# Base-$N$ algorithm with $N-1$ inputs (carry-free digit sums)

This document describes a base-$N$, fixed-width “digit-extraction + accumulation”
algorithm for $N-1$ inputs under a key constraint:

- Each input digit is restricted to ${0,1}$.

With $N-1$ such inputs, each digit-position sum is in ${0,\\dots,N-1}$ and
there is **no inter-digit carry**. That makes the digit-sum stream directly
usable as a per-digit classifier.

The primary outputs are four derived digitwise boolean-like functions, defined
from the per-position digit-sum $s_k$:

- **NOR**: $s_k = 0$
- **AND**: $s_k = N-1$
- **XOR**: $s_k$ is odd
- **XNOR**: $s_k$ is even

The mathematical operations used in the algorithm consist only of:

- addition and subtraction
- multiplying by a fixed constant
- determining if a quantity is less than one of a set of fixed constants

This means that the algorithm can be implemented in a wide variety of contexts,
including using low-power analogue circuits that can implement these
mathematical operations using voltage sums/diffs/gains/filtering.

The output functions produce values of base-$N$ numbers, of the same fixed-width,
that also satisfy the main constraint:

- Each output digit is, by construction, restricted to ${0,1}$.

This means that the outputs can be used as inputs to subsequent instances of
this algorithm without further transformation, so larger circuits can be built
by composing multiple instances.

Please also note that NOR is a universal gate and so this algorithm could
implement any other standard gate or combination of gates.

We present the general base-$N$ algorithm first, then two worked examples:

- base-3, $W=8$ (the current kbee setting)
- base-4, $W=8$ (3 inputs; demonstrates the general-$N$ pattern)

______________________________________________________________________

## 1. Model and notation

- Base: $N > 2$
- Width: $W \\ge 1$
- Number of inputs: $M = N-1$

Each input $x^{(i)}$ for $i\\in{1,\\dots,M}$ is a base-$N$ number with digits
restricted to ${0,1}$:

$$
x^{(i)} = \\sum\_{k=0}^{W-1} x^{(i)}\_k , N^k,\\quad x^{(i)}\_k \\in {0,1}.
$$

Define the per-position digit-sum:

$$
s_k = \\sum\_{i=1}^{M} x^{(i)}\_k \\in {0,1,\\dots,M} = {0,\\dots,N-1}.
$$

Then the total sum is

$$
z = \\sum\_{i=1}^{M} x^{(i)} = \\sum\_{k=0}^{W-1} s_k,N^k.
$$

### 1.1. Fixed-width NOT for binary-format base-$N$ numbers

For a width-$W$ base-$N$ number

$$
x = \\sum\_{k=0}^{W-1} x_k N^k,\\quad x_k \\in {0,1},
$$

define the fixed-width all-ones mask:

$$
R_W = \\sum\_{k=0}^{W-1} N^k = \\frac{N^W-1}{N-1} = \\underbrace{11\\ldots11}\_{W\\ \\text{digits in base }N}.
$$

Then binary-format NOT is:

$$
\\mathrm{not}(x) = R_W - x.
$$

Because each digit of $x$ is 0 or 1, this is digitwise complement with no
borrow:

$$
\\mathrm{not}(x)\_k = 1 - x_k \\in {0,1}.
$$

So $\\mathrm{not}(x)$ is also binary-format (digits only in ${0,1}$), same
width $W$.

Example (base 3, width 4):

$$
x = 0101_3,\\quad R_4 = 1111_3,\\quad \\mathrm{not}(x)=1111_3-0101_3=1010_3.
$$

### Carry-free bound (why “no modulo” is needed)

Because each $s_k \\le N-1$, the maximum $z$ is

$$
z\_{\\max} = \\sum\_{k=0}^{W-1} (N-1),N^k
= (N-1),\\frac{N^W-1}{N-1}
= N^W - 1.
$$

So $z \\in [0, N^W - 1]$ and all operations below stay within the $W$-digit
base-$N$ space without requiring $z \\bmod N^W$.

______________________________________________________________________

## 2. Derived outputs from the digit-sum stream

For each digit position $k$, define four derived indicator bits from $s_k$:

Here $[\\cdot]$ denotes an Iverson bracket (indicator function): it evaluates to
1 if the condition is true and 0 otherwise. We write equality checks inside
$[\\cdot]$ using `==` to distinguish them from definitional uses of `=` elsewhere.

$$
\\mathrm{nor}\_k = [s_k == 0]
$$

$$
\\mathrm{and}\_k = [s_k == N-1]
$$

$$
\\mathrm{xor}\_k = [s_k \\bmod 2 == 1]
$$

$$
\\mathrm{xnor}\_k = [s_k \\bmod 2 == 0].
$$

Each output is itself a base-$N$ number with digits in ${0,1}$:

$$
A\_{\\mathrm{nor}} = \\sum\_{k=0}^{W-1} \\mathrm{nor}_k,N^k,\\quad
A_{\\mathrm{and}} = \\sum\_{k=0}^{W-1} \\mathrm{and}\_k,N^k,
$$

$$
A\_{\\mathrm{xor}} = \\sum\_{k=0}^{W-1} \\mathrm{xor}_k,N^k,\\quad
A_{\\mathrm{xnor}} = \\sum\_{k=0}^{W-1} \\mathrm{xnor}\_k,N^k.
$$

Two immediate invariants:

- For every $k$, $\\mathrm{xor}\_k + \\mathrm{xnor}\_k = 1$.
- Therefore $A\_{\\mathrm{xor}} + A\_{\\mathrm{xnor}} = \\sum\_{k=0}^{W-1} N^k = \\dfrac{N^W-1}{N-1}$.

______________________________________________________________________

## 3. MSB-first digit extraction from a residue

The core loop extracts one base-$N$ digit per tick, MSB-first, from a residue
state.

In our application, $z$ is the carry-free digit-sum number
$z=\\sum\_{k=0}^{W-1} s_k,N^k$, so its base-$N$ digits are exactly the per-position
counts $s_k$.

Let $z_t \\in {0,\\dots,N^W-1}$ be the integer residue before tick $t$, where
$t = 0,\\dots,W-1$.

### 3.1. Leading digit classification

Let the MSB place value be

$$
P = N^{W-1}.
$$

The leading digit is

$$
d_t = \\left\\lfloor \\frac{z_t}{P} \\right\\rfloor \\in {0,1,\\dots,N-1}.
$$

Equivalently, $d_t$ is the unique integer such that:

$$
d_t,P \\le z_t < (d_t + 1),P.
$$

This can be implemented using thresholds at $m,P$ for $m=1,\\dots,N-1$
(an $N$-way band classification).

### 3.2. Residue update (shift-left, drop extracted digit)

After extracting $d_t$, update the residue by removing that leading digit and
shifting the remaining $W-1$ digits left by one:

$$
z\_{t+1} = N,(z_t - d_t,P).
$$

Expanded:

$$
z\_{t+1} = N,z_t - d_t,N^W.
$$

This keeps $z\_{t+1} \\in \[0, N^W)$ for the carry-free sums considered here.

______________________________________________________________________

## 4. Accumulator recurrence for derived outputs

The MSB-first extraction yields the digit sequence $d_0,\\dots,d\_{W-1}$.
To build an output number whose digits are $out_k \\in {0,1}$, use the
standard “shift-and-add” recurrence:

$$
A^{(out)}\_{t+1} = N,A^{(out)}\_t + out(d_t),
\\quad A^{(out)}\_0 = 0.
$$

where $out(d_t)$ is one of:

- $out(d_t)= [d_t == 0]$ for NOR
- $out(d_t)= [d_t == N-1]$ for AND
- $out(d_t)= [d_t \\bmod 2 == 1]$ for XOR
- $out(d_t)= [d_t \\bmod 2 == 0]$ for XNOR

After $W$ ticks, $A^{(out)}_W$ equals the desired base-$N$ number with digits
$out_k$, where $out_k$ corresponds to the digit extracted at tick $t$ (MSB-first).
Equivalently, that tick-$t$ digit is the original position digit
$d_t = s_{W-1-t}$ of $z = \\sum\_{k=0}^{W-1} s_k N^k$.

### 4.1. Operational loop summary

Given $z\\in[0,N^W-1]$ and $P=N^{W-1}$:

- Initialize: $z_0=z$, and for each desired output accumulator set $A^{(out)}\_0=0$.
- For ticks $t=0,\\dots,W-1$:
  - Classify the leading digit $d_t$ by thresholds at $mP$ for $m=1,\\dots,N-1$.
  - Update residue: $z\_{t+1}=N(z_t-d_tP)=Nz_t-d_tN^W$.
  - Update each accumulator: $A^{(out)}_{t+1}=N,A^{(out)}_{t}+out(d_t)$.

______________________________________________________________________

## 5. Worked example: base-3, $W=8$ (two inputs)

Here $N=3$, $M=N-1=2$ inputs.

### 5.1. Canonical bounds (carry-free)

Each input digit is in ${0,1}$, so the maximum 8-digit input value is
$\\sum\_{k=0}^{7} 3^k = \\dfrac{3^8-1}{3-1} = 3280$, i.e.

- $x,y \\in [00000000_3, 11111111_3] = [0,3280]$

The digitwise sum $s_k=x_k+y_k \\in {0,1,2}$, so

- $z=x+y \\in [00000000_3, 22222222_3] = [0,6560] < 3^8$

### 5.2. MSB thresholds and residue update

For $W=8$,

- $P = 3^{7} = 2187$
- $3^8 = 6561$

The leading digit $d \\in {0,1,2}$ is determined by:

- if $z_t < 1\\cdot 2187$, then $d_t=0$
- else if $z_t < 2\\cdot 2187 = 4374$, then $d_t=1$
- else $d_t=2$

The residue update $z\_{t+1} = 3,(z_t - d_t,2187)$ becomes:

$$
\\begin{cases}
d_t=0: & z\_{t+1} = 3,z_t \\
d_t=1: & z\_{t+1} = 3,(z_t-2187) = 3,z_t - 6561 \\
d_t=2: & z\_{t+1} = 3,(z_t-4374) = 3,z_t - 2\\cdot 6561
\\end{cases}
$$

### 5.3. Outputs in the base-3 case

The digit-sum values map directly to one-hot outputs:

- $s_k=0 \\Rightarrow$ NOR digit is 1
- $s_k=1 \\Rightarrow$ XOR digit is 1
- $s_k=2 \\Rightarrow$ AND digit is 1

This legacy 3-output view is consistent with the 4-output view here by defining:

- XOR is unchanged: $\\mathrm{xor}\_k = [s_k == 1]$
- XNOR is parity-even: $\\mathrm{xnor}\_k = [s_k\\in{0,2}]$

And the known invariant for the three one-hot accumulators:

$$
A\_{\\mathrm{nor}} + A\_{\\mathrm{xor}} + A\_{\\mathrm{and}}
= 11111111_3
= 3280
= \\frac{3^8 - 1}{2}.
$$

______________________________________________________________________

### 5.4. Concrete 8-digit example

Take two 8-digit base-3 inputs (digits restricted to ${0,1}$):

- $x = 10011100_3$
- $y = 11010010_3$

Digitwise (MSB $\\rightarrow$ LSB), the carry-free sums are:

- $s = x+y = 21021110_3$

In integers:

- $x = 2304$
- $y = 3000$
- $z=x+y = 5304$ (and indeed $5304 < 3^8 = 6561$)

Per digit position, the derived output digits are:

- $\\mathrm{nor} = [s_k == 0] = 00100001_3$
- $\\mathrm{and} = [s_k == 2] = 10010000_3$
- $\\mathrm{xor} = [s_k \\text{ odd}] = 01001110_3$
- $\\mathrm{xnor} = [s_k \\text{ even}] = 10110001_3$

______________________________________________________________________

## 6. Worked example: base-4, $W=8$ (three inputs)

Here $N=4$, $M=N-1=3$ inputs, digits still restricted to ${0,1}$.

### 6.1. Bounds

Maximum 8-digit input value with digits in ${0,1}$ is:

$$
\\sum\_{k=0}^{7} 4^k = \\frac{4^8-1}{4-1} = \\frac{65536-1}{3} = 21845.
$$

So each input $x^{(i)} \\in [0, 21845]$, and with three inputs:

$$
z = x^{(1)} + x^{(2)} + x^{(3)} \\in [0, 4^8-1] = [0,65535].
$$

Per digit, $s_k \\in {0,1,2,3}$.

### 6.2. Derived digit outputs (NOR/AND/XOR/XNOR)

For each digit position:

- NOR: $[d == 0]$
- AND: $[d == 3]$
- XOR: $[d\\in{1,3}]$ (odd)
- XNOR: $[d\\in{0,2}]$ (even)

### 6.3. MSB thresholds and residue update

For $W=8$,

- $P = 4^{7} = 16384$
- $4^8 = 65536$

Digit bands:

$$
\\begin{aligned}
d=0 &\\iff 0 \\le z_t < 1\\cdot 16384 \\
d=1 &\\iff 1\\cdot 16384 \\le z_t < 2\\cdot 16384 \\
d=2 &\\iff 2\\cdot 16384 \\le z_t < 3\\cdot 16384 \\
d=3 &\\iff 3\\cdot 16384 \\le z_t < 4\\cdot 16384
\\end{aligned}
$$

Residue update:

$$
z\_{t+1} = 4,(z_t - d_t,16384) = 4,z_t - d_t,65536.
$$

### 6.4. Concrete 8-digit example (three inputs)

To keep the same ${0,1}$ digit style as the base-3 example, take:

- $x^{(1)} = 10011100_4$
- $x^{(2)} = 11010010_4$
- $x^{(3)} = 10001010_4$

Then the digitwise sums are:

- $s = x^{(1)}+x^{(2)}+x^{(3)} = 31022120_4$

In integers:

- $x^{(1)} = 16720$
- $x^{(2)} = 20740$
- $x^{(3)} = 16452$
- $z = 53912$ (and indeed $53912 < 4^8 = 65536$)

Per digit position, the derived output digits are:

- $\\mathrm{nor} = [s_k == 0] = 00100001_4$
- $\\mathrm{and} = [s_k == 3] = 10000000_4$
- $\\mathrm{xor} = [s_k \\text{ odd}] = 11000100_4$
- $\\mathrm{xnor} = [s_k \\text{ even}] = 00111011_4$

______________________________________________________________________

## Appendix A. Voltage view (optional)

This section is optional and only needed when mapping the integer quantities
above to a physical encoding.

Let $V\_{\\mathrm{range}}$ represent a full-scale range corresponding to $N^W$
uniform code steps (i.e. the wrap point is $N^W$). Define one integer unit as:

$$
V\_{\\mathrm{unit}} = \\frac{V\_{\\mathrm{range}}}{N^W}.
$$

Then an integer $u \\in [0, N^W-1]$ maps to voltage $u,V\_{\\mathrm{unit}}$.
Note that the maximum code $u=N^W-1$ maps to
$\\left(1-\\frac{1}{N^W}\\right)V\_{\\mathrm{range}}$.

The residue thresholds at $m,N^{W-1}$ correspond to voltages
$\\frac{m}{N},V\_{\\mathrm{range}}$, i.e. $V\_{\\mathrm{range}}/N$,
$2V\_{\\mathrm{range}}/N$, …, $(N-1)V\_{\\mathrm{range}}/N$.

module Mul where

open import Function
open import Data.Bool hiding (_<_; _≤_)
open import Data.Nat
open import Data.Nat.Properties
open import Data.Product hiding (map)
import Data.Product as P
open import Data.Fin hiding (_+_; _<_; _≤_)
open import Data.Fin.Properties hiding (bounded)
import Data.Fin as F
open import Data.Vec
open import Relation.Binary.PropositionalEquality

addℕ : ℕ → ℕ → ℕ
addℕ zero x = x
addℕ (suc a) x = suc (addℕ a x)


addF' : {m n : ℕ} → Fin (suc m) → Fin n → Fin (m + n)
addF' {m} {n} (zero {x}) y = cast (+-comm n m) (inject+ m y)
addF' {suc m} {n} (suc x) y = suc (addF' x y)

mulℕ : ℕ → ℕ → ℕ
mulℕ zero b = zero
mulℕ (suc a) b = b + mulℕ a b

mulF' : {m n : ℕ} → Fin m → Fin n → Fin (m * n)
mulF' zero zero = zero
mulF' zero (suc n) = zero
mulF' (suc m) zero = zero
mulF' {m = suc m} {suc n} (suc x) (suc y) = inject₁ (addF' (suc y) (mulF' x (suc y)))


Bits : ℕ → Set
Bits = Vec Bool


interpretBF : Bool → Fin 2
interpretBF false = zero
interpretBF true = suc zero



add3 : ∀ {m n p} → Fin m × Fin n × Fin p → ℕ
add3 (m , n , p) = toℕ m + toℕ n + toℕ p

digitize : ∀ {m n} → Fin m × Fin n → ℕ
digitize = toℕ ∘ uncurry combine ∘ swap

record IsAdd {τ : Set} {size : ℕ} (μ : τ → Fin size) : Set where
  constructor adds
  field
    add : Fin 2 × τ × τ → τ × Fin 2
    proof-add
      : (mnp : Fin 2 × τ × τ)
      → digitize (P.map μ id (add mnp)) ≡ add3 (P.map id (P.map μ μ) mnp)


record IsMult {τ : Set} {size : ℕ} (μ : τ → Fin size) : Set where
  constructor multiples
  field
    mult : τ → τ → τ × τ
    zeroM : τ
    proof-mult
      : (m n : τ)
      → uncurry combine (P.map μ μ (mult m n))  -- 1
      ≡ mulF' (μ m) (μ n)  -- 2

open IsAdd
open IsMult

xor : Fin 2 → Fin 2 → Fin 2
xor zero y = y
xor y zero = y
xor (suc x) (suc y) = zero

module _ {τ : Set} {size : ℕ} {μ : τ → Fin size} where
  add3Adder : IsAdd μ → Fin 2 → τ → τ → τ → τ × Fin 2
  add3Adder (adds add _) cin a b c =
    let (ab  , cout1)  = add (cin , a , b)
        (abc , cout2)  = add (zero , ab , c)
     in (abc , xor cout1 cout2)

composeMultFin : {τ : Set} → {size : ℕ} → (τ → Fin size) → (τ × τ → Fin (size * size))
composeMultFin μ = uncurry combine ∘ P.map μ μ

-- (a , b) * (c , d)
-- (ax + b) * (cx + d)
-- (acx^2 + adx + bcx + bd)
-- ((0x + 6)x^2 + (0x + 3)x + (3x + 0)x + (1x + 5))
-- (0x^3 + 6x^2 + 0x^2 + 3x + 3x^2 + 0x + 1x + 5)
-- (0x^3 + (6 + 0 + 3)x^2 + (3 + 0 + 1)x + 5)
-- ((0 , 9) , (4 , 5))


compose
    : {τ : Set} {size : ℕ} {μ : τ → Fin size}
    → IsAdd μ
    → IsMult μ
    → IsMult {τ × τ} {size * size} (composeMultFin μ)
IsMult.mult (compose adder multipler) (a , b) (c , d) =
  let (k , l) = multipler .mult a c -- x2
      (g , h) = multipler .mult a d
      (e , f) = multipler .mult b d
      (i , j) = multipler .mult b c

      (ehj , carry1)  = add3Adder adder zero   e h j
      (lig , carry2)  = add3Adder adder carry1 l i g

      -- (ax + b) * (cx + d) = (acx^2 + bcx + adx + bd)
      -- bd = (ex + f)
      -- ad = (gx + h)
      -- bc = (ix + j)
      -- ac = (kx + l)
      -- = (kx + l)x^2 + (ix + j)x + (gx + h)x + (ex + f))
      -- = (kx^3 + (l + i + g)x^2 + (j + h + e)x + f
   in (proj₁ (adder .add (carry2 , k , multipler .zeroM)) , lig) , (ehj , f)
IsMult.zeroM (compose adder multipler) = multipler .zeroM  , multipler .zeroM
IsMult.proof-mult (compose {μ = μ} adder multipler) ab@(a , b) cd@(c , d) = {!!}

open IsMult

bvalA : IsAdd interpretBF
add bvalA (zero , false , false) = false , zero
add bvalA (zero , false , true) = true , zero
add bvalA (zero , true , false) = true , zero
add bvalA (zero , true , true) = false , suc zero
add bvalA (suc zero , false , false) = true , zero
add bvalA (suc zero , false , true) = false , suc zero
add bvalA (suc zero , true , false) = false , suc zero
add bvalA (suc zero , true , true) = true , suc zero
proof-add bvalA (zero , false , false) = refl
proof-add bvalA (zero , false , true) = refl
proof-add bvalA (zero , true , false) = refl
proof-add bvalA (zero , true , true) = refl
proof-add bvalA (suc zero , false , false) = refl
proof-add bvalA (suc zero , false , true) = refl
proof-add bvalA (suc zero , true , false) = refl
proof-add bvalA (suc zero , true , true) = refl


bval : IsMult interpretBF
mult bval false false = false , false
mult bval false true = false , false
mult bval true false = false , false
mult bval true true = false , true
zeroM bval = false
proof-mult bval false false = refl
proof-mult bval false true = refl
proof-mult bval true false = refl
proof-mult bval true true = refl

data Three : Set where
  one : Three
  two : Three
  three : Three

interpretThree : Three → Fin 3
interpretThree one = zero
interpretThree two = suc zero
interpretThree three = suc (suc zero)


_ : mult (compose bvalA bval) (true , true) (true , true) ≡ ((true , false) , (false , true))
_ = refl


-----------------------------------------------------------------------------
-- |
-- Module    : Documentation.SBV.Examples.BitPrecise.MultMask
-- Copyright : (c) Levent Erkok
-- License   : BSD3
-- Maintainer: erkokl@gmail.com
-- Stability : experimental
--
-- An SBV solution to the bit-precise puzzle of shuffling the bits in a
-- 64-bit word in a custom order. The idea is to take a 64-bit value:
--
--    @1.......2.......3.......4.......5.......6.......7.......8.......@
--
-- And turn it into another 64-bit value, that looks like this:
--
--    @12345678........................................................@
--
-- We do not care what happens to the bits that are represented by dots. The
-- problem is to do this with one mask and one multiplication.
--
-- Apparently this operation has several applications, including in programs
-- that play chess of all things. We use SBV to find the appropriate mask and
-- the multiplier.
--
-- Note that this is an instance of the program synthesis problem, where
-- we "fill in the blanks" given a certain skeleton that satisfy a certain
-- property, using quantified formulas.
-----------------------------------------------------------------------------

{-# OPTIONS_GHC -Wall -Werror #-}

module Documentation.SBV.Examples.BitPrecise.MultMask where

import Data.SBV
import Data.SBV.Control

-- | Find the multiplier and the mask as described. We have:
--
-- >>> maskAndMult
-- Satisfiable. Model:
--   mask = 0x8080808080808080 :: Word64
--   mult = 0x0002040810204081 :: Word64
--
-- That is, any 64 bit value masked by the first and multiplied by the second
-- value above will have its bits at positions @[7,15,23,31,39,47,55,63]@ moved
-- to positions @[56,57,58,59,60,61,62,63]@ respectively.
--
-- NB. Depending on your z3 version, you might also get the following
-- multiplier as the result: 0x8202040810204081. That value works just fine as well!
--
-- NB. Note the custom call to z3 with a specific tactic. A simple call to z3 unfortunately
-- does not terminate quickly.
maskAndMult :: IO ()
maskAndMult = print =<< satWith z3{printBase=16} find
  where find = do -- Magic incantation to make the test go fast. See <http://github.com/Z3Prover/z3/issues/5660> for details.
                  setOption $ OptionKeyword ":tactic.default_tactic" ["sat"]
                  setOption $ OptionKeyword ":sat.euf"               ["true"]
                  setOption $ OptionKeyword ":smt.ematching"         ["false"]

                  mask <- sbvExists "mask"
                  mult <- sbvExists "mult"
                  inp  <- sbvForall "inp"
                  let res = (mask .&. inp) * (mult :: SWord64)
                  solve [inp `sExtractBits` [7, 15 .. 63] .== res `sExtractBits` [56 .. 63]]

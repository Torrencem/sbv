-----------------------------------------------------------------------------
-- |
-- Module      :  Data.SBV.Examples.Queries.CaseSplit
-- Copyright   :  (c) Levent Erkok
-- License     :  BSD3
-- Maintainer  :  erkokl@gmail.com
-- Stability   :  experimental
--
-- A couple of demonstrations for the caseSplit tactic.
-----------------------------------------------------------------------------

module Data.SBV.Examples.Queries.CaseSplit where

import Data.SBV
import Data.SBV.Control

-- | A simple floating-point problem, but we do the sat-analysis via a case-split.
-- Due to the nature of floating-point numbers, a case-split on the characteristics
-- of the number (such as NaN, negative-zero, etc. is most suitable.)
--
-- We have:
-- >>> csDemo1
-- Case fpIsNegativeZero: Starting
-- Case fpIsNegativeZero: Unsatisfiable
-- Case fpIsPositiveZero: Starting
-- Case fpIsPositiveZero: Unsatisfiable
-- Case fpIsNormal: Starting
-- Case fpIsNormal: Satisfiable
-- ("fpIsNormal",-3.689405e19)
csDemo1 :: IO (String, Float)
csDemo1 = runSMT $ do

       x <- sFloat "x"

       constrain $ x .== x + 1 -- yes, in the FP land, this does hold quite often!

       query $ do mbR <- caseSplit True [ ("fpIsNegativeZero", fpIsNegativeZero x)
                                        , ("fpIsPositiveZero", fpIsPositiveZero x)
                                        , ("fpIsNormal",       fpIsNormal       x)
                                        , ("fpIsSubnormal",    fpIsSubnormal    x)
                                        , ("fpIsPoint",        fpIsPoint        x)
                                        ]

                  case mbR of
                    Nothing     -> error "Cannot find a FP number x such that x == x + 1"  -- Won't happen!
                    Just (s, _) -> do xv <- getValue x
                                      return (s, xv)

-- | Demonstrates the "coverage" case.
--
-- We have:
-- >>> csDemo2
-- Case negative: Starting
-- Case negative: Unsatisfiable
-- Case less than 8: Starting
-- Case less than 8: Unsatisfiable
-- Case Coverage: Starting
-- Case Coverage: Satisfiable
csDemo2 :: IO (String, Integer)
csDemo2 = runSMT $ do

       x <- sInteger "x"

       constrain $ x .>= 10

       query $ do mbR <- caseSplit True [ ("negative"   , x .< 0)
                                        , ("less than 8", x .< 8)
                                        ]

                  case mbR of
                    Nothing     -> error "Cannot find a solution!" -- Won't happen!
                    Just (s, _) -> do xv <- getValue x
                                      return (s, xv)

{-# LANGUAGE OverloadedStrings #-}
module NLP.TokenizeTests where

import Test.Tasty.HUnit
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.QuickCheck (testProperty)

import qualified Data.Map as Map
import Data.Monoid ((<>))
import Data.Text (Text)
import qualified Data.Text as T

import NLP.Tokenize (runTokenizer, protectTerms, tokenize)

import NLP.Types (CaseSensitive(..))
import NLP.Types.Annotations
import NLP.POS

import TestUtils

tests :: TestTree
tests = testGroup "NLP.Tokenze"
        [ testGroup "Annotation Tokenizer" $ map mkTokTest
          [ ( "This is a test"
            , [ (0, "This")
              , (5, "is")
              , (8, "a")
              , (10, "test")
              ])
          , ("A url: http://google.com"
            , [ (0, "A")
              , (2, "url")
              , (5, ":")
              , (7, "http://google.com")
              ])
          , ("we'll don't."
            --  012345678901
            , [ (0, "we")
              , (2, "'ll")
              , (6, "do")
              , (8, "n't")
              , (11, ".")
              ])
          , ("jumped ."
            --  0123456789
            , [ (0, "jumped")
              , (7, ".")
              ])
          , ("jumped."
            --  0123456789
            , [ (0, "jumped")
              , (6, ".")
              ])
          , (" ., "
            , [(1, ".,")])
          , (" . "
            , [(1, ".")])
          , (" "
            , [])
          , ("  "
            , [])
          , (" \t "
            , [])
          ]
        , testGroup "Protect Terms" $ map (mkProtectTermsTokTest basicTerms)
          [ ("We use Apache."
            , Sensitive
            , [ (0, "We use ")
              , (7, "Apache")
              , (13, ".")
              ])
          , ("We use apache."
            , Insensitive
            , [ (0, "We use ")
              , (7, "apache")
              , (13, ".")
              ])
          , ("use Apache Hadoop here"
          --  0123456789012345678901
            , Sensitive
            , [ (0, "We use ")
              , (4, "Apache Hadoop")
              , (18, "here")
              ])
          ,  ("We use apache."
             , Sensitive
             , [ (0, "We use apache.")
               ])
          ]
        ]

basicTerms :: [Text]
basicTerms = ["Apache Hadoop", "Apache", "Apache Tomcat"]

mkTokSentence :: Text -> [(Int, Text)] -> TokenizedSentence
mkTokSentence dat toks = TokSentence { tokText = dat
                                     , tokAnnotations = map (mkTxtAnnotation dat) toks
                                     }

mkTxtAnnotation :: Text -> (Int, Text) -> Annotation Text Token
mkTxtAnnotation dat (idx, tok) = Annotation (Index idx) (T.length tok) (Token tok) dat

mkTokTest :: (Text, [(Int, Text)]) -> TestTree
mkTokTest (dat, toks) = let actual = tokenize dat
                            expected = mkTokSentence dat toks
                        in testCase (T.unpack ("\"" <> dat <> "\"")) (actual @?= expected)


mkProtectTermsTokTest :: [Text] -> (Text, CaseSensitive, [(Int, Text)]) -> TestTree
mkProtectTermsTokTest terms (dat, sensitive, toks) =
  let actual = runTokenizer (protectTerms terms sensitive) dat
      expected = mkTokSentence dat toks
  in testCase (T.unpack ("\"" <> dat <> "\"")) (actual @?= expected)
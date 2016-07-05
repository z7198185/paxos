module TestMajority (
  tests
)
where

  -- local imports

import Control.Consensus.Paxos

import SimpleDecree

-- external imports

import qualified Data.Map as M
import qualified Data.Set as S

import Test.Framework
import Test.HUnit
import Test.Framework.Providers.HUnit

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

tests :: [Test.Framework.Test]
tests = [
  testCase "majoriy" testMajority
  ]

testMajority :: Assertion
testMajority = do
  let instanceId = InstanceId 1
      mid1 = MemberId 1
      mid2 = MemberId 2
      mid3 = MemberId 3
      members = S.fromList [mid1, mid2, mid3]
      decree1 = Decree {
        decreeInstanceId = instanceId,
        decreeMemberId = mid1,
        decreeable = SetValue 1
        }
      votes1 = M.fromList [(mid1, Just Assent),(mid2, Just Assent),(mid3, Just Assent)]
  assertBool "Unanimous assent is majority" $ isMajority members votes1 $ \v ->
    case v of
      Assent -> True
      _ -> False
  let votes2 = M.fromList [
        (mid1, Just Assent),
        (mid2, Just Assent),
        (mid3, Just $ Dissent {
          dissentInstanceId = instanceId,
          dissentBallotNumber = BallotNumber 2
          })]
  assertBool "Majority assent is majority" $ isMajority members votes2 $ \v ->
    case v of
      Assent -> True
      _ -> False
  let votes3 = M.fromList [
        (mid1, Just Assent),
        (mid2, Just Dissent {
          dissentInstanceId = instanceId,
          dissentBallotNumber = BallotNumber 2
          }),
        (mid3, Just $ Dissent {
          dissentInstanceId = instanceId,
          dissentBallotNumber = BallotNumber 2
          })]
  assertBool "Majority dissent is minority" $ not $ isMajority members votes3 $ \v ->
    case v of
      Assent -> True
      _ -> False

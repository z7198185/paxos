{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE ExistentialQuantification #-}

-----------------------------------------------------------------------------
-- |
-- Module      :  Control.Consensus.Paxos.Types
-- Copyright   :  (c) Phil Hargett 2015
-- License     :  MIT (see LICENSE file)
--
-- Maintainer  :  phil@haphazardhouse.net
-- Stability   :  $(Stability)
-- Portability :  $(Portability)
--
--
-----------------------------------------------------------------------------

module Control.Consensus.Paxos.Types (

  Paxos(..),
  Ledger(..),
  Member(..),
  Vote(..),
  Votes(..),
  Prepare(..),
  Proposal(..),
  Decree(..),
  Decreeable(..)

) where

-- local imports

-- external imports

import Control.Concurrent.STM
import qualified Data.Map as M
import Data.Maybe
import Data.Serialize

import GHC.Generics

import Network.Endpoints

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

data Paxos d = Paxos {
  -- common fields
  paxosEndpoint :: Endpoint,
  paxosName :: Name,
  paxosMemberId :: Integer,
  paxosMembers :: M.Map Name Member,
  paxosTimeout :: Integer,
  paxosInstanceId :: Integer,
  paxosLedger :: TVar (Ledger d)
}

{-|
Central state for an instance of the Paxos algorithm.
-}
data Ledger d = Ledger {
  -- leader fields
  -- | The last proposal made by this member
  lastProposedBallotNumber :: Integer, -- ^ this is lastTried[p]
  -- member fields
  nextBallotNumber:: Integer, -- ^ this is nextBal[q]
  lastVote :: Maybe (Vote d) -- ^ this is prevVote[q]
}

data Member = Member {
  memberPriority :: Integer
  }

{-|
Eq. to NextBallot in basic protocol
-}
data Prepare = Prepare {
  prepareInstanceId :: Integer,
  tentativeBallotNumber :: Integer
} deriving (Generic)

instance Serialize Prepare

data Vote d = Dissent {
    dissentInstanceId :: Integer,
    dissentBallotNumber :: Integer
  } |
  Assent |
  Vote {
    voteInstanceId :: Integer,
    voteBallotNumber :: Integer,
    voteDecree :: Decree d
    }
  deriving (Generic)

instance Eq (Vote d) where
  a == b = voteBallotNumber a == voteBallotNumber b

instance Ord (Vote d) where
  Dissent _ _ <= _ = True
  _ <= Dissent _ _ = False
  Assent <= _ = True
  _ <= Assent = False
  a <= b = voteBallotNumber a <= voteBallotNumber b

type Votes d = M.Map Name (Maybe (Vote d))

instance (Decreeable d) => Serialize (Vote d)

class (Generic d, Serialize d) => Decreeable d

data Decree d = (Decreeable d) => Decree {
  -- the member from which this decree originated
  decreeMemberId :: Integer,
  decreeable :: d
  }

instance (Decreeable d) => Serialize (Decree d) where
  put d = do
    put $ decreeMemberId d
    put $ decreeable d
  get = do
    memberId <- get
    decree <- get
    return Decree {
      decreeMemberId = memberId,
      decreeable = decree
      }

{-|
Eq. BeginBallot in basic protocolx
-}
data Proposal d =  Proposal {
  proposalInstanceId :: Integer,
  proposedBallotNumber :: Integer,
  proposedDecree :: Decree d
} deriving Generic

instance (Decreeable d) => Serialize (Proposal d)

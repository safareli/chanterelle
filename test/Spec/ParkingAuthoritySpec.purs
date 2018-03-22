module ParkingAuthoritySpec (parkingAuthoritySpec) where


import Prelude

import Contracts.ParkingAuthority as ParkingAuthority
import Control.Monad.Aff (Aff)
import Control.Monad.Aff.AVar (AVAR, makeEmptyVar, putVar, takeVar)
import Control.Monad.Aff.Class (liftAff)
import Control.Monad.Eff.AVar as EffAVar
import Control.Monad.Eff.Class (liftEff)
import Control.Monad.Eff.Console (CONSOLE, log)
import Control.Monad.Eff.Unsafe (unsafePerformEff)
import Data.Either (Either(..))
import Data.Lens.Setter ((?~))
import Data.Maybe (Maybe(..), fromJust)
import Network.Ethereum.Web3 (ETH, Address, BigNumber, runWeb3, EventAction(..), event, embed, eventFilter, uIntNFromBigNumber, _from, _to, defaultTransactionOptions, ChainCursor(..))
import Node.FS.Aff (FS)
import Partial.Unsafe (unsafePartial)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import Type.Prelude (Proxy(..))
import Deploy (readDeployAddress)
import ContractConfig (foamCSRConfig, makeParkingAuthorityConfig)
import Types (DeployConfig, ContractConfig)


buildParkingAuthorityConfig
  :: forall eff.
     BigNumber
  -> Aff (fs :: FS | eff) (ContractConfig (deployArgs :: {foamCSR :: Address}))
buildParkingAuthorityConfig networkId= do
  foamCSRAddress <- readDeployAddress foamCSRConfig.filepath networkId
  pure $ makeParkingAuthorityConfig {foamCSR : foamCSRAddress}

parkingAuthoritySpec
  :: forall e.
     DeployConfig
  -> Spec ( fs :: FS
          , eth :: ETH
          , avar :: AVAR
          , console :: CONSOLE
          | e
          ) Unit
parkingAuthoritySpec deployConfig = do

  describe "Testing basic functionality of the parking authority" do
    it "has the correct foamCSR contract" do
      parkingAuthorityConfig <- buildParkingAuthorityConfig deployConfig.networkId
      parkingAuthorityAddress <- readDeployAddress parkingAuthorityConfig.filepath deployConfig.networkId
      let txOpts = defaultTransactionOptions # _to ?~ parkingAuthorityAddress
      ecsr <- runWeb3 deployConfig.provider $ ParkingAuthority.parkingCSR txOpts Latest
      ecsr `shouldEqual` (Right (Right parkingAuthorityConfig.deployArgs.foamCSR))
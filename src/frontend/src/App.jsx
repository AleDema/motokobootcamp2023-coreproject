import React, { useEffect, useState } from "react"
import logo from "./assets/dfinity.svg"
import { Principal } from '@dfinity/principal';
import { AccountIdentifier } from "@dfinity/nns";

//ROUTING
import { createRoutesFromElements, Link } from "react-router-dom";
import {
  createBrowserRouter,
  RouterProvider,
  Route
} from "react-router-dom";
/*
 * Connect2ic provides essential utilities for IC app development
 */
import { createClient } from "@connect2ic/core"
import { defaultProviders } from "@connect2ic/core/providers"
import { Connect2ICProvider, useConnect } from "@connect2ic/react"
import { useBalance, useWallet } from "@connect2ic/react"
import "@connect2ic/core/style.css"
import { useCanister } from "@connect2ic/react"
import { PlugWallet } from "@connect2ic/core/providers/plug-wallet"
/*
 * Import canister definitions like this:
 */
// import * as declarations from "@declarations/*"
/*
 * Some examples to get you started
 */
// import { Transfer } from "@components/Transfer"
// import { Profile } from "@components/Profile"

import Home from './pages/Home';
import DaoPage from './pages/DaoPage';
import NeuronPage from './pages/NeuronPage';
import Neurons from './pages/Neurons';
import ErrorPage from './pages/ErrorPage';
import ProposalPage from "./pages/ProposalPage"
import RootLayout from './layouts/RootLayout';

//STATE
import { useSnapshot } from 'valtio'
import state from "@context/global"

// //CANISTER
// import { DAO } from "@declarations/DAO"
import * as DAO from "../../../.dfx/local/canisters/DAO"
import * as ledger from "../../../.dfx/local/canisters/ledger"

import { accountIdentifierFromBytes, principalToAccountDefaultIdentifier, principalToSubAccount } from "./helpers"

function App() {

  const snap = useSnapshot(state)

  const [deposit, setDeposit] = useState({})
  const { isConnected, disconnect, activeProvider } = useConnect();
  const [auth_dao, { loading, error }] = useCanister("DAO")
  const [auth_ledger] = useCanister("ledger")
  const [wallet] = useWallet()

  const to32bits = (num) => {
    let b = new ArrayBuffer(4);
    new DataView(b).setUint32(0, num);
    return Array.from(new Uint8Array(b));
  }

  const whoami = async () => {
    //console.log(auth_dao)
    auth_dao.whoami()
    //console.log(await auth_dao.whoami())
  }

  const dotransfer = async () => {
    //console.log(wallet.principal)
    //let principal = Principal.fromText("jsznl-dkl5x-uqwae-2imi4-l6yvy-ya4ov-6fkgj-5eo33-3f7sc-hfg6t-3qe")
    let principal = Principal.fromUint8Array(deposit.principal)
    console.log(await auth_ledger.icrc1_transfer({
      to: { owner: principal, subaccount: [] }, fee: [1000000n], memo: [], from_subaccount: [], created_at_time: [], amount: 1000n
    }))
  }


  const dotransferaccount = async () => {
    console.log(wallet.principal)
    let principal = Principal.fromText("jsznl-dkl5x-uqwae-2imi4-l6yvy-ya4ov-6fkgj-5eo33-3f7sc-hfg6t-3qe")
    console.log(await auth_ledger.icrc1_transfer({
      to: { owner: principal, subaccount: [to32bits(1)] }, fee: [1000000n], memo: [], from_subaccount: [], created_at_time: [], amount: 1000n
    }))
  }

  const getbalance = async () => {
    console.log(wallet.principal)
    console.log(await auth_ledger.icrc1_balance_of({
      owner: Principal.fromText(wallet.principal), subaccount: []
    }))
  }


  const getbalanceacc = async () => {
    let principal = Principal.fromText("jsznl-dkl5x-uqwae-2imi4-l6yvy-ya4ov-6fkgj-5eo33-3f7sc-hfg6t-3qe")
    console.log(principal)
    console.log(await auth_ledger.icrc1_balance_of({
      owner: deposit.principal, subaccount: deposit.subaccount
    }))
  }

  //add_balance_debug
  const addinternalbalance = async () => {
    auth_dao.add_balance_debug(10000)
  }

  let lockup_years = 365 * 4
  let fake_creation = [Number(1579705832000000)]
  let fake_dissolve = []

  //1674398316721558903
  //1579705832000100000
  //157970583200000000
  //1579705832000000
  //1579705832000000
  //157970583200000
  //1579705832000000000
  const create_debug_neuron = async () => {
    auth_dao.create_neuron_debug(10, lockup_years, fake_creation, fake_dissolve)
  }

  const initDeposit = async () => {
    if (isConnected) {

      console.log(await auth_dao.get_debug_info())
      console.log("CONNECTED")
      console.log(isConnected)
      let address = await auth_dao.get_deposit_address_info();
      // console.log(accountIdentifierFromBytes(address))
      // console.log(principalToAccountDefaultIdentifier(Principal.fromText(wallet.principal)));
      // console.log(principalToSubAccount(Principal.fromText(wallet.principal)));
      //setDeposit(accountIdentifierFromBytes(address))
      console.log(address)
      console.log(Principal.fromUint8Array(address.principal))
      console.log(accountIdentifierFromBytes(address.accountid))
      setDeposit(address)
    } else {
      setDeposit(null);
    }
  }

  useEffect(() => {
    initDeposit()
  }, [isConnected])

  useEffect(() => {

  }, [])

  //TODO MAINNET CHECK WEBPAGE CANISTER ID
  return (
    <>
      <div>
        <img src={logo} className="logo h-28" alt="logo" />
      </div>
      <h1 className="text-5xl">Bootcamp DAO</h1>
      <div className="space-x-4">
      </div>
      <button onClick={whoami}>get id</button>
      <button onClick={dotransfer}>tranfer</button>
      <button onClick={dotransferaccount}>tranfer acc</button>
      <button onClick={getbalance}>get balance</button>
      <button onClick={getbalanceacc}>get balance acc</button>
      <button onClick={addinternalbalance}>addinternalbalance</button>
      <button onClick={create_debug_neuron}>create debug neuron</button>
      <div>
        {/* <Profile /> */}
        <p>{deposit?.accountid}</p>
        <a href="https://tpyud-myaaa-aaaap-qa4gq-cai.ic0.app/">Webpage </a>
        {isConnected ? <Link to="/dao">DAO</Link> : null}
        {isConnected ? <Link to="/neurons">Neurons</Link> : null}
      </div>
    </>

  )
}


const client = createClient({
  canisters: {
    DAO,
    ledger
  },
  providers: [
    new PlugWallet(),
  ],
  globalProviderConfig: {
    dev: import.meta.env.DEV,
  },
})


const router = createBrowserRouter(createRoutesFromElements(
  <Route path="/" element={<RootLayout />} errorElement={<ErrorPage />}>
    <Route index element={<App />} />
    <Route path="/home" element={<Home />} />
    <Route path="/dao" element={<DaoPage />} />
    <Route path="/neurons" element={<Neurons />} />
    <Route path="/proposal:id" element={<ProposalPage />} />
    <Route path="/neuron:id" element={<NeuronPage />} />
  </Route>
));

export default () => (
  <Connect2ICProvider client={client}>
    <RouterProvider router={router} />
  </Connect2ICProvider>
)

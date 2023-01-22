import React, { useEffect, useState } from "react"
import logo from "./assets/dfinity.svg"
import { Principal } from '@dfinity/principal';
// import { AccountIdentifier } from "@dfinity/nns";

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
import { ConnectButton, ConnectDialog, Connect2ICProvider, useCanister, useBalance, useWallet, useConnect } from "@connect2ic/react"
import "@connect2ic/core/style.css"
/*
 * Import canister definitions like this:
 */
// import * as counter from "../.dfx/local/canisters/counter"
import * as DAO from "../.dfx/local/canisters/DAO"
// import idlFactory from "../.dfx/local/canisters/ledger.did.js"
import { idlFactory as idlFactoryLedger } from "../.dfx/local/canisters/ledger/ledger.did.js"
/*
 * Some examples to get you started
 */

import Home from './pages/Home';
import DaoPage from './pages/DaoPage';
import NeuronPage from './pages/NeuronPage';
import Neurons from './pages/Neurons';
import ErrorPage from './pages/ErrorPage';
import ProposalPage from "./pages/ProposalPage"
import RootLayout from './layouts/RootLayout';
import { PlugWallet } from "@connect2ic/core/providers/plug-wallet"

import { Counter } from "./components/Counter"
import { Transfer } from "./components/Transfer"
import { Profile } from "./components/Profile"

function App() {

  const [deposit, setDeposit] = useState({})
  const { isConnected, disconnect, activeProvider } = useConnect();
  const [wallet] = useWallet()
  const [auth_dao, { loading, error }] = useCanister("DAO")
  const [auth_ledger] = useCanister("ledger")

  const dotransfer = async () => {
    console.log(auth_ledger)
    //let principal = Principal.fromText("jsznl-dkl5x-uqwae-2imi4-l6yvy-ya4ov-6fkgj-5eo33-3f7sc-hfg6t-3qe")
    let principal = deposit.principal
    console.log(await auth_ledger.icrc1_transfer({
      to: { owner: principal, subaccount: [] }, fee: [BigInt(1000000)], memo: [], from_subaccount: [], created_at_time: [], amount: BigInt(10000000000)
    }))
  }


  const dotransferaccount = async () => {
    console.log(auth_ledger)
    console.log(wallet.principal)
    let principal = deposit.principal
    console.log(await auth_ledger.icrc1_transfer({
      to: { owner: principal, subaccount: [deposit.subaccount] }, fee: [BigInt(1000000)], memo: [], from_subaccount: [], created_at_time: [], amount: BigInt(10000000000)
    }))
  }

  const getbalance = async () => {
    console.log(wallet.principal)
    console.log(await auth_ledger.icrc1_balance_of({
      owner: Principal.fromText(wallet.principal), subaccount: []
    }))
  }

  const getbalanceacc = async () => {

    console.log(await auth_ledger.icrc1_balance_of({
      owner: deposit.principal, subaccount: [deposit.subaccount]
    }))
  }

  //add_balance_debug
  const addinternalbalance = async () => {
    auth_dao.add_balance_debug(10000)
  }

  let lockup_years = 365 * 4
  let fake_creation = [Number(1579705832000000)]
  let fake_dissolve = []


  const create_debug_neuron = async () => {
    auth_dao.create_neuron_debug(10, lockup_years, fake_creation, fake_dissolve)
  }
  const check_deposit = async () => {
    auth_dao.check_deposit()
  }

  const check_dao_ledger_balance = async () => {
    auth_dao.get_default_dao_ledger_balance()
  }

  const check_dao_internal_balance = async () => {
    auth_dao.get_dao_internal_balance()
  }

  const withdraw = async () => {
    let res = await auth_dao.withdraw(Principal.fromText(wallet.principal), Number.parseFloat(1))
    console.log(res)
  }

  const initDeposit = async () => {
    if (isConnected) {
      console.log(await auth_dao.get_debug_info())
      console.log("CONNECTED: " + isConnected)
      let address = await auth_dao.get_deposit_address_info();
      // console.log(address)
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


  return (
    <>
      <div className="auth-section">
        <ConnectButton />
      </div>
      <ConnectDialog />
      <div>
        <img src={logo} className="logo h-28" alt="logo" />
      </div>
      <h1 className="text-5xl">Bootcamp DAO</h1>
      <div className="space-x-4">
      </div>
      {/* <button onClick={whoami}>get id</button> */}
      {/* <button onClick={dotransfer}>tranfer</button> */}
      <button onClick={dotransferaccount}>tranfer to deposit addr</button>
      <button onClick={getbalance}>get user balance</button>
      <button onClick={getbalanceacc}>get deposit acc balance</button>
      <button onClick={addinternalbalance}>addinternalbalance</button>
      <button onClick={check_deposit}>check deposit</button>
      <button onClick={check_dao_ledger_balance}>check canister ledger balance</button>
      <button onClick={check_dao_internal_balance}>check canister internal balance</button>
      <button onClick={withdraw}>withdraw to ledger</button>
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
    ledger: { canisterId: "l7jw7-difaq-aaaaa-aaaaa-c", idlFactory: idlFactoryLedger }
  },
  providers: [
    new PlugWallet(),
  ],
  globalProviderConfig: {
    /*
     * Disables dev mode in production
     * Should be enabled when using local canisters
     */
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
    {/* <App /> */}
    <RouterProvider router={router} />
  </Connect2ICProvider>
)

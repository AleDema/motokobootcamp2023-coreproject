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

import { Transfer } from "./components/Transfer"
import { Profile } from "./components/Profile"

function App() {

  const [deposit, setDeposit] = useState({})
  const [sendAmount, setSendAmount] = useState(0)
  const [withAmount, setWithAmount] = useState(0)
  const [withPrincipal, setWithPrincipal] = useState(0)
  const [isConnected, setIsConnected] = useState(false)
  const [wallet] = useWallet()
  const [auth_dao, { loading, error }] = useCanister("DAO")
  const [auth_ledger] = useCanister("ledger")
  const [ledgerBalance, setLedgerBalance] = useState(0)
  const [votingPower, setVotingPower] = useState(0)
  const [votingMode, setVotingMode] = useState(0)
  const [minVp, setMinVP] = useState(0)
  const [propThreshold, setPropThreshold] = useState(0)
  const [isQuadratic, setIsQuadratic] = useState("")
  const [daoLedgerBalance, setDaoLedgerBalance] = useState(0)
  const [internalBalance, setInternalBalance] = useState(0)
  const [internalDaoBalance, setInternalDaoBalance] = useState(0)
  const [depositLedgerBalance, setDepositLedgerBalance] = useState(0)

  const dotransfer = async () => {
    console.log(auth_ledger)
    //let principal = Principal.fromText("jsznl-dkl5x-uqwae-2imi4-l6yvy-ya4ov-6fkgj-5eo33-3f7sc-hfg6t-3qe")
    let principal = deposit.principal
    console.log(await auth_ledger.icrc1_transfer({
      to: { owner: principal, subaccount: [] }, fee: [BigInt(1000000)], memo: [], from_subaccount: [], created_at_time: [], amount: BigInt(sendAmount * 100000000)
    }))
  }


  const dotransferaccount = async () => {
    console.log(auth_ledger)
    console.log(wallet.principal)
    let principal = deposit.principal
    console.log(await auth_ledger.icrc1_transfer({
      to: { owner: principal, subaccount: [deposit.subaccount] }, fee: [BigInt(1000000)], memo: [], from_subaccount: [], created_at_time: [], amount: BigInt(sendAmount * 100000000)
    }))

    init(wallet?.principal)
  }

  const getbalance = async () => {
    let ledgerbalance = await auth_ledger.icrc1_balance_of({
      owner: Principal.fromText(wallet.principal), subaccount: []
    })


    console.log("getbalance " + wallet.principal)
    console.log(await auth_ledger.icrc1_balance_of({
      owner: Principal.fromText(wallet.principal), subaccount: []
    }))

    return ledgerbalance
  }

  const getbalanceacc = async (addr) => {
    let deposit_bal = await auth_ledger.icrc1_balance_of({
      owner: addr.principal, subaccount: [addr.subaccount]
    })
    console.log(deposit_bal)
    return deposit_bal
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
    init(wallet?.principal)
  }
  const check_deposit = async () => {
    auth_dao.check_deposit()
    init(wallet?.principal)
  }

  const check_dao_ledger_balance = async () => {
    return auth_dao.get_default_dao_ledger_balance()
  }

  const check_dao_internal_balance = async () => {
    return auth_dao.get_dao_internal_balance()
  }

  const withdraw = async () => {
    let res = await auth_dao.withdraw(Principal.fromText(wallet.principal), Number.parseFloat(sendAmount))
    console.log(res)
    init(wallet?.principal)
  }

  const init = async (principal) => {
    if (principal) {
      console.log(principal)
      console.log("CONNECTED: ")
      let address = await auth_dao.get_deposit_address_info();
      // console.log(address)
      setDeposit(address)
      setIsConnected(true)
      let debug_infos = await auth_dao.get_debug_info()
      console.log(debug_infos)
      let quadratic = "false"
      if (debug_infos?.isQuadratic === true) {
        quadratic = "true"
      }
      setIsQuadratic(quadratic)
      setVotingPower(debug_infos?.my_vp)
      setMinVP(debug_infos?.min_vp_required)
      setPropThreshold(debug_infos?.proposal_vp_threshold)
      setVotingMode(debug_infos?.current_vp_mode)
      setInternalBalance(debug_infos?.internal_balance)
      let depositAccBal = await getbalanceacc(address)
      setDepositLedgerBalance(Number(depositAccBal) / 100000000)
      let userledgerBal = await getbalance()
      setLedgerBalance(Number(userledgerBal) / 100000000)
      let daoLedgerBal = await check_dao_ledger_balance()
      setDaoLedgerBalance(Number(daoLedgerBal))
      let daoInternalBal = await check_dao_internal_balance()
      setInternalDaoBalance(daoInternalBal)
    } else {
      setIsConnected(false)
      setDeposit(null);
    }
  }

  // useEffect(() => {
  //   initDeposit()
  // }, [isConnected])

  useEffect(() => {
    init(wallet?.principal)
  }, [wallet])

  useEffect(() => {

  }, [])


  return (
    <>
      <div>
        <img src={logo} className="logo h-28" alt="logo" />
      </div>
      <h1 className="text-5xl">Bootcamp DAO</h1>
      <div className="space-x-4">
      </div>

      {isConnected ?
        <div>
          <div>
            <p>Your ledger balance: {Number(ledgerBalance)} MBT</p>
            <p>Your Voting Power: {votingPower}</p>
            <p>Current voting mode {JSON.stringify(votingMode)}</p>
            <p>Minimum VP required to vote: {Number(minVp)}</p>
            <p>Proposal Approve Threshold: {Number(propThreshold)}</p>
            <p>Is Quadratic mode on: {String(isQuadratic)}</p>
            <p>DAO Balance on MBT ledger: {daoLedgerBalance} MBT</p>
            <p>Your DAO balance: {internalBalance}</p>
            <p>DAO internal balance: {internalDaoBalance}</p>
            <p>Deposit Address MBT Balance: {Number(depositLedgerBalance)} MBT</p>
          </div>

          <div>
            <input className="text-black  w-5/12" type="text"
              value={sendAmount}
              placeholder="Amount"
              onChange={(e) => setSendAmount(e.target.value)}></input>
            <button onClick={dotransferaccount}>Tranfer to deposit address</button>
          </div>
          <button onClick={check_deposit}>Check Deposit</button>
          <div>
            <button onClick={withdraw}>Withdraw to ledger (current principal)</button>
          </div>
          <button onClick={create_debug_neuron}>Create debug neuron (immediately dissolvable, 10 MBT required)</button>
          <div>
            <Link to="/dao">DAO</Link>
            <br></br>
            <Link to="/neurons">Neurons</Link>
            <p>Deposit account id (use to load tokens in the DAO): {deposit?.accountid}</p>
          </div>
        </div>
        : <p>Login to access functionality</p>}
      <div>
        <a href="https://tpyud-myaaa-aaaap-qa4gq-cai.ic0.app/">Webpage </a>
      </div>
    </>

  )
}


// let ledgerCanisterId = import.meta.env.DEV ? "l7jw7-difaq-aaaaa-aaaaa-c" : "db3eq-6iaaa-aaaah-abz6a-cai"
// console.log(ledgerCanisterId)

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
    <Route path="/dao" element={<DaoPage />} />
    <Route path="/neurons" element={<Neurons />} />
    <Route path="/proposal/:id" element={<ProposalPage />} />
    <Route path="/neuron/:id" element={<NeuronPage />} />
    <Route path="/home" element={<Home />} />
  </Route>
));


export default () => (
  <Connect2ICProvider client={client}>
    {/* <App /> */}
    <RouterProvider router={router} />
  </Connect2ICProvider>
)

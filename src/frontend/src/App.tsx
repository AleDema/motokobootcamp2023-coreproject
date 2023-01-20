import React, { useEffect, useState } from "react"
import logo from "./assets/dfinity.svg"
/*
 * Connect2ic provides essential utilities for IC app development
 */
import { createClient } from "@connect2ic/core"
import { defaultProviders } from "@connect2ic/core/providers"
import { Connect2ICProvider, useConnect } from "@connect2ic/react"
import "@connect2ic/core/style.css"
/*
 * Import canister definitions like this:
 */
import * as declarations from "@declarations/DAO"
/*
 * Some examples to get you started
 */
import { Transfer } from "@components/Transfer"
import { Profile } from "@components/Profile"

import Home from '@pages/Home';
import DaoPage from '@pages/DaoPage';
import ErrorPage from '@pages/ErrorPage';
import RootLayout from '@layouts/RootLayout';

//STATE
import { useSnapshot } from 'valtio'
import state from "@context/global"

//CANISTER
import { DAO } from "@declarations/DAO"

//ROUTING
import { createRoutesFromElements, Link } from "react-router-dom";
import {
  createBrowserRouter,
  RouterProvider,
  Route
} from "react-router-dom";
import ProposalPage from "@pages/ProposalPage"

function App() {

  const snap = useSnapshot(state)

  const [count, setCount] = useState<bigint>()
  const { isConnected, disconnect } = useConnect();

  // const refreshCounter = async () => {
  //   const freshCount = await DAO.getValue() as bigint
  //   setCount(freshCount)
  // }

  // const increment = async () => {
  //   //setCount(count++)
  //   await DAO.increment()
  //   await refreshCounter()
  // }

  useEffect(() => {
    //refreshCounter();
  }, [])

  return (
    <>
      <div>
        <img src={logo} className="logo h-28" alt="logo" />
      </div>
      <h1 className="text-5xl">Bootcamp DAO</h1>
      <div className="space-x-4">
      </div>

      <div>
        <Profile />
        <Link to="/dao">dApp</Link>
        {isConnected ? <Link to="/dao">DAO</Link> : null}
      </div>
    </>

  )
}


const client = createClient({
  canisters: {
    declarations,
  },
  providers: defaultProviders,
  globalProviderConfig: {
    dev: import.meta.env.DEV,
  },
})


const router = createBrowserRouter(createRoutesFromElements(
  <Route path="/" element={<RootLayout />} errorElement={<ErrorPage />}>
    <Route index element={<App />} />
    <Route path="/home" element={<Home />} />
    <Route path="/dao" element={<DaoPage />} />
    <Route path="/proposal:id" element={<ProposalPage />} />
  </Route>
));

export default () => (
  <Connect2ICProvider client={client}>
    <RouterProvider router={router} />
  </Connect2ICProvider>
)

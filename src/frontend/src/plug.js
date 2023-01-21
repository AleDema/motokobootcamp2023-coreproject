import { idlFactory as idlFactoryDAO } from "@declarations/DAO/DAO.did.js"
import { idlFactory as idlFactoryLedger } from "@declarations/ledger/ledger.did.js"
import { HttpAgent, Actor } from "@dfinity/agent"

// See https://docs.plugwallet.ooo/ for more informations
export async function plugConnection() {


    //TODO : Add your mainnet id whenever you have deployed on the IC
    const daoCanisterId =
        process.env.NODE_ENV === "development" ? "fterm-bydaq-aaaaa-aaaaa-c" : "fterm-bydaq-aaaaa-aaaaa-c"

    const ledgerCanisterId =
        process.env.NODE_ENV === "development" ? "jcuhx-tqeaq-aaaaa-aaaaa-c" : "db3eq-6iaaa-aaaah-abz6a-cai"



    const p = await window.ic.plug.agent.getPrincipal()

    const actor = await window.ic.plug.createActor({
        canisterId: daoCanisterId,
        interfaceFactory: idlFactoryDAO,
    })

    const ledger = await window.ic.plug.createActor({
        canisterId: ledgerCanisterId,
        interfaceFactory: idlFactoryLedger,
    })


    return { daoActor: actor, principal: p, ledgerActor: ledger }
}
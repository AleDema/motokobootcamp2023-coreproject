import { idlFactory as idlFactoryDAO } from "@declarations/DAO/DAO.did.js"
import { HttpAgent, Actor } from "@dfinity/agent"

//TODO : Add your mainnet id whenever you have deployed on the IC
const daoCanisterId =
    process.env.NODE_ENV === "development" ? "ai7t5-aibaq-aaaaa-aaaaa-c" : "ai7t5-aibaq-aaaaa-aaaaa-c"

// See https://docs.plugwallet.ooo/ for more informations
export async function plugConnection() {
    const result = await window.ic.plug.requestConnect({
        whitelist: [daoCanisterId],
    })
    if (!result) {
        throw new Error("User denied the connection")
    }
    const p = await window.ic.plug.agent.getPrincipal()

    const agent = new HttpAgent({
        host: process.env.NODE_ENV === "development" ? "http://localhost:8000" : "https://ic0.app",
    });

    if (process.env.NODE_ENV === "development") {
        agent.fetchRootKey();
    }

    const actor = Actor.createActor(idlFactoryDAO, {
        agent,
        canisterId: daoCanisterId,
    });

    return { actor: actor, principal: p }
}
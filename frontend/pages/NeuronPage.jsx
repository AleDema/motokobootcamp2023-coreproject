import React from 'react';

import { useSnapshot } from 'valtio'
import state from "../context/global"
import { useParams } from "react-router-dom";
import { useCanister } from "@connect2ic/react"

//CANISTER
// import { DAO } from "@declarations/DAO"

const VotingOptions = {
    approve: null,
    reject: null,
}

const NeuronPage = () => {

    const [auth_dao, { loading, error }] = useCanister("DAO")
    const [neuron, setNeuron] = React.useState({});
    const [neuronStake, setNeuronStake] = React.useState(0);
    const [neuronDelay, setNeuronDelay] = React.useState(0);
    let { id } = useParams();

    const fetchNeuron = async (id) => {
        let res = await auth_dao.get_user_neuron(id);
        console.log(res)
        if (res !== null && res.ok)
            setNeuron(res.ok)
        console.log(res.ok.dissolve_delay)
    }

    const startdissolve = async () => {
        await auth_dao.dissolve_neuron(parseInt(id));
    }


    const stopDissolve = async () => {
        await auth_dao.stop_dissolve_neuron(parseInt(id));
    }

    const tryDelete = async () => {
        let res = await auth_dao.completely_dissolve_neuron(parseInt(id));
        console.log(res)
    }


    const increaseStake = async () => {
        await auth_dao.increase_neuron_stake(parseInt(id), Number.parseFloat(neuronStake));
    }


    const increaseDelay = async () => {
        console.log(parseInt(neuronDelay))
        await auth_dao.set_neuron_lockup(parseInt(id), parseInt(neuronDelay));
    }

    React.useEffect(() => {
        //console.log(parseInt(id))
        fetchNeuron(parseInt(id))
    }, [])

    return (
        <div className="flex flex-col items-center">
            <p>ID: {Number(neuron?.id)}</p>
            <p>Stake: {Number(neuron?.stake)} MBT</p>
            <p>Creation Date {Number(neuron?.creation_date)}</p>
            <p>{Number(neuron?.dissolve_delay)} days</p>
            <p>State: {JSON.stringify(neuron?.state)}</p>
            <button onClick={startdissolve}>
                Start Dissolve
            </button>
            <button onClick={stopDissolve}>
                stop dissolve
            </button>
            <button onClick={tryDelete}>
                try delete
            </button>

            <input className="text-black w-5/12 h-44" type="num"
                placeholder="increase stake"
                value={neuronStake}
                onChange={(e) => setNeuronStake(e.target.value)}>
            </input>
            <button onClick={increaseStake}>
                increase stake
            </button>

            <input className="text-black w-5/12 h-44" type="num"
                placeholder="increase delay"
                value={neuronDelay}
                onChange={(e) => setNeuronDelay(e.target.value)}>
            </input>
            <button onClick={increaseDelay}>
                increase delay
            </button>
        </div>
    );
};

export default NeuronPage;
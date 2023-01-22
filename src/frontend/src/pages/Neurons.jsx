import React, { useEffect, useState } from "react"
import { useNavigate, Link } from "react-router-dom";
import { useCanister } from "@connect2ic/react"
import { useSnapshot } from 'valtio'
import state from "../context/global"

//CANISTER
import { DAO } from "@declarations/DAO"


const Neurons = () => {

    const snap = useSnapshot(state)
    const [neurons, setSeurons] = useState([{}]);
    const [neuronStake, setNeuronStake] = useState(0);
    const [neuronDelay, setNeuronDelay] = useState(0);
    const [auth_dao, { loading, error }] = useCanister("DAO")

    const fetchNeurons = async () => {
        let neurons = await auth_dao.get_user_neurons();
        console.log(neurons)
        console.log(neurons.ok.neurons)
        let neuronsarray = []
        if (neurons.ok.neurons)
            neuronsarray = neurons.ok.neurons
        // neurons.ok.map(function (e, i) {
        //     console.log(e)
        // })
        setSeurons(neuronsarray)

    }

    // submit_proposal(title : Text, description : Text, change : ProposalType) 
    const createNeuron = async () => {
        let res = await auth_dao.create_neuron(Number.parseFloat(neuronStake), Number.parseFloat(neuronDelay));
        console.log(res)
        setNeuronStake(0)
        setNeuronDelay(0)
        //somehow refresh with new proposal
        //ghetto solution
        setTimeout(fetchNeurons, 1600);
    }

    useEffect(() => {
        fetchNeurons();
    }, [])

    return (
        <div>
            <p>{snap.principal}</p>
            <div className="flex flex-col items-center">
                {neurons.map(function (e, i) {
                    return (<Link to={`/neuron${e.id}`} key={e.id}>{"Neuron " + e.id}</Link>)
                })}
            </div>
            <div className="flex flex-col space-y-4 w-screen w-screen items-center">
                <input className="text-black w-5/12 h-44" type="num"
                    placeholder="Stake amount"
                    value={neuronStake}
                    onChange={(e) => setNeuronStake(e.target.value)}>

                </input>

                <input className="text-black w-5/12 h-44" type="num"
                    placeholder="delay days"
                    value={neuronDelay}
                    onChange={(e) => setNeuronDelay(e.target.value)}>

                </input>
                <button onClick={createNeuron}>
                    Create Neuron
                </button>
            </div>

        </div>
    );
};

export default Neurons;
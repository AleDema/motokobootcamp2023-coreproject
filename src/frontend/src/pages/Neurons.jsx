import React, { useEffect, useState } from "react"
import { useNavigate, Link } from "react-router-dom";
import { useCanister } from "@connect2ic/react"
import { useSnapshot } from 'valtio'
import state from "../context/global"

//CANISTER
import { DAO } from "@declarations/DAO"


const DaoPage = () => {

    const snap = useSnapshot(state)
    const [proposals, setProposals] = useState([{}]);
    const [auth_dao, { loading, error }] = useCanister("DAO")

    const fetchNeurons = async () => {
        let neurons = await auth_dao.get_user_neurons();
        console.log(neurons)
        // proposals.map(function (e, i) {
        //     console.log(e)
        // })
    }

    // submit_proposal(title : Text, description : Text, change : ProposalType) 
    const submitProposal = async () => {
    }

    // Handle change event on select tag
    const handleChange = (event) => {
        //console.log(event.target.value)
        setProposalType(event.target.value);
    }

    useEffect(() => {
        fetchNeurons();
        //console.log(proposals)
    }, [])

    return (
        <div>
            <p>{snap.principal}</p>
            <div className="flex flex-col items-center">
                {proposals.map(function (e, i) {
                    return (<Link to={`/proposal${e.id}`} key={e.id}>{e.title + " " + e.id}</Link>)
                })}
            </div>
        </div>
    );
};

export default DaoPage;
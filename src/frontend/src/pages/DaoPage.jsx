import React, { useEffect, useState } from "react"
import { useNavigate, Link } from "react-router-dom";

import { useSnapshot } from 'valtio'
import state from "../context/global"

//CANISTER
import { DAO } from "@declarations/DAO"

const options = [
    { value: "update_page", label: "update_page" },
    { value: "update_min_vp", label: "update_min_vp" },
    { value: "update_thresold", label: "update_thresold" },
    { value: "toggle_quadratic", label: "toggle_quadratic" }
];

const DaoPage = () => {

    const snap = useSnapshot(state)
    const [proposals, setProposals] = useState([{}]);
    const [proposalTitle, setProposalTitle] = useState("");
    const [proposalDescription, setProposalDescription] = useState("");
    const [proposalChange, setProposalChange] = useState("");
    const [proposalType, setProposalType] = useState("");

    const fetchProposals = async () => {
        setProposals(await DAO.get_all_proposals());
        //console.log(proposals)
        proposals.map(function (e, i) {
            console.log((e))
        })
    }

    const submitProposal = async () => {
        //maybe validate fields
        DAO.submit_proposal(proposalTitle, proposalDescription, proposalChange)
        setProposalTitle("")
        setProposalDescription("")
        setProposalChange("")
        //somehow refresh with new proposal
        //ghetto solution
        setTimeout(fetchProposals, 1600);
    }

    useEffect(() => {
        fetchProposals();
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
            <div className="flex flex-col space-y-4 w-screen items-center">
                <select className="text-black  w-5/12" onChange={setProposalType}>
                    {options.map((option) => (
                        <option className="text-black  w-5/12" key={option.value} value={option.value}>
                            {option.label}
                        </option>
                    ))}
                </select>
                <input className="text-black  w-5/12" type="text"
                    value={proposalTitle}
                    placeholder="Title"
                    onChange={(e) => setProposalTitle(e.target.value)}></input>
                <input className="text-black w-5/12 h-44 break-normal overflow-x-auto" type="text"
                    placeholder="Description"
                    value={proposalDescription}
                    onChange={(e) => setProposalDescription(e.target.value)}></input>
                <input className="text-black w-5/12 h-44" type="text"
                    placeholder="Change"
                    value={proposalChange}
                    onChange={(e) => setProposalChange(e.target.value)}></input>
                <button onClick={submitProposal}>
                    Create Proposal
                </button>
            </div>
        </div>
    );
};

export default DaoPage;
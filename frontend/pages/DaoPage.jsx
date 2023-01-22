import React, { useEffect, useState } from "react"
import { useNavigate, Link } from "react-router-dom";
import { useCanister } from "@connect2ic/react"
import { useSnapshot } from 'valtio'
import state from "../context/global"

//CANISTER
// import { DAO } from "@declarations/DAO"

const options = [
    { value: "update_page", label: "Update Page Text" },
    { value: "update_min_vp", label: "Update Min VP" },
    { value: "update_thresold", label: "Update Thresold" },
    { value: "toggle_quadratic", label: "Toggle Quadratic" },
    { value: "toggle_advanced_mode", label: "Toggle Neuron mode" }
];

const DaoPage = () => {

    const snap = useSnapshot(state)
    const [proposals, setProposals] = useState([{}]);
    const [proposalTitle, setProposalTitle] = useState("");
    const [proposalDescription, setProposalDescription] = useState("");
    const [proposalChange, setProposalChange] = useState("");
    const [proposalType, setProposalType] = useState("update_page");
    const [auth_dao, { loading, error }] = useCanister("DAO")

    const fetchProposals = async () => {
        setProposals(await auth_dao.get_all_proposals());
        console.log(await auth_dao.get_all_proposals())
        proposals.map(function (e, i) {
            console.log(e)
        })
    }

    // submit_proposal(title : Text, description : Text, change : ProposalType) 
    const submitProposal = async () => {
        //maybe validate fields

        let propVariant = {}

        if (proposalType === "update_page") {
            propVariant = { change_text: proposalChange }
        }
        if (proposalType === "update_min_vp") {
            propVariant = { update_min_vp: parseInt(proposalChange) }
        }
        if (proposalType === "update_thresold") {
            propVariant = { update_threshold: parseInt(proposalChange) }
        }
        if (proposalType === "toggle_quadratic") {
            propVariant = { toggle_quadratic: null }
        }

        if (proposalType === "toggle_advanced_mode") {
            propVariant = { toggle_advanced_mode: null }
        }

        console.log(propVariant)

        auth_dao.submit_proposal(proposalTitle, proposalDescription, propVariant)
        setProposalTitle("")
        setProposalDescription("")
        setProposalChange("")
        //somehow refresh with new proposal
        //ghetto solution
        setTimeout(fetchProposals, 1600);
    }

    // Handle change event on select tag
    const handleChange = (event) => {
        //console.log(event.target.value)
        setProposalType(event.target.value);
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
                    return (<Link to={`/proposal/${e.id}`} key={e.id}>{e.title + " " + e.id}</Link>)
                })}
            </div>
            <div className="flex flex-col space-y-4 w-screen items-center">
                <select className="text-black  w-5/12" onChange={handleChange}>
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

                {proposalType === "update_page" ? <input className="text-black w-5/12 h-44" type="text"
                    placeholder="Change"
                    value={proposalChange}
                    onChange={(e) => setProposalChange(e.target.value)}>

                </input>
                    : null}
                {proposalType === "update_min_vp" ? <input className="text-black w-5/12 h-44" type="number"
                    placeholder="Change"
                    value={proposalChange}
                    onChange={(e) => setProposalChange(e.target.value)}>

                </input>
                    : null}
                {proposalType === "update_thresold" ? <input className="text-black w-5/12 h-44" type="num"
                    placeholder="Change"
                    value={proposalChange}
                    onChange={(e) => setProposalChange(e.target.value)}>

                </input>
                    : null}
                <button onClick={submitProposal}>
                    Create Proposal
                </button>
            </div>
        </div>
    );
};

export default DaoPage;
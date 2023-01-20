module GovernanceTypes {

    public type VotingPowerLogic = {
        #basic;
        #advanced
    };
    public type ProposalId = Nat;
    public type Proposal = {
        id : ProposalId;
        title : Text;
        description : Text;
        state : ProposalState;
        approve_votes : Nat;
        reject_votes : Nat;
        change_data : ProposalType
    };

    // pType : ProposalType

    public type ProposalType = {
        #change_text : Text; //just text
        #update_min_vp : Nat; //just nat
        #update_threshold : Nat; //just nat
        #toggle_quadratic;
        #create_lottery : (Nat, Nat, Nat, Nat) // amount, price per, share %, winning %
    };

    public type ProposalState = {
        #approved;
        #rejected;
        #open
    };

    public type VotingOptions = {
        #approve;
        #reject
    };

    public type Vote = {
        voting_power : Nat;
        vote : VotingOptions
    }
}

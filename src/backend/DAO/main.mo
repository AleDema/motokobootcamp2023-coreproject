import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Trie "mo:base/Trie";
import Nat "mo:base/Nat";
import Float "mo:base/Float";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Time "mo:base/Time";
import G "./GovernanceTypes";
import N "./neuron";
import TU "../utils/time";
import Map "../utils/Map";
//import Webpage "canister:Webpage";
// import Map "mo:hashmap/Map";

actor {

    public type AccountIdentifier = Blob;
    public type Subaccount = Blob;

    type VotingPowerLogic = G.VotingPowerLogic;
    type ProposalId = G.ProposalId;
    type Proposal = G.Proposal;
    type ProposalType = G.ProposalType;
    type ProposalState = G.ProposalState;
    type VotingOptions = G.VotingOptions;
    type Vote = G.Vote;
    type Neuron = N.Neuron;
    type NeuronsContainer = N.NeuronsContainer;
    type NeuronActions = N.NeuronActions;

    let { ihash; nhash; thash; phash; calcHash } = Map;

    var DEV_MODE = true;

    stable var MIN_VP_REQUIRED = 1;
    stable var PROPOSAL_VP_THESHOLD = 100;
    stable var IS_QUADRATIC = false;
    private var current_vp_mode : VotingPowerLogic = #basic;

    private stable var proposal_id_counter = 0;
    private stable let proposals = Map.new<Nat, Proposal>();
    private stable let user_votes = Map.new<Principal, Map.Map<ProposalId, Vote>>();
    private stable let neurons = Map.new<Principal, NeuronsContainer>();
    private stable let user_balances = Map.new<Principal, Float>();

    public shared ({ caller }) func whoami() : async Principal {
        Debug.print(debug_show (caller));
        return caller
    };

    public shared (msg) func submit_proposal(title : Text, description : Text, change : ProposalType) : async () {
        if (verify_balance(msg.caller) < Float.fromInt(MIN_VP_REQUIRED)) return;

        //TODO input validation

        let p : Proposal = {
            id = proposal_id_counter;
            title = title;
            description = description;
            change_data = change;
            approve_votes = 0;
            reject_votes = 0;
            state = #open
        };
        ignore Map.put(proposals, nhash, p.id, p);
        Debug.print("CREATED PROPOSAL");
        proposal_id_counter := proposal_id_counter +1
    };

    public query func get_proposal(id : ProposalId) : async Result.Result<Proposal, Text> {
        switch (Map.get(proposals, nhash, id)) {
            case (null) {
                return #err("no proposal")
            };
            case (?proposal) {
                return #ok(proposal)
            }
        }
    };

    public query func get_all_proposals() : async [Proposal] {
        //Debug.print(debug_show (Map.toArray(proposals)));
        let iter = Map.vals<Nat, Proposal>(proposals);
        Iter.toArray(iter)
    };

    public shared ({ caller }) func vote(id : ProposalId, choice : VotingOptions) : async () {

        Debug.print("vote");
        Debug.print(debug_show (id));
        Debug.print(debug_show (choice));

        let user_vp = get_voting_power(caller);
        if (user_vp <= Float.fromInt(MIN_VP_REQUIRED)) return;

        let p : Proposal = do {
            switch (Map.get(proposals, nhash, id)) {
                case (?proposal) proposal;
                case (_) return //does it return null or return the func? TODO TEST
            }
        };

        //check if already voted
        var hasVoted = false;

        let test1 : ?Map.Map<ProposalId, Vote> = do ? {
            let first = Map.get(user_votes, phash, caller);
            first!
        };

        let test2 : ?Vote = do ? {
            let first = Map.get(user_votes, phash, caller);
            let second = Map.get(first!, nhash, id);
            second!
        };

        //TODO TEST
        switch (test1, test2) {
            case (?exists1, ?exist2) {
                hasVoted := true
            };
            case (?exist1, _) {
                var init_votes : Map.Map<ProposalId, Vote> = Map.new<ProposalId, Vote>();
                ignore Map.put(exist1, nhash, id, { voting_power = user_vp; vote = choice })
            };
            case (_, _) {
                //both false
                var init_votes : Map.Map<ProposalId, Vote> = Map.new<ProposalId, Vote>();
                ignore Map.put(init_votes, nhash, id, { voting_power = user_vp; vote = choice });
                ignore Map.put(user_votes, phash, caller, init_votes)
            }
        };

        if (hasVoted) return;

        //if approved or rejected can't vote'
        if (p.state == #approved or p.state == #rejected) return;

        var state = p.state;
        var approve_votes = p.approve_votes;
        var reject_votes = p.reject_votes;
        switch choice {
            case (#approve) {
                if (p.approve_votes + user_vp >= Float.fromInt(PROPOSAL_VP_THESHOLD)) {
                    state := #approved
                };
                approve_votes := p.approve_votes + user_vp
            };
            case (#reject) {
                if (p.reject_votes + user_vp >= Float.fromInt(PROPOSAL_VP_THESHOLD)) {
                    state := #rejected
                };
                reject_votes := p.reject_votes + user_vp
            }
        };

        let updated_p = {
            p with state = state;
            reject_votes = reject_votes;
            approve_votes = approve_votes
        };
        Debug.print("end vote");
        ignore Map.put(proposals, nhash, p.id, updated_p);
        //Debug.print(debug_show (Map.get(proposals, nhash, id)));
        if (state == #approved) await execute_change(p.change_data);

    };

    private func execute_change(change : ProposalType) : async () {
        //TODO proposal types
        //ignore Webpage.update_body(change)
        switch (change) {
            case (#change_text(new_text)) {
                //ignore Webpage.update_body(change)
            };
            case (#update_min_vp(new_vp)) {
                MIN_VP_REQUIRED := new_vp
            };
            case (#update_threshold(new_th)) {
                PROPOSAL_VP_THESHOLD := new_th
            };
            case (#toggle_quadratic) {
                IS_QUADRATIC := not IS_QUADRATIC
            };
            case (#create_lottery(amount, price, share_percentage, winning_percentage)) {
                //todo
            }
        }
    };

    //TODO actually implement this
    private func verify_balance(user : Principal) : Float {
        if (DEV_MODE) {
            return 100
        } else return 10; //TODO

    };

    //todo
    public shared ({ caller }) func check_deposit(address : Subaccount) : async Float {
        0.0
    };
    //todo
    public shared ({ caller }) func withdraw(amount : Float, address : Principal) : async () {

    };

    public shared ({ caller }) func generate_deposit_address() : async () {

    };

    public func internal_transfer(from : Principal, to : Principal, amount : Float) : () {

    };

    private func has_enough_balance(user : Principal, amount : Float) : Bool {
        let test : ?Float = do ? {
            let balance = Map.get(user_balances, phash, user);
            balance!
        };
        switch (test) {
            case (?balance) return (balance - amount >= 0);
            case (_) false
        }
    };

    public func get_neurons() : async [NeuronsContainer] {
        let iter = Map.vals<Principal, NeuronsContainer>(neurons);
        Iter.toArray(iter)
    };

    public shared ({ caller }) func get_user_neurons() : async Result.Result<NeuronsContainer, Text> {
        get_user_neurons_internal(caller)
    };

    private func get_user_neurons_internal(caller : Principal) : Result.Result<NeuronsContainer, Text> {
        let test1 : ?NeuronsContainer = do ? {
            let first = Map.get(neurons, phash, caller);
            first!
        };

        switch (test1) {
            case (?container) {
                #ok(container)
            };
            case (_) {
                #err("No Neurons found")
            }
        }
    };

    public shared ({ caller }) func create_neuron(stake : Float, dissolve_delay : Nat) : async () {
        //has_enough_balance
        if (not DEV_MODE) {
            if (not has_enough_balance(caller, stake)) return
        };

        //internal_transfer TODO

        //create neuron Map.new<Principal, (Nat, [Neuron])>()
        let test1 : ?NeuronsContainer = do ? {
            let first = Map.get(neurons, phash, caller);
            first!
        };

        var neurons_temp : [Neuron] = [];
        var id = 0;

        var neuron : Neuron = {
            id = id;
            stake = stake;
            state = #locked;
            dissolve_start = null;
            creation_date = Time.now();
            dissolve_delay = dissolve_delay
        };

        switch (test1) {
            case (?record) {
                //if user already has at least 1 neuron
                neuron := { neuron with id = record.current_neuron_id };
                id := record.current_neuron_id;
                neurons_temp := Array.append(record.neurons, [neuron])

            };
            case (_) {
                neurons_temp := [neuron]
            }
        };

        let neurons_container : NeuronsContainer = {
            current_neuron_id : Nat = id + 1;
            neurons = neurons_temp
        };

        ignore Map.put(neurons, phash, caller, neurons_container)

    };

    private func process_neuron_state_change(neuron : Neuron, change : NeuronActions) : Neuron {
        var new_neuron = neuron;
        switch (change) {
            case (#increase_stake(new_stake)) {
                //todo check balance and transfer
                new_neuron := { new_neuron with stake = new_stake }
            };
            case (#increase_delay(new_delay)) {
                //check if dissolving
                new_neuron := { new_neuron with dissolve_delay = new_delay }
            };
            case (#change_state(new_state)) {
                // check if can be dissolved
                new_neuron := { new_neuron with state = new_state }
            }
        };
        neuron
    };

    private func can_dissolve(neuron : Neuron) : Bool {
        return true
    };

    private func time_since_dissolve_start(dissolve_start : Nat) : Nat {
        return 0
    };

    //todo change to private
    public func set_neuron_state(user : Principal, id : Nat, new_value : NeuronActions) : async Result.Result<Text, Text> {
        let test1 : ?NeuronsContainer = do ? {
            let first = Map.get(neurons, phash, user);
            first!
        };

        switch (test1) {
            case (?container) {
                let neuron : ?Neuron = Array.find<Neuron>(
                    container.neurons,
                    func(n) {
                        if (n.id == id) {
                            return true
                        } else {
                            return false
                        }
                    },
                );
                switch (neuron) {
                    case (?neuron) {
                        let new_neuron = process_neuron_state_change(neuron, new_value);
                        var new_neurons = Array.filter<Neuron>(container.neurons, func(n) { return n.id == neuron.id });
                        new_neurons := Array.append(new_neurons, [new_neuron]);
                        ignore Map.put(neurons, phash, user, { current_neuron_id = container.current_neuron_id; neurons = new_neurons });
                        #ok("done")
                    };
                    case (_) {
                        #err("neuron not found")
                    }
                }

            };
            case (_) {
                return #err("Dont have neurons")
            }
        }

    };

    public shared ({ caller }) func dissolve_neuron(id : Nat) : async () {
        ignore set_neuron_state(caller, id, #change_state(#dissolving))
    };

    public shared ({ caller }) func stop_dissolve_neuron(id : Nat) : async () {
        ignore set_neuron_state(caller, id, #change_state(#locked))
    };

    public shared ({ caller }) func set_neuron_lockup(id : Nat, dissolve_delay : Nat) : async () {
        ignore set_neuron_state(caller, id, #increase_delay(dissolve_delay))
    };

    //check dissolve condition TODO
    public shared ({ caller }) func completely_dissolve_neuron(id : Nat) : async () {
        var reimburse_amount : Float = delete_neuron(caller, id);
        //delete neuron

        //internal_transfer TODO
    };

    //todo remove public and async
    func delete_neuron(user : Principal, id : Nat) : Float {
        var reimburse_amount : Float = 0;
        let test1 : ?NeuronsContainer = do ? {
            let first = Map.get(neurons, phash, user);
            first!
        };

        switch (test1) {
            case (?container) {
                let new_neurons = Array.filter<Neuron>(
                    container.neurons,
                    func(n) {
                        if (n.id != id) {
                            return true
                        } else {
                            reimburse_amount := n.stake;
                            return false
                        }

                    },
                );

                ignore Map.put(neurons, phash, user, { current_neuron_id = container.current_neuron_id; neurons = new_neurons })
            };
            case (_) {

            }
        };
        reimburse_amount
    };

    private func get_voting_power(user : Principal) : Float {
        switch (current_vp_mode) {
            case (#basic) verify_balance(user);
            case (#advanced) { calculate_user_vp(user) } //todo wrap
        }
    };

    private func get_neurons_vp(user : Principal) : Float {
        var vp : Float = 0;
        if (DEV_MODE) {
            vp := 10
        } else vp := 10; //TODO

        if (IS_QUADRATIC) {
            // var ftval = Float.fromInt(vp);
            var sqr = Float.sqrt(vp);
            // let i64_vp = Float.toInt64(sqr)
        };

        return vp
    };

    private func calculate_user_vp(caller : Principal) : Float {
        let neurons = get_user_neurons_internal(caller);
        var vp : Float = 0;
        switch (neurons) {
            case (#ok(neuron_container)) {
                for (neuron in neuron_container.neurons.vals()) {
                    vp := vp + calculate_neuron_vp(neuron)
                }
            };
            case (#err(text)) {
                vp := 0.0
            }
        };

        vp
    };

    var MIN_LOCKUP_MONTHS = 6;
    var MAX_LOCKUP_MONTHS = 12 * 8;
    var LOCKUP_BONUS_START = 1.06;
    var LOCKUP_BONUS_END = 2;
    var MAX_AGE_BONUS = 4;
    var AGE_BONUS_START = 1.0;
    var AGE_BONUS_END = 1.25;

    private func calculate_neuron_vp(neuron : Neuron) : Float {
        var lockup_bonus = LOCKUP_BONUS_START;
        var age_bonus = AGE_BONUS_START;
        var stake = neuron.stake;

        if (IS_QUADRATIC) {
            // var ftval = Float.fromInt(vp);
            stake := Float.sqrt(stake);
            // let i64_vp = Float.toInt64(sqr)
        };

        if (neuron.state == #dissolving) {
            age_bonus := 1.0
        };

        //todo time conversion
        if (TU.daysFromEpoch(neuron.dissolve_delay) < MIN_LOCKUP_MONTHS * 30) {
            return 0
        };

        if (TU.daysFromEpoch(neuron.dissolve_delay) - TU.daysFromEpoch(Option.get(neuron.dissolve_start, 0)) > MIN_LOCKUP_MONTHS * 30) {

        };

        return stake * age_bonus * lockup_bonus
    };

    //advanced

    // modify_parameters
    // quadratic_voting

}

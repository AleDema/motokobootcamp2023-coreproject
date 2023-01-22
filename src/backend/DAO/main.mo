import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Trie "mo:base/Trie";
import Nat "mo:base/Nat";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Time "mo:base/Time";
import G "./GovernanceTypes";
import N "./neuron";
import TU "../utils/time";
import Map "../utils/Map";
import ICRCTypes "../ledger/Types";
import A "../utils/Account";

shared actor class DAO() = this {

    //change on main
    var DEV_MODE = true;
    let main_ledger_principal = "db3eq-6iaaa-aaaah-abz6a-cai";
    let local_ledger_principal = "ai7t5-aibaq-aaaaa-aaaaa-c";
    var icrc_principal = main_ledger_principal;
    if (DEV_MODE) {
        icrc_principal := local_ledger_principal
    };
    let icrc_canister = actor (icrc_principal) : ICRCTypes.TokenInterface;

    //todo swap on main
    let main_webpage_principal = "hozae-racaq-aaaaa-aaaaa-c";
    let local_webpage_principal = "hozae-racaq-aaaaa-aaaaa-c";
    var webpage_principal = main_ledger_principal;
    if (DEV_MODE) {
        webpage_principal := local_webpage_principal
    };

    public type WebPageType = actor {
        update_body : shared Text -> async ()
    };

    let webpage_canister = actor (webpage_principal) : WebPageType;

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

    stable var MIN_VP_REQUIRED = 1;
    stable var PROPOSAL_VP_THESHOLD = 100;
    stable var IS_QUADRATIC = false;
    private var current_vp_mode : VotingPowerLogic = #advanced;
    private stable var proposal_id_counter = 0;
    private stable let proposals = Map.new<Nat, Proposal>();
    private stable let user_votes = Map.new<Principal, Map.Map<ProposalId, Vote>>();
    private stable let neurons = Map.new<Principal, NeuronsContainer>();
    private stable let user_balances = Map.new<Principal, Float>();

    public shared ({ caller }) func whoami() : async Principal {
        Debug.print(debug_show (caller));
        return caller
    };

    type DebugInfo = {
        my_principal : Principal;
        min_vp_required : Nat;
        proposal_vp_threshold : Nat;
        is_quadratic : Bool;
        current_vp_mode : VotingPowerLogic;
        my_vp : Float;
        internal_balance : Float

    };

    public shared ({ caller }) func get_debug_info() : async DebugInfo {
        let debug_data = {
            my_principal = caller;
            min_vp_required = MIN_VP_REQUIRED;
            proposal_vp_threshold = PROPOSAL_VP_THESHOLD;
            is_quadratic = IS_QUADRATIC;
            current_vp_mode = current_vp_mode;
            my_vp = await get_voting_power(caller);
            internal_balance = get_user_internal_balance(caller)
        };
        Debug.print(debug_show (caller));
        // Debug.print(debug_show (debug_data));
        return debug_data
    };

    public shared (msg) func submit_proposal(title : Text, description : Text, change : ProposalType) : async () {
        if (A.isAnonymous(msg.caller)) return;

        let vp = await get_voting_power(msg.caller);
        if (vp < Float.fromInt(MIN_VP_REQUIRED)) return;

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
        let iter = Map.vals<Nat, Proposal>(proposals);
        let arr = Iter.toArray(iter);
        Debug.print(debug_show (arr));
        arr
    };

    public shared ({ caller }) func vote(id : ProposalId, choice : VotingOptions) : async () {
        if (A.isAnonymous(caller)) return;
        Debug.print("vote");
        Debug.print(debug_show (id));
        Debug.print(debug_show (choice));

        let user_vp = await get_voting_power(caller);
        if (user_vp <= Float.fromInt(MIN_VP_REQUIRED)) return;

        let p : Proposal = do {
            switch (Map.get(proposals, nhash, id)) {
                case (?proposal) proposal;
                case (_) return //does it return null or return the func? seems to work
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

        // TEST
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

        //TODO ENABLE
        // if (hasVoted) return;

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

    // modify_parameters
    private func execute_change(change : ProposalType) : async () {
        //TEST proposal types
        switch (change) {
            case (#change_text(new_text)) {
                ignore webpage_canister.update_body(new_text)
            };
            case (#update_min_vp(new_vp)) {
                MIN_VP_REQUIRED := new_vp
            };
            case (#update_threshold(new_th)) {
                PROPOSAL_VP_THESHOLD := new_th
            };
            case (#toggle_quadratic) {
                quadratic_voting()
            };
            case (#create_lottery(amount, price, share_percentage, winning_percentage)) {
                //BEYOND
            }
        }
    };

    private func quadratic_voting() {
        IS_QUADRATIC := not IS_QUADRATIC
    };

    public func get_default_ledger_balance(user : Principal) : async Float {
        normalize_ledger_balance(await icrc_canister.icrc1_balance_of({ owner = user; subaccount = null }))
    };

    private func normalize_ledger_balance(amount : Nat) : Float {
        if (amount == 0) return 0.0;
        return Float.fromInt(amount) / 100000000
    };

    //TEST
    public shared func check_deposit(principal : Principal, subaccount : Subaccount) : async () {
        let deposit = normalize_ledger_balance(await icrc_canister.icrc1_balance_of({ owner = principal; subaccount = ?subaccount }));
        if (deposit > 0.0) {
            ignore Map.put(user_balances, phash, principal, get_user_internal_balance(principal) + deposit)
        }
    };

    //TEST
    public shared ({ caller }) func withdraw(address : Principal, amount : Float) : async () {
        if (A.isAnonymous(caller)) return;
        if (has_enough_balance(address, amount)) {
            ignore Map.put(user_balances, phash, address, get_user_internal_balance(address) - amount);
            //ledger transfer
            ignore icrc_canister.icrc1_transfer({
                to = { owner = address; subaccount = null };
                fee = null;
                memo = null;
                from_subaccount = null;
                created_at_time = null;
                amount = Int.abs(Float.toInt(amount * 100000000)) //decimals
            })
        }
    };

    private func generate_deposit_address(owner : Principal) : AccountIdentifier {
        A.accountIdentifier(Principal.fromActor(this), A.principalToSubaccount(owner))
    };

    type DepositAddressInfo = {
        principal : Principal;
        subaccount : Subaccount;
        accountid : AccountIdentifier
    };

    public shared ({ caller }) func get_deposit_address_info() : async DepositAddressInfo {
        return {
            principal = Principal.fromActor(this);
            subaccount = A.principalToSubaccount(caller);
            accountid = generate_deposit_address(caller)
        }
    };

    private func internal_transfer(from : Principal, to : Principal, amount : Float) : () {
        if (has_enough_balance(from, amount)) {
            ignore Map.put(user_balances, phash, from, get_user_internal_balance(from) - amount);
            ignore Map.put(user_balances, phash, to, get_user_internal_balance(to) + amount)
        }
    };

    //WARNING can cause issues with withdrawals
    public func add_balance_debug_to_principal(to : Principal, amount : Float) : async () {
        ignore Map.put(user_balances, phash, to, get_user_internal_balance(to) + amount)
    };

    //WARNING can cause issues with withdrawals
    public shared ({ caller }) func add_balance_debug(amount : Float) : async () {
        await add_balance_debug_to_principal(caller, amount)
    };

    private func has_enough_balance(user : Principal, amount : Float) : Bool {
        let balance = get_user_internal_balance(user);
        if (balance - amount >= 0) { return true } else { return false }
    };

    private func get_user_internal_balance(user : Principal) : Float {
        let test : ?Float = do ? {
            let balance = Map.get(user_balances, phash, user);
            balance!
        };
        switch (test) {
            case (?balance) return (balance);
            case (_) 0.0
        }
    };

    //NEURONS START

    public func get_neurons() : async [NeuronsContainer] {
        let iter = Map.vals<Principal, NeuronsContainer>(neurons);
        Iter.toArray(iter)
    };

    public shared ({ caller }) func get_user_neurons() : async Result.Result<NeuronsContainer, Text> {
        get_user_neurons_internal(caller)
    };

    public shared ({ caller }) func get_user_neuron(id : Nat) : async Result.Result<Neuron, Text> {
        let neurons = get_user_neurons_internal(caller);
        switch (neurons) {
            case (#ok(container)) {
                let test = Array.find<Neuron>(
                    container.neurons,
                    func(n) {
                        if (n.id == id) {
                            return true
                        } else {
                            return false
                        }
                    },
                );

                switch (test) {
                    case (?found) {
                        return #ok(found)
                    };
                    case (_) {
                        return #err("no neuron with this id")
                    }
                }
            };
            case (_) {
                #err("no neurons")
            }
        }
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

    public shared ({ caller }) func create_neuron(stake : Float, dissolve_delay : Nat) : async Result.Result<Text, Text> {

        if (stake <= 0) return #err("invalid amount");
        //has_enough_balance
        if (not has_enough_balance(caller, stake)) return #err("no balance");

        //internal_transfer
        internal_transfer(caller, Principal.fromActor(this), stake);

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

        ignore Map.put(neurons, phash, caller, neurons_container);
        #ok("Neuron created")

    };

    public shared ({ caller }) func create_neuron_debug(stake : Float, dissolve_delay : Nat, fake_creation : ?Time.Time, fake_dissolve : ?Int) : async Result.Result<Text, Text> {

        if (stake <= 0) return #err("invalid amount");
        //has_enough_balance
        if (not has_enough_balance(caller, stake)) return #err("no balance");

        //internal_transfer
        internal_transfer(caller, Principal.fromActor(this), stake);

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
            state = #dissolving;
            dissolve_start = ?1485097832000000000;
            creation_date = Time.now(); //1579705832000000000; //1485097832000000000; //2017 //1579705832000000000;2years
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

        ignore Map.put(neurons, phash, caller, neurons_container);
        #ok("Neuron created")

    };

    private func process_neuron_state_change(owner : Principal, neuron : Neuron, change : NeuronActions) : Neuron {
        var new_neuron = neuron;
        switch (change) {
            case (#increase_stake(new_stake)) {
                //TEST
                if (has_enough_balance(owner, new_stake)) {
                    internal_transfer(owner, Principal.fromActor(this), new_stake);
                    new_neuron := {
                        new_neuron with stake = neuron.stake + new_stake
                    }
                }
            };
            case (#increase_delay(new_delay)) {
                //check if dissolving TEST
                var delay : Int = new_delay;
                if (new_delay < neuron.dissolve_delay) delay := neuron.dissolve_delay;

                if (neuron.state == #locked) {
                    Debug.print("increase dissolve_delay");
                    new_neuron := {
                        new_neuron with dissolve_delay = delay
                    }
                }
            };
            case (#change_state(new_state)) {
                switch (new_state) {
                    case (#dissolving) {
                        new_neuron := {
                            new_neuron with state = new_state;
                            dissolve_start = ?Time.now()
                        }
                    };
                    case (#locked) {
                        Debug.print("new dissolve_delay");
                        Debug.print(debug_show (neuron.dissolve_delay - TU.daysFromEpoch(Time.now() - Option.get(neuron.dissolve_start, 0))));
                        new_neuron := {
                            new_neuron with state = new_state;
                            dissolve_delay = neuron.dissolve_delay - TU.daysFromEpoch(Time.now() - Option.get(neuron.dissolve_start, 0))
                        }
                    }
                }
                //new_neuron := { new_neuron with state = new_state }
            }
        };
        new_neuron
    };

    //CHORE change to private
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
                        let new_neuron = process_neuron_state_change(user, neuron, new_value);
                        var new_neurons = Array.filter<Neuron>(container.neurons, func(n) { return n.id != neuron.id });
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

    public shared ({ caller }) func increase_neuron_stake(id : Nat, new_stake : Float) : async () {
        ignore set_neuron_state(caller, id, #increase_stake(new_stake))
    };

    //check dissolve condition TEST
    public shared ({ caller }) func completely_dissolve_neuron(id : Nat) : async Result.Result<Bool, Text> {

        switch (can_dissolve(caller, id)) {
            case (#ok(true)) {
                //delete neuron
                var reimburse_amount : Float = delete_neuron(caller, id);

                //internal_transfer TEST
                internal_transfer(Principal.fromActor(this), caller, reimburse_amount);
                return #ok(true)
            };
            case (#ok(false)) { return #ok(false) };
            case (#err(msg)) {
                return #err(msg)
            }
        }
    };

    private func can_dissolve(owner : Principal, id : Nat) : Result.Result<Bool, Text> {
        let test1 : ?NeuronsContainer = do ? {
            let first = Map.get(neurons, phash, owner);
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
                        if (neuron.state == #locked) {
                            #ok(false)
                        } else {
                            if (neuron.dissolve_delay - TU.daysFromEpoch(Time.now() - Option.get(neuron.dissolve_start, 0)) > 0 or neuron.dissolve_delay <= 0) {
                                #ok(false)
                            } else {
                                #ok(true)
                            }
                        }
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

    //CHORE remove public and async
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

    private func get_voting_power(user : Principal) : async Float {

        if (IS_QUADRATIC) {
            return (Float.sqrt(await get_default_ledger_balance(user)))
        };

        switch (current_vp_mode) {
            case (#basic) await get_default_ledger_balance(user);
            case (#advanced) { calculate_user_vp(user) } //CHORE wrap
        }
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
                Debug.print(text);
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

    //TEST
    private func calculate_neuron_vp(neuron : Neuron) : Float {
        Debug.print("calculate_neuron_vp START");
        var lockup_bonus = LOCKUP_BONUS_START;
        var age_bonus = AGE_BONUS_START;
        var stake = neuron.stake;

        let days_since_last_unlock = TU.daysFromEpoch(Time.now() - Option.get(neuron.dissolve_start, neuron.creation_date));
        //Debug.print("TIME.NOW: " # debug_show (Time.now()) # " , " # debug_show (Option.get(neuron.dissolve_start, neuron.creation_date)));
        Debug.print("days_since_last_unlock");
        Debug.print(debug_show (days_since_last_unlock));
        if (neuron.state != #dissolving) {
            var capped_days = days_since_last_unlock;
            if (capped_days > 365 * MAX_AGE_BONUS) {
                capped_days := 365 * MAX_AGE_BONUS
            };
            age_bonus := age_bonus + (0.0001712 * Float.fromInt(capped_days))
        };

        if (age_bonus > AGE_BONUS_END) age_bonus := AGE_BONUS_END; // round

        var remaining_days = neuron.dissolve_delay;
        Debug.print("remaining_days");
        Debug.print(debug_show (remaining_days));
        if (remaining_days < MIN_LOCKUP_MONTHS * 30) {
            return 0
        };

        var capped_remaining_days = remaining_days;
        if (capped_remaining_days > MAX_LOCKUP_MONTHS * 30) {
            capped_remaining_days := MAX_LOCKUP_MONTHS * 30
        };

        //let lockup_bonus_daily_factor = (MAX_LOCKUP_MONTHS - MIN_LOCKUP_MONTHS) / (LOCKUP_BONUS_END - LOCKUP_BONUS_START)
        lockup_bonus := lockup_bonus + (Float.fromInt(capped_remaining_days) * 0.00034337);

        if (lockup_bonus > Float.fromInt(LOCKUP_BONUS_END)) lockup_bonus := Float.fromInt(LOCKUP_BONUS_END); // round
        //2.737,5
        Debug.print("lockup_bonus");
        Debug.print(debug_show (lockup_bonus));
        Debug.print("age_bonus");
        Debug.print(debug_show (age_bonus));
        Debug.print("stake");
        Debug.print(debug_show (stake));

        Debug.print("vp neuron id: " # debug_show (neuron.id) # " VP:" # debug_show (stake * age_bonus * lockup_bonus));

        return stake * age_bonus * lockup_bonus
    };

}

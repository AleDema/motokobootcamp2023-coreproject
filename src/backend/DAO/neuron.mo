module {
    public type NeuronState = {
        #locked;
        #dissolving;
        #dissolved
    };

    public type NeuronActions = {
        #increase_stake : Float;
        #increase_delay : Nat;
        #change_state : NeuronState
    };

    public type Neuron = {
        id : Nat;
        stake : Float;
        creation_date : Int; //timestamp
        dissolve_start : ?Nat; //timestamp
        dissolve_delay : Nat; //days
        state : NeuronState
    };

    public type NeuronsContainer = {
        current_neuron_id : Nat;
        neurons : [Neuron]
    };

}

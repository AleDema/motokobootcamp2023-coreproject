module {
    public type NeuronState = {
        #locked;
        #dissolving
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
        dissolve_start : ?Int; //timestamp
        dissolve_delay : Int; //days
        state : NeuronState
    };

    public type NeuronsContainer = {
        current_neuron_id : Nat;
        neurons : [Neuron]
    };

}

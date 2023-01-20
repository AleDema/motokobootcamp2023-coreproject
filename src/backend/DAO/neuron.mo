module {
    public type NeuronState = {
        #locked;
        #dissolving;
        #dissolved
    };

    public type Neuron = {
        id : Nat;
        stake : Nat;
        creation_date : Nat;
        dissolve_delay : Nat;
        state : NeuronState
    }

}

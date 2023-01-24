# Motoko Bootcamp 2023 Core project

Motoko Bootcamp 2023 core project

- React for DOM manipulation
- TailwindCSS for styling
- Valtio as state manager
- React Router V6 for routing
- Connect2IC for auth
- ZhenyaUsenko's stable hashmap

## Running the project locally

If you want to test your project locally, you can use the following commands:

```bash
npm i
mops install
dfx start --clean --emulator
```
Run this comand to start the ledger canister locally

```
  dfx deploy ledger --argument "( record {                     
      name = \"<MBTT>\";                         
      symbol = \"<MBTT>\";                           
      decimals = 6;                                           
      fee = 1_000_000;                                        
      max_supply = 1_000_000_000_000;                         
      initial_balances = vec {                                
          record {                                            
              record {                                        
owner = principal \"your-principal\";   
                  subaccount = null;                                  
              };                                              
              100_000_000_000_000_000                                 
          }                                                   
      };                                                      
      min_burn_amount = 10_000_000;                           
      minting_account = null;                                 
      advanced_settings = null;                               
  })"
  ```

Alternately, step by step, you can run

```
    change IS_LOCAL_ENV to "true" in Webpage.mo and main.mo
    change the ledger canister id in App.jsx
    dfx deploy (webpage, DAO)
    num run dev
```


☑️ Requirements
The goal for this edition is to build a DAO (Decentralized Autonomous Organization) with the following requirements:

The DAO is controlling a webpage and is able to modify the text on that page through proposals.
The DAO can create proposals. Each user is able to vote on proposals if he has at least 1 Motoko Bootcamp (MB)token.
The voting power of any member is equal to the number of MB they hold (at the moment they cast their vote).
A proposal will automatically be passed if the cumulated voting power of all members that voted for it is equals or above 100.
A proposal will automatically be rejected if the cumulated voting power of all members that voted against it is equals or above 100.
Here is a few functions that you'll need to implement in your canister

submit_proposal
get_proposal
get_all_proposals
vote
If you want to graduate with honors you'll have to complete those additional requirements:

Users are able to lock their MB tokens to create neurons by specifying an amount and a dissolve delay.

Neurons can be in 3 different states:

Locked: the neuron is locked with a set dissolve delay and the user needs to switch it to dissolving to access their MB.
Dissolving: the neuron's dissolve delay decreases over time until it reaches 0 and then the neuron is dissolved and the user can access their ICP.
Dissolved: the neuron's dissolve delay is 0 and the user can access their ICP. The dissolve delay can be increased after the neuron is created but can only be decreased over time while the neuron is in dissolving state. Also, neurons can only vote if their dissolve delay is more than 6 months. Additionally, neurons have an age which represents the time passed since it was created or last stopped dissolving.
Voting power of a neuron is counted as followed: AMOUNT MB TOKENS * DISSOLVE DELAY BONUS * AGE BONUS where:

Dissolve delay bonus: The bonuses scale linearly, from 6 months which grants a 1.06x voting power bonus, to 8 years which grants a 2x voting power bonus
Age bonus: the maximum bonus is attained for 4 years and grants a 1.25x bonus, multiplicative with any other bonuses. The bonuses for durations between 0 seconds and 4 years scale linearly between.
Proposals are able to modify the following parameters:

The minimum of MB token necessary to vote (by default - 1).
The amount of voting power necesary for a proposal to pass (by default - 100).
An option to enable quadratic voting, which makes voting power equal to the square root of their MB token balance.

The canister is blackholed.

Here is a few functions that you'll need to implement in your canister

submit_proposal
get_proposal
get_all_proposals
vote
modify_parameters
quadratic_voting
createNeuron
dissolveNeuron 
To graduate with honors you do not need to implement a follow system between neurons as in the NNS (but of course if you want to do that feel free to do so!)

If you want to graduate among the best students there is no specific requirement that we can give but you will be judged based on the following criteria:

The code is clear and concise.
The code is safe, secure and doesn't contain any bug.
Additional functionalities have been implemented beyond the requirements.
```
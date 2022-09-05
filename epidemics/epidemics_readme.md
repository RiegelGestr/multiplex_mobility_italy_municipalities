# Epidemics
The following text walks through the main functionalities of the folder.

## `disease.jl`
Inside this script there are the main functions of the disease step of the simulation, i.e. the SIR update rule.
We loop over all the municipalities, identified by the struct `City`, and we modifies the value of the compartments of the city according to the used model. The SIR model is implemented and the parameter are given by the fields `R0` and `tau` of the struct `Model`.
To implement another model one needs to modify the function `disease_single!` and use other update rule, we suggest to reuse the function `change_state` sample the number of people `total` that change state given the probability `prob` of changing state.

## `mobility.jl`
Inside this script there are the main functions of the mobility step of the simulation. 
The functions are independent of the model implemente, they apply the same mobility rule to all the
compartments of the city. The mobility sampling is done using <em> Inverse Smirnov Sampling</em>, more can be found [here](https://en.wikipedia.org/wiki/Inverse_transform_sampling).

## `utils.jl`
Inside this script there are utility functions. 
`add_infected!` add the starting infected population to the chosen starting point. 
`reset_all_cities` reset the compartments to the initial state, it assumes that we are simulating a SIR model.
`lockdown!`: if `lockdown_flag` is `true`, at time `t0` it removes the layers in `lockdowns_array`, and at time `t1` it re-inserts.


## `simulations.jl`
The function `read_and_initialize_the_model` load the data from the folder `network`, that can be
downloaded from [zenodo_small_folder](https://github.com), and initialize a `Model` struct, given the input passed.
The input of this function are:
- `lockdown_flag` a `Bool` variable used to know if some layers need to be removed and reinserted at the given time `[t0,t1]`
- `lockdowns` a `Vector` of `Int64` representing the number of the layers to be removed and reinserted. `1` is associated to `intra_prov`, `2` to `inter_prov`, `3` to `train`,`4` to `flight`. In case `lockdown_flag` is `false` pass an empty `Vector`.
- `t0` a `Int64` representing the time at which the layers inside `lockdowns` are removed.
- `t1` a `Int64` representing the time at which the layers inside `lockdowns` are reinserted.
- `mobility_level` a `Float64` representing the mobility level, i.e. the percentage of population leaving the starting location. Default value set to 0.1 (as explained in the paper).
- `R0` a `Float64` representing the mean reproduction number. Default value set to 2.5 (as explained in the paper)
- `tau` a `Float64` representing the inverse of mean infectious period. Default value set to 8.0 (as explained in the paper).

Note that inside this function the probability of choosing a layer is hard-coded (line 119). This function has been written having in mind to simulate a SIR model, inside the function we explain what are the lines to be changed to account for a different disease model.

The function `main` is an example of simulation code. The function needs as input the following parameters:
- `model` a `Model` variable initialized as done by the function `read_and_initialize_the_model`.
- `tot_config` a `Int64` representing the total number of configurations to simulate.
- `starting_point` a `Int64` representing the starting city of the disease.
- `how_many_infected` a `Int64` representing the infected population of the starting city.
- `total_time_length` a `Int64` representing the total length time of the simulation.

The output of this function are saved inside the folder `data_output`.
The results are stored as a csv file for each compartment followed by the number of simulated configuration, e.g. `susceptible_42.csv`.
Each column is associated with a municipality, and the row corresponds to the time evolution.

As an example a `REPL` code is provided:
<br>
<code>
julia> include("simulations.jl")<br>
julia> lockdowns = [1,2]<br>
julia> model = read_and_initialize_the_model(lockdown_flag = true,lockdowns = lockdowns,t0 = 10, t1 = 40,mobility_level = 0.1,R0 = 2.5, tau = 8.0)<br>
julia> main(model = model,tot_config = 1,starting_point = 1463, how_many_infected = 25,total_time_length = 60)<br>
</code>

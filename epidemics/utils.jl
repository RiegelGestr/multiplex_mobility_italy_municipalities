#fundamental structs
#city struct containing information of the city, its connections
mutable struct City <: Any
	#city label
	pos::Int64
	#disease compartments
    compartments::Array{Int64,1}
	#movement matrix --> layer probability
    movement::Array{Float64,1}
	#array containing the layers in lockdown, i.e. people cannot use it to move across city
    lockdown::Array{Int64,1}
    #=
    dictionary with key the layer and value an array containing labels of the neighbors cities on the given layer and
    the associated probability (sum of this array is 1)
	=#
    neighbors::Dict{Int64,Tuple{Array{Int64,1},Array{Float64,1}}}
    #=
    dictionary with key the neighbor city to move people and value an array containing the disease compartments
    this field is used in the mobility and update step
    =#
	neighbors_to_who_messages::Dict{Int64,Array{Int64,1}}
    #=
    dictionary with key the neighbor city that move people to this city and value an array containing the disease compartments
    this field is used in the disease step
    =#
	neighbors_from_who_messages::Dict{Int64,Array{Int64,1}}
end
#city struct containing information of the model, nodes and relationships
mutable struct Model <: Any
    #disease fields R0 and tau, explained in https://arxiv.org/abs/2205.03639
    R0::Float64
    tau::Float64
	#flag if the model is running in lockdown mode
	lockdown_flag::Bool
	#array containing the layers in lockdown, i.e. the people cannot use it to move across city
	lockdowns_array::Array{Int64,1}
	#t0 --> time at which remove the layers in lockdowns_array (check function lockdown in utils.jl)
	t0::Int64
    #t1 --> time at which re-add the layers in lockdowns_array (check function lockdown in utils.jl)
    t1::Int64
	#mobility level --> probability people leaving the home city
	mobility_level::Float64
	#movement matrix --> layer probability
	movement::Array{Float64,1}
	#dataframe containing information about the nodes, used to do check
	data::DataFrame
	#array containing the nodes or the cities structs
	cities::Array{City,1}
	#temp fields used to do checks, more can be found in the function update_situation_cities in mobility.jl
	register::Dict{Int64,Array{Int64,1}}
	register_edges::Dict{Tuple{Int64,Int64},Array{Int64,1}}
end
#reset all cities after N time steps. the function assumes that we are simulating a SIR (3+1 compartments)
function reset_all_cities!(model::Model)
	for city in model.cities
		agents = model.data[model.data.node .== city.pos,:].agents[1]
		city.compartments = [agents,0,0,0]
		city.lockdown = Array{Int64,1}()
	end
	return model
end
#=
add infected function at the starting cities. here we are assuming that the infection start in a single city, in the
case of multiple starting points one needs just to add a for loop and the starting point becomes an array of integers.
also the function assumes that we are simulating a SIR (3+1 compartments)
=#
function add_infected!(;model::Model,starting_point::Int64,how_many_infected::Int64)
	city = model.cities[starting_point]
	city.compartments = [city.compartments[1]-how_many_infected,city.compartments[2]+how_many_infected,0,0]
	return model
end
#=
lockdown function: if lockdown flag is true, at the decided times the chosen layers (in the model struct) are
removed (i.e. pushed to city.lockdown field). the lockdown times are used for all the layers, but this function and the
struct can be easily changed to account for this issue.
=#
function lockdown!(model::Model,time::Int64)
	model.lockdown_flag != true && return model
	t0 = model.t0
	t1 = model.t1
	if time == t0
	    #add the layers in lockdowns_array field to city.lockdown field
		for city in model.cities
			for l in model.lockdowns_array
				push!(city.lockdown,l)
			end
		end
		return model
	elseif time == t1
        #remove the layers in lockdowns_array field to city.lockdown field
		for city in model.cities
			for l in model.lockdowns_array
				filter!(x-> x ≠ l,city.lockdown)
			end
		end
		return model
	else
		return model
	end
end

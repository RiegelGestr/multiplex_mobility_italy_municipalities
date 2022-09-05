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

#=
Inverse transform sampling function
https://en.wikipedia.org/wiki/Inverse_transform_sampling
also here https://stephens999.github.io/fiveMinuteStats/inverse_transform_sampling.html
This function was written in 2020. in that period the sampling function of Distributions.jl was not that performant.
However today if one use the sampling function of Distributions.jl, by defining a categorical distribution,
the performance are similar to this one :D.
(more can be found here https://juliastats.org/Distributions.jl/stable/univariate/#Distributions.Categorical)
=#
function rand_intervals(intervals::Array{Float64,1})
	j = rand()
    idx = findfirst(x-> j <= x,intervals)
    return idx
end
#mobility function to each city
function mobility_single_city!(city::City,mobility_level::Float64)
    #loop on the compartments
	for index_compartment in 1:length(city.compartments)
        #check if
		if city.compartments[index_compartment] == 0
			continue
		end
		#temp variable counting the number of people in the given compartment leaving
		tmp = 0
		total = city.compartments[index_compartment]
		for i in 1:total
			x = rand()
			if x < mobility_level
			    #choosing the layer in the possible ones (in our case 4: intra_prov,inter_provi,trains,flights)
				how_index = rand_intervals(city.movement)
				#if the chosen layer is prohibited (i.e. lockdown for the given transportation layer), continue
				if how_index in city.lockdown
					continue
				end
				#it could be that on the chosen layer there are no connections
				if length(city.neighbors[how_index][1]) == 0
					continue
				end
				#where to move (chosen according to the probability distribution)
				where_index = rand_intervals(city.neighbors[how_index][2])
				#use the index to retrieve the neighbor
				where_send = city.neighbors[how_index][1][where_index]
				#save the messages
				city.neighbors_to_who_messages[where_send][index_compartment] += 1
				tmp += 1
			end
		end
		#use the temp variable to update the pop in the given compartments
		city.compartments[index_compartment] -= tmp
	end
	return city
end
#mobility function on single process (simple scatter of the cities array in multi-proc case)
function mobility_cities_single_proc(x::Array{City,1},mobility_level::Float64)
	z = Array{City,1}()
	for city in x
		push!(z,mobility_single_city!(city,mobility_level))
	end
	return z
end
#mobility function over all the cities
function mobility_cities!(model::Model)
	x = model.cities
	mobility_level = model.mobility_level
	temp_x = mobility_cities_single_proc(x,mobility_level)
	model.cities = temp_x
	return model
end
#=
update function: after the mobility step (i.e. find the people where they want to go) the messages (people moving across)
need to be sent, so update the field neighbors_from_who_messages of the city struct
=#
function update_situation_cities!(model::Model)
    #the register_edges field is a temp variable, used to do check
	for city in model.cities
		for (neighbor,array_message) in city.neighbors_to_who_messages
			#starting city -> neighbor city to which send the message (array_message)
			push!(model.register_edges,(city.pos,neighbor) => array_message)
		end
	end
	Number_of_compartments = length(model.cities[1].compartments)
	#store the messages in the proper fields of the city struct
	for ((starting_city,ending_city),v) in model.register_edges
		for i in 1:Number_of_compartments
			model.cities[ending_city].neighbors_from_who_messages[starting_city][i]+=v[i]
		end
	end
	return model
end
#=
go back home function: after the disease step the messages (people moving across) need to be resent back,
so bring back home the moved people in the mobility-update step
=#
function go_back_home!(model::Model)
	Number_of_compartments = length(model.cities[1].compartments)
    #the register field is a temp variable, used to do check
	for city in model.cities
		for (neighbor,array_message) in city.neighbors_from_who_messages
			for i in 1:Number_of_compartments
				model.register[neighbor][i] += array_message[i]
			end
		end
	end
	for city in model.cities
		for i in 1:Number_of_compartments
			city.compartments[i] += model.register[city.pos][i]
		end
		#reset the temp fields
		for k in keys(city.neighbors_to_who_messages)
			city.neighbors_to_who_messages[k] = zeros(Int64,Number_of_compartments)
		end
		for k in keys(city.neighbors_from_who_messages)
			city.neighbors_from_who_messages[k] = zeros(Int64,Number_of_compartments)
		end
		model.register[city.pos] = zeros(Int64,Number_of_compartments)
	end
	model.register_edges = Dict{Tuple{Int64,Int64},Array{Int64,1}}()
	return model
end
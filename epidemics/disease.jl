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
#function disease over all the cities, i.e. the nodes
function disease_cities!(model::Model)
    #it modifies the model, since it modifies the value of the compartments of each city
	for city in model.cities
	    #disease single city
	    #used this structure since it can easily be parallelized (process parallel)
		disease_single!(city,model.R0,model.tau)
	end
	#return the model modified
	return model
end
#function disease on a single city, i.e. the node
function disease_single!(city::City,R0::Float64,tau::Float64)
    #this function modifies the value of the compartments of the city according to the used model
    #in our case we consider the SIR Model
    #function compartment transition rule S -> I
	susceptible_to_infected!(city,tau,R0)
	#function compartment transition rule I -> R
	infected_to_recover!(city,tau)
	#return the city modified
	return city
end
#generic function sample the number of people [total] that change state given the probability [prob] of changing state
function change_state(total::Int64,prob::Float64)
    #total number of people that change state
	i = 0
	for idx in 1:total
	    #used this structure --> thread pool
		if rand() < prob
			i += 1
		end
	end
	#return the total number of people changing state
	return i
end
#function compartment transition rule: susceptible to infected
function susceptible_to_infected!(city::City,tau::Float64,R0::Float64)
    #count total number of infected in the city, both the city and the visting people
	total_infected_in_the_city = city.compartments[2]
	#neighbors people
	for (k,v) in city.neighbors_from_who_messages
		total_infected_in_the_city += v[2]
	end
	#check if
	if total_infected_in_the_city == 0
		return city
	else
        #count total people in the city, both the city and the visting people
		total_people_in_city = sum(city.compartments)
		total_people_in_city += sum([sum(v) for (k,v) in city.neighbors_from_who_messages])
		#probability of the transition rule
		prob = 1 - (1-R0/(tau*total_people_in_city))^total_infected_in_the_city
		#count number of people changing state, first city
		total_susc = city.compartments[1]
		new_i = change_state(total_susc,prob)
		#the third compartment is a temporary element, to properly count infected to recover in the other function
		city.compartments[3] += new_i
		city.compartments[1] -= new_i
		#neighbors
		tmp_dict = city.neighbors_from_who_messages
		for (neighbor,v) in tmp_dict
			total_susc = v[1]
            #check if (if no susceptible dont waste time)
			if total_susc == 0
				continue
			end
			new_i = change_state(total_susc,prob)
			#collect the results for eac h neighbor
            #the third compartment is a temporary element, to properly count infected to recover in the other function
			city.neighbors_from_who_messages[neighbor][3] += new_i
			city.neighbors_from_who_messages[neighbor][1] -= new_i
		end
		#return the city modified
		return city
	end
end
#function compartment transition rule: infected to recover
function infected_to_recover!(city::City,tau::Float64)
	#start with the infected of the city
	if city.compartments[2] == 0
	    #if no infected, then update correctly the infected position by using the temporary infected in the third pos
		city.compartments[2] = city.compartments[3]
		#erase the temporary element
		city.compartments[3] = 0
	else
		total_inf = city.compartments[2]
        #probability of the transition rule
		prob = 1/tau
		#count number of people changing state, first city
		new_r = change_state(total_inf,prob)
		#update correctly the various compartments
		city.compartments[4] = city.compartments[4] + new_r
		#update the infected, using both the infected -> recover and the temporary infected (third pos)
		city.compartments[2] = city.compartments[2] - new_r + city.compartments[3]
        #erase the temporary element
		city.compartments[3] = 0
	end
	#neighbor people
	#tmp_dict is a copy of city.neighbors_from_who_messages to properly update it in the loop
	tmp_dict = city.neighbors_from_who_messages
	for (neighbor,v) in tmp_dict
		total_inf = v[2]
		#check if on the total infected
		if total_inf == 0
            #if no infected, then update correctly the infected position by using the temporary infected in the third pos
			city.neighbors_from_who_messages[neighbor][2] = city.neighbors_from_who_messages[neighbor][3]
            #erase the temporary element
			city.neighbors_from_who_messages[neighbor][3] = 0
		else
			prob = 1/tau
            #probability of the transition rule
			new_r = change_state(total_inf,prob)
            #update correctly the various compartment
			city.neighbors_from_who_messages[neighbor][4] = city.neighbors_from_who_messages[neighbor][4] + new_r
            #update the infected, using both the infected -> recover and the temporary infected (third pos)
			city.neighbors_from_who_messages[neighbor][2] = city.neighbors_from_who_messages[neighbor][2] - new_r + city.neighbors_from_who_messages[neighbor][3]
            #erase the temporary element
			city.neighbors_from_who_messages[neighbor][3] = 0
		end
	end
	#return the modified city
	return city
end

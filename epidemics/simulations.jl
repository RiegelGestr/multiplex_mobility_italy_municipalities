#packages to be loaded (used for the input and the output)
using CSV, DataFrames, LazyJSON
using ProgressBars
#include other scripts
include("disease.jl")
include("mobility.jl")
include("utils.jl")
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
main function --> simulation of the model and save the results on disk
=#
function main(;model::Model,tot_config::Int64,starting_point::Int64,how_many_infected::Int64,total_time_length::Int64)
    #loop on the total number of simulation (tot_config) that we want to run
	for config in ProgressBar(1:tot_config)
		#create a dataframe as output for each compartment.
		#the columns identify the municipalities (associate with the index), storing the time evolution (as time series)
		data_collection_susceptible = DataFrame()
		data_collection_infected = DataFrame()
		data_collection_recovered = DataFrame()
		for i in 1:length(model.cities)
			data_collection_susceptible[!,string(i)] = zeros(Int64,total_time_length)
			data_collection_infected[!,string(i)] = zeros(Int64,total_time_length)
			data_collection_recovered[!,string(i)] = zeros(Int64,total_time_length)
		end
		#add starting infected at the given starting_point
		add_infected!(model = model,starting_point = starting_point,how_many_infected = how_many_infected)
		#time evolution of the model
		for t in ProgressBar(1:total_time_length)
            #check if put a layer in lockdown, i.e. remove the given layer from the possible ones.
			lockdown!(model,t)
			#mobility step
			mobility_cities!(model)
			#update the mobility (actually move the population)
			update_situation_cities!(model)
			#disease step
			disease_cities!(model)
			#bring back the moved people
			go_back_home!(model)
			#store output in the dataframes
			for city in model.cities
				data_collection_susceptible[t,string(city.pos)] = city.compartments[1]
				data_collection_infected[t,string(city.pos)] = city.compartments[2]
				data_collection_recovered[t,string(city.pos)] = city.compartments[4]
			end
		end
		#save output
		#!!! Assumption that there is a folder data_output in the same folder of the code !!!
		CSV.write("data_output/susceptible_$config.csv",data_collection_susceptible)
		CSV.write("data_output/infected_$config.csv",data_collection_infected)
		CSV.write("data_output/recovered_$config.csv",data_collection_recovered)
		#reset all cities
		reset_all_cities!(model)
	end
end
#=
read and initialize model struct function to use in the main simulation function
=#
function read_and_initialize_the_model(;lockdown_flag::Bool,lockdowns::Vector{Int64},t0::Int64,t1::Int64,mobility_level::Float64=0.1,R0::Float64=2.5,tau::Float64=8.0)
	#load input data (ASSUMPTION that the date are in the network/ folder and this folder is the same directory as the file)
	#these files are explained in the folder network construction
	#graph file as dictionary (JSON)
	graph = LazyJSON.parse(String(read("network/graph.json")))
	#graph file with the connections (JSON)
	rev_graph = LazyJSON.parse(String(read("network/rev_graph.json")))
	#dataframe file containing information about the nodes (cities),like the number of people
	data = CSV.File("network/nodes.csv")|>DataFrame
	#probability of each layer (HARD CODED)
	probs = [0.0,0.4,0.3,0.2,0.1]
	#create the movement_matrix to be used in the smirnov inverse sampling
	#intervals is an array where each element is a vector [\sum{j = 1}^{i} p_i,\sum{j = 1}^{i+1} p_i]
	intervals = [[sum(probs[1:i]),sum(probs[1:i+1])] for i in 1:length(probs)-1]
	movement_matrix = [intervals[i][2] for i in 1:length(intervals)]
	#loop to build the cities array used in the model struct
	#here we are assuming that we are simulating a SIR model (HARD CODED) and that the layers are 4
	array_cities = Array{City,1}()
	neighbors_register = Dict{Int64,Array{Int64,1}}()
	for row in ProgressBar(eachrow(data))
	    #mobility
		temp_neighbors_movement = graph[string(row.node)]
		new_dict_movement = Dict{Int64,Tuple{Array{Int64,1},Array{Float64,1}}}()
		dict_to_message = Dict{Int64,Array{Int64,1}}()
		for index_layer in 1:4
			layer = temp_neighbors_movement[string(index_layer)]
			tmp = (convert(Array{Int64,1},layer[1]),convert(Array{Float64,1},layer[2]))
			push!(new_dict_movement, index_layer=>tmp)
			for neighbor in tmp[1]
				push!(dict_to_message,neighbor => zeros(Int64,4))
			end
		end
		temp_rev_neighbors = rev_graph[string(row.node)]
		tmp = convert(Array{Int64,1},temp_rev_neighbors)
		dict_from_message = Dict{Int64,Array{Int64,1}}()
		#=
		In case of different disease Model simulated, one needs to change the following lines.
		Line 157 needs to be change to:
		push!(dict_from_message,n=>zeros(Int64,number_of_compartments)
        where number_of_compartments accounts for the number of disease compartments in the new model.
        Line 159 needs to be change to:
        push!(array_cities,City(row.node,[row.agents,0 x (number_of_compartments-1)],movement_matrix,Array{Int64,1}(),new_dict_movement,dict_to_message,dict_from_message))
        where with 0 x (number_of_compartments -1) we are suggesting to pass to the City struct an array with zeros as many compartments.
        Line 160 needs to be change to:
		push!(neighbors_register,row.node=>zeros(Int64,number_of_compartments))
        where number_of_compartments accounts for the number of disease compartments in the new model.
		=#
		for n in tmp
			push!(dict_from_message, n => zeros(Int64,4))
		end
		push!(array_cities,City(row.node,[row.agents,0,0,0],movement_matrix,Array{Int64,1}(),new_dict_movement,dict_to_message,dict_from_message))
		push!(neighbors_register,row.node=>zeros(Int64,4))
	end
	register_edges = Dict{Tuple{Int64,Int64},Array{Int64,1}}()
	model = Model(R0,tau,lockdown_flag,convert(Array{Int64,1},lockdowns),t0,t1,mobility_level,movement_matrix,data,array_cities,neighbors_register,register_edges)
	return model
end
#=
lockdowns = [parse(Int64,x) for x in ARGS]
model = read_and_initialize_the_model(lockdown_flag = true,lockdowns = lockdowns,t0 = 10, t1 = 40,mobility_level = 0.1,R0 = 2.5, tau = 8.0)
main(model = model,tot_config = 1,starting_point = 1463, how_many_infected = 25,total_time_length = 60)
main(model = model,tot_config = 100,starting_point = 1463, how_many_infected = 25,total_time_length = 60)
=#
#####################################################################################################################
#dict_nodes = {"roma":"5008","milano":"1463","napoli":"5609"}
# roma  50 5008
# napoli 20 5609
# milano 25 1463
# how_many_infected = parse(Int64,ARGS[1])
# starting_point = parse(Int64,ARGS[2])

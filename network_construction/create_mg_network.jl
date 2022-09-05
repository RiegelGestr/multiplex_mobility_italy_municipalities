using Graphs, MetaGraphs,JSON
using CSV, DataFrames

function create_metagraph_from_csv()
    edges = CSV.File("edges.csv") |> DataFrame
    nodes = Set(vcat(edges.src,edges.dst))
    graph = DiGraph(length(nodes))
    for edge in eachrow(edges)
        add_edge!(graph,edge.src,edge.dst)
    end
    savegraph("simple_graph.lgz", graph)
    meta_graph = MetaDiGraph(graph)
    nodes = CSV.File("nodes.csv") |> DataFrame
    for node in eachrow(nodes)
        set_prop!(meta_graph,node.node,:agents,node.agents)
    end
    translate_dict = Dict("intra_prov"=>:intra_prov,"inter_prov"=>:inter_prov,"train"=>:train,"flight"=>:flight)
    for edge in eachrow(edges)
        set_prop!(meta_graph,edge.src,edge.dst,translate_dict[edge.type],edge.weight)
    end
    savegraph("network.mg", meta_graph)
end


function create_intervals(weight::Array{Float64,1})
	neighbor_weight = [0.0]
	neighbor_weight = vcat(neighbor_weight,weight)
	intervals = [[sum(neighbor_weight[1:i]),sum(neighbor_weight[1:i+1])] for i in 1:length(neighbor_weight)-1]
	res_intervals = [intervals[i][2] for i in 1:length(intervals)]
	return res_intervals
end


function create_json_from_metagraph()
    graph = loadgraph("network.mg",MGFormat())
    json_output = Dict{String,Dict{String,Tuple{Array{Int64,1},Array{Float64,1}}}}()
    for n in vertices(graph)
        #layer
        inter_prov_neigh = Array{Int64,1}()
        intra_prov_neigh = Array{Int64,1}()
        train_neigh = Array{Int64,1}()
        flight_neigh = Array{Int64,1}()
        #weight
        inter_prov_weigh = Array{Float64,1}()
        intra_prov_weigh = Array{Float64,1}()
        train_weigh = Array{Float64,1}()
        flight_weigh = Array{Float64,1}()
        for neighbor in neighbors(graph,n)
            for (key_prop,prop) in props(graph,n,neighbor)
                if key_prop == :inter_prov
                    push!(inter_prov_neigh,neighbor)
                    push!(inter_prov_weigh,prop)
                elseif key_prop == :intra_prov
                    push!(intra_prov_neigh,neighbor)
                    push!(intra_prov_weigh,prop)
                elseif key_prop == :train
                    push!(train_neigh,neighbor)
                    push!(train_weigh,prop)
                elseif key_prop == :flight
                    push!(flight_neigh,neighbor)
                    push!(flight_weigh,prop)
                end
            end
        end
        push!(json_output,string(n)=>Dict{String,Tuple{Array{Int64,1},Array{Float64,1}}}())
        push!(json_output[string(n)],"1"=>(inter_prov_neigh,create_intervals(inter_prov_weigh)))
        push!(json_output[string(n)],"2"=>(intra_prov_neigh,create_intervals(intra_prov_weigh)))
        push!(json_output[string(n)],"3"=>(train_neigh,create_intervals(train_weigh)))
        push!(json_output[string(n)],"4"=>(flight_neigh,create_intervals(flight_weigh)))
    end
    stringdata = JSON.json(json_output)
    open("graph.json", "w") do f
        write(f, stringdata)
    end
end
import json
import networkx as nx

import pandas as pd

def create_reversed_network():
    with open("graph.json","r") as inpuf:
        graph = json.load(inpuf)
    tmp_graph = nx.DiGraph()
    for (k_node,v) in graph.items():
        for (layer,array) in v.items():
            for el in array[0]:
                tmp_graph.add_edge(k_node,str(el))
    rev_graph = tmp_graph.reverse()
    dict_output = {n:[int(x) for x in rev_graph.neighbors(n)] for n in rev_graph.nodes()}
    with open("rev_graph.json","w") as outpuf:
        json.dump(dict_output,outpuf)


def create_network_for_julia():
    italy = nx.read_gpickle('network_italy.pkl')
    easy_node_dict = {n:idx+1 for idx,n in enumerate(italy.nodes())}
    easy_edge_dict = []
    for e in italy.edges():
        for k,v in italy.edges[e].items():
            if k == 'intra_prov':
                easy_edge_dict.append({
                    'src':easy_node_dict[e[0]],
                    'dst':easy_node_dict[e[1]],
                    'weight':v,
                    'type':'intra_prov',
                })
            elif k == 'inter_prov':
                easy_edge_dict.append({
                    'src':easy_node_dict[e[0]],
                    'dst':easy_node_dict[e[1]],
                    'weight':v,
                    'type':'inter_prov',
                })
            elif k == 'train':
                easy_edge_dict.append({
                    'src':easy_node_dict[e[0]],
                    'dst':easy_node_dict[e[1]],
                    'weight':v,
                    'type':'train',
                })
            elif k == 'flight':
                easy_edge_dict.append({
                    'src':easy_node_dict[e[0]],
                    'dst':easy_node_dict[e[1]],
                    'weight':v,
                    'type':'flight',
                })
    edges = pd.DataFrame(easy_edge_dict)
    edges.to_csv('edges.csv',sep=',')
    #agents
    with open("municipalities.csv", "r") as inpuf:
        municipalities = pd.read_csv(inpuf)
    select = 'SELECT * FROM ComuniItalia where id_istat == {numero}'
    easy_agents_dict = []
    for k,v in easy_node_dict.items():
        data = municipalities[municipalities.id_istat == k]
        easy_agents_dict.append({
                                'id_istat':k,
                                'node':v,
                                'agents':data.agents.values[0],
                                'lat':italy.nodes[k]["lat"],
                                "lng":italy.nodes[k]["lng"]
                                })
    nodes = pd.DataFrame(easy_agents_dict)
    nodes["min_max"] = 3*(nodes.agents-min(nodes.agents))/(max(nodes.agents)-min(nodes.agents))
    nodes.to_csv('nodes.csv',sep=',')


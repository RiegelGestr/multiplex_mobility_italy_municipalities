import pandas as pd
import networkx as nx
def main():
    with open("trains.csv",'r') as input_file:
        trains = pd.read_csv(input_file, sep = ',')
    id_trains = list(set(list(trains.src.unique())+list(trains.dst.unique())))
    graph = nx.DiGraph()
    for id_train in id_trains:
        select_rows_id_train = trains[trains.src == id_train]
        graph.add_node(id_train, **{'lat':select_rows_id_train.iloc[0].lat_src,'lng':select_rows_id_train.iloc[0].lng_src,'regione':select_rows_id_train.iloc[0].reg_src})
        select_rows_id_train = trains[trains.src == id_train]
        dsts_from_id_train = select_rows_id_train.dst.unique()
        for destination in dsts_from_id_train:
            if not graph.has_node(destination):
                select_destination = trains[trains.dst == destination].iloc[0]
                graph.add_node(id_train, **{'lat':select_destination.lat_dst,'lng':select_destination.lng_dst,'regione':select_destination.reg_dest})
            weight = select_rows_id_train[select_rows_id_train.dst == destination].weight.mean()
            graph.add_edge(id_train,destination, weight = weight)
    #normalize
    d_graph = graph.copy()
    for v in graph.nodes():
        tot = sum([graph.edges[(v,neigh)]['weight'] for neigh in graph.neighbors(v)])
        for neigh in graph.neighbors(v):
            d_graph.edges[(v,neigh)]['weight'] = graph.edges[(v,neigh)]['weight']/tot
    nx.write_gpickle(d_graph,'network_trains.pkl')
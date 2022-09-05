import networkx as nx
from geopy import distance
import pandas as pd


def calculate_distance(a,b):
    tuple_0 = (float(a['lat']),float(a['lng']))
    tuple_1 = (float(b['lat']),float(b['lng']))
    return distance.distance(tuple_0,tuple_1).kilometers


def add_train_to_municipality():
    trains = nx.read_gpickle('network_trains.pkl')
    cities = nx.read_gpickle('network_municipalities.pkl')
    #copy graph
    new_network = nx.DiGraph()
    for n in cities.nodes():
        new_network.add_node(n,**cities.nodes[n])
    for edge in cities.edges():
        if cities.nodes[edge[0]]['prov'] != cities.nodes[edge[1]]['prov']:
            new_network.add_edge(edge[0],edge[1],**{'inter_prov':cities.edges[edge]['weight']})
        else:
            new_network.add_edge(edge[0],edge[1],**{'intra_prov':cities.edges[edge]['weight']})
    translate_trains = pd.DataFrame(columns = ['train_node','city_node'])
    for node in trains.nodes():
        distances = {city: float(calculate_distance(trains.nodes[node],cities.nodes[city])) for city in cities.nodes() if cities.nodes[city]['region'] == trains.nodes[node]['region']}
        df = pd.DataFrame.from_dict(distances)
        lista = df[df[1] < 5][0].to_list()
        if len(lista) == 0:
            lista = [df.sort_values(by = [1]).iloc[0][0]]
        for el in lista:
            translate_trains = translate_trains.append({
                'train_node':node,
                'city_node':el
            },ignore_index = True, verify_integrity = True)
    for edge in trains.edges():
        weight = trains.edges[edge]['weight']
        dictionary_origin = translate_trains[translate_trains.train_node == edge[0]]['city_node'].to_list()
        dictionary_dest = translate_trains[translate_trains.train_node == edge[1]]['city_node'].to_list()
        for origin in dictionary_origin:
            for dest in dictionary_dest:
                if origin == dest:
                    continue
                if new_network.has_edge(origin,dest):
                    new_network.edges[(origin,dest)]['train'] = weight
                else:
                    new_network.add_edge(origin,dest,**{'train':weight})
    #normalize network
    norm_network = new_network.copy()
    for n in new_network.nodes():
        #normalize train part
        tot_train = sum([new_network.edges[(n,neigh)]['train'] for neigh in new_network.neighbors(n) if 'train' in new_network.edges[(n,neigh)]])
        tot_inter_prov = sum([new_network.edges[(n,neigh)]['inter_prov'] for neigh in new_network.neighbors(n) if 'inter_prov' in new_network.edges[(n,neigh)]])
        tot_intra_prov = sum([new_network.edges[(n,neigh)]['intra_prov'] for neigh in new_network.neighbors(n) if 'intra_prov' in new_network.edges[(n,neigh)]])
        for neigh in new_network.neighbors(n):
            if 'train' in new_network.edges[(n,neigh)]:
                norm_network.edges[(n,neigh)]['train'] = new_network.edges[(n,neigh)]['train']/tot_train
            if 'inter_prov' in new_network.edges[(n,neigh)]:
                norm_network.edges[(n,neigh)]['inter_prov'] = new_network.edges[(n,neigh)]['inter_prov']/tot_inter_prov
            if 'intra_prov' in new_network.edges[(n,neigh)]:
                norm_network.edges[(n,neigh)]['intra_prov'] = new_network.edges[(n,neigh)]['intra_prov']/tot_intra_prov
    nx.write_gpickle(norm_network,'network_mun_plus_trains.pkl')


def add_flights_to_network():
    flights = nx.read_gpickle('network_flights.pkl')
    cities = nx.read_gpickle('network_mun_plus_trains.pkl')
    #copy graph
    new_network = nx.DiGraph()
    for n in cities.nodes():
        new_network.add_node(n,**cities.nodes[n])
    for edge in cities.edges():
        new_network.add_edge(edge[0],edge[1],**cities.edges[edge])
    translate_flights = pd.DataFrame(columns = ['airport_node','city_node'])
    for node in flights.nodes():
        distances = {city: float(calculate_distance(flights.nodes[node],cities.nodes[city])) for city in cities.nodes()}
        df = pd.DataFrame.from_dict(distances)
        for el in df[df[1] < 15][0].to_list():
            translate_flights = translate_flights.append({
                'airport_node':node,
                'city_node':el
            },ignore_index = True, verify_integrity = True)
    for edge in flights.edges():
        weight = flights.edges[edge]['weight']
        dictionary_origin = translate_flights[translate_flights.airport_node == edge[0]]['city_node'].to_list()
        dictionary_dest = translate_flights[translate_flights.airport_node == edge[1]]['city_node'].to_list()
        for origin in dictionary_origin:
            for dest in dictionary_dest:
                if origin == dest:
                    continue
                if new_network.has_edge(origin,dest):
                    new_network.edges[(origin,dest)]['flight'] = weight
                else:
                    new_network.add_edge(origin,dest,**{'flight':weight})
    #normalize network
    norm_network = new_network.copy()
    for n in new_network.nodes():
        #normalize flights part
        tot = sum([new_network.edges[(n,neigh)]['flight'] for neigh in new_network.neighbors(n) if 'flight' in new_network.edges[(n,neigh)]])
        for neigh in new_network.neighbors(n):
            if 'flight' in new_network.edges[(n,neigh)]:
                norm_network.edges[(n,neigh)]['flight'] = new_network.edges[(n,neigh)]['flight']/tot
    nx.write_gpickle(norm_network,'italy.pkl')
import os,sys
import pandas as pd
import networkx as nx
from geopy import distance


def calculate_distance(comune_0,comune_1):
    tuple_0 = (float(comune_0['lat'].values[0]),float(comune_0['lng'].values[0]))
    tuple_1 = (float(comune_1['lat'].values[0]),float(comune_1['lng'].values[0]))
    return distance.distance(tuple_0,tuple_1).kilometers


def main():
    with open("connections.csv","r") as inpuf:
        connections = pd.read_csv(inpuf,sep = ",")
    with open("municipalities.csv","r") as inpuf:
        municipalities = pd.read_csv(inpuf,sep = ",")
    graph = nx.DiGraph()
    for id_row,row in connections.iterrows():
        row_1 = municipalities[municipalities.id_istat == row['id_municipality_0']]
        if not graph.has_node(row['id_municipality_0']):
            graph.add_node(row['id_municipality_0'],**{'lat':row_1['lat'].values[0],'lng':row_1['lng'].values[0],'prov':row_1['province'].values[0],'region':row_1['region'].values[0]})
        row_2 = municipalities[municipalities.id_istat == row['id_municipality_1']]
        if not graph.has_node(row['id_municipality_1']):
            graph.add_node(row['id_municipality_1'],**{'lat':row_2['lat'].values[0],'lng':row_2['lng'].values[0],'prov':row_2['province'].values[0],'region':row_2['region'].values[0]})
        numerator = (float(row_2['agents'].values[0])*float(row_1['agents'].values[0]))/(float(row_2['surface'].values[0])*float(row_1['surface'].values[0]))
        graph.add_edge(row['id_municipality_0'],row['id_municipality_1'], weight = numerator/calculate_distance(row_1,row_2))
        graph.add_edge(row['id_municipality_1'],row['id_municipality_0'], weight = numerator/calculate_distance(row_1,row_2))
    #normalize flow
    d_graph = graph.copy()
    for v in graph.nodes():
        tot = sum([graph.edges[(v,neigh)]['weight'] for neigh in graph.neighbors(v)])
        for neigh in graph.neighbors(v):
            d_graph.edges[(v,neigh)]['weight'] = graph.edges[(v,neigh)]['weight']/tot
    nx.write_gpickle(d_graph,'network_municipalities.pkl')

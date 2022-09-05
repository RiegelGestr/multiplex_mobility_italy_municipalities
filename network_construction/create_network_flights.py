import pandas as pd
import networkx as nx
def main():
    graph = nx.DiGraph()
    with open('flights.csv','r') as input_file:
        df = pd.read_csv(input_file,sep = ',')
    for _, row in df.iterrows():
        if not graph.has_node(row.src):
            graph.add_node(row.src,**{'lat':row.lat_src,'lng':row.lng_src})
        if not graph.has_node(row.dst):
            graph.add_node(row.dst,**{'lat':row.lat_dst,'lng':row.lng_dst})
        graph.add_edge(row.src,row.dst, weight = row.weight)
    nx.write_gpickle(graph,'network_flights.pkl')
#in this case we do not need to normalize. it has been yet done in scraping/flights folder
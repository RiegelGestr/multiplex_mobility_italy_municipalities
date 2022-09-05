# Scraping
The following text walks through the main functionalities of the folder.
## Municipalities
Inside this folder there is a python script called `create_network_mun.py`, which output is the graph file `network_municipalities.pkl`. This graph is the starting point for the script inside the current folder. The node of the network are the municipalities and there is an edge if the two municipalities are contiguous according to ISTAT. The weight is given by the gravity model.
### `create_network_flights.py`
The purpose of this script is to create the flights layer of the multiplex mobility network. This script needs as input the output file of the script `create_csv_network.py` of the `scraping/flights` folder. The node of this layer are the municipalities, while the edges are given by the airports' connections (weights properly normalized).

### `create_network_trains.py`
The purpose of this script is to create the trains layer of the multiplex mobility network. This script needs as input the output file of the script `create_csv_network.py` of the `scraping/viaggiotreno` folder. The node of this layer are the municipalities, while the edges are given by the trains stations' connections (weights properly normalized).

### `join_networks.py`
The purpose of this script is to join all the layers together. The output file of this script is the graph file `italy.pkl`, in which nodes are the municipalities while the edges are a dictionary containing informations of the layer (key) and the weights of the connections (value).

### `translate_network_to_julia.py`
The purpose of this script is to create two csvs file to be used in `create_mg_network.jl`: `nodes.csv` and `edges.csv`.

### `create_mg_network.jl`
The purpose of this script is to create the files needed for the epidemic part of the pipeline, together with `translate_network_to_julia.py`. In a previous version of this code we use the `Metagraph.jl` format for the network, this changed due to performance reason.
# Scraping
The following text walks through the main functionalities of the folders.
## Flights
Inside this folder there is a markdown file `split_pdf_and_convert_csv.md`, in which it is explained how to convert the pdf into csv file. The csv output file is used by `create_csv_network.py` which output is an edges table csv file. Eachrow of the file is an edge between airports, containing information of the geographic coordinates (source and destination), the weights of the connection as explained in the paper.
## ViaggioTreno
Inside this folder there are the scraping scripts `scrap_stations.py` and `scrap_drawn_stations.py`, which are used to query the viaggiotreno API. The output files are used by `create_csv_network.py` which output is an edges table csv file. Eachrow of the file is an edge between train stations, containing information of the geographic coordinates (source and destination), the weights of the connection as explained in the paper

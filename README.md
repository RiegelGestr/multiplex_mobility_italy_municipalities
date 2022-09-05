## Multiplex mobility network and metapopulation epidemic simulations of Italy based on Open Data

## Dependencies
Python (3.9.0)
\
Julia (1.7.2)
\
Python Modules: [requirements.txt](https://github.com/RiegelGestr/multiplex_mobility_italy_municipalities/blob/main/requirements.txt)
\
Julia Packages: [Project.toml](https://github.com/RiegelGestr/multiplex_mobility_italy_municipalities/blob/main/Project.toml)

### How the repository is structured
- `scraping`: this folder contains the code and documentation to use the API <em>Viaggiotreno</em> and to parse the pdf files from <em>ENAC</em>. For a more in depth explanation of the code, [click here](https://github.com/RiegelGestr/multiplex_mobility_italy_municipalities/blob/main/scraping/scraping_readme.md).
- `network_construction`: this folder contains the code and documentation for the network construction part of the pipeline. For a more in depth explanation of the code, [click here](https://github.com/RiegelGestr/multiplex_mobility_italy_municipalities/blob/main/network_construction/network_construction_readme.md).
- `epidemics`: this folder contains the code and documentation for the epidemics part. The code can be run without the other parts, making sure you have dowloaded the small data from [zenodo_small_folder.txt](data.com) and installed the needed julia requirements. Note that although some part of the code are general, it assumes that the input network is a multiplex and it is designed to run simulations of the SIR model as explained in the paper.

## Extra-link
- [Pre-print](https://arxiv.org/abs/2205.03639)
- [Data](https://zenodo.com/)

## For Developers
License: MIT
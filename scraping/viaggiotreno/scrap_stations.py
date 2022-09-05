import requests
import pandas as pd


def get_data(link):
    r = requests.get(link)
    results = r.json()
    return results


def main():
    # Assumption regions.csv in the same directory of the file !!!
    with open('regions.csv','r') as input_file:
        df_reg = pd.read_csv(input_file, sep = ',', dtype = 'object')
    mother_link = 'http://www.viaggiatreno.it/viaggiatrenonew/resteasy/viaggiatreno/elencoStazioni/'
    #output
    stations = pd.DataFrame(columns=["id_station", "name_station", "cod_reg","region","name_city", "lat", "lng", "type_station"])
    #loop over regions
    for id_row,row_reg in df_reg.iterrows():
        id_reg = row_reg['id_reg']
        name_region = row_reg['region']
        link = mother_link + id_reg
        #get data from link
        results = get_data(link)
        for res in results:
            cod_staz = res['codStazione']
            lat = res['lat']
            lng = res['lon']
            name_station = res['localita']['nomeLungo']
            name_city = res['nomeCitta']
            kind_station = res['tipoStazione']
            stations = stations.append({'id_station':cod_staz,
                                        'name_station':name_station,
                                        'cod_reg': id_reg,
                                        'region': name_region,
                                        "name_city": name_city,
                                        'lat':lat,
                                        'lng':lng,
                                        'type_station':kind_station
                                        }, ignore_index=True, verify_integrity=True)
    stations.to_csv('stations.csv', sep =';',index = False)
import requests
import pandas as pd
from tqdm import tqdm


def get_data(link):
    r = requests.get(link)
    return r.json()


def main(list_timetables,day_string):
    drawn_trains = pd.DataFrame(columns=["id_origin", "category", "name_destination","num_train",'station_query'])
    with open('stations.csv','r') as input_file:
        df_stations = pd.read_csv(input_file,sep = ';', dtype = 'object')
    mother_links = ['http://www.viaggiatreno.it/viaggiatrenonew/resteasy/viaggiatreno/partenze/',
                    'http://www.viaggiatreno.it/viaggiatrenonew/resteasy/viaggiatreno/arrivi/']
    for i, station in tqdm(df_stations.iterrows(), desc='Stations', unit='station', dynamic_ncols = True, total = df_stations.shape[0]):
        id_station = station['id_station']
        for id_what, mother_link in enumerate(mother_links):
            for x in list_timetables:
                link = mother_link + id_station + '/' + day_string.format(time = x)
                results = get_data(link)
                #it could be that no trains at the given hour are arriving or departing
                if len(results) == 0:
                    continue
                for res in results:
                    id_origin = res['codOrigine']
                    category = res['categoria']
                    name_destination = res['destinazione']
                    num_train = res['numeroTreno']
                    #
                    if name_destination == None:
                        continue
                    drawn_trains = drawn_trains.append({'id_origin':id_origin,
                                            'category':category,
                                            'name_destination': name_destination,
                                            'num_train': num_train,
                                            'station_query': id_station,
                                            }, ignore_index=True, verify_integrity=True)
    drawn_trains = drawn_trains.drop_duplicates()
    drawn_trains.to_csv('drawn_trains.csv',sep =';',index = False)


#Example day string and list_timetables
day_string = 'Mon Aug 31 2020 {time}:00:00 GMT+0200 (Ora legale Europa occidentale)'
list_timetables = ['0' + str(x) for x in range(0,10)]
list_timetables.extend([str(x) for x in range(10,24)])
main(list_timetables, day_string)

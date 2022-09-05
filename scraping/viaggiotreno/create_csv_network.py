import pandas as pd
import math

#Weight kind of train --> hard coded
def weight_kind_train(kind):
    if kind == 'REG':
        return 0.1316
    elif kind == 'IC':
        return 0.1316
    elif kind == 'EC':
        return 0.0789
    elif kind == 'EN':
        return 0.0526
    elif kind == 'MET':
        return 0.1579
    elif math.isnan(float(kind)):
        return 0.4474


def main():
    with open('stations.csv','r') as input_file:
        stations = pd.read_csv(input_file, sep = ';')
    with open('drawn_trains.csv','r') as input_file:
        draw_trains = pd.read_csv(input_file, sep = ';')
    output_df = pd.DataFrame(columns = ['src','reg_src','dst','reg_dest','lat_src','lng_src','lat_dst','lng_dst','weight'])
    for _,row in draw_trains.iterrows():
        staz_1 = stations[stations.id_staz == row.id_origin]
        staz_2 = stations[stations.nome_staz == row.name_destination]
        staz_3 = stations[stations.id_staz == row.station_query]
        #1-2
        if not ((staz_1.empty) or (staz_2.empty)):
            output_df = output_df.append({
                                        'src':staz_1['id_staz'].values[0],
                                        'dst':staz_2['id_staz'].values[0],
                                        'reg_src':staz_1['regione'].values[0],
                                        'reg_dest':staz_2['regione'].values[0],
                                        'lat_src':staz_1['lat'].values[0],
                                        'lng_src':staz_1['lng'].values[0],
                                        'lat_dst':staz_2['lat'].values[0],
                                        'lng_dst':staz_2['lng'].values[0],
                                        'weight':weight_kind_train(row['category'])
                                    },ignore_index=True, verify_integrity=True)
            output_df = output_df.append({
                                        'src':staz_2['id_staz'].values[0],
                                        'dst':staz_1['id_staz'].values[0],
                                        'reg_src':staz_2['regione'].values[0],
                                        'reg_dest':staz_1['regione'].values[0],
                                        'lat_src':staz_2['lat'].values[0],
                                        'lng_src':staz_2['lng'].values[0],
                                        'lat_dst':staz_1['lat'].values[0],
                                        'lng_dst':staz_1['lng'].values[0],
                                        'weight':weight_kind_train(row['category'])
                                    },ignore_index=True, verify_integrity=True)
        #2-3
        if not ((staz_2.empty) or (staz_3.empty)):
            output_df = output_df.append({
                                        'src':staz_2['id_staz'].values[0],
                                        'dst':staz_3['id_staz'].values[0],
                                        'reg_src':staz_2['regione'].values[0],
                                        'reg_dest':staz_3['regione'].values[0],
                                        'lat_src':staz_2['lat'].values[0],
                                        'lng_src':staz_2['lng'].values[0],
                                        'lat_dst':staz_3['lat'].values[0],
                                        'lng_dst':staz_3['lng'].values[0],
                                        'weight':weight_kind_train(row['category'])
                                    },ignore_index=True, verify_integrity=True)

            output_df = output_df.append({
                                        'src':staz_3['id_staz'].values[0],
                                        'dst':staz_2['id_staz'].values[0],
                                        'reg_src':staz_3['regione'].values[0],
                                        'reg_dest':staz_2['regione'].values[0],
                                        'lat_src':staz_3['lat'].values[0],
                                        'lng_src':staz_3['lng'].values[0],
                                        'lat_dst':staz_2['lat'].values[0],
                                        'lng_dst':staz_2['lng'].values[0],
                                        'weight':weight_kind_train(row['category'])
                                    },ignore_index=True, verify_integrity=True)
        #3-1
        if not ((staz_1.empty) or (staz_3.empty)):
            output_df = output_df.append({
                                        'src':staz_1['id_staz'].values[0],
                                        'dst':staz_3['id_staz'].values[0],
                                        'reg_src':staz_1['regione'].values[0],
                                        'reg_dest':staz_3['regione'].values[0],
                                        'lat_src':staz_1['lat'].values[0],
                                        'lng_src':staz_1['lng'].values[0],
                                        'lat_dst':staz_3['lat'].values[0],
                                        'lng_dst':staz_3['lng'].values[0],
                                        'weight':weight_kind_train(row['category'])
                                    },ignore_index=True, verify_integrity=True)
            output_df = output_df.append({
                                        'src':staz_3['id_staz'].values[0],
                                        'dst':staz_1['id_staz'].values[0],
                                        'reg_src':staz_3['regione'].values[0],
                                        'reg_dest':staz_1['regione'].values[0],
                                        'lat_src':staz_3['lat'].values[0],
                                        'lng_src':staz_3['lng'].values[0],
                                        'lat_dst':staz_1['lat'].values[0],
                                        'lng_dst':staz_1['lng'].values[0],
                                        'weight':weight_kind_train(row['category'])
                                    },ignore_index=True, verify_integrity=True)
    output_df = output_df.drop(output_df[output_df.src == output_df.dst].index)
    output_df.to_csv('trains.csv',sep = ',')
import pandas as pd
def main():
    with open('merge_csv.csv','r') as input_file:
        df = pd.read_csv(input_file,sep = ',',dtype = 'object')
    df['passeggeri'] = df.apply(lambda x: int(''.join(x['Passeggeri trasportati (partenze)'].split('.'))),axis = 1)
    df['source_code'] = df.apply(lambda x: x['Unnamed: 0'].replace('-','').replace('  ',' ').split(' ')[0],axis = 1)
    df['dest_code'] = df.apply(lambda x: x['Unnamed: 0'].replace('-','').replace('  ',' ').split(' ')[1],axis = 1)
    with open('airports.csv','r') as input_file:
        airports = pd.read_csv(input_file, sep = ',')
    airports = airports.replace("\\N",None)
    airports = airports.dropna()
    to_save_df = pd.DataFrame(columns = ['src','dst','lat_src','lng_src','lat_dst','lng_dst','weight'])
    for _, row in df.iterrows():
        name_source = airports[(airports.iata == row['source_code']) | (airports.icao == row['source_code'])]['name'].to_list()[0]
        name_dest = airports[(airports.iata == row['dest_code']) | (airports.icao == row['dest_code'])]['name'].to_list()[0]
        row_src = airports[airports.name == name_source]
        row_dst = airports[airports.name == name_dest]
        to_save_df = to_save_df.append({
            'src':row_src['icao'].values[0],
            'dst':row_dst['icao'].values[0],
            'lat_src':row_src['lat'].values[0],
            'lng_src':row_src['lng'].values[0],
            'lat_dst':row_dst['lat'].values[0],
            'lng_dst':row_dst['lng'].values[0],
            'weight':row['passeggeri']
        },ignore_index=True, verify_integrity=True)
    srcs = to_save_df.src.unique()
    for src in srcs:
        df_to_normalize = to_save_df[to_save_df.src == src]
        norm = sum(df_to_normalize.weight)
        for id_r, row in df_to_normalize.iterrows():
            to_save_df.loc[id_r,'weight'] = to_save_df.loc[id_r,'weight']/norm
    to_save_df.to_csv('flights.csv',sep = ',')
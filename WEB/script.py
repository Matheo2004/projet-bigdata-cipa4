import base64
import json
import sys

import plotly.express as px
import pandas as pd
from pyproj import Transformer
import plotly.graph_objects as go

def map(tree_data):
     # Create two map, one with two cluster the other with three
    fig2 = px.scatter_map(tree_data, lat='latitude', lon='longitude', color="taille2", hover_data=["haut_tot"])
    fig3 = px.scatter_map(tree_data, lat='latitude', lon='longitude', color="taille3", hover_data=["haut_tot"])

    # Make the map with three clusters invisble
    for trace in fig3.data:
        trace.visible = False

    # Create a map with the two map
    fig = go.Figure(data=list(fig2.data) + list(fig3.data))

    # Create the visibility of the data by category
    n_cluster2 = len(fig2.data)
    n_cluster3 = len(fig3.data)
    vis_cluster2 = [True] * n_cluster2 + [False] * n_cluster3
    vis_cluster3 = [False] * n_cluster2 + [True] * n_cluster3

    # Create the buttons who change the visibility when a category is choosen
    fig.update_layout(
        updatemenus=[
            {
                "buttons": [
                    {
                        "label": "Petits et grands",
                        "method": "update",
                        "args": [{"visible": vis_cluster2}, {"title": "Visualisation Cluster 2"}],
                    },
                    {
                        "label": "Petits, moyens et grands",
                        "method": "update",
                        "args": [{"visible": vis_cluster3}, {"title": "Visualisation Cluster 3"}],
                    },
                ],
                "direction": "down",
                "x": 0.1,
                "y": 1.15
            }
        ],
        # Create a auto zoom for the map
        autosize=True,
        hovermode='closest',
        map=dict(
            bearing=0,
            center=dict(
                lat=49.84,
                lon=3.288009
            ),
            pitch=0,
            zoom=11.75
        ),)

    # Show the map
    fig.write_html("ma_carte.html", full_html=False, include_plotlyjs='cdn')

def predict(tree,value):
    max_haut=value.groupby("taille_2")["haut_tot"].max()
    if int(tree["haut_tot"])<=max_haut["Petit"]:
        tree['taille2']= "Petit"
    else:
        tree['taille2']= "Grand"
    max_haut=value.groupby("taille_3")["haut_tot"].max()
    min_haut=value.groupby("taille_3")["haut_tot"].min()
    if int(tree["haut_tot"])<=max_haut["Petit"]:
        tree['taille3']= "Petit"
    elif int(tree["haut_tot"])>=min_haut["Grand"]:
        tree['taille3']= "Grand"
    else:
        tree['taille3']= "Moyen"

    return tree

def main():
    # Retrieve the data 
    df =  pd.read_csv("../../../arbres_complet_avec_clusters.csv")

    # Take only the coordinates, the total height and the clusters
    value=df[["X","Y","haut_tot","cluster_2","cluster_3"]].dropna()

    # Calculate the mean of the tree height group by cluster
    means_c2 = value.groupby("cluster_2")["haut_tot"].mean()
    means_c3 = value.groupby("cluster_3")["haut_tot"].mean()

    # Identify witch cluster is the tiny trees or the high trees
    tiny2 = means_c2.idxmin()
    tiny3 = means_c3.idxmin()
    high3 = means_c3.idxmax()

    # Attribute height category for each cluster
    value["taille_2"]=['Petit' if i==tiny2 else 'Grand' for i in value["cluster_2"]]
    value["taille_3"]=['Petit' if i==tiny3 else 'Grand' if i==high3 else 'Moyen' for i in value["cluster_3"]]

    try:
        raw_input = sys.argv[1]
        decoded_bytes = base64.b64decode(raw_input)
        raw_json = decoded_bytes.decode('utf-8')
    except IndexError:
        print(json.dumps({"error": "Pas assez d'arguments fournis"}))
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(json.dumps({"error": f"JSON invalide : {str(e)}", "recu": raw_json}))
        sys.exit(1)
  
    trees=pd.DataFrame(json.loads(raw_json))
    trees['latitude'] = pd.to_numeric(trees['latitude'], errors='coerce')
    trees['longitude'] = pd.to_numeric(trees['longitude'], errors='coerce')
    trees['haut_tot'] = pd.to_numeric(trees['haut_tot'], errors='coerce')
    trees = trees.apply(predict, axis=1, args=(value,))
    map(trees)

main()
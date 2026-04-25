import plotly.express as px
import pandas as pd
from pyproj import Transformer
import plotly.graph_objects as go

# Retrieve the data 
df =  pd.read_csv("arbres_complet_avec_clusters.csv")

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

# Transform coordinates in the right projection
x_coor,y_coor=value['X'],value['Y']
transformer = Transformer.from_crs("EPSG:3949", "EPSG:4326", always_xy=True)
longitude, latitude = transformer.transform(x_coor,y_coor)

# Create two map, one with two cluster the other with three
fig2 = px.scatter_map(value, lat=latitude, lon=longitude, color="taille_2", hover_data=["haut_tot"])
fig3 = px.scatter_map(value, lat=latitude, lon=longitude, color="taille_3", hover_data=["haut_tot"])

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
fig.show()
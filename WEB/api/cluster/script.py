import json
import sys
import plotly.express as px
import pandas as pd
from pyproj import Transformer
import plotly.graph_objects as go

def map(value):
    # value est maintenant toujours un DataFrame
    x_coor = value['X']
    y_coor = value['Y']
    transformer = Transformer.from_crs("EPSG:3949", "EPSG:4326", always_xy=True)
    longitude, latitude = transformer.transform(x_coor.values, y_coor.values)

    fig2 = px.scatter_map(value, lat=latitude, lon=longitude, color="taille_2", hover_data=["haut_tot"])
    fig3 = px.scatter_map(value, lat=latitude, lon=longitude, color="taille_3", hover_data=["haut_tot"])

    for trace in fig3.data:
        trace.visible = False

    fig = go.Figure(data=list(fig2.data) + list(fig3.data))

    n_cluster2 = len(fig2.data)
    n_cluster3 = len(fig3.data)
    vis_cluster2 = [True] * n_cluster2 + [False] * n_cluster3
    vis_cluster3 = [False] * n_cluster2 + [True] * n_cluster3

    fig.update_layout(
        updatemenus=[{
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
        }],
        autosize=True,
        hovermode='closest',
        map=dict(
            bearing=0,
            center=dict(lat=49.84, lon=3.288009),
            pitch=0,
            zoom=11.75
        ),
    )

    fig.write_html("ma_carte.html", full_html=False, include_plotlyjs='cdn')


def predict(haut_total, value, cluster):
    if cluster == 2:
        max_haut = value.groupby("taille_2")["haut_tot"].max()
        if haut_total <= max_haut["Petit"]:
            return "Petit"
        else:
            return "Grand"
    elif cluster == 3:
        max_haut = value.groupby("taille_3")["haut_tot"].max()  # ← taille_3 (pas taille_2)
        min_haut = value.groupby("taille_3")["haut_tot"].min()
        if haut_total <= max_haut["Petit"]:
            return "Petit"
        elif haut_total >= min_haut["Grand"]:
            return "Grand"
        else:
            return "Moyen"


def main():
    df = pd.read_csv("arbres_complet_avec_clusters.csv")
    value = df[["X", "Y", "haut_tot", "cluster_2", "cluster_3", "id_arbre"]].dropna()

    means_c2 = value.groupby("cluster_2")["haut_tot"].mean()
    means_c3 = value.groupby("cluster_3")["haut_tot"].mean()

    tiny2 = means_c2.idxmin()
    tiny3 = means_c3.idxmin()
    high3 = means_c3.idxmax()

    value = value.copy()
    value["taille_2"] = ['Petit' if i == tiny2 else 'Grand' for i in value["cluster_2"]]
    value["taille_3"] = ['Petit' if i == tiny3 else 'Grand' if i == high3 else 'Moyen' for i in value["cluster_3"]]

    try:
        raw_json = sys.argv[1]
        lignes_db = json.loads(raw_json)
        cluster_choice = int(sys.argv[2])
    except IndexError:
        print(json.dumps({"error": "Pas assez d'arguments fournis"}))
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(json.dumps({"error": f"JSON invalide : {str(e)}", "recu": raw_json}))
        sys.exit(1)

    # ✅ Prédiction : on cherche la hauteur réelle via id_arbre dans le DataFrame
    for ligne in lignes_db:
        arbre = value[value["id_arbre"] == ligne["id_arbre"]]
        if arbre.empty:
            ligne["taille"] = "Inconnu"
        else:
            haut = arbre["haut_tot"].values[0]
            ligne["taille"] = predict(haut, value, cluster_choice)

    print(json.dumps(lignes_db))

    # ✅ On passe le DataFrame complet à map(), pas lignes_db
    map(value)


main()
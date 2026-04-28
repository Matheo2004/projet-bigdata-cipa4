import pandas as pd
from pyproj import Transformer
import json
import sys

def main():
    csv_path = sys.argv[1] if len(sys.argv) > 1 else "arbres_complet_avec_clusters.csv"
    n = int(sys.argv[2]) if len(sys.argv) > 2 else 2
    cluster_col = f"cluster_{n}"

    df = pd.read_csv(csv_path)
    df = df[["X", "Y", "haut_tot", "id_arbre", "nomlatin", cluster_col]].dropna()

    transformer = Transformer.from_crs("EPSG:3949", "EPSG:4326", always_xy=True)
    lons, lats = transformer.transform(df["X"].values, df["Y"].values)

    df["latitude"] = lats
    df["longitude"] = lons
    df["cluster"] = df[cluster_col].astype(int)
    df["espece"] = df["nomlatin"]
    df["hauteur"] = df["haut_tot"]

    result = df[["id_arbre", "latitude", "longitude", "hauteur", "espece", "cluster"]].to_dict(orient="records")
    print(json.dumps(result))

main()
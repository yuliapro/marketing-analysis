"""
================================================================================
MARKETING STRATEGY: PREDICTIVE SUCCESS ANALYSIS
================================================================================
This script addresses the following key business questions:

1. ATTRIBUTION: Which factors (funnel type, experiment, session duration) 
   carry the most weight in driving a user to "Success" (Level 5)?
   
2. PREDICTION: Based on historical behavior, what is the specific 
   probability of each current user completing the funnel successfully?
   
3. OPTIMIZATION: Which segments or experiments are generating "High-Quality" 
   leads with the highest conversion potential?
INPUT REQUIRED: where #tut for connection, file, non_cum columns, attribute columns, targer column
DATA SOURCE: Datawarehouse.gold.user_zscore_segmentation
MODEL: Random Forest Classifier (Supervised Learning)
================================================================================
"""
import pandas as pd
import numpy as np
import pyodbc
import os
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split, GridSearchCV # <--- Añadido GridSearchCV
from sklearn.preprocessing import LabelEncoder
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score

# 1. CONFIGURACIÓN #tut
conn_str = 'DRIVER={ODBC Driver 17 for SQL Server};SERVER=localhost,1433;DATABASE=Datawarehouse;UID=sa;PWD=TuPasswordFuerte123;TrustServerCertificate=yes'
sql_file_path = '/Users/yulia/analytics/user_attributes.sql' #tut - Path to your SQL query

# 2. CARGA DE DATOS Y PROCESO
try:
    if os.path.exists(sql_file_path):
        with open(sql_file_path, 'r') as f:
            query = f.read()
    else:
        raise FileNotFoundError(f"El archivo {sql_file_path} no existe.")

    print("Conectando a SQL y cargando datos...")
    with pyodbc.connect(conn_str) as conn:
        df = pd.read_sql(query, conn)

    if df.empty:
        print("La tabla está vacía.")
    else:
        # ==========================================================
        # 3. PROCESAMIENTO (Dentro del bloque else)
        # ==========================================================
        
        # A. Limpieza de columnas: Dejamos solo los CASE de SQL y métricas numéricas #tut
        # Tiramos user_id, date y los textos originales porque ya tienes los "dummies" en SQL
        X = df.drop(['user_id', 'date', 'funnel_type', 'funnel_category', 'experiment_name', 'is_success'], 
                    axis=1, errors='ignore') #tut - Columns to exclude
        y = df['is_success'] #tut - Target variable (what to predict)

        # Dividimos en entrenamiento y prueba para validar al final
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

        # B. Definir el Menú de Opciones (param_grid) #tut
        param_grid = {
            'n_estimators': [100, 200], #tut - Number of trees
            'max_depth': [10, 20, None], #tut - Depth of trees
            'min_samples_split': [2, 5] #tut - Minimum samples to split a node
        }

        # C. Configurar la búsqueda inteligente
        print("Iniciando búsqueda de mejores parámetros (GridSearch)...")
        grid_search = GridSearchCV(
            estimator=RandomForestClassifier(random_state=42),
            param_grid=param_grid,
            cv=5, 
            n_jobs=-1,
            verbose=1
        )

        # D. Entrenar (Aquí ocurre la magia)
        grid_search.fit(X_train, y_train)

        # E. Resultados
        print(f"\n✅ MEJOR CONFIGURACIÓN ENCONTRADA: {grid_search.best_params_}")
        
        # Usar el mejor modelo para predecir en el test
        mejor_modelo = grid_search.best_estimator_
        predicciones = mejor_modelo.predict(X_test)
        score = accuracy_score(y_test, predicciones)

        print(f"📊 Accuracy del mejor modelo: {score:.2%}")

        # --- IMPORTANCIA DE ATRIBUTOS ---
        importancias = mejor_modelo.feature_importances_
        tabla_importancia = pd.Series(importancias, index=X.columns).sort_values(ascending=False)

        print("\n--- TOP 10 ATRIBUTOS QUE INFLUYEN EN EL ÉXITO ---")
        print(tabla_importancia.head(10))

        # Graficar
        tabla_importancia.head(15).plot(kind='barh', color='lightgreen')
        plt.title('Atributos más influyentes (GridSearch Best Model)')
        plt.show()

except Exception as e:
    print(f"HA OCURRIDO UN ERROR: {e}")

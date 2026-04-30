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

DATA SOURCE: Datawarehouse.gold.user_zscore_segmentation
MODEL: Random Forest Classifier (Supervised Learning)
================================================================================
"""
import pandas as pd
import numpy as np
import pyodbc
import os
import matplotlib.pyplot as plt # ¡Importante para los gráficos!
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score

# 1. CONFIGURACIÓN #tut 
conn_str = 'DRIVER={ODBC Driver 17 for SQL Server};SERVER=localhost,1433;DATABASE=Datawarehouse;UID=sa;PWD=TuPasswordFuerte123;TrustServerCertificate=yes'
sql_file_path = '/Users/yulia/analytics/user_attributes.sql'

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
        # 3. PROCESAMIENTO
        # ==========================================================
        
        # 1. Traducir texto a números #tut 
        cats = ['funnel_type', 'funnel_category', 'experiment_name']
        le = LabelEncoder()
        for col in cats:
            df[col] = le.fit_transform(df[col].astype(str))

        # 2. Limpieza de ruido #tut 
        df_limpio = df.drop(['user_id', 'date'], axis=1)

        # 3. Separar X e y #tut 
        X = df_limpio.drop('is_success', axis=1)
        y = df_limpio['is_success']

        # 4. Dividir en Entrenamiento y Prueba
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=1)

        # ==========================================================
        # 4. MODELO Y PREDICCIÓN
        # ==========================================================
        
        print("Entrenando el Bosque Aleatorio...")
        modelo_rf = RandomForestClassifier(n_estimators=100, random_state=42)
        modelo_rf.fit(X_train, y_train)

# A) Predicciones para el EXAMEN (esto es para calcular el Accuracy)
        rf_predictions_test = modelo_rf.predict(X_test)

        # B) Calcular el Accuracy Score correctamente
        # Comparamos la realidad (y_test) con las adivinanzas (rf_predictions_test)
        score = accuracy_score(y_test, rf_predictions_test)

        # C) Predicciones para TODA la tabla (esto es para tu columna final)
        df['prediction_result'] = modelo_rf.predict(X)
        df['success_probability'] = modelo_rf.predict_proba(X)[:, 1]

        # 3. Mostrar el resultado
        print(f"\n✅ MODEL ACCURACY: {score:.2%}")
        print("---------------------------------------")

         
        # --- ANÁLISIS DE IMPORTANCIA (Ahora con la sangría correcta) ---
        importancias = modelo_rf.feature_importances_
        tabla_importancia = pd.Series(importancias, index=X.columns).sort_values(ascending=False)

        print("\n--- IMPACTO DE ATRIBUTOS EN EL ÉXITO ---")
        print(tabla_importancia)

        # Gráfico de importancia
        plt.figure(figsize=(10, 6))
        tabla_importancia.plot(kind='barh', color='skyblue')
        plt.title('¿Qué atributos influyen más en el éxito?')
        plt.gca().invert_yaxis() # Para que el más importante salga arriba
        plt.show()

        # 5. VERIFICACIÓN FINAL
        print("\n--- RESULTADOS (Primeras 10 filas) ---")
        print(df[['user_id', 'is_success', 'prediction_result', 'success_probability']].head(10))

        # Exportar resultados
        df.to_csv('resultados_prediccion.csv', index=False)
        print("\nArchivo 'resultados_prediccion.csv' guardado con éxito.")

except Exception as e:
    print(f"HA OCURRIDO UN ERROR: {e}")

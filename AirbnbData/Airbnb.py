# This Python 3 environment comes with many helpful analytics libraries installed
# It is defined by the kaggle/python docker image: https://github.com/kaggle/docker-python
# For example, here's several helpful packages to load in 

import numpy as np # linear algebra
import pandas as pd # data processing, CSV file I/O (e.g. pd.read_csv)

import matplotlib.pyplot as plt
import seaborn as sns

# Es necesario tener en el mismo directorio una carpeta "Data" que contenga los ficheros:
# listings.csv
# reviews.csv
# neighbourghood.geojson


plt.rcParams['figure.facecolor'] = 'w'

# Leemos del fichero listings.csv
listings_detail_df = pd.read_csv(
    'data/listings.csv',
    true_values=['t'], false_values=['f'], na_values=[None, 'none'])


# Crear una función para mostrar el porcentaje y el número de listados en el gráfico de sectores
def func(pct, allvalues):
    absolute = int(pct / 100. * np.sum(allvalues))
    return '{:.1f}%\n({:d})'.format(pct, absolute)



# Figura 1: % Alojamientos según Tipo de Habitación
listings_detail_df_copy = listings_detail_df.copy()

# Umbral para agrupar atributos con bajo porcentaje en "Other". Escojo y reemplazo.
threshold = 0.05
low_percentage_attrs = listings_detail_df_copy['room_type'].value_counts(normalize=True) < threshold
listings_detail_df_copy.loc[listings_detail_df_copy['room_type'].isin(low_percentage_attrs[low_percentage_attrs].index), 'room_type'] = 'Other'

# Define los colores que deseas usar para cada sector
custom_colors = ['#bfe3d9', '#3984a9', '#2c5c84', '#6eb9c6']

fig, ax = plt.subplots(figsize=(6, 6))
pie_data = listings_detail_df_copy['room_type'].value_counts()

wedges, texts, autotexts = ax.pie(
    pie_data,
    autopct=lambda pct: func(pct, pie_data),
    explode=(0.01,) * len(pie_data),
    labels=pie_data.index,
    textprops={'fontsize': 10},
    startangle=90, 
    colors=custom_colors
)
ax.set_ylabel('')
ax.set_title('% of Listings per Room Type', weight='bold')

plt.show()


# Figura 2: Proporción de Tipo de Habitación en cada Zona
fig, ax = plt.subplots(figsize=(10, 6))

barplot_data = (
    listings_detail_df
    .groupby(['neighbourhood', 'room_type'])
    .size()
    .unstack('room_type')
    .fillna(0)
    .apply(lambda row: row / row.sum(), axis=1)
    .sort_values('Entire home/apt')
    .reindex(columns=listings_detail_df['room_type'].value_counts().index))

barplot_data.plot(kind='barh', width=.75, stacked=True, ax=ax, color = custom_colors)

ax.set_xticks(np.linspace(0,1, 5))
ax.set_xticklabels(np.linspace(0,1, 5))
ax.grid(axis='x', c='k', ls='--')
ax.set_xlim(0,1)
ax.set_ylabel('Zona')
ax.set_xlabel('Alojamientos (%)')
ax.legend(loc=(1.01, 0))

ax.set_title('Proporción de Tipo de Habitación en cada Zona', weight='bold')

plt.show()


# Figura 3: Área de las zonas y densidad de alojamientos por zona
import json
from shapely.geometry import shape

# Crear la figura y los ejes solo para las gráficas de interés
fig, (ax2, ax3) = plt.subplots(1, 2, figsize=(12, 5))

# Cargar el archivo GeoJSON y calcular áreas
with open('data/neighbourhoods.geojson') as f:
    geojson = json.loads(f.read())
    
    
with open('data/neighbourhoods.geojson') as f:
    geojson = json.loads(f.read())
areas = []
for feature in geojson['features']:
    geometry = feature.get('geometry')
    if geometry and geometry['type'] == 'MultiPolygon':
        polygon = shape(geometry)
        area = polygon.area
        properties = feature.get('properties', {})
        areas.append({'area': area, **properties})

areas_srs = (
    pd.DataFrame(areas)
    .groupby('neighbourhood')
    ['area']
    .sum() * 10**4)

# Graficar Neighbourhood Area
areas_srs.sort_values().plot(kind='barh', ax=ax2)
ax2.set_title('Área Zonas', weight='bold')
ax2.grid(axis='x')
ax2.set_ylabel('')
ax2.set_xlabel('Area (km²)')

# Calcular y graficar Neighbourhood Density
n_listings_per_neighbourhood = listings_detail_df['neighbourhood'].value_counts()
n_listings_density = n_listings_per_neighbourhood.divide(areas_srs)
n_listings_density.sort_values().plot(kind='barh', ax=ax3)
ax3.set_title('Densidad Zonas', weight='bold')
ax3.set_xlabel('Densidad (Alojamientos por km²)')
ax3.grid(axis='x')

fig.tight_layout()
plt.show()


# Figura 4: Comparación porcentaje de Hosts con 5+ Alojamientos
fig, ax4 = plt.subplots(1, 1, figsize=(7, 5))
hosts_per_neighbourhood = listings_detail_df.groupby('neighbourhood')['host_id'].nunique()


multiple_listings_perc_per_neighbourhood = (
    (listings_detail_df
    [listings_detail_df['room_type'].isin(['Entire home/apt'])]
    .groupby(['neighbourhood', 'host_id'])
    .size().ge(5)
    .groupby('neighbourhood')
    .sum() / hosts_per_neighbourhood)
    .iloc[::-1]
)

(multiple_listings_perc_per_neighbourhood
 .plot(kind='barh', color=[sns.color_palette()[0] 
                           if n != 'Centro' else 'navy' 
                           for n in multiple_listings_perc_per_neighbourhood.index], ax=ax4))

ax4.grid(axis='x')
ax4.set_ylabel('Zona')
ax4.set_xlabel('Hosts con 5+ Alojamientos (%)')
ax4.set_title('Comparación porcentaje de Hosts con 5+ Alojamientos', weight='bold')

fig.tight_layout()
plt.show()


# Figura 5: Número de Alojamientos por Usuario
# Define los colores que deseas usar para cada sector
custom_colors2 = ['#DAF7A6', '#FFC300', '#FF5733', '#C70039', '#900C3F']

fig, ax5 = plt.subplots(figsize=(6, 6))

n_listings_per_user = (
    listings_detail_df
    .groupby('host_id')
    .size())

category_order = ['1', '2', '3', '4', '5+']

pie_data = (
    n_listings_per_user
    .pipe(pd.cut, bins=[1, 2, 3, 4, 5, 1000], include_lowest=True, right=False,
          labels=category_order).value_counts())

pie_data = pie_data.reindex(category_order)

wedges, texts, autotexts = ax5.pie(
    pie_data,
    explode=(0.01, ) * len(pie_data),
    autopct=lambda pct: func(pct, pie_data),
    labels=pie_data.index,
    textprops={'fontsize': 10},
    colors = custom_colors2,
)

ax5.set_ylabel('')
ax5.set_title('Número de Alojamientos por Usuario', weight='bold')

plt.show()


# Figura 6: Distribución de precios
plt.figure(figsize=(10,6))
sns.distplot(listings_detail_df['price'])
plt.title('Distribución de Precios', weight='bold')
plt.xlabel('Precio')  # Etiqueta del eje x
plt.ylabel('Densidad')  # Etiqueta del eje y
plt.grid()

plt.show()


# No considero pagar más de 300 €/noche
listings_detail_df = listings_detail_df[listings_detail_df['price'] < 300]
trans_prices = listings_detail_df['price'].pipe(np.log1p)

fig, ax6 = plt.subplots(figsize=(10,6))
ax2 = ax6.twiny().twinx()

sns.distplot(listings_detail_df['price'], ax=ax6, label='Datos Exactos')
sns.distplot(trans_prices, color=sns.color_palette()[1], ax=ax2, label='Datos Transformados\n(log)')
ax6.set_title('Distribución de Precios', weight='bold')
ax6.grid()
ax6.legend(loc=2)
ax2.legend(loc=1)
ax6.set_xlabel('Precio')
ax6.set_ylabel('Densidad')

fig.tight_layout()
plt.show()

# La transformación logarítmica se utiliza en el análisis de datos cuando los valores tienen una amplia gama o distribución sesgada, como es común en muchas situaciones financieras y económicas. En este caso específico, se aplica la transformación logarítmica a los precios de los alojamientos.

# La razón principal detrás de la transformación logarítmica es reducir la variabilidad y la influencia de los valores extremadamente altos en la distribución de datos. Los precios de los alojamientos pueden variar mucho, con algunos precios muy altos que pueden distorsionar la distribución general. Aplicar el logaritmo a los precios tiene varios beneficios:

# Reducción de la asimetría: Muchas distribuciones de precios tienden a ser sesgadas hacia la derecha (valores más altos). Aplicar el logaritmo puede ayudar a reducir esta asimetría, lo que facilita la interpretación de las diferencias y patrones en la distribución.

# Atenuación de los valores extremadamente altos: Los valores extremadamente altos tienen una influencia desproporcionada en las estadísticas y gráficos. Al tomar el logaritmo, los valores más altos se reducen en magnitud, lo que ayuda a evitar que dominen la visualización y el análisis.

# Interpretación más sencilla: Después de la transformación, los valores logarítmicos se comportan de manera más lineal y pueden interpretarse como porcentajes de cambio. Esto puede facilitar la comparación y el análisis de patrones.


# Figura 7 y 8: Total y Tendencias Reseñas
reviews_df = (
    pd.read_csv('data/reviews.csv', 
                parse_dates=['date'])
    .rename(columns={'id': 'review_id'})
    .sort_values('date'))

fig, (ax7, ax8) = plt.subplots(1, 2, figsize=(15,5), gridspec_kw={'width_ratios': [1, .6]})

n_reviews_srs = (
    reviews_df
    .groupby('date')
    .size()
    .reindex(index=pd.date_range(*reviews_df['date'].agg(['min', 'max']).values))
    .fillna(0))

n_reviews_srs.plot(ax=ax7, color='#9C1D9A')
n_reviews_srs.rolling(365).mean().plot(ax=ax7, c='k', ls='--')

ax7.set_xlabel('Fecha')
ax7.set_ylabel('Número de Reseñas')
ax7.set_title('Tendencias Reseñas', weight='bold')
ax7.grid(axis='both')

n_reviews_srs.cumsum().plot(ax=ax8, color='#9C1D9A')

ax8.set_xlabel('Fecha')
ax8.set_ylabel('Número de Reseñas (Acumulativo)')
ax8.set_title('Total Reseñas', weight='bold')
ax8.grid(axis='both')

plt.show()


# Figura 9: Alojamientos por Tipo y Ubicación
plt.figure(figsize=(8,5))
sns.scatterplot(listings_detail_df['longitude'], listings_detail_df['latitude'], hue=listings_detail_df['room_type'], palette="CMRmap")
plt.title('Distribución de Alojamientos por Tipo y Ubicación', weight='bold')
plt.xlabel('Longitud')
plt.ylabel('Latitud')
plt.legend(title='Tipo de Habitación')
plt.grid(True)

plt.show()

# Figura 10: Alojamiento por Zona y Ubicación
custom_colors3 = ['#fadb87', '#ffca92', '#e47a75', '#78b76e', '#f1a759', '#c8ab56', '#6badac', '#9cc7c4', '#9cdf90', '#6f94be', '#b2d5eb']

plt.figure(figsize=(8,5))
scatter = sns.scatterplot(listings_detail_df['longitude'], listings_detail_df['latitude'], hue=listings_detail_df['neighbourhood'], palette=custom_colors3)
plt.title('Distribución de Alojamientos por Tipo y Ubicación', weight='bold')
plt.xlabel('Longitud')
plt.ylabel('Latitud')
legend = scatter.legend(title='Zona')
legend.set_bbox_to_anchor((0.9, 0.5))  # Ajustar la posición de la leyenda
plt.grid(True)

plt.show()


# Figura 11 (External)
from bokeh.plotting import figure, show
from bokeh.models import ColumnDataSource
from bokeh.transform import jitter

data = listings_detail_df[['room_type','price']]
cats = list(listings_detail_df.room_type.unique())

source = ColumnDataSource(data)

p = figure(plot_width=850, plot_height=400, y_range=cats, title="Precio")

# Crear puntos en el gráfico de dispersión
p.circle(x='price', y=jitter('room_type', width=0.3, range=p.y_range), source=source, alpha=0.3)

p.x_range.start = 0
p.x_range.end = 350
p.x_range.range_padding = 0
p.ygrid.grid_line_color = None

show(p)

# Figura 12: Número de reviews en función de los precios. ¿Influyen?
price_per_number_of_reviews = listings_detail_df.groupby(["number_of_reviews"]).mean().price
price_per_number_of_reviews.sort_values(ascending=False)
plt.figure(figsize=(8,5))
price_per_number_of_reviews.plot(kind="line", color="#499C1D")
plt.title("¿Conducir más reseñas a precios más altos?")
plt.xlabel("Número de Reseñas")
plt.ylabel("Precio")


# Figura 13: Correlación entre variables
# Eliminamos la columna neighbourhood_group porque en nuestra base de datos tiene valor NULL
if 'neighbourhood_group' in listings_detail_df.columns:
    listings_detail_df = listings_detail_df.drop(columns=['neighbourhood_group'])
    
# Calcular la matriz de correlación
correlation_matrix = listings_detail_df.corr()

# Crear un mapa de correlación (heatmap)
plt.figure(figsize=(10, 8))
sns.heatmap(correlation_matrix.iloc[::-1], annot=True, cmap='rocket_r', center=0,
            square=True, linewidths=.5, cbar_kws={"shrink": 0.8, "aspect": 20},
            linecolor='black', fmt=".2f",
            vmin=-1, vmax=1, yticklabels=correlation_matrix.columns[::-1],
            xticklabels=correlation_matrix.columns)

plt.title('Mapa de Correlación de Atributos', weight='bold')

plt.show()



















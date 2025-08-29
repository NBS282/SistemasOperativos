import networkx as nx
import matplotlib.pyplot as plt

# Nombres de los nodos con sus siglas
nodos = { 
    "IP": "Introducción a la Programación", 
    "M1": "Matemáticas I", 
    "F1": "Física I", 
    "ED": "Estructuras de Datos", 
    "M2": "Matemáticas II", 
    "F2": "Física II", 
    "PA": "Programación Avanzada", 
    "BD": "Bases de Datos", 
    "RC": "Redes de Computadoras", 
    "SO": "Sistemas Operativos", 
    "IS": "Ingeniería de Software", 
    "SI": "Seguridad Informática", 
    "IA": "Inteligencia Artificial", 
    "CG": "Computación Gráfica", 
    "DW": "Desarrollo Web", 
    "SD": "Sistemas Distribuidos", 
    "BDD": "Big Data", 
    "RO": "Robótica", 
    "CS": "Ciberseguridad", 
    "AA": "Análisis de Algoritmos"
}

# Dependencias entre los nodos
dependencias = [
    ("IP", "ED"),
    ("M1", "M2"),
    ("F1", "F2"),
    ("ED", "PA"),
    ("M2", "PA"),
    ("ED", "BD"),
    ("PA", "RC"),
    ("F2", "RC"),
    ("PA", "SO"),
    ("RC", "SO"),
    ("PA", "IS"),
    ("RC", "SI"),
    ("BD", "SI"),
    ("PA", "IA"),
    ("M2", "IA"),
    ("F2", "CG"),
    ("PA", "CG"),
    ("BD", "DW"),
    ("RC", "DW"),
    ("SO", "SD"),
    ("RC", "SD"),
    ("BD", "BDD"),
    ("M2", "BDD"),
    ("F2", "RO"),
    ("PA", "RO"),
    ("SI", "CS"),
    ("SO", "CS"),
    ("PA", "AA"),
    ("M2", "AA")
]

# Crear grafo dirigido
grafo = nx.DiGraph()
grafo.add_edges_from(dependencias)

# Reordenar los nodos manualmente para asegurar una mejor disposición
# Esto puede ayudar a evitar cruces de flechas específicas como entre PA e IA
pos = {
    "IP": (0, 0),
    "M1": (-2, 1),
    "F1": (2, 1),
    "ED": (-1, -1),
    "M2": (-4, -4),
    "F2": (2, -2),
    "PA": (0, -2),
    "BD": (-3, -3),
    "RC": (1, -3),
    "SO": (-3, -6),
    "IS": (-1, -5),
    "SI": (1, -4),
    "IA": (0, -3),
    "CG": (2, -3),
    "DW": (-3, -5),
    "SD": (2, -5),
    "BDD": (-4, -5),
    "RO": (5, -3),
    "CS": (2, -6),
    "AA": (1.6, -7)
}

# Dibujar el grafo con la disposición ajustada
plt.figure(figsize=(14, 12))  # Aumenta el tamaño de la figura para más espacio
nx.draw_networkx_nodes(grafo, pos, node_size=700, node_color="skyblue")
nx.draw_networkx_edges(
    grafo, 
    pos, 
    arrowstyle="->",  # Estilo de flecha
    arrowsize=20,  # Tamaño de las flechas
    edge_color="gray", 
    width=2  # Ancho de las flechas
)

# Dibujar etiquetas sin sobreponerlas
nx.draw_networkx_labels(grafo, pos, labels={key: key for key in nodos}, font_size=9, font_color="black")

plt.title("Dependencias entre Cursos ", fontsize=14)
plt.axis("off")
plt.show()

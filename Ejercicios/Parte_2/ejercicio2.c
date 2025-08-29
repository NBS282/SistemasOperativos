#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

#define NUM_MATERIAS 20

// Representación de una materia
typedef struct Materia
{
    char *codigo;
    struct Materia **predecesores; // materias que deben cursarse primero
    int numPredecesores;           // cuantas materias deben cursarse antes de esta
    pthread_cond_t *cond;          // variable de condición para sincronización
    pthread_mutex_t *mutex;        // mutex para protección de condición
    int ejecutada;                 // indicador de si la materia ha sido ejecutada
} Materia;

Materia *materias[NUM_MATERIAS];

// nombres de las materias
char *materia_nombres[] = {
    "IP", "M1", "F1", "ED", "M2", "F2", "PA", "BD", "RC", "SO", "IS", "SI", "IA", "CG", "DW", "SD", "BDD", "RO", "CS", "AA"};

//exclusión mutua
pthread_mutex_t mutex;

void inicializarMaterias()
{
    for (int i = 0; i < NUM_MATERIAS; i++)
    {
        materias[i] = (Materia *)malloc(sizeof(Materia));
        materias[i]->codigo = materia_nombres[i];
        materias[i]->predecesores = NULL;
        materias[i]->numPredecesores = 0;
        materias[i]->cond = (pthread_cond_t *)malloc(sizeof(pthread_cond_t));
        materias[i]->mutex = (pthread_mutex_t *)malloc(sizeof(pthread_mutex_t));
        pthread_mutex_init(materias[i]->mutex, NULL);
        pthread_cond_init(materias[i]->cond, NULL);
        materias[i]->ejecutada = 0;
    }

    // Definimos las dependencias entre las materias
    materias[3]->predecesores = (Materia **)malloc(sizeof(Materia *)); // ED depende de IP
    materias[3]->predecesores[0] = materias[0];                        // IP es predecesor de ED
    materias[3]->numPredecesores = 1;

    materias[4]->predecesores = (Materia **)malloc(sizeof(Materia *)); // M2 depende de M1
    materias[4]->predecesores[0] = materias[1];                        // M1 es predecesor de M2
    materias[4]->numPredecesores = 1;

    materias[5]->predecesores = (Materia **)malloc(sizeof(Materia *)); // F2 depende de F1
    materias[5]->predecesores[0] = materias[2];                        // F1 es predecesor de F2
    materias[5]->numPredecesores = 1;

    materias[6]->predecesores = (Materia **)malloc(2 * sizeof(Materia *)); // PA depende de ED y M2
    materias[6]->predecesores[0] = materias[3];                            // ED es predecesor de PA
    materias[6]->predecesores[1] = materias[4];                            // M2 es predecesor de PA
    materias[6]->numPredecesores = 2;

    materias[7]->predecesores = (Materia **)malloc(sizeof(Materia *)); // BD depende de ED
    materias[7]->predecesores[0] = materias[3];                        // ED es predecesor de BD
    materias[7]->numPredecesores = 1;

    materias[8]->predecesores = (Materia **)malloc(2 * sizeof(Materia *)); // RC depende de PA y F2
    materias[8]->predecesores[0] = materias[6];                            // PA es predecesor de RC
    materias[8]->predecesores[1] = materias[5];                            // F2 es predecesor de RC
    materias[8]->numPredecesores = 2;

    materias[9]->predecesores = (Materia **)malloc(2 * sizeof(Materia *)); // SO depende de PA y RC
    materias[9]->predecesores[0] = materias[6];                            // PA es predecesor de SO
    materias[9]->predecesores[1] = materias[8];                            // RC es predecesor de SO
    materias[9]->numPredecesores = 2;

    materias[10]->predecesores = (Materia **)malloc(sizeof(Materia *)); // IS depende de PA
    materias[10]->predecesores[0] = materias[6];                        // PA es predecesor de IS
    materias[10]->numPredecesores = 1;

    materias[11]->predecesores = (Materia **)malloc(2 * sizeof(Materia *)); // SI depende de RC y BD
    materias[11]->predecesores[0] = materias[8];                            // RC es predecesor de SI
    materias[11]->predecesores[1] = materias[7];                            // BD es predecesor de SI
    materias[11]->numPredecesores = 2;

    materias[12]->predecesores = (Materia **)malloc(2 * sizeof(Materia *)); // IA depende de PA y M2
    materias[12]->predecesores[0] = materias[6];                            // PA es predecesor de IA
    materias[12]->predecesores[1] = materias[4];                            // M2 es predecesor de IA
    materias[12]->numPredecesores = 2;

    materias[13]->predecesores = (Materia **)malloc(2 * sizeof(Materia *)); // CG depende de F2 y PA
    materias[13]->predecesores[0] = materias[5];                            // F2 es predecesor de CG
    materias[13]->predecesores[1] = materias[6];                            // PA es predecesor de CG
    materias[13]->numPredecesores = 2;

    materias[14]->predecesores = (Materia **)malloc(2 * sizeof(Materia *)); // DW depende de BD y RC
    materias[14]->predecesores[0] = materias[7];                            // BD es predecesor de DW
    materias[14]->predecesores[1] = materias[8];                            // RC es predecesor de DW
    materias[14]->numPredecesores = 2;

    materias[15]->predecesores = (Materia **)malloc(2 * sizeof(Materia *)); // SD depende de SO y RC
    materias[15]->predecesores[0] = materias[9];                            // SO es predecesor de SD
    materias[15]->predecesores[1] = materias[8];                            // RC es predecesor de SD
    materias[15]->numPredecesores = 2;

    materias[16]->predecesores = (Materia **)malloc(2 * sizeof(Materia *)); // BD depende de BD y M2
    materias[16]->predecesores[0] = materias[7];                            // BD es predecesor de Big Data
    materias[16]->predecesores[1] = materias[4];                            // M2 es predecesor de Big Data
    materias[16]->numPredecesores = 2;

    materias[17]->predecesores = (Materia **)malloc(2 * sizeof(Materia *)); // RO depende de F2 y PA
    materias[17]->predecesores[0] = materias[5];                            // F2 es predecesor de RO
    materias[17]->predecesores[1] = materias[6];                            // PA es predecesor de RO
    materias[17]->numPredecesores = 2;

    materias[18]->predecesores = (Materia **)malloc(2 * sizeof(Materia *)); // CS depende de SI y SO
    materias[18]->predecesores[0] = materias[11];                           // SI es predecesor de CS
    materias[18]->predecesores[1] = materias[9];                            // SO es predecesor de CS
    materias[18]->numPredecesores = 2;

    materias[19]->predecesores = (Materia **)malloc(2 * sizeof(Materia *)); // AA depende de PA y M2
    materias[19]->predecesores[0] = materias[6];                            // PA es predecesor de AA
    materias[19]->predecesores[1] = materias[4];                            // M2 es predecesor de AA
    materias[19]->numPredecesores = 2;
}

void imprimirGrafo()
{
    for (int i = 0; i < NUM_MATERIAS; i++)
    {
        printf("%s -> ", materias[i]->codigo);
        for (int j = 0; j < materias[i]->numPredecesores; j++)
        {
            printf("%s ", materias[i]->predecesores[j]->codigo);
        }
        printf("\n");
    }
}

void *imprimirMateria(void *arg)
{
    Materia *materia = (Materia *)arg;

    pthread_mutex_lock(materia->mutex);
    for (int i = 0; i < materia->numPredecesores; i++)
    {
        while (!materia->predecesores[i]->ejecutada)
        {
            pthread_cond_wait(materia->cond, materia->mutex);
        }
    }

    printf("%s\n", materia->codigo);
    materia->ejecutada = 1;

    for (int i = 0; i < NUM_MATERIAS; i++)
    {
        for (int j = 0; j < materias[i]->numPredecesores; j++)
        {
            if (materias[i]->predecesores[j] == materia)
            {
                pthread_cond_signal(materias[i]->cond);
            }
        }
    }

    pthread_mutex_unlock(materia->mutex);
    return NULL;
}

int main()
{

    inicializarMaterias();

    // imprimimos grafo inicial de precedencias

    printf("\nOrden de ejecucion de las materias:\n");

    pthread_t hilos[NUM_MATERIAS];

    // Crear los hilos para cada materia
    for (int i = 0; i < NUM_MATERIAS; i++)
    {
        pthread_create(&hilos[i], NULL, imprimirMateria, (void *)materias[i]);
    }

    // Esperar a que todos los hilos terminen
    for (int i = 0; i < NUM_MATERIAS; i++)
    {
        pthread_join(hilos[i], NULL);
    }

    /*
    printf("\n");
    printf("Grafo de precedencias:\n");
    imprimirGrafo();
    */

    // Liberar memoria
    for (int i = 0; i < NUM_MATERIAS; i++)
    {
        free(materias[i]->predecesores);
        free(materias[i]->cond);
        free(materias[i]->mutex);
        free(materias[i]);
    }

    return 0;
}

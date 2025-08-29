#!/bin/bash

# Variables globales a utilizar:

# tipo_total tiene del tipo de mascota la cantidad total que se registró en el sistema, Ejemplo tipo_total["Perro"] = 10
# tipo_adoptado tiene del tipo de mascota la cantidad de adopciones que se realizaron, Ejemplo tipo_adoptado["Perro"] = 5
# adopciones_por_mes tiene del mes la cantidad de adopciones que se realizaron por cada mes (1-12), Ejemplo adopciones_por_mes["1"] = 5
declare -A tipo_total tipo_adoptado adopciones_por_mes

# Función para registrar administrador
opcion_1() {
    clear
    echo 'Ingrese usuario admin:'
    read usuario
    echo 'Ingrese contraseña:'
    read -s contrasena
    usuycontra="$usuario|$contrasena"
    echo "$usuycontra" >>Usuarios_admin.txt
    echo -e
    clear
}

# Función para ingreso de usuario
opcion_2() {
    clear
    echo 'Ingrese su cedula:'
    read usuario
    echo 'Ingrese contraseña:'
    read -s contrasena
    clear

    ingreso=0
    ingresoAdmin=0

    # Verificación de usuario administrador
    while IFS='|' read -r nombreUsuario Contrasena1; do
        if [ "$nombreUsuario" = "$usuario" ] && [ "$Contrasena1" = "$contrasena" ]; then
            ingresoAdmin=1
            break
        fi
    done <./Usuarios_admin.txt

    # Verificación de usuario cliente si no es administrador
    if [ "$ingresoAdmin" -eq 0 ]; then
        while IFS='|' read -r nombreUsuario Contrasena1; do
            if [ "$nombreUsuario" = "$usuario" ] && [ "$Contrasena1" = "$contrasena" ]; then
                ingreso=1
                break
            fi
        done <./Usuarios_clientes.txt
    else
        ingreso=1
    fi

    # Mensaje de error si usuario o contraseña no son válidos
    if [ "$ingreso" -eq 0 ] && [ "$ingresoAdmin" -eq 0 ]; then
        clear
        echo 'Usuario o contraseña incorrecta'
        echo -e
        echo "Presiona Enter para Volver a Ingresar datos"
        read enter
        menu_principal
        return
    fi

    # Redirigir a menú adecuado según tipo de usuario
    if [ "$ingresoAdmin" -eq 1 ]; then
        menu_Admin
    else
        menu_Usuario
    fi
}

# Función para registrar un usuario
registrar_usuario() {
    clear
    echo 'Ingrese datos del Usuario'
    echo 'Ingrese Nombre:'
    read usuario
    echo 'Ingrese Cedula:'
    read cedula

    # Verificar que la cédula no esté registrada en ninguno de los dos archivos
    while grep -q "^$cedula|" Usuarios_clientes.txt || grep -q "^$cedula|" Usuarios_admin.txt; do
        echo "El Usuario ya existe."
        echo 'Ingrese una Cedula no registrada en el Sistema:'
        read cedula
    done

    echo 'Ingrese Numero de Telefono:'
    read telefono
    echo 'Ingrese fecha de Nacimiento (dd/mm/aaaa):'
    read fecha
    echo 'Ingrese tipo de usuario (1: Cliente, 2: Admin):'
    read tipoUsuario
    echo 'Ingrese Contraseña:'
    read contrasena

    # Guardar usuario en el archivo correspondiente
    if [ "$tipoUsuario" -eq 1 ]; then
        echo "$cedula|$contrasena" >>Usuarios_clientes.txt
        echo "Usuario registrado exitosamente."
    else
        echo "$cedula|$contrasena" >>Usuarios_admin.txt
        echo "Administrador registrado exitosamente."
    fi

    clear
    menu_Admin
}

# Función para registrar una mascota
registrar_mascotas() {
    clear
    echo 'Ingrese datos de la Mascota'
    echo 'Ingrese Numero de Identificador:'
    read idMacota
    idMacota_sin_espacios="${idMacota// /}"

    # Verificar que el identificador sea un número entero y no esté registrado ya
    while ! [[ "$idMacota_sin_espacios" =~ ^[0-9]+$ ]] || grep -q "^$idMacota_sin_espacios|" Datos_mascotas.txt; do
        if ! [[ "$idMacota_sin_espacios" =~ ^[0-9]+$ ]]; then
            echo "El identificador debe contener solo números enteros."
        else
            echo "El identificador ya existe."
        fi
        echo 'Ingrese nuevamente el Numero de Identificador:'
        read idMacota
        idMacota_sin_espacios="${idMacota// /}"
    done

    echo 'Tipo de Mascota:'
    read tipo
    echo 'Ingrese Nombre:'
    read nombre
    echo 'Ingrese Sexo:'
    read sexo
    echo 'Ingrese Edad:'
    read edad
    edadMascota_sin_espacios="${edad// /}"

    # Verificar que la edad sea un número entero
    while ! [[ "$edadMascota_sin_espacios" =~ ^[0-9]+$ ]]; do
        echo "La edad debe contener solo números enteros."
        echo 'Ingrese nuevamente la Edad:'
        read edad
        edadMascota_sin_espacios="${edad// /}"
    done

    echo 'Ingrese Descripcion:'
    read descripcion
    fechaIngreso=$(date +'%d/%m/%Y')
    estado=1

    # Guardar datos de la mascota en el archivo
    datosMascota="$idMacota_sin_espacios|$tipo|$nombre|$sexo|$edadMascota_sin_espacios|$descripcion|$fechaIngreso|$estado"
    echo "$datosMascota" >>Datos_mascotas.txt

    menu_Admin
}

# Función para mostrar estadísticas de adopción
estadisticas_adopcion() {
    clear
    echo 'Estadísticas de Adopción'
    echo -e

    total_adoptados=0
    suma_edades_adoptados=0

    # Leer datos de cada mascota
    while IFS='|' read -r idMacota tipo nombre sexo edad descripcion fechaIngreso estado; do
        # Asegúrate de que tipo no esté vacío
        if [ -n "$tipo" ]; then
            # Incrementa el total de mascotas por tipo
            tipo_total["$tipo"]=$((tipo_total["$tipo"] + 1))

            # Si la mascota ha sido adoptada (estado = 2)
            if [ "$estado" -eq 2 ]; then
                # Incrementa el total de adopciones por tipo
                tipo_adoptado["$tipo"]=$((tipo_adoptado["$tipo"] + 1))

                # Extrae el mes de la fecha de ingreso
                mes=$(echo "$fechaIngreso" | cut -d'/' -f2)
                adopciones_por_mes["$mes"]=$((adopciones_por_mes["$mes"] + 1))

                total_adoptados=$((total_adoptados + 1))

                # Convierte edad a número y súmala para el cálculo de la edad promedio
                edad_numero=$((edad))
                suma_edades_adoptados=$((suma_edades_adoptados + edad_numero))
            fi
        fi
    done <Datos_mascotas.txt

    # Porcentaje de Adopción por Tipo de Mascota
    echo 'Porcentaje de Adopción por Tipo de Mascota:'
    for tipo in "${!tipo_total[@]}"; do
        total=${tipo_total["$tipo"]}
        adoptados=${tipo_adoptado["$tipo"]}
        if [ "$total" -gt 0 ]; then
            porcentaje=$((adoptados * 100 / total))
            echo "Tipo: $tipo - $porcentaje%"
        fi
    done
    echo -e

    # Mes con más adopciones
    max_adopciones=0
    mes_max=""
    for mes in "${!adopciones_por_mes[@]}"; do
        if [ "${adopciones_por_mes["$mes"]}" -gt "$max_adopciones" ]; then
            max_adopciones=${adopciones_por_mes["$mes"]}
            mes_max=$mes
        fi
    done
    echo "Mes con más adopciones: $mes_max ($max_adopciones adopciones)"
    echo -e

    # Edad promedio de los animales adoptados
    if [ "$total_adoptados" -gt 0 ]; then
        edad_promedio=$((suma_edades_adoptados / total_adoptados))
        echo "Edad promedio de los animales adoptados: $edad_promedio años"
    else
        echo "No hay animales adoptados para calcular la edad promedio."
    fi
    echo -e

    echo "Presiona Enter para Volver"
    read enter
    clear
    menu_Admin
}

adoptar_mascota() {
    clear
    echo 'Ingrese el ID de la mascota que desea adoptar:'
    read idMascotaAdoptar
    adopto=0
    while IFS='|' read -r idMascota tipo nombre sexo edad descripcion fechaIngreso estado; do
        if [ "$idMascota" -eq "$idMascotaAdoptar" ] && [ "$estado" -eq 1 ]; then
            fechaIngreso=$(date +'%d/%m/%Y')
            datosMascota="$idMascota|$tipo|$nombre|$sexo|$edad|$descripcion|$fechaIngreso|2"
            sed -i "s#$idMascota|.*#$datosMascota#" Datos_mascotas.txt
            echo "$idMascota|$tipo|$nombre|$sexo|$edad|$descripcion|$fechaIngreso" >>adopciones.txt
            adopto=1
            echo "Mascota adoptada exitosamente."
        fi
    done <Datos_mascotas.txt

    if [ "$adopto" -eq 0 ]; then
        echo "ID de mascota invalido, ingresar nuevamente."
    else
        echo Presiona Enter para Volver
        read enter
    fi
    clear
    menu_Usuario
}

menu_inicio() {
    clear
    echo 'Bienvenido!'
    echo -e
    echo 'Opción 1: Registrar Admin: Ingresar usuario y contraseña'
    echo 'Opción 2: Entrar al sistema'
    echo 'Opción 3: Salir del sistema'
    echo 'Ingrese opción:'
}

menu_principal() {
    while true; do
        menu_inicio
        read opcion
        case $opcion in
        1)
            opcion_1
            ;;
        2)
            opcion_2
            ;;
        3)
            clear
            exit
            ;;
        *)
            echo "Opción incorrecta. Presiona Enter para y vuelve a ingrear la opcion."
            read enter
            ;;
        esac
    done
}

menu_Admin() {

    clear
    echo 'Bienvenido Admin'
    echo -e
    echo 'Opción 1: Registrar Usuario'
    echo 'Opción 2: Registrar Mascotas'
    echo 'Opción 3: Estadísticas de Adopción'
    echo 'Opción 4: Salir'
    echo -e
    echo 'Ingrese opción:'
    read opcion

    case $opcion in
    1)
        registrar_usuario
        ;;
    2)
        registrar_mascotas
        ;;
    3)
        estadisticas_adopcion
        ;;
    4)
        clear
        menu_inicio
        ;;
    *)
        echo "Opción incorrecta. Presiona Enter y vuelve a ingresar la opcion."
        read enter
        return
        ;;
    esac

}

# Función para listar mascotas disponibles para adopción
listar_mascotas() {
    clear
    echo 'Mascotas Disponibles para Adopción:'
    while IFS='|' read -r idMascota tipo nombre sexo edad descripcion fechaIngreso estado; do
        if [ "$estado" -eq 1 ]; then
            echo "ID: $idMascota | Nombre: $nombre | Tipo: $tipo | Edad: $edad | Descripción: $descripcion"
            echo -e
        fi
    done <Datos_mascotas.txt
    echo "Presiona Enter para Volver"
    read enter
    menu_Usuario
}

menu_Usuario() {
    clear
    echo 'Bienvenido Usuario'
    echo -e
    echo 'Opción 1: Listar Mascotas Disponibles para Adopción'
    echo 'Opción 2: Adoptar Mascota'
    echo 'Opción 3: Salir'
    echo -e
    echo 'Ingrese opción:'
    read opcion

    case $opcion in
    1)
        listar_mascotas
        ;;
    2)
        adoptar_mascota
        ;;
    3)
        clear
        menu_inicio
        ;;
    *)
        echo "Opción incorrecta. Presiona Enter para continuar."
        read enter
        return
        ;;
    esac

}
#Creo archivos de texto para almacenar los datos
>Usuarios_admin.txt
>Usuarios_clientes.txt
>Datos_mascotas.txt
>adopciones.txt
echo -e "admin|admin" >>Usuarios_admin.txt # Usar >> para agregar al archivo

# Inicializar programa
menu_principal

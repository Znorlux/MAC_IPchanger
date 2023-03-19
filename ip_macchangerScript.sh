#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Por favor, ejecute el script con permisos de root"
  exit
fi

echo -e "\e[34mGenerando nueva direccion MAC y IP...\e[0m"
echo "Desactivando interfaz de red..."
sudo ifconfig eth0 down

# Generar una dirección MAC aleatoria
NEWMAC=$(sudo macchanger -a eth0 | grep "Current MAC:" | awk '{print $3}')
#NEWMAC=$(printf '52:54:%02X:%02X:%02X:%02X\n' $[RANDOM%256] $[RANDOM%256] $[RANDOM%256] $[RANDOM%256])

# Verificar la red y generar una dirección IP aleatoria válida
CURRENT_IP=$(ip addr show eth0 | grep 'inet\b' | awk '{print $2}' | cut -d/ -f1)

NETWORK=$(echo "$CURRENT_IP" | cut -d "." -f1-2)
if [[ $NETWORK == "192.168" ]]; then
    while true; do
        NEWIP="$NETWORK.$((RANDOM%255+1))"
        if ping -c1 "$NEWIP" &> /dev/null; then
            echo "La IP $NEWIP ya está en uso, generando otra IP..."
        else
            break
        fi
    done
elif [[ $NETWORK == "10" ]]; then
    while true; do
        NEWIP="$NETWORK.$((RANDOM%255+1)).$((RANDOM%255+1))"
        if ping -c1 "$NEWIP" &> /dev/null; then
            echo "La IP $NEWIP ya está en uso, generando otra IP..."
        else
            break
        fi
    done
else
    echo "No se reconoce la red actual, no se puede generar una IP aleatoria válida."
    macchanger -p eth0
    sudo ifconfig eth0 up
    exit 1
fi

# Cambiar la dirección MAC e IP
sudo ifconfig eth0 hw ether $NEWMAC
sudo ifconfig eth0 $NEWIP
echo "Activando interfaz de red..."
sudo ifconfig eth0 up
echo "La dirección MAC se ha cambiado a: $NEWMAC"
echo "La dirección IP se ha cambiado a: $NEWIP"

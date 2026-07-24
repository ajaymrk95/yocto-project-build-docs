#!/bin/bash

NOCOLOR='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;41m'
STD='\033[0;0;39m'

flash(){
    ./flash.sh cti/$2/$BOARD_TYPE/$1 mmcblk0p1
    exit 0
}

menu() {
    clear
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"  
    echo "         CTI FLASH         "
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "1. Astro"
    echo "2. Elroy"
    echo "3. Orbitty"
    echo "4. Spacely (ASG006)"
    echo "5. Spacely (ASG026)"
    echo "6. Sprocket"
    echo "7. Rudi"
    echo "8. Cogswell"
    echo "9. Rosie"
    echo "10. Graphite VPX"
    echo "11. Quasar"
    echo "x. Exit"
}

astroMenu() {
    clear
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
    echo "           Astro           "
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "1. Revison J+"
    echo "2. Revison G to Revision I"
    echo "3. USB3.0 (Rev F prior)"
    echo "4. mPCIe (Rev F prior)"
    echo "5. Cancel (back to main menu)"
}

elroyMenu() {
    clear
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"  
    echo "           Elroy           "
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "1. Revison F+"
    echo "2. USB3.0 (Rev E prior)"
    echo "3. mPCIe (Rev E prior )"
    echo "4. Cancel (back to main menu)"
}

spacelyMenu() {
    clear
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"  
    echo "    Spacely (ASG006)       "
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "1. Base"
    echo "2. IMX274 3 Cameras"
    echo "3. IMX274 6 Cameras"
    echo "4. Cancel (back to main menu)"
}

spacelyRevjMenu() {
    clear
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"  
    echo "    Spacely (ASG026)       "
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "1. Base"
    echo "2. IMX274 3 Cameras"
    echo "3. IMX274 6 Cameras"
    echo "4. Cancel (back to main menu)"
}

rudiMenu() {
    clear
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"  
    echo "           Rudi            "
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "1. Revison C+"
    echo "2. USB3.0 (Rev B prior)"
    echo "3. mPCIe (Rev B prior )"
    echo "4. Cancel (back to main menu)"
}

sprocketMenu() {
    clear
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"  
    echo "          Sprocket          "
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "1. Base"    
    echo "2. IMX274"
    echo "3. Cancel (back to main menu)"
}

quasarMenu() {
    clear
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"  
    echo "          Quasar           "
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "1. Base"    
    echo "2. IMX274"
    echo "3. Cancel (back to main menu)"
}

vpxMenu() {
    clear
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"  
    echo "            VPX            "
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "1. Base"
    echo "2. IMX274-2CAM"
#    echo "3. IMX185"
    echo "3. Cancel (back to main menu)"
}

tx2Menu() {
    clear
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"  
    echo "        TX2 Version        "
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "1. TX2"
    echo "2. TX2i"
    echo "3. TX2-4G"
    echo "4. Cancel (back to main menu)"
}


tx2Options(){
    tx2Menu
    local choice
    read -p "Enter choice:  " choice
    case $choice in
        1) flash $1 tx2;;    
        2) flash $1 tx2i;;
        3) flash $1 tx2-4G;;
        4) ;;
        *) echo -e "${RED}Invalid Choice...${STD}" && sleep 1
    esac
}



astroOptions(){
    astroMenu
    local choice
    read -p "Enter choice:  " choice
    case $choice in
        1) tx2Options revJ+;;
        2) tx2Options revG+;;    
        3) tx2Options usb3;;
        4) tx2Options mpcie;;
        5) ;;
        *) echo -e "${RED}Invalid Choice...${STD}" && sleep 1
    esac
}

elroyOptions(){
    elroyMenu
    local choice
    read -p "Enter choice:  " choice
    case $choice in
        1) tx2Options revF+;;    
        2) tx2Options usb3;;
        3) tx2Options mpcie;;
        4) ;;
        *) echo -e "${RED}Invalid Choice...${STD}" && sleep 1
    esac
}

spacelyOptions(){
    spacelyMenu
    local choice
    read -p "Enter choice:  " choice
    case $choice in
        1) tx2Options base;;    
        2) tx2Options li-imx274-3cam;;
        3) tx2Options li-imx274-6cam;;
        4) ;;
        *) echo -e "${RED}Invalid Choice...${STD}" && sleep 1
    esac
}

spacelyRevjOptions(){
    spacelyRevjMenu
    local choice
    read -p "Enter choice:  " choice
    case $choice in
        1) tx2Options base-revj+;;    
        2) tx2Options li-imx274-3cam-revj+;;
        3) tx2Options li-imx274-6cam-revj+;;
        4) ;;
        *) echo -e "${RED}Invalid Choice...${STD}" && sleep 1
    esac
}
quasarOptions(){
    quasarMenu
    local choice
    read -p "Enter choice:  " choice
    case $choice in
        1) tx2Options base;;    
        2) tx2Options li-imx274;;
        3) ;;
        *) echo -e "${RED}Invalid Choice...${STD}" && sleep 1
    esac
}
sprocketOptions(){
    sprocketMenu
    local choice
    read -p "Enter choice:  " choice
    case $choice in  
        1) tx2Options base;;
        2) tx2Options li-imx274;;
        3) ;;
        *) echo -e "${RED}Invalid Choice...${STD}" && sleep 1
    esac
}

rudiOptions(){
    rudiMenu
    local choice
    read -p "Enter choice:  " choice
    case $choice in
        1) tx2Options base;;    
        2) tx2Options usb3;;
        3) tx2Options mpcie;;
        4) ;;
        *) echo -e "${RED}Invalid Choice...${STD}" && sleep 1
    esac
}

vpxOptions(){
    vpxMenu
    local choice
    read -p "Enter choice:  " choice
    case $choice in  
        1) tx2Options base;;
        2) tx2Options li-imx274-2cam;;
#        3) tx2Options vpg003-imx185-3cam;;
        3) ;;
        *) echo -e "${RED}Invalid Choice...${STD}" && sleep 1
    esac
}


boardOptions(){
    local choice
    read -p "Enter choice:  " choice
    case $choice in
        1) BOARD_TYPE="astro"; astroOptions;;    
        2) BOARD_TYPE="elroy"; elroyOptions;;
        3) BOARD_TYPE="orbitty"; tx2Options base;;
        4) BOARD_TYPE="spacely"; spacelyOptions;;
	5) BOARD_TYPE="spacely"; spacelyRevjOptions;;
        6) BOARD_TYPE="sprocket"; sprocketOptions;;
        7) BOARD_TYPE="rudi"; rudiOptions;;
        8) BOARD_TYPE="cogswell"; tx2Options base;;
        9) BOARD_TYPE="rosie"; tx2Options base;;
        10) BOARD_TYPE="vpg003"; vpxOptions;; 
        11) BOARD_TYPE="quasar"; quasarOptions;;
        x) exit 0;;
        *) echo -e "${RED}Invalid Choice...${STD}" && sleep 1
    esac
}
 
trap ''
dmesg -D
 
while true
do
    menu
    boardOptions
done


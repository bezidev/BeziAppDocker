#!/bin/bash

DOCKER_COMPOSE_VERSION='v2.5.0'

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[1;34m'
NC='\033[0m'

echo -e "${GREEN}"
echo "  ____           _                      "
echo " |  _ \         (_)   /\                "
echo " | |_) | ___ _____   /  \   _ __  _ __  "
echo " |  _ < / _ \_  / | / /\ \ | '_ \| '_ \ "
echo " | |_) |  __// /| |/ ____ \| |_) | |_) |"
echo " |____/ \___/___|_/_/    \_\ .__/| .__/ "
echo "                           | |   | |    "
echo "                           |_|   |_|    "
echo -e "${NC}"
echo "Pozdravljeni in dobrodošli v namestitvenem orodju BežiApp sistema."
echo "V tem orodju vas popeljemo čez namestitev BežiApp sistema na vaš strežnik."
echo "To orodje je bilo narejeno, da bi čim bolj olajšali postopek namestitve."
echo ""
echo -e "${YELLOW}Možno je, da vas bo namestitev včasih vprašala za skrbniško geslo. Kadar vas vpraša, prosimo da ga vpišete.${NC}"
echo -e "${YELLOW}NE DELITE SKRBNIŠKEGA GESLA Z NIKOMER DRUGIM.${NC}"
echo ""
echo -e "Pritisnite ${BLUE}ENTER${NC}, če želite začeti z namestitvijo"

read

OS=`( lsb_release -ds || cat /etc/*release || uname -om ) 2>/dev/null | head -n1 | awk '{print $1}'`
echo -e "Zaznana distribucija Linux operacijskega sistema $YELLOW$OS$NC"

if [ $OS == Ubuntu ]; then
    echo -e "${BLUE}Posodabljam apt repozitorije${NC}"
    sudo apt update
    
    echo -e "${BLUE}Nameščam potrebne pakete za namestitev BežiApp sistema${NC}"
    sudo apt install -y curl git software-properties-common openssl haveged sed
    
    echo -e "${BLUE}Nameščam Docker repozitorij za ${YELLOW}Ubuntu${NC}"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    
    echo -e "${BLUE}Posodabljam apt repozitorije${NC}"
    sudo apt update
    
    echo -e "${BLUE}Nameščam Docker za ${YELLOW}Ubuntu${NC}"
    sudo apt install -y docker-ce
elif [ $OS == Debian ]; then
    echo -e "${BLUE}Posodabljam apt repozitorije${NC}"
    sudo apt update
    
    echo -e "${BLUE}Nameščam potrebne pakete za namestitev BežiApp sistema${NC}"
    sudo apt install -y curl git software-properties-common openssl haveged sed apt-transport-https ca-certificates gnupg2
    
    echo -e "${BLUE}Nameščam Docker repozitorij za ${YELLOW}Debian${NC}"
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
    
    echo -e "${BLUE}Posodabljam apt repozitorije${NC}"
    sudo apt update
    
    echo -e "${BLUE}Nameščam Docker za ${YELLOW}Ubuntu${NC}"
    sudo apt install -y docker-ce
else
    echo "Nepodprta Linux distribucija. Orodje ne more avtomatično namestiti BežiApp sistema na tej distribuciji."
    exit 1
fi

# Splošni ukazi (velja za vse operacijske sisteme)

echo -e "${BLUE}Nameščam Docker Compose${NC}"
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

echo -e "${BLUE}Dodeljujem izvršilno pravico za Docker Compose${NC}"
sudo chmod +x /usr/local/bin/docker-compose

echo -e "${BLUE}Docker verzija je ${YELLOW}$(docker --version)${BLUE}. docker-compose verzija je ${YELLOW}$(docker-compose --version)${NC}"
echo -e "${YELLOW}Prosimo, preverite če se vse ujema (izpisati bi se vam morala Docker in docker-compose verzija)${NC}"
echo -e "${YELLOW}Če se vam katera verzija ne izpiše, prekličite namestitev z ukazom ${BLUE}CTRL+C${NC}"
echo -e "${YELLOW}Če se vse ujema, nadljujte s pritiskom na gumb ${BLUE}ENTER${NC}"
read

echo -e "${YELLOW}V tem delu namestitve vas moramo vprašati za nekaj podatkov za pridobitev SSL certifikata od Let's Encrypt avtoritete${NC}"
echo -e "${YELLOW}Prosimo, da vpišete korektne podatke, saj drugače verjetno ne bo delovalo${NC}"

echo -e "${GREEN}Službeni (šolski) elektronski naslov: ${NC}"
read EMAIL
echo -e "${GREEN}Domena (oz. poddomena) na kateri se bo nahajal BežiApp sistem: ${NC}"
read DOMAIN

echo -e "Če sta vaš elektronski naslov ${YELLOW}${EMAIL}${NC} in BežiApp (pod)domena ${YELLOW}${DOMAIN}${NC} pravilno podana, kliknite ${BLUE}ENTER${NC}, drugače pa prekličite namestitveni postopek z ukazom ${BLUE}CTRL+C${NC}"
read

echo -e "${BLUE}Vgrajujem podatke v BežiApp sistem${NC}"
sed -i "s/test@example.org/${EMAIL}/" initcert.sh
sed -i "s/-d example.org/-d ${DOMAIN}/" initcert.sh
sed -i "s/example.com www.example.com/${DOMAIN}/" default.conf.aftercert

echo -e "${BLUE}Dodeljujem izvršilne pravice za BežiApp namestitvene datoteke${NC}"
chmod +x getdhparam.sh
chmod +x initcert.sh

echo -e "${BLUE}Pridobivam DH parametre za SSL certifikat z uporabo OpenSSL programa${NC}"
echo -e "${YELLOW}To lahko traja nekaj časa, vmes ne preklicujte programa${NC}"
./getdhparam.sh

echo -e "${GREEN}Zdaj smo pripravljeni na pridobivanje SSL certifikata. Potrdite začetek z uporabo tipke ${BLUE}ENTER${NC}"
read

echo -e "${BLUE}Pridobivam SSL certifikat od Let's Encrypt avtoritete${NC}"
echo -e "${YELLOW}To lahko traja nekaj časa, vmes ne preklicujte programa${NC}"
./initcert.sh

echo -e "${RED}Naslednje, kar se bo zgodilo je, da bomo zagnali kontejnerje (BežiApp sistem). Prosimo, počakajte nekaj časa, dokler se izpisi ne ustavijo, nakar pojdite na svojo domeno za BežiApp in preverite, če vse deluje. Če vse deluje, pritisnite ${BLUE}CTRL+C${RED} enkrat, nakar se bi vam moral sistem zagnati v ozadju. V nasprotnem primeru, klikajte ${BLUE}CTRL+C${RED} dokler se program ne konča, nakar lahko prijavite napako."
echo -e "${YELLOW}Ali se je vse prejšnje (pridobivanje SSL certifikata) končalo brez napak? Če se je, samo nadaljujte s klikom na tipko ${BLUE}ENTER${YELLOW}, drugače pa poskusite znova zagnati namestitev (trenutno namestitev lahko prekličete z uporabo kombinacije tipk ${BLUE}CTRL+C${YELLOW}). Če se napaka ponavlja, lahko prijavite napako na ${BLUE}info@BežiApp.si${YELLOW} ali pa na GitHub repozitorij ${BLUE}https://github.com/BežiApp/BežiAppDocker${YELLOW}. Prosimo vas, če v primeru prijave napake vključite vse, kar se vam je izpisalo od začetka tega programa.${NC}"

read

sudo docker-compose up

echo -e "${YELLOW}Zdaj bomo zagnali sistem v ozadju. Potrdite, da vse deluje s tipko ${BLUE}ENTER${NC}"
read

sudo docker-compose up -d

echo -e "${GREEN}BežiApp sistem bi se v kratkem moral zagnati do konca. Želimo vam prijetno uporabo tega sistema, v primeru težav pa lahko kadarkoli kontaktirate BežiApp ekipo na ${BLUE}info@BežiApp.si${NC}"

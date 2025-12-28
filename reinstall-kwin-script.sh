#!/bin/bash

# ============================================================
# KWin Script Neuinstallation Script
# Führt eine komplette Neuinstallation des Scripts durch
# ============================================================

set -e  # Beende bei Fehlern

SCRIPT_NAME="rememberwindowpositions"
SCRIPT_DIR=""
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== KWin Script Neuinstallation ===${NC}"
echo ""

# Prüfe ob wir im richtigen Verzeichnis sind
# Variante 1: metadata.json im Root (alte Struktur)
# Variante 2: metadata.json in src/ (neue Struktur mit Makefile)
if [ -f "metadata.json" ]; then
    SCRIPT_DIR=$(pwd)
    echo -e "${GREEN}✓ Script-Verzeichnis gefunden: $SCRIPT_DIR${NC}"
elif [ -f "src/metadata.json" ] || [ -f "Makefile" ]; then
    SCRIPT_DIR=$(pwd)
    echo -e "${GREEN}✓ Script-Projekt-Verzeichnis gefunden: $SCRIPT_DIR${NC}"
    echo -e "${BLUE}  (Verwendet Makefile für Installation)${NC}"
else
    echo -e "${YELLOW}Suche nach Script-Verzeichnis...${NC}"
    # Suche nach dem Script-Verzeichnis
    POSSIBLE_DIRS=(
        "."
        ".."
        "../RememberWindowPositions"
        "~/RememberWindowPositions"
        "~/Projects/RememberWindowPositions"
        "/Daten/freigabe/git/RememberWindowPositions"
    )
    
    for dir in "${POSSIBLE_DIRS[@]}"; do
        if [ -f "$dir/metadata.json" ] || [ -f "$dir/src/metadata.json" ] || [ -f "$dir/Makefile" ]; then
            SCRIPT_DIR="$dir"
            echo -e "${GREEN}✓ Script-Verzeichnis gefunden: $SCRIPT_DIR${NC}"
            break
        fi
    done
    
    if [ -z "$SCRIPT_DIR" ]; then
        echo -e "${RED}✗ Script-Verzeichnis nicht gefunden!${NC}"
        echo "Erwartete Struktur: metadata.json ODER src/metadata.json ODER Makefile"
        read -p "Bitte gib den Pfad zum Script-Verzeichnis ein: " SCRIPT_DIR
        if [ ! -f "$SCRIPT_DIR/metadata.json" ] && [ ! -f "$SCRIPT_DIR/src/metadata.json" ] && [ ! -f "$SCRIPT_DIR/Makefile" ]; then
            echo -e "${RED}✗ Ungültiges Verzeichnis!${NC}"
            exit 1
        fi
    fi
fi

cd "$SCRIPT_DIR"
echo ""

# Frage ob automatisch oder Schritt für Schritt
echo "Möchtest du:"
echo "  1) Alles automatisch durchführen (empfohlen)"
echo "  2) Schritt für Schritt mit Bestätigung"
echo ""
read -p "Wähle Option (1 oder 2): " mode

AUTO=false
if [ "$mode" = "1" ]; then
    AUTO=true
    echo -e "${BLUE}Automatischer Modus aktiviert${NC}"
    echo ""
fi

function wait_for_user() {
    if [ "$AUTO" = false ]; then
        read -p "Drücke Enter um fortzufahren..."
    fi
}

# ============================================================
# Schritt 1: Backup erstellen (optional)
# ============================================================
echo -e "${BLUE}[1/8] Backup der Konfiguration erstellen (optional)${NC}"
echo "Aktuelle Konfiguration in: ~/.config/kde.org/kwin.conf"

if [ "$AUTO" = false ]; then
    read -p "Backup erstellen? (y/n): " do_backup
else
    do_backup="y"
    echo "Erstelle Backup..."
fi

if [ "$do_backup" = "y" ]; then
    BACKUP_FILE="$HOME/.config/kde.org/kwin.conf.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$HOME/.config/kde.org/kwin.conf" "$BACKUP_FILE"
    echo -e "${GREEN}✓ Backup erstellt: $BACKUP_FILE${NC}"
else
    echo -e "${YELLOW}⊘ Backup übersprungen${NC}"
fi
echo ""
wait_for_user

# ============================================================
# Schritt 2: Altes Script deinstallieren
# ============================================================
echo -e "${BLUE}[2/8] Altes Script deinstallieren${NC}"
if kpackagetool6 --type=KWin/Script --show=$SCRIPT_NAME &>/dev/null; then
    echo "Script ist installiert, deinstalliere..."
    kpackagetool6 --type=KWin/Script --remove=$SCRIPT_NAME
    echo -e "${GREEN}✓ Script deinstalliert${NC}"
else
    echo -e "${YELLOW}⊘ Script war nicht installiert${NC}"
fi
echo ""
wait_for_user

# ============================================================
# Schritt 3: Alte Dateien löschen
# ============================================================
echo -e "${BLUE}[3/8] Alte Script-Dateien löschen${NC}"
INSTALL_DIR="$HOME/.local/share/kwin/scripts/$SCRIPT_NAME"
if [ -d "$INSTALL_DIR" ]; then
    echo "Lösche: $INSTALL_DIR"
    rm -rf "$INSTALL_DIR"
    echo -e "${GREEN}✓ Alte Dateien gelöscht${NC}"
else
    echo -e "${YELLOW}⊘ Keine alten Dateien gefunden${NC}"
fi
echo ""
wait_for_user

# ============================================================
# Schritt 4: Cache löschen
# ============================================================
echo -e "${BLUE}[4/8] KWin Cache löschen${NC}"
echo "Lösche Cache-Verzeichnisse..."
rm -rf ~/.cache/kwin/
rm -rf ~/.cache/plasma*
echo -e "${GREEN}✓ Cache gelöscht${NC}"
echo ""
wait_for_user

# ============================================================
# Schritt 5: KWin neustarten
# ============================================================
echo -e "${BLUE}[5/8] KWin neustarten${NC}"
echo "Erkenne Session-Type..."

# Erkenne ob X11 oder Wayland
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    SESSION_TYPE="wayland"
    echo "Wayland Session erkannt"
elif [ "$XDG_SESSION_TYPE" = "x11" ] || [ -n "$DISPLAY" ]; then
    SESSION_TYPE="x11"
    echo "X11 Session erkannt"
else
    echo -e "${YELLOW}Session-Type konnte nicht erkannt werden${NC}"
    read -p "Verwende Wayland? (y/n): " is_wayland
    if [ "$is_wayland" = "y" ]; then
        SESSION_TYPE="wayland"
    else
        SESSION_TYPE="x11"
    fi
fi

echo "Starte KWin neu..."
if [ "$SESSION_TYPE" = "wayland" ]; then
    # Für Wayland - nur reconfigure, kein vollständiger Neustart möglich
    echo -e "${YELLOW}Hinweis: Auf Wayland kann KWin nicht einfach neu gestartet werden${NC}"
    echo "Führe KWin reconfigure aus..."
    qdbus org.kde.KWin /KWin reconfigure
    sleep 2
else
    # Für X11
    kwin_x11 --replace &
    sleep 3
fi
echo -e "${GREEN}✓ KWin neugestartet${NC}"
echo ""
wait_for_user

# ============================================================
# Schritt 6: Script neu installieren
# ============================================================
echo -e "${BLUE}[6/8] Script neu installieren${NC}"
echo "Installiere von: $SCRIPT_DIR"

# Verwende Makefile falls vorhanden
if [ -f "Makefile" ]; then
    echo "Verwende Makefile..."
    make clean
    make install
else
    echo "Verwende kpackagetool6..."
    kpackagetool6 --type=KWin/Script --install=.
fi

echo -e "${GREEN}✓ Script installiert${NC}"
echo ""

# Verifiziere Installation
echo "Suche nach installierten Dateien..."
MAIN_QML=""
MAINMENU_QML=""

# Prüfe verschiedene mögliche Pfade
if [ -f "$INSTALL_DIR/contents/code/main.qml" ]; then
    MAIN_QML="$INSTALL_DIR/contents/code/main.qml"
elif [ -f "$INSTALL_DIR/contents/ui/main.qml" ]; then
    MAIN_QML="$INSTALL_DIR/contents/ui/main.qml"
fi

if [ -f "$INSTALL_DIR/contents/ui/MainMenu.qml" ]; then
    MAINMENU_QML="$INSTALL_DIR/contents/ui/MainMenu.qml"
fi

# Zeige gefundene Struktur
echo "Installierte Struktur:"
if [ -d "$INSTALL_DIR" ]; then
    tree -L 3 "$INSTALL_DIR" 2>/dev/null || find "$INSTALL_DIR" -type f | head -20
else
    echo -e "${RED}✗ Installation-Verzeichnis existiert nicht: $INSTALL_DIR${NC}"
fi
echo ""

if [ -n "$MAIN_QML" ]; then
    echo -e "${GREEN}✓ main.qml gefunden: $MAIN_QML${NC}"
    
    # Prüfe ob getTileInfo vorhanden ist
    if grep -q "function getTileInfo" "$MAIN_QML"; then
        echo -e "${GREEN}✓ Tile-Support in main.qml erkannt - NEUE VERSION${NC}"
    else
        echo -e "${RED}✗ Tile-Support in main.qml NICHT gefunden - ALTE VERSION?${NC}"
    fi
else
    echo -e "${RED}✗ main.qml nicht gefunden!${NC}"
    echo "  Gesuchte Pfade:"
    echo "    - $INSTALL_DIR/contents/code/main.qml"
    echo "    - $INSTALL_DIR/contents/ui/main.qml"
fi

if [ -n "$MAINMENU_QML" ]; then
    echo -e "${GREEN}✓ MainMenu.qml gefunden: $MAINMENU_QML${NC}"
    
    # Prüfe ob Tile-Checkbox vorhanden ist
    if grep -q "id: aTile" "$MAINMENU_QML"; then
        echo -e "${GREEN}✓ Tile-Checkbox in MainMenu.qml erkannt - NEUE VERSION${NC}"
    else
        echo -e "${RED}✗ Tile-Checkbox in MainMenu.qml NICHT gefunden - ALTE VERSION?${NC}"
    fi
else
    echo -e "${YELLOW}⊘ MainMenu.qml nicht gefunden (optional)${NC}"
fi

# Prüfe Source-Dateien im Projekt
echo ""
echo "Source-Dateien im Projekt:"
if [ -f "$SCRIPT_DIR/src/contents/code/main.qml" ]; then
    echo -e "${GREEN}✓ $SCRIPT_DIR/src/contents/code/main.qml${NC}"
    if grep -q "function getTileInfo" "$SCRIPT_DIR/src/contents/code/main.qml"; then
        echo "  → Enthält getTileInfo()"
    else
        echo -e "  ${RED}→ Enthält KEIN getTileInfo()${NC}"
    fi
elif [ -f "$SCRIPT_DIR/src/contents/ui/main.qml" ]; then
    echo -e "${GREEN}✓ $SCRIPT_DIR/src/contents/ui/main.qml${NC}"
    if grep -q "function getTileInfo" "$SCRIPT_DIR/src/contents/ui/main.qml"; then
        echo "  → Enthält getTileInfo()"
    else
        echo -e "  ${RED}→ Enthält KEIN getTileInfo()${NC}"
    fi
else
    echo -e "${YELLOW}⊘ main.qml in Source nicht gefunden${NC}"
fi

if [ -f "$SCRIPT_DIR/src/contents/ui/MainMenu.qml" ]; then
    echo -e "${GREEN}✓ $SCRIPT_DIR/src/contents/ui/MainMenu.qml${NC}"
    if grep -q "id: aTile" "$SCRIPT_DIR/src/contents/ui/MainMenu.qml"; then
        echo "  → Enthält Tile-Checkbox"
    else
        echo -e "  ${RED}→ Enthält KEINE Tile-Checkbox${NC}"
    fi
else
    echo -e "${YELLOW}⊘ MainMenu.qml in Source nicht gefunden${NC}"
fi
echo ""
wait_for_user

# ============================================================
# Schritt 7: Script aktivieren und konfigurieren
# ============================================================
echo -e "${BLUE}[7/8] Script aktivieren und konfigurieren${NC}"

# Script aktivieren
echo "Aktiviere Script..."
kwriteconfig6 --file kwinrc --group Plugins --key ${SCRIPT_NAME}Enabled true
echo -e "${GREEN}✓ Script aktiviert${NC}"

# Debug-Logs aktivieren
echo "Aktiviere Debug-Logs..."
kwriteconfig6 --file kwinrc --group Script-$SCRIPT_NAME --key debugLogs true
echo -e "${GREEN}✓ Debug-Logs aktiviert${NC}"

# Tile-Support aktivieren (falls gewünscht)
if [ "$AUTO" = false ]; then
    read -p "Tile-Support aktivieren? (y/n): " enable_tile
else
    enable_tile="y"
    echo "Aktiviere Tile-Support..."
fi

if [ "$enable_tile" = "y" ]; then
    kwriteconfig6 --file kwinrc --group Script-$SCRIPT_NAME --key restoreTile true
    echo -e "${GREEN}✓ Tile-Support aktiviert${NC}"
fi

echo ""
wait_for_user

# ============================================================
# Schritt 8: KWin erneut neustarten
# ============================================================
echo -e "${BLUE}[8/8] KWin erneut neustarten${NC}"
echo "Starte KWin neu um Änderungen zu übernehmen..."

if [ "$SESSION_TYPE" = "wayland" ]; then
    qdbus org.kde.KWin /KWin reconfigure
    sleep 2
else
    kwin_x11 --replace &
    sleep 3
fi

echo -e "${GREEN}✓ KWin neugestartet${NC}"
echo ""

# ============================================================
# Fertig - Logs anzeigen
# ============================================================
echo -e "${GREEN}=== Installation abgeschlossen! ===${NC}"
echo ""
echo -e "${BLUE}Überprüfe die Installation:${NC}"
echo ""

# Zeige Version-Check Log
echo "Suche nach Version-Check in Logs..."
if journalctl --user -b | grep -i "RememberWindowPositions VERSION CHECK" | tail -n 1; then
    echo -e "${GREEN}✓ Script wurde geladen${NC}"
else
    echo -e "${YELLOW}⊘ Kein Version-Check Log gefunden${NC}"
fi
echo ""

# Zeige letzte Script-Logs
echo "Letzte 10 Script-Logs:"
journalctl --user -b | grep -i "RememberWindowPositions" | tail -n 10
echo ""

# Anleitung für weitere Logs
echo -e "${BLUE}Live-Logs anzeigen:${NC}"
echo "  journalctl --user -f | grep -i RememberWindowPositions"
echo ""

# Zeige Konfiguration
echo -e "${BLUE}Aktuelle Konfiguration:${NC}"
echo "  Script aktiviert: $(kreadconfig6 --file kwinrc --group Plugins --key ${SCRIPT_NAME}Enabled)"
echo "  Debug-Logs: $(kreadconfig6 --file kwinrc --group Script-$SCRIPT_NAME --key debugLogs)"
echo "  Tile-Support: $(kreadconfig6 --file kwinrc --group Script-$SCRIPT_NAME --key restoreTile)"
echo ""

# Backup-Info
if [ -n "$BACKUP_FILE" ]; then
    echo -e "${BLUE}Backup gespeichert unter:${NC}"
    echo "  $BACKUP_FILE"
    echo ""
fi

echo -e "${GREEN}Fertig! Das Script sollte jetzt funktionieren.${NC}"
echo ""
echo "Teste es, indem du ein Fenster öffnest, schließt und wieder öffnest."
echo "Die Logs sollten die Wiederherstellung anzeigen."
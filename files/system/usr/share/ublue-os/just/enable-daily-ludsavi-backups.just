# vim: set ft=make :

setup-ludusavi ACTION="":
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh
    LUDUSAVI="com.github.mtkennerly.ludusavi"
    if flatpak info "$LUDUSAVI" >/dev/null 2>&1; then
      INSTALLED_STATE="${green}${b}Installed${n}"
    else
      INSTALLED_STATE="${red}${b}Not Installed${n}"
    fi
    SERVICE_STATE="$(systemctl is-enabled --user ludusavi.timer)"
    OPTION={{ ACTION }}
    if [ "$SERVICE_STATE" == "enabled" ]; then
      SERVICE_STATE="${green}${b}Enabled${n}"
    else
      SERVICE_STATE="${red}${b}Disabled${n}"
    fi
    if [ "$OPTION" == "help" ]; then
      echo "Useage: ujust setup-ludusavi <option>"
      echo "  <option>: Specify the quick option to skip the prompt"
      echo "  Use 'install' to install Ludusavi Flatpak"
      echo "  Use 'remove' to remove Ludusavi"
      echo "  Use 'autostart' to select Toggle Daily backups"
      exit 0
    elif [ "$OPTION" == "" ]; then
      echo "${bold}Ludusavi setup and configuration${normal}"
      echo "Ludusavi is $INSTALLED_STATE"
      echo "Daily backup is $SERVICE_STATE"
      OPTION=$(Choose "Install Ludusavi" "Remove Ludusavi" "Toggle Daily Backup")
    fi
    if [[ "${OPTION,,}" =~ ^install ]]; then
      flatpak install "$LUDUSAVI"
      echo "Ludusavi is installed!"
    elif [[ "${OPTION,,}" =~ ^(remove|uninstall) ]]; then
      flatpak uninstall "$LUDUSAVI"
      systemctl --user disable ludusavi.timer
      echo "Ludusavi has been uninstalled."
    elif [[ "${OPTION,,}" =~ toggle ]]; then
      if [[ "${SERVICE_STATE,,}" =~ disabled ]]; then
        systemctl enable --user --now ludusavi.timer
      else
        systemctl disable --user --now ludusavi.timer
      fi
    fi

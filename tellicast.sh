#!/bin/bash
#
# Entry point for tellicast docker container
# Maintainer: Daniel R. Hurtmans
#

# Function to create a prioritized file list
get_prioritized_file_list() {
  local default_dir="$1"
  local custom_dir="$2"

  # Initialize an associative array to track files
  local -A file_list

  # First, add files from the default folder
  for file in "$default_dir"/*; do
    # Check if it's actually a file (not a directory)
    if [ -f "$file" ]; then
      # Use basename to get just the filename
      local filename=$(basename "$file")
      # Add to the array if not already present
      if [[ ! -v file_list["$filename"] ]]; then
        file_list["$filename"]="$file"
      fi
    fi
  done

  # Now add files from the custom folder, overwriting any existing entries
  for file in "$custom_dir"/*; do
    if [ -f "$file" ]; then
      local filename=$(basename "$file")
      # Always replace the entry with the custom folder version
      file_list["$filename"]="$file"
    fi
  done

  # Output files to stdout, one per line
  for filename in "${!file_list[@]}"; do
    echo "${file_list[$filename]}"
  done
}

# Main script execution
main() {
  case ${1} in
    graceful)  # gracefull restart
      docker compose exec tellicast sudo /etc/init.d/tellicast-client restart
      ;;
      
    logs)  # Logs of the service
      docker compose logs
      ;;

    status)  # is service on
      docker compose exec tellicast sudo /etc/init.d/tellicast-client status
      ;;

    ps)  # Status of the service
      docker compose ps
      ;;

    start)  # Start the service in detached mode
      docker compose up -d
      ;;

    stop)  # Stop the service
      docker compose down
      ;;

    restart)  # "Hard" restart of the service
      docker compose down
      docker compose up -d
      ;;

    build)  # Build the container
      # Test if .env file exists
      if [[ ! -f ".env" ]]; then
        echo "Please setup a .env file using the env.model file as base"
        exit 1
      fi

      # Test if license, user and net if are filled
      source ./.env
      LOG_DIR=${LOG_DIR-./logs}
      DATA_DIR=${DATA_DIR-./data}

      if [[ -z "${LICENSE_USER}" ]]; then
        echo "Error LICENSE_USER is empty; check your .env file"
        exit 1
      fi
      if [[ -z "${LICENSE_KEY}" ]]; then
        echo "Error LICENSE_KEY is empty; check your .env file"
        exit 1
      fi
      if [[ -z "${USER_NAME}" ]]; then
        echo "Error USER_NAME is empty; check your .env file"
        exit 1
      fi
      if [[ -z "${NET_IF}" ]]; then
        echo "Error NET_IF is empty; check your .env file"
        exit 1
      fi

      # Let's start buildding now
      echo "Building for ${LICENSE_USER}/${LICENSE_KEY} running as ${USER_NAME}"

      # Downloading packages from Eumesat (Not stored on git due to potential license problems)
      https_path=https://sftp.eumetsat.int/public/folder/uscvknvooksycdgpmimjnq/User-Materials/EUMETCast_Support/EUMETCast_Licence_cd/Linux
      mkdir -p pkgs/eumetsat/ 2>/dev/null

      if [[ ! -f pkgs/eumetsat/SafenetAuthenticationClient-core-9.0.43-0_amd64.deb ]]; then
        wget ${https_path}/EKU_software/SafenetAuthenticationClient-core-9.0.43-0_amd64.deb -P pkgs/eumetsat/
      fi
      if [[ ! -f pkgs/eumetsat/README_Safenet_EKU_linux.txt ]]; then
        wget ${https_path}/EKU_software/README_Safenet_EKU_linux.txt -P pkgs/eumetsat/
      fi

      if [[ ! -f pkgs/eumetsat/README-tc-cast-client-linux.txt ]]; then
        wget ${https_path}/Tellicast/README-tc-cast-client-linux.txt -P pkgs/eumetsat/
      fi

      if [[ ! -f pkgs/eumetsat/tellicast-client-2.14.7-4.amd64.deb ]]; then
        wget ${https_path}/Tellicast/tellicast-client-2.14.7-4.amd64.deb -P pkgs/eumetsat/
      fi

      # Fill license and user placeholders into *.ini files. Use custom or default directory as basis
      is_crypt_key="No"
      if [[ ${LICENSE_KEY} == *"-"* ]]; then
        is_crypt_key="Yes"
      fi

      mapfile -t file_array < <(get_prioritized_file_list "etc/default" "etc/custom")

      for infile in "${file_array[@]}"; do
        outfile=${infile/custom\//}
        outfile=${outfile/default\//}

        if [[ ${is_crypt_key} == "Yes" ]]; then
          sed ${infile} -e "s/@LICENSE_USER@/${LICENSE_USER}/" -e "s/@LICENSE_KEY@/${LICENSE_KEY}/" \
                        -e "s/user_key=/user_key_crypt=/" -e "s/@USER_NAME@/${USER_NAME}/" > ${outfile}
        else
          sed ${infile} -e "s/@LICENSE_USER@/${LICENSE_USER}/" -e "s/@LICENSE_KEY@/${LICENSE_KEY}/" \
                        -e "s/user_key_crypt=/user_key=/" -e "s/@USER_NAME@/${USER_NAME}/" > ${outfile}
        fi
      done

      # Building container from the Dockerfile
      docker compose build

      # Create dirs with proper uid:gid
      if [[ ! -d ${LOG_DIR}  || ! -d ${DATA_DIR} ]]; then
        mkdir ${DATA_DIR} ${LOG_DIR}
        echo "I'll ask you your sudo password to change ${DATA_DIR} and ${LOG_DIR} owner."
        echo "This is perfectly normal!"
        read -p "Press enter to continue"
        sudo chown ${USER_ID}:${GROUP_ID} ${DATA_DIR} ${LOG_DIR}
      fi

      # Remind to set-up some hardware limits (see tc-cast-linux-2.14.6-1 in README-tc-cast-client-linux.txt)
      echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      echo "Don't forget to copy pkgs/tune/00-tellicast.conf into /ets/sysctl.d/"
      echo "and reload the configuration with : sysctl --system                 "
      echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    ;;

    clean)  # Cleanup installation
      echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      echo "This will erase all your content and setup...                       "
      echo "Only .env file will remain untouched.                               "
      echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      read -p "Press enter to continue, ^C to abort"
      docker rmi tellicast-tellicast

      source ./.env 2>/dev/null
      LOG_DIR=${LOG_DIR-./logs}
      DATA_DIR=${DATA_DIR-./data}

      rm -fr ${LOG_DIR}/* 2>/dev/null
      rm -fr ${DATA_DIR}/* 2>/dev/null
      rm etc/*.ini 2>/dev/null
      rm etc/*.cfg 2>/dev/null
      ;;

    *)  # Give usage
      echo "Usage: ${0} start|stop|restart|graceful|build|clean|logs|ps|status"
      ;;
  esac
}

# Start it now
main "$@"

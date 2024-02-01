#!/bin/bash

main_folder="$HOME/auto-reboot"
log_file="$HOME/auto-reboot/log.txt"
qubic_log_file="$HOME/auto-reboot/qubic_log.txt"
screen_session="qubic"
qubic="$HOME/projects/qubic/qliclient/qli-Client"

if [ ! -f "$qubic" ]; then
    qubic="$HOME/projects/qubic_client/qliclient/qli-Client"
    if [ ! -f "$qubic" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') No qli-Client file" | tee -a "$log_file"
        exit 1
    fi
fi

if [ ! -d "$main_folder" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Created main folder" | tee -a "$log_file"
    mkdir -p "$main_folder"
fi

if [ ! -f "$log_file" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Created log.txt" | tee -a "$log_file"
    touch "$HOME/auto-reboot/log.txt"
fi

if [ ! -f "$qubic_log_file" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Created qubic_log.txt" | tee -a "$log_file"
    touch "$HOME/auto-reboot/qubic_log.txt"
fi

if ! crontab -l | grep -q "auto_reboot.sh"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Created cron" | tee -a "$log_file"
    (crontab -u $(whoami) -l; echo "*/15 * * * * $HOME/auto-reboot/auto_reboot.sh" ) | crontab -u $(whoami) -
fi

if ! screen -ls | grep -q "$screen_session"; then
   echo "$(date '+%Y-%m-%d %H:%M:%S') Created screen" | tee -a "$log_file"
   screen -S "$screen_session" -d -m sh -c "$qubic >> $qubic_log_file"
fi

check_for_words() {
    if grep -q "INFO" <<< "$1" && grep -q "it/s" <<< "$1"; then
        return 1
    else
        return 0
    fi
}

for attempt in {1..3}; do
    last_line=$(tail -n 1 "$qubic_log_file")

    if check_for_words "$last_line"; then
       if [ "$attempt" -lt 3 ]; then
          echo "$(date '+%Y-%m-%d %H:%M:%S') No last line!" | tee -a "$log_file"
          sleep 120
       else
          echo "$(date '+%Y-%m-%d %H:%M:%S') No last line. Attempting to restart the server..." | tee -a "$log_file"
          truncate -s 0 "$qubic_log_file"
          sudo reboot
       fi
    else
       echo "$(date '+%Y-%m-%d %H:%M:%S') The last line is good!" | tee -a "$log_file"
       truncate -s 0 "$qubic_log_file"
       break
    fi
done

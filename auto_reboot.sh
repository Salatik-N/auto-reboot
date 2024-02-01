#!/bin/bash

log_file="$HOME/auto-reboot/log.txt"
qubic_log_file="$HOME/auto-reboot/qubic_log.txt"
screen_session="qubic"
qubic="$HOME/projects/qubic/qliclient/qli-Client"
process_name="qli-Client"

if ! screen -ls | grep -q "$screen_session"; then
   echo "$(date '+%Y-%m-%d %H:%M:%S') Create screen" | tee -a "$log_file"
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

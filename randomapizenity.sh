#!/bin/bash

get_about() {
    echo -e "Zenity:    $(zenity --version)"
    echo -e "Platform:  $(uname -or)"
    echo -e "Path:      $(readlink -f "${BASH_SOURCE[0]}")"
    echo
    echo    "Message:   $(curl -s https://random-data-api.com/api/hipster/random_hipster_stuff | jq -r '.sentence' | cut -c -50)"
}

report_parallel_progress() {
    perl -pe 'BEGIN{$/="\r";$|=1};s/\r/\n/g' |
    sed -u 's/#.*https/# https/g' |
    (sleep 0.1 && zenity --progress --title="Initializing" --percentage=0 --auto-close --width=500)
}

get_user_count() {
    count=$(zenity --entry --title="Random API Example" --width=500 --text="$(get_about)\n\nPlease enter a number of users greater than 1:")
    if [[ $? -eq 1 ]]; then 
        exit 1
    elif [[ $count =~ ^[0-9]+$ ]] && (( count > 1 )); then
        echo "$count"
    else
        zenity --error --title="Error" --text="Invalid input \"$count\". Please enter a number of users greater than 1."
        get_user_count  # Prompt again recursively
    fi
}

get_user_row() {
    user=$(curl -s "https://random-data-api.com/api/v2/users?size=$COUNT" |
    jq -r '.[] | [.id, (.first_name + " " + .last_name), .phone_number, .email, .avatar] | @tsv' |
    awk -F '?' '{print $1}' |
    parallel -j8 --bar --colsep '\t' 'wget -q -O "/dev/shm/$(basename {5})" {5}?size=32x32 && echo -e "/dev/shm/$(basename {5})\n{1}\n{2}\n{3}\n{4}"' 2> >(report_parallel_progress) |
    zenity --list --title="Users" \
	--ok-label=OK \
	--cancel-label=Close \
	--column="Icon" \
	--column="Id" \
	--column="Name" \
	--column="Phone" \
	--column="Email" \
    --hide-column=4,5 \
	--imagelist \
	--print-column="ALL" \
	--mid-search \
	--width=300 \
	--height=400)

    if [[ $? -eq 1 ]]; then
        exit 1
    else
        echo "$user"
    fi
}

show_user_detail() {
    IFS='|' read -r user_avatar user_id user_name user_phone user_email <<< "${ROW//\'/}"
    wget -q -O $user_avatar "https://robohash.org/$(basename "$user_avatar")?size=200x200" &&
    zenity --text-info --title="User Detail" \
        --html \
        --width=430 \
        --height=430 \
        --filename=<(echo "
        <div style=\"border: 1px solid #ccc; border-radius: 5px; padding: 20px; width: 320px; margin: auto;\">
            <img src=\"$user_avatar\" alt=\"User Avatar\" style=\"width: 200px; height: 200px; border-radius: 50%; margin: auto; display: block;\">
            <div style=\"text-align: center; margin-top: 10px; font-size: 20px;\">$user_name</div>
            <div style=\"margin-top: 10px;\">
                <span style=\"font-weight: bold;\">ID:</span> $user_id<br>
                <span style=\"font-weight: bold;\">Email:</span> $user_email<br>
                <span style=\"font-weight: bold;\">Phone:</span> $user_phone
            </div>
        </div>")
}

COUNT=$(get_user_count) || exit 1
ROW=$(get_user_row) || exit 1
show_user_detail

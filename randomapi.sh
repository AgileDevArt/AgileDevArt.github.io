#!/bin/bash

get_about() {
    echo -e "Random API Example"
	echo
    echo -e "Platform:  $(uname -or)"
    echo -e "Path:      $(readlink -f "${BASH_SOURCE[0]}")"
    echo
    echo    "Message:   $(curl -s https://random-data-api.com/api/hipster/random_hipster_stuff | jq -r '.sentence' | cut -c -50)"
}

get_user_count() {
    local prompt="$(echo -e "$1\n\nPlease enter a number of users greater than 1: ")"
    read -p "$prompt" count
    if [[ $count =~ ^[0-9]+$ ]] && (( count > 1 )); then
        echo "$count"
    else
        get_user_count "Invalid input \"$count\". Please enter a number of users greater than 1." # Prompt again recursively         
    fi
}

get_user_row() {
    users=$(curl -s "https://random-data-api.com/api/v2/users?size=$COUNT" |
    jq -r '.[] | [.id, (.first_name + " " + .last_name), .phone_number, .email, .avatar] | @tsv' |
    awk -F '?' '{print $1}' |
    parallel -j8 --bar --colsep '\t' 'wget -q -O "/dev/shm/$(basename {5})" {5}?size=32x32 && echo -e "/dev/shm/$(basename {5})|{1}|{2}|{3}|{4}"')

    local table="$(echo -e "Icon|Id|Name\n$users" | awk -F '|' '{printf "%-50s %-10s %-25s\n", $1, $2, $3}' | nl -v0 -w6)"
    local prompt="$(echo -e "\n      ${table:6}\n\nPlease enter a row number between 1 and $COUNT: ")"

	while true; do
        read -p "$prompt" row
        if [[ $row =~ ^[0-9]+$ ]] && ((row > 0 && row <= COUNT)); then
		    echo $(awk "NR==$row" <<< "$users")
            break
        else
            prompt="Invalid input \"$row\". Please enter a row number between 1 and $COUNT: "
        fi
    done
}

show_user_detail() {
    IFS='|' read -r user_avatar user_id user_name user_phone user_email <<< "${ROW//\'/}"
    wget -q -O $user_avatar "https://robohash.org/$(basename "$user_avatar")?size=200x200" &&
    echo "
    User Detail:
    ------------
    Icon:    $user_avatar
    ID:      $user_id
    Name:    $user_name
    Email:   $user_email
    Phone:   $user_phone
    "
}

COUNT=$(get_user_count "$(get_about)") || exit 1
ROW=$(get_user_row) || exit 1
show_user_detail

#!/bin/bash

# ./ssh-tunnel.sh -h host_address -u username -l local_ssh_port -r remote_forward_port

check_host_availability() {
    local host=$1
    if [[ -z "$host" ]]; then
        echo "Error: No IP address or FQDN provided."
        return 1
    fi
    if ping -c 1 -W 5 "$host" &> /dev/null; then
        echo "Host $host is reachable."
        return 0
    else
        echo "Host $host is unreachable or invalid."
        return 1
    fi
}

setup_reverse_shell_tunnel() {
    local fqdn_or_ip=$1
    local username=$2
    local local_ssh_port=$3
    local remote_forward_port=$4

    if [[ -z "$fqdn_or_ip" || -z "$username" || -z "$local_ssh_port" || -z "$remote_forward_port" ]]; then
        echo "Error: Missing required arguments."
        return 1
    fi

    ssh -f -N -T \
        -o ExitOnForwardFailure=yes \
        -o ServerAliveInterval=60 \
        -o ConnectTimeout=10 \
        -R "${remote_forward_port}:localhost:${local_ssh_port}" \
        "${username}@${fqdn_or_ip}"

    if [ $? -eq 0 ]; then
        echo "SSH tunnel established successfully."
        return 0
    else
        echo "Failed to establish SSH tunnel."
        return 1
    fi
}

while getopts "h:u:l:r:" opt; do
    case ${opt} in
        h ) host=${OPTARG} ;;
        u ) username=${OPTARG} ;;
        l ) local_ssh_port=${OPTARG} ;;
        r ) remote_forward_port=${OPTARG} ;;
        \? ) echo "Usage: cmd [-h] host [-u] username [-l] local_ssh_port [-r] remote_forward_port"
             exit 1 ;;
    esac
done

if [[ -z "$host" || -z "$username" || -z "$local_ssh_port" || -z "$remote_forward_port" ]]; then
    echo "All arguments (-h, -u, -l, -r) must be provided."
    exit 1
fi

if check_host_availability "$host"; then
    if setup_reverse_shell_tunnel "$host" "$username" "$local_ssh_port" "$remote_forward_port"; then
        echo "Tunnel successfully established."
    else
        echo "Failed to establish tunnel."
        exit 1
    fi
else
    echo "Host is not reachable."
    exit 1
fi

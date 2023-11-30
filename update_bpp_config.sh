#!/bin/bash

# File names
clientFile="$HOME/default-bpp-client.yml"
networkFile="$HOME/default-bpp-network.yml"

client_port=6001
network_port=6002

mongo_initdb_root_username="beckn"
mongo_initdb_root_password="beckn123"
mongo_initdb_database="protocol_server"
rabbitmq_default_user="beckn"
rabbitmq_default_pass="beckn123"
registry_url="https://registry.becknprotocol.io/subscribers"

# Display current values
echo "Current BPP_CLIENT_PORT value is set to 6001."

# Prompt user for BPP_CLIENT_PORT value
read -p "Do you want to change the BPP_CLIENT_PORT value? (y/n): " changeClientPort
if [[ "${changeClientPort,,}" == "yes" || "${changeClientPort,,}" == "y" ]]; then
    read -p "Enter new BPP_CLIENT_PORT value: " newClientPort\
    client_port=$newClientPort
    # sed -i "s/BPP_CLIENT_PORT/$newClientPort/" $clientFile
    # echo "BPP_CLIENT_PORT value updated to $newClientPort."
else
    echo "Keeping the default BPP_CLIENT_PORT value."
fi

# Display current values
echo "Current BPP_NETWORK_PORT value is set to 6002."

# Prompt user for BPP_NETWORK_PORT value
read -p "Do you want to change the BPP_NETWORK_PORT value? (y/n): " changeNetworkPort

if [[ "${changeNetworkPort,,}" == "yes" || "${changeNetworkPort,,}" == "y" ]]; then
    read -p "Enter new BPP_NETWORK_PORT value: " newNetworkPort
    network_port=$newNetworkPort
    # sed -i "s/BPP_CLIENT_PORT/$newNetworkPort/" $clientFile
    # echo "BPP_NETWORK_PORT value updated to $newNetworkPort."
else
    echo "Keeping the default BPP_NETWORK_PORT value."
fi

# Ask user about Redis and RabbitMQ configurations
read -p "Is Redis running on the same instance? (y/n): " redisSameInstance
if [[ "${redisSameInstance,,}" == "no" || "${redisSameInstance,,}" == "n" ]]; then
    read -p "Enter the private IP or URL for Redis: " redisUrl
else
    redisUrl="0.0.0.0"
fi

read -p "Is RabbitMQ running on the same instance? (y/n): " rabbitmqSameInstance
if [[ "${rabbitmqSameInstance,,}" == "no" || "${rabbitmqSameInstance,,}" == "n" ]]; then
    read -p "Enter the private IP or URL for RabbitMQ: " rabbitmqUrl
else
    rabbitmqUrl="0.0.0.0"
fi


curl_response=$(curl -s https://registry-ec.becknprotocol.io/subscribers/generateEncryptionKeys)

# Check if the curl command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to execute the curl command. Exiting."
    exit 1
else
    # Extract private_key and public_key from the JSON response
    private_key=$(echo "$curl_response" | jq -r '.private_key')
    public_key=$(echo "$curl_response" | jq -r '.public_key')
fi

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --mongo_initdb_root_username)
            mongo_initdb_root_username="$2"
            shift 2
            ;;
        --mongo_initdb_root_password)
            mongo_initdb_root_password="$2"
            shift 2
            ;;
        --mongo_initdb_database)
            mongo_initdb_database="$2"
            shift 2
            ;;
        --rabbitmq_default_user)
            rabbitmq_default_user="$2"
            shift 2
            ;;
        --rabbitmq_default_pass)
            rabbitmq_default_pass="$2"
            shift 2
            ;;
        --rabbitmqUrl)
            rabbitmqUrl="$2"
            shift 2
            ;;
        --bpp_subscriber_id)
            if [ -n "$2" ]; then
                bpp_subscriber_id="$2"
                bpp_subscriber_id_key="$2-key"
                shift 2
            else
                echo "error: --bpp_subscriber_id requires a non-empty option argument."
                exit 1
            fi
            ;;
        --bpp_subscriber_uri)
            if [ -n "$2" ]; then
                bpp_subscriber_uri="$2"
                shift 2
            else
                echo "error: --bpp_subscriber_uri requires a non-empty option argument."
                exit 1
            fi
            ;;
        *)
            echo "error: Unknown option $1"
            exit 1
            ;;
    esac
done

# Define an associative array for replacements
declare -A replacements=(
    ["REDIS_URL"]=$redisUrl
    ["MONGO_USERNAME"]=$mongo_initdb_root_username
    ["MONGO_PASSWORD"]=$mongo_initdb_root_password
    ["MONGO_DB_NAME"]=$mongo_initdb_database
    ["RABBITMQ_USERNAME"]=$rabbitmq_default_user
    ["RABBITMQ_PASSWORD"]=$rabbitmq_default_pass
    ["RABBITMQ_URL"]=$rabbitmqUrl
    ["PRIVATE_KEY"]=$private_key
    ["PUBLIC_KEY"]=$public_key
    ["BPP_SUBSCRIBER_ID"]=$bpp_subscriber_id
    ["SUBSCRIBER_URL"]=$subscriber_url
    ["BPP_SUBSCRIBER_ID_KEY"]=$bpp_subscriber_id_key
)

# Apply replacements in both files
for file in "$clientFile" "$networkFile"; do
    for key in "${!replacements[@]}"; do
        sed -i "s/$key/${replacements[$key]}/" "$file"
    done
done

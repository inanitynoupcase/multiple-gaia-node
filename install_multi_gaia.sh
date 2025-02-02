#!/bin/bash

# Check if number of nodes is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <number_of_nodes>"
    echo "Example: $0 5"
    exit 1
fi

# Validate input is a number
if ! [[ "$1" =~ ^[0-9]+$ ]]; then
    echo "Error: Please provide a valid number"
    exit 1
fi

# Number of nodes from command line argument
NUM_NODES=$1

# Starting port for llamaedge_port
START_PORT=1000

echo "Preparing to install $NUM_NODES GaiaNet nodes..."

# Download install.sh if not exists
if [ ! -f "install.sh" ]; then
    echo "Downloading install.sh..."
    curl -O https://raw.githubusercontent.com/GaiaNet-AI/gaianet-node/main/install.sh
    if [ $? -ne 0 ]; then
        echo "Error: Failed to download install.sh"
        exit 1
    fi
fi

# Make install.sh executable
chmod +x install.sh
if [ $? -ne 0 ]; then
    echo "Error: Failed to make install.sh executable"
    exit 1
fi

# Create directories
for i in $(seq 1 $NUM_NODES); do
    if [ ! -d "/root/gaianet$i" ]; then
        mkdir -p "/root/gaianet$i"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to create directory /root/gaianet$i"
            exit 1
        fi
    fi
done

# Setup aliases in ~/.bashrc
setup_aliases() {
    # Remove old aliases if exist
    sed -i '/# GaiaNet node/d' ~/.bashrc
    sed -i '/alias g[0-9]/d' ~/.bashrc
    
    # Add new aliases for each node
    for i in $(seq 1 $NUM_NODES); do
        echo "# GaiaNet node $i" >> ~/.bashrc
        echo "alias g${i}info=\"/root/gaianet${i}/bin/gaianet info --base /root/gaianet${i}\"" >> ~/.bashrc
        echo "alias g${i}start=\"/root/gaianet${i}/bin/gaianet start --base /root/gaianet${i}\"" >> ~/.bashrc
        echo "alias g${i}stop=\"/root/gaianet${i}/bin/gaianet stop --base /root/gaianet${i}\"" >> ~/.bashrc
        echo "alias g${i}init=\"/root/gaianet${i}/bin/gaianet init --base /root/gaianet${i}\"" >> ~/.bashrc
        echo "" >> ~/.bashrc
    done
}

# Install and configure each node
for i in $(seq 1 $NUM_NODES); do
    echo -e "\nInstalling GaiaNet node $i..."
    
    # Install node with custom directory
    ./install.sh --base "/root/gaianet$i"
    
    # Wait for config.json to be created
    sleep 2
    
    # Calculate port for current node
    CURRENT_PORT=$((START_PORT + i))
    
    # Check if config.json exists
    if [ -f "/root/gaianet$i/config.json" ]; then
        # Update llamaedge_port in config.json
        sed -i "s/\"llamaedge_port\": \"[0-9]*\"/\"llamaedge_port\": \"$CURRENT_PORT\"/" "/root/gaianet$i/config.json"
        echo "Node $i installed with llamaedge_port: $CURRENT_PORT"
    else
        echo "Error: config.json not found for node $i"
        echo "Installation may have failed"
    fi
done

# Setup aliases
setup_aliases

# Source bashrc to use the new aliases
source ~/.bashrc

echo -e "\nInitializing and starting all nodes..."
# Initialize and start each node
for i in $(seq 1 $NUM_NODES); do
    echo -e "\nInitializing node $i..."
    /root/gaianet$i/bin/gaianet init --base /root/gaianet$i
    sleep 2
    echo "Starting node $i..."
    /root/gaianet$i/bin/gaianet start --base /root/gaianet$i
    sleep 2
done

echo -e "\nAll nodes are initialized and started!"
echo -e "\nNode Information:"
for i in $(seq 1 $NUM_NODES); do
    echo -e "\nNode $i:"
    /root/gaianet$i/bin/gaianet info --base /root/gaianet$i
done

echo -e "\nYou can use these commands to control nodes:"
for i in $(seq 1 $NUM_NODES); do
    echo "g${i}info  # Show info for node $i"
    echo "g${i}start # Start node $i"
    echo "g${i}stop  # Stop node $i"
    echo "g${i}init  # Initialize node $i"
    echo ""
done

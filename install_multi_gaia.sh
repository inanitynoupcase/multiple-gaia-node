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
START_PORT=1001

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

# Setup aliases in ~/.bashrc
setup_aliases() {
    # Remove old aliases if exist
    sed -i '/# GaiaNet node aliases/d' ~/.bashrc
    sed -i '/alias gaianet[0-9]/d' ~/.bashrc
    
    # Add new aliases
    echo "# GaiaNet node aliases" >> ~/.bashrc
    for i in $(seq 1 $NUM_NODES); do
        echo "alias gaianet$i=\"cd ~/gaianet$i && gaianet\"" >> ~/.bashrc
    done
}

# Install and configure each node
for i in $(seq 1 $NUM_NODES); do
    echo -e "\nInstalling GaiaNet node $i..."
    
    # Install node with custom directory
    ./install.sh --base ~/gaianet$i
    
    # Calculate port for current node
    CURRENT_PORT=$((START_PORT + i - 1))
    
    # Update llamaedge_port in config.json
    sed -i "s/\"llamaedge_port\": \"[0-9]*\"/\"llamaedge_port\": \"$CURRENT_PORT\"/" ~/gaianet$i/config.json
    
    echo "Node $i installed with llamaedge_port: $CURRENT_PORT"
done

# Setup aliases
setup_aliases

echo -e "\nInstallation completed!"
echo "Created $NUM_NODES nodes with llamaedge_ports from $START_PORT to $((START_PORT + NUM_NODES - 1))"
echo -e "\nTo use the new aliases, please run:"
echo "source ~/.bashrc"
echo -e "\nThen you can use commands like:"
for i in $(seq 1 $NUM_NODES); do
    echo "gaianet$i start"
done

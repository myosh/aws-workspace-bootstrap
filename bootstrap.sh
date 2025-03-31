#!/bin/bash
set -e

echo "🛠️  Starting AWS Developer Workspace Bootstrap"

# --- 1. Install Required Tools ---
echo "📦 Installing Git, Ansible, and OpenSSH..."
sudo apt update
sudo apt install -y git ansible openssh-client

# --- 2. Configure Git ---
git_name=$(git config --global user.name)
git_email=$(git config --global user.email)

if [ -z "$git_name" ] || [ -z "$git_email" ]; then
    echo "🔧 Configuring Git..."
    read -p "Enter your Git name: " git_name
    read -p "Enter your Git email: " git_email

    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
else
    echo "✅ Git is already configured with:"
    echo "   Name: $git_name"
    echo "   Email: $git_email"
fi

# --- 3. Generate SSH Key (if needed) ---
SSH_KEY="$HOME/.ssh/id_ed25519"

if [ ! -f "$SSH_KEY" ]; then
    echo "🔐 Generating a new SSH key..."
    ssh-keygen -t ed25519 -C "$git_email" -f "$SSH_KEY" -N ""

    echo ""
    echo "📋 Copy the following SSH key and add it to your GitHub account:"
    echo ""
    cat "$SSH_KEY.pub"
    echo ""
    echo "➡️  https://github.com/settings/keys"
    echo ""
    read -p "Press Enter once your SSH key has been added to GitHub..."
else
    echo "✅ SSH key already exists at $SSH_KEY"
fi

# --- 4. Start SSH Agent ---
eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY"

# --- 5. Test SSH Access to GitHub ---
echo "🔗 Testing SSH connection to GitHub..."
ssh -T git@github.com || true

# --- 6. Clone the Private Ansible Workspace Setup Repo ---
SETUP_DIR="$HOME/aws-workspace-setup"

if [ ! -d "$SETUP_DIR" ]; then
    echo "📥 Cloning the private setup repo..."
    git clone git@github.com:myosh/aws-workspace-setup.git "$SETUP_DIR"
else
    echo "📁 Repo already exists at $SETUP_DIR"
    echo "🔄 Pulling the latest changes..."
    cd "$SETUP_DIR"
    git pull
fi

# --- 7. Run the Ansible Playbook ---
cd "$SETUP_DIR/ansible"
echo "🚀 Running the Ansible playbook..."
ansible-playbook -i inventory.ini playbook.yml --ask-become-pass

echo ""
echo "✅ AWS developer workspace setup complete!"

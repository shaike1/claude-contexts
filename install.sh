#!/bin/bash
# Claude Context Sync - Basic installer
# Usage: curl -sSL https://raw.githubusercontent.com/shaike1/claude-contexts/main/install.sh | bash -s -- YOUR_GITHUB_REPO

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 Claude Context Sync Installer${NC}"
echo "================================"

# Get GitHub repo from argument or prompt
GITHUB_REPO="${1:-}"
if [ -z "$GITHUB_REPO" ]; then
    echo -e "${BLUE}Enter your GitHub repository URL for storing contexts:${NC}"
    echo "Example: https://github.com/username/claude-contexts"
    read -r GITHUB_REPO
fi

# Validate repo URL
if [[ ! "$GITHUB_REPO" =~ ^https://github\.com/[^/]+/[^/]+(.git)?$ ]]; then
    echo -e "${RED}❌ Invalid GitHub repository URL${NC}"
    exit 1
fi

# Ensure .git extension
if [[ ! "$GITHUB_REPO" =~ \.git$ ]]; then
    GITHUB_REPO="${GITHUB_REPO}.git"
fi

echo -e "${BLUE}📦 Installing Claude Context Sync...${NC}"

# Create directories
mkdir -p ~/.claude-code/slash-commands
mkdir -p ~/.claude-sync

# Download the main sync script
echo "📥 Downloading claude-sync.py..."
curl -sSL -o ~/claude-sync.py https://raw.githubusercontent.com/shaike1/claude-contexts/main/claude-sync-simple.py
chmod +x ~/claude-sync.py

# Create slash commands
echo "📝 Creating slash commands..."

# /sync-pull
cat > ~/.claude-code/slash-commands/sync-pull.md << 'EOF'
Pull the latest Claude context from your remote repository.

```bash
cd ~
python3 ~/claude-sync.py pull
echo "✅ Context synchronized from remote"
```
EOF

# /sync-push
cat > ~/.claude-code/slash-commands/sync-push.md << 'EOF'
Push your current Claude context to the remote repository.

```bash
cd ~
python3 ~/claude-sync.py push
echo "✅ Context pushed to remote"
```
EOF

# /sync
cat > ~/.claude-code/slash-commands/sync.md << 'EOF'
Perform a full bidirectional sync (pull then push).

```bash
cd ~
python3 ~/claude-sync.py sync
echo "✅ Full sync completed"
```
EOF

# /sync-status
cat > ~/.claude-code/slash-commands/sync-status.md << 'EOF'
Check the current sync status and configuration.

```bash
if [ -f ~/.claude-sync/config.json ]; then
    echo "📊 Claude Sync Status"
    echo "===================="
    echo "Config: ~/.claude-sync/config.json"
    cat ~/.claude-sync/config.json | python3 -m json.tool
    
    if [ -d ~/.claude-sync/contexts/repo/.git ]; then
        cd ~/.claude-sync/contexts/repo
        echo ""
        echo "📅 Last sync: $(git log -1 --format=%cd --date=relative 2>/dev/null || echo 'Never')"
        echo "🌿 Current branch: $(git branch --show-current 2>/dev/null || echo 'Not initialized')"
        echo "📝 Pending changes: $(git status --porcelain 2>/dev/null | wc -l) files"
    fi
else
    echo "❌ Claude Sync not configured. Run installer again."
fi
```
EOF

# Configure with provided repo
echo -e "\n${BLUE}⚙️  Configuring with repository: ${GITHUB_REPO}${NC}"
python3 ~/claude-sync.py setup --git-repo "$GITHUB_REPO"

# Create initial CLAUDE.md if it doesn't exist
if [ ! -f ~/CLAUDE.md ]; then
    cat > ~/CLAUDE.md << EOF
# Claude Context

Synchronized across all machines via claude-sync.

## Setup Info
- Repository: $GITHUB_REPO
- Installed: $(date)
- Machine: $(hostname)

## Project Notes

Add your project-specific context here.
EOF
    echo -e "${GREEN}✅ Created initial CLAUDE.md${NC}"
fi

# Try initial push
echo -e "\n${BLUE}📤 Attempting initial sync...${NC}"
if python3 ~/claude-sync.py push 2>/dev/null; then
    echo -e "${GREEN}✅ Initial sync successful${NC}"
else
    echo -e "${BLUE}ℹ️  Initial sync skipped (repository might need to be created)${NC}"
fi

echo -e "\n${GREEN}✨ Installation complete!${NC}"
echo -e "\n${BLUE}Available slash commands:${NC}"
echo "  /sync-pull    - Pull latest context from GitHub"
echo "  /sync-push    - Push current context to GitHub"
echo "  /sync         - Full bidirectional sync"
echo "  /sync-status  - Check sync status"
echo -e "\n${BLUE}Quick start:${NC}"
echo "1. Make sure your GitHub repo exists: ${GITHUB_REPO%.git}"
echo "2. Use /sync-push to upload your current context"
echo "3. On other machines, run this installer with the same repo"
echo -e "\n${GREEN}Happy syncing! 🚀${NC}"
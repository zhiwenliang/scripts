#!/bin/bash

# Update Claude Code (Native install - recommended)
echo "Updating Claude Code..."
curl -fsSL https://claude.ai/install.sh | bash

# Update Codex CLI
echo "Updating OpenAI Codex CLI..."
npm i -g @openai/codex@latest

# Update Gemini CLI
echo "Updating Gemini CLI..."
npm i -g @google/gemini-cli@latest

# Update OpenCode
echo "Updating OpenCode..."
curl -fsSL https://opencode.ai/install | bash

echo "All SDKs and CLIs updated successfully!"

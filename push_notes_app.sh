name: Run push_notes_app.sh

on:
  workflow_dispatch:

jobs:
  run-script:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository (full history)
        uses: actions/checkout@v4
        with:
          persist-credentials: false   # we will use the SSH key instead of GITHUB_TOKEN
          fetch-depth: 0

      - name: Configure git identity
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"

      - name: Start ssh-agent and add private key
        uses: webfactory/ssh-agent@v0.7.0
        with:
          # must match the name of the secret you created
          ssh-private-key: ${{ secrets.DEPLOY_KEY }}

      - name: Add GitHub to known_hosts
        run: |
          mkdir -p ~/.ssh
          ssh-keyscan github.com >> ~/.ssh/known_hosts
          chmod 644 ~/.ssh/known_hosts

      - name: Make script executable
        run: |
          chmod +x ./push_notes_app.sh

      - name: Run push script
        env:
          # ensure ssh uses the known_hosts file we created
          GIT_SSH_COMMAND: 'ssh -o UserKnownHostsFile=/home/runner/.ssh/known_hosts'
        run: |
          ./push_notes_app.sh

      - name: Show pushed commit (HEAD)
        run: |
          git rev-parse HEAD

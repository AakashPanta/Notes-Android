if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git add .
  git commit -m "Add production-ready notes app" || echo "No changes to commit."
  git push origin main || echo "Push failed. Check your remote, branch, and token permissions."
else
  echo "Not inside a Git repository. Files were created locally only."
fi
echo "✅ Production Notes App files created."

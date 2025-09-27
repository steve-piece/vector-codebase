# Vector-Codebase: A Semantic Database for Code

<div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; border-radius: 10px; color: white; margin: 20px 0;">
<h3 style="margin: 0; color: white;">🚀 Generate vector embeddings for your codebase and store them in Supabase for AI-powered code search and understanding.</h3>
</div>

---

## 🎯 Quick Setup

<div style="background-color: #f8f9fa; padding: 15px; border-left: 4px solid #28a745; border-radius: 5px; margin: 10px 0; color: #000000;">
<strong>Prerequisites:</strong> Node.js, npm/pnpm/yarn, Supabase project, OpenAI API key
</div>

### <span style="color: #e74c3c;">📦 Step 1: Install Workflow</span>

<div style="background-color: #f8f9fa; padding: 15px; border-left: 4px solid #e74c3c; border-radius: 5px; color: #000000;">
Run from your project root:
</div>

<div style="background-color: #1a202c; padding: 15px; border-radius: 8px; margin: 10px 0; color: #e2e8f0;">

**One-liner installation:**

```bash
curl -sSL https://raw.githubusercontent.com/steve-piece/vector-codebase/main/install-embeddings-workflow.sh | bash
```

**Manual installation:**

```bash
# Clone and run installer
git clone https://github.com/steve-piece/vector-codebase.git temp-vector-codebase
cd temp-vector-codebase
bash install-embeddings-workflow.sh --target ../your-project
cd ../your-project
rm -rf temp-vector-codebase
```

</div>

### <span style="color: #3498db;">🗄️ Step 2: Setup Database</span>

<div style="background-color: #f8f9fa; padding: 15px; border-left: 4px solid #3498db; border-radius: 5px; color: #000000;">
Copy and paste the entire <strong>vector-search-functions.sql</strong> file into your Supabase SQL Editor and run it.
</div>

<div style="background-color: #d1ecf1; padding: 15px; border-left: 4px solid #bee5eb; border-radius: 5px; margin: 10px 0; color: #000000;">
<strong>💡 This includes:</strong> pgvector extension, table creation, RLS setup, and AI analysis functions.
</div>

### <span style="color: #f39c12;">⚙️ Step 3: Configure Environment</span>

<div style="background-color: #fff3cd; padding: 15px; border-left: 4px solid #f39c12; border-radius: 5px; color: #0000ff">
Edit <code style="color: #0000ff; font-weight: bold;">.env</code> with your credentials:
</div>
<br><em>If you need help finding the credentials, please refer to <span style="font-weight: bold; color: #ffffff;">env.txt</span></em>
<div style="background-color: #1a202c; padding: 15px; border-radius: 8px; margin: 10px 0; color: #e2e8f0;">

```env
OPENAI_API_KEY="your-openai-api-key"
SUPABASE_URL="your-supabase-project-url"
SUPABASE_SECRET_KEY="your-supabase-service-role-key"
```

</div>

### <span style="color: #27ae60;">▶️ Step 4: Run Script</span>

<div style="background-color: #d4edda; padding: 15px; border-left: 4px solid #27ae60; border-radius: 5px; color: #000000;">
Execute the embedding generation:
</div>

<div style="background-color: #1a202c; padding: 15px; border-radius: 8px; margin: 10px 0; color: #e2e8f0;">

```bash
node --env-file=.env embedding_workflow/ingest-embeddings.mjs
```

</div>
cd
---

## <span style="color: #9b59b6;">🔄 Auto-sync with GitHub Actions (Optional)</span>

<div style="background-color: #f8f9fa; padding: 15px; border-left: 4px solid #9b59b6; border-radius: 5px; margin: 10px 0; color: #000000;">
The <code>github-actions/</code> folder contains 5 pre-configured workflow variants for different package managers and triggers.
</div>

### 📋 Available Workflow Types:

**Trigger-based:**

- **`npm-workflow.yml`** - Runs on every push to main (npm)
- **`pnpm-workflow.yml`** - Runs on every push to main (pnpm)
- **`yarn-workflow.yml`** - Runs on every push to main (yarn)
- **`manual-workflow.yml`** - Manual trigger only (workflow_dispatch)
- **`scheduled-workflow.yml`** - Daily at 2 AM UTC + manual trigger

### 🚀 Setup Your Workflow:

<div style="background-color: #1a202c; padding: 15px; border-radius: 8px; margin: 10px 0; color: #e2e8f0;">

```bash
# Create workflows directory
mkdir -p .github/workflows

# Choose ONE workflow that matches your setup:

# For npm users:
mv embedding_workflow/github-actions/npm-workflow.yml .github/workflows/sync-embeddings.yml

# For pnpm users:
mv embedding_workflow/github-actions/pnpm-workflow.yml .github/workflows/sync-embeddings.yml

# For yarn users:
mv embedding_workflow/github-actions/yarn-workflow.yml .github/workflows/sync-embeddings.yml

# For manual-only runs:
mv embedding_workflow/github-actions/manual-workflow.yml .github/workflows/sync-embeddings.yml

# For scheduled daily runs:
mv embedding_workflow/github-actions/scheduled-workflow.yml .github/workflows/sync-embeddings.yml
```

</div>

<div style="background-color: #fff3cd; padding: 15px; border-left: 4px solid #f39c12; border-radius: 5px; margin: 10px 0; color: #000000;">
<strong>⚡ Repository Secrets Required:</strong><br>
Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):
</div>

- `OPENAI_API_KEY`
- `SUPABASE_URL`
- `SUPABASE_SECRET_KEY`

---

## <span style="color: #8e44ad;">🤖 AI Coding Assistant Integration (Optional)</span>

<div style="background-color: #f8f9fa; padding: 15px; border-left: 4px solid #8e44ad; border-radius: 5px; margin: 10px 0; color: #000000;">
Transform any AI coding assistant into a <strong>context-aware developer</strong> that understands your codebase architecture, finds existing implementations, and maintains consistency across your project.
</div>

**🎯 What this enables:**

- **Smart code placement** - AI knows where files belong based on your project structure
- **Duplicate prevention** - AI finds existing similar functions before creating new ones
- **Pattern consistency** - AI matches your existing code style and architecture
- **Context-aware suggestions** - AI understands your tech stack and conventions

### Setup Complete!

<div style="background-color: #d4edda; padding: 15px; border-left: 4px solid #28a745; border-radius: 5px; color: #000000;">
If you ran <code>vector-search-functions.sql</code> in Step 2, you already have the AI analysis functions set up! The database setup includes both the table creation and all 4 RPC functions.
</div>

<div style="background-color: #d1ecf1; padding: 15px; border-left: 4px solid #bee5eb; border-radius: 5px; margin: 10px 0; color: #000000;">
<strong>💡 Performance Note:</strong> For small codebases (&lt; 1000 files), no vector index is needed - PostgreSQL's sequential scan is actually faster! The index is only beneficial for large projects.
</div>

### Add AI Agent Guidelines (Recommended)

<div style="background-color: #f8f9fa; padding: 15px; border-left: 4px solid #8e44ad; border-radius: 5px; color: #000000;">
Copy the <code>agents.md</code> file to your project root to provide AI assistants with complete codebase analysis instructions and SQL examples.
</div>

<div style="background-color: #1a202c; padding: 15px; border-radius: 8px; margin: 10px 0; color: #e2e8f0;">

```bash
# Copy AI agent guidelines to your project (includes complete SQL examples)
cp embeddings_workflow/agents.md agents.md
```

</div>

### Available AI Functions

- **`get_codebase_overview()`** - Understand project scope and technologies
- **`find_existing_implementations()`** - Avoid duplicate code
- **`find_architecture_patterns()`** - Match existing code patterns
- **`analyze_directory_patterns()`** - Follow project organization

<div style="background-color: #d1ecf1; padding: 15px; border-left: 4px solid #bee5eb; border-radius: 5px; margin: 10px 0; color: #000000;">
<strong>💡 How it works:</strong> AI assistants call these functions before coding to understand your codebase architecture, find existing implementations, and maintain consistency with your project patterns.
</div>

# Vector-Codebase: A Semantic Database for Code

[![Version](https://img.shields.io/badge/version-1.0.0-blue)](#)
![Node](https://img.shields.io/badge/node-%3E%3D18-339933?logo=node.js&logoColor=white)
![Package%20Managers](https://img.shields.io/badge/pkg-npm%20%7C%20pnpm%20%7C%20yarn-orange)
![OpenAI](https://img.shields.io/badge/OpenAI-embeddings-412991?logo=openai&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-pgvector-3ECF8E?logo=supabase&logoColor=white)
[![License: MIT](https://img.shields.io/badge/License-MIT-gray.svg)](LICENSE)

This workflow provides a script to scan your codebase, generate vector embeddings for each file, and ingest them into a Supabase PostgreSQL database. It's designed to keep your vector store in sync with your git repository, automatically updating embeddings as your code evolves.

While it's pre-configured for Supabase, the ingestion logic in `ingest-embeddings.mjs` can be customized to work with any vector database of your choice.

For an enhanced AI-powered development experience, consider using this workflow in parallel with the [Supabase MCP](https://supabase.com/docs/guides/getting-started/mcp), allowing an AI assistant to query embeddings for a deeper understanding of your codebase.

## Prerequisites

- Node.js (v18 or higher is recommended)
- npm (or pnpm/yarn)
- An existing Supabase project
- An OpenAI API key

---

## Setup Guide

Follow these steps to set up and run the embedding workflow for your project.

### Step 1: Install the Workflow (merge deps into root)

Run the installer from your project root. It installs dependencies into your root `node_modules` (merging with any existing packages) and scaffolds the `embeddings_workflow` folder.

```bash
bash embedding_workflow/install-embeddings-workflow.sh
```

Options:

- `--force`: overwrite existing files in `embeddings_workflow`
- `--pm npm|yarn|pnpm`: choose a package manager (defaults to auto-detect; npm prioritized)

### Step 2: Set Up the Supabase Database

You need to enable the `pgvector` extension and create a table to store the embeddings. Run the following SQL commands in your Supabase project's SQL Editor.

```sql
-- Enable the pgvector extension which is required for vector types
create extension if not exists vector with schema extensions;

-- Create the table to store codebase embeddings
create table
  public.codebase_embeddings (
    id bigserial,
    file_path text not null,
    content text null,
    embedding vector(1536) null, -- Corresponds to OpenAI text-embedding-3-small model
    metadata jsonb null, -- For storing file extension, size, etc.
    constraint codebase_embeddings_pkey primary key (id),
    constraint codebase_embeddings_file_path_key unique (file_path)
  ) tablespace pg_default;
```

### Step 3: Configure Environment Variables

This folder contains a template environment file named `env.txt`.

1.  **Rename the file:** Rename `env.txt` to `.env`. This file should be placed in the root directory of your project.

    ```bash
    # Run from the project root
    mv embedding_workflow/env.txt .env
    ```

2.  **Add your credentials:** Open the `.env` file and replace the placeholder values with your actual credentials from your Supabase project and OpenAI dashboard.

    ```env
    OPENAI_API_KEY="your-openai-api-key"
    SUPABASE_URL="your-supabase-project-url"
    SUPABASE_SERVICE_ROLE_KEY="your-supabase-service-role-key"
    ```

    > **Note:** This script uses the service role key to bypass any Row Level Security policies when ingesting embeddings. Keep this key secure.

### Step 4: Run the Script

Once your database and environment variables are set up, run the script from the **root of your project** using the following command. The script will automatically load your credentials from the `.env` file.

```bash
node embeddings_workflow/ingest-embeddings.mjs
```

The script will:

- Scan your project files, ignoring anything listed in your root `.gitignore` file.
- **Delete embeddings** for any files that have been removed from the codebase.
- Generate an embedding for the content of each file.
- **Create or update** the file path, content, and embedding in your `codebase_embeddings` table.

You will see progress logged to your console.

---

## Automating with GitHub Actions

To keep your embeddings in sync with your codebase automatically, you can use the provided GitHub Actions workflow. This will run the script every time you push changes to your `main` branch.

### Step 1: Create the Workflow File

1.  Create a `.github/workflows` directory in the root of your project if you don't already have one.

    ```bash
    mkdir -p .github/workflows
    ```

2.  Move the `sync-embeddings.yml` file from the `embedding_workflow` directory into the new `.github/workflows` directory.

    ```bash
    mv embedding_workflow/sync-embeddings.yml .github/workflows/sync-embeddings.yml
    ```

### Step 2: Set Up Repository Secrets

Add these encrypted repository secrets (Settings → Secrets and variables → Actions):

- `OPENAI_API_KEY`
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

### Step 3: Example Workflow

If you use npm:

```yaml
name: Sync Codebase Embeddings
on:
  push:
    branches: [main]
jobs:
  sync-embeddings:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "18"
          cache: "npm"
      - run: npm ci || npm install
      - run: node embeddings_workflow/ingest-embeddings.mjs
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_SERVICE_ROLE_KEY: ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}
```

If you use pnpm:

```yaml
name: Sync Codebase Embeddings
on:
  push:
    branches: [main]
jobs:
  sync-embeddings:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "18"
          cache: "pnpm"
      - run: pnpm install --frozen-lockfile
      - run: node embeddings_workflow/ingest-embeddings.mjs
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_SERVICE_ROLE_KEY: ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}
```

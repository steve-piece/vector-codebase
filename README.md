# Codebase Embedding Workflow

This workflow provides a script to scan a codebase, generate vector embeddings for each file using the OpenAI API, and ingest them into a Supabase PostgreSQL database.

## Prerequisites

- Node.js (v18 or higher is recommended)
- pnpm (or your preferred package manager)
- An existing Supabase project
- An OpenAI API key

---

## Setup Guide

Follow these steps to set up and run the embedding workflow for your project.

### Step 1: Install Dependencies

The `embedding_workflow` directory contains its own `package.json` file, so you can install the required dependencies locally to this folder.

```bash
cd embedding_workflow
pnpm install
cd ..
```

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

Once your database and environment variables are set up, run the script from the **root of your project** using the following command. The `node --env-file=.env` flag ensures that your environment variables are loaded correctly.

```bash
node --env-file=.env embedding_workflow/ingest-embeddings.mjs
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

The GitHub Action needs access to your keys to run. You must add them as encrypted secrets to your GitHub repository.

1.  Go to your GitHub repository's page.
2.  Click on `Settings` > `Secrets and variables` > `Actions`.
3.  Click `New repository secret` for each of the following secrets:
    - `OPENAI_API_KEY`: Your OpenAI API key.
    - `SUPABASE_URL`: Your Supabase project URL.
    - `SUPABASE_SERVICE_ROLE_KEY`: Your Supabase service role key.

### Step 3: Push to GitHub

Once you've set up the secrets and moved the workflow file, commit and push the changes to your `main` branch. The action will run automatically on this push and every subsequent push, keeping your codebase embeddings perfectly in sync. You can monitor the progress in the `Actions` tab of your GitHub repository.

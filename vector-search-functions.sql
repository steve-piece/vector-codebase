-- Vector-Codebase Database Setup & AI Functions
-- Complete setup script for Supabase database with AI coding assistant functions
-- Run this entire file in your Supabase SQL Editor

-- ================================================================
-- STEP 1: Enable vector extension and create table
-- ================================================================

-- Enable the pgvector extension
CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA extensions;

-- Create the codebase embeddings table
CREATE TABLE IF NOT EXISTS public.codebase_embeddings (
  id bigserial PRIMARY KEY,
  file_path text NOT NULL UNIQUE,
  content text,
  embedding vector(1536),
  metadata jsonb,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security
ALTER TABLE public.codebase_embeddings ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (adjust based on your security requirements)
-- Policy for service role (full access for embedding ingestion)
CREATE POLICY "Service role can manage all embeddings" ON public.codebase_embeddings
  FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Policy for authenticated users (read access)  
CREATE POLICY "Authenticated users can read embeddings" ON public.codebase_embeddings
  FOR SELECT USING (auth.role() = 'authenticated');

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.codebase_embeddings
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- ================================================================
-- STEP 2: AI Coding Assistant RPC Functions
-- ================================================================
-- These functions help AI understand codebase architecture before making changes

-- 1. Find related architecture patterns
CREATE OR REPLACE FUNCTION find_architecture_patterns(
  query_embedding vector(1536),
  match_threshold float DEFAULT 0.80,
  match_count int DEFAULT 8
)
RETURNS TABLE (
  file_path text,
  content text,
  similarity float,
  file_type text
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    codebase_embeddings.file_path,
    codebase_embeddings.content,
    1 - (codebase_embeddings.embedding <=> query_embedding) as similarity,
    COALESCE(codebase_embeddings.metadata->>'extension', 'unknown') as file_type
  FROM codebase_embeddings
  WHERE 1 - (codebase_embeddings.embedding <=> query_embedding) > match_threshold
  ORDER BY codebase_embeddings.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;

-- 2. Get codebase overview for AI context
CREATE OR REPLACE FUNCTION get_codebase_overview()
RETURNS TABLE (
  total_files bigint,
  file_types jsonb,
  key_directories text[],
  dominant_languages text[]
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*) as total_files,
    jsonb_object_agg(
      COALESCE(metadata->>'extension', 'no-ext'),
      file_count
    ) as file_types,
    array_agg(DISTINCT split_part(file_path, '/', 1)) as key_directories,
    array_agg(DISTINCT COALESCE(metadata->>'extension', 'unknown')) as dominant_languages
  FROM (
    SELECT 
      file_path,
      metadata,
      COUNT(*) as file_count
    FROM codebase_embeddings
    GROUP BY metadata->>'extension', file_path, metadata
  ) stats;
END;
$$;

-- 3. Find existing implementations before adding new code
CREATE OR REPLACE FUNCTION find_existing_implementations(
  query_embedding vector(1536),
  file_pattern text DEFAULT '%',
  match_threshold float DEFAULT 0.75
)
RETURNS TABLE (
  file_path text,
  content_preview text,
  similarity float,
  file_type text
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    codebase_embeddings.file_path,
    LEFT(codebase_embeddings.content, 300) || '...' as content_preview,
    1 - (codebase_embeddings.embedding <=> query_embedding) as similarity,
    COALESCE(codebase_embeddings.metadata->>'extension', 'unknown') as file_type
  FROM codebase_embeddings
  WHERE 
    codebase_embeddings.file_path LIKE file_pattern
    AND 1 - (codebase_embeddings.embedding <=> query_embedding) > match_threshold
  ORDER BY codebase_embeddings.embedding <=> query_embedding
  LIMIT 10;
END;
$$;

-- 4. Analyze code patterns by directory
CREATE OR REPLACE FUNCTION analyze_directory_patterns(
  directory_path text
)
RETURNS TABLE (
  directory text,
  file_count bigint,
  file_types text[],
  common_patterns text[]
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    split_part(file_path, '/', 1) as directory,
    COUNT(*) as file_count,
    array_agg(DISTINCT COALESCE(metadata->>'extension', 'no-ext')) as file_types,
    array_agg(DISTINCT 
      CASE 
        WHEN file_path LIKE '%test%' OR file_path LIKE '%spec%' THEN 'tests'
        WHEN file_path LIKE '%component%' OR file_path LIKE '%Component%' THEN 'components'
        WHEN file_path LIKE '%util%' OR file_path LIKE '%helper%' THEN 'utilities'
        WHEN file_path LIKE '%config%' THEN 'configuration'
        WHEN file_path LIKE '%api%' OR file_path LIKE '%service%' THEN 'services'
        ELSE 'general'
      END
    ) as common_patterns
  FROM codebase_embeddings
  WHERE file_path LIKE directory_path || '%'
  GROUP BY split_part(file_path, '/', 1);
END;
$$;

-- ================================================================
-- STEP 3: Performance index (Only needed for large datasets)
-- ================================================================
-- Note: Vector indexes are only beneficial for large datasets (1000+ rows).
-- For small codebases (< 1000 files), PostgreSQL's sequential scan is faster.
-- 
-- If your codebase grows large, uncomment this index:
-- CREATE INDEX CONCURRENTLY codebase_embeddings_embedding_idx 
-- ON codebase_embeddings USING ivfflat (embedding vector_cosine_ops)
-- WITH (lists = GREATEST(rows/1000, 10));

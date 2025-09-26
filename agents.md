# AI Coding Assistant Rules for Vector-Codebase Integration

## Available Codebase Analysis Functions

Before making any code changes or additions, use these RPC functions to understand the existing codebase architecture and patterns:

### 1. `get_codebase_overview()`

**Purpose:** Get high-level codebase structure and technologies used
**When to use:** At the start of any coding session to understand the project scope
**Returns:** total_files, file_types, key_directories, dominant_languages

### 2. `find_architecture_patterns(query_embedding, match_threshold?, match_count?)`

**Purpose:** Find similar architectural patterns and implementations
**When to use:** Before implementing new features to understand existing patterns
**Parameters:**

- query_embedding: vector(1536) - Generate from your implementation intent
- match_threshold: float (default 0.80) - Similarity threshold
- match_count: int (default 8) - Max results to return
  **Returns:** file_path, content, similarity, file_type

### 3. `find_existing_implementations(query_embedding, file_pattern?, match_threshold?)`

**Purpose:** Check if similar functionality already exists before creating duplicate code
**When to use:** Before adding new components, utilities, or services
**Parameters:**

- query_embedding: vector(1536) - Generate from feature description
- file_pattern: text (default '%') - Optional file path filter
- match_threshold: float (default 0.75) - Similarity threshold
  **Returns:** file_path, content_preview, similarity, file_type

### 4. `analyze_directory_patterns(directory_path)`

**Purpose:** Understand organization patterns within specific directories
**When to use:** When deciding where to place new files or understanding module structure
**Parameters:**

- directory_path: text - Directory to analyze (e.g., 'src', 'components')
  **Returns:** directory, file_count, file_types, common_patterns

## Best Practices for AI Assistants

1. **Always start with `get_codebase_overview()`** to understand the project context
2. **Use `find_existing_implementations()`** before creating new functionality
3. **Use `find_architecture_patterns()`** to match existing code style and patterns
4. **Use `analyze_directory_patterns()`** to follow project organization conventions

## Integration Requirements

- Use Supabase MCP to execute SQL commands directly
- Generate embeddings externally using OpenAI 'text-embedding-3-small' model
- Pass embedding vectors as parameters to RPC functions

## Complete SQL Usage Examples

### Step 1: Always Start with Codebase Overview

```sql
-- Get high-level understanding of the project structure and technologies
SELECT * FROM get_codebase_overview();

-- Example result:
-- total_files | file_types                                    | key_directories    | dominant_languages
-- 245         | {"js": 89, "tsx": 67, "ts": 45, "css": 44} | {src,components}   | {js,tsx,ts,css}
```

### Step 2: Check for Existing Implementations

```sql
-- Find existing similar functionality to avoid duplication
-- (Replace [EMBEDDING_VECTOR] with actual embedding from OpenAI API)
SELECT file_path, content_preview, similarity, file_type
FROM find_existing_implementations(
  '[0.123, -0.456, 0.789, ...]'::vector(1536),  -- Generated from your feature description
  '%',  -- Search all files (or specify pattern like 'src/%')
  0.75  -- Similarity threshold
);

-- Example result:
-- file_path              | content_preview                           | similarity | file_type
-- src/auth/Login.tsx     | import React from 'react'; const Login..  | 0.89      | tsx
-- components/Auth.js     | export const Auth = () => { const hand.. | 0.82      | js
```

### Step 3: Find Architectural Patterns

```sql
-- Understand existing patterns and code style before implementing
SELECT file_path, content, similarity, file_type
FROM find_architecture_patterns(
  '[0.234, -0.567, 0.890, ...]'::vector(1536),  -- Generated from implementation intent
  0.80,  -- Higher threshold for architectural consistency
  8      -- Get top 8 examples
);

-- Example result:
-- file_path                | content               | similarity | file_type
-- src/hooks/useAuth.ts    | import { useState }... | 0.91      | ts
-- components/UserForm.tsx | const UserForm = ()... | 0.87      | tsx
```

### Step 4: Analyze Directory Structure

```sql
-- Understand how files are organized in specific directories
SELECT directory, file_count, file_types, common_patterns
FROM analyze_directory_patterns('src');

-- Example result:
-- directory | file_count | file_types        | common_patterns
-- src       | 156        | {tsx,ts,js,css}   | {components,services,utilities}

-- For more specific directory analysis:
SELECT directory, file_count, file_types, common_patterns
FROM analyze_directory_patterns('components');
```

### Complete AI Assistant Workflow

```sql
-- 1. Get project overview
SELECT 'PROJECT OVERVIEW:' as step, * FROM get_codebase_overview();

-- 2. Check for existing implementations
SELECT 'EXISTING IMPLEMENTATIONS:' as step, file_path, similarity
FROM find_existing_implementations(
  '[EMBEDDING_FOR_YOUR_FEATURE]'::vector(1536),
  '%',
  0.75
) LIMIT 5;

-- 3. Find architectural patterns
SELECT 'ARCHITECTURAL PATTERNS:' as step, file_path, similarity
FROM find_architecture_patterns(
  '[EMBEDDING_FOR_YOUR_IMPLEMENTATION]'::vector(1536),
  0.80,
  5
);

-- 4. Analyze target directory
SELECT 'DIRECTORY ANALYSIS:' as step, *
FROM analyze_directory_patterns('src');
```

## Important Notes for AI Assistants

1. **Generate embeddings using OpenAI 'text-embedding-3-small' model**
2. **Replace [EMBEDDING_VECTOR] placeholders with actual vector arrays**
3. **Adjust similarity thresholds based on how strict you want matching to be**
4. **Use file_pattern parameter to narrow searches to specific areas**
5. **Always run get_codebase_overview() first to understand the project**

Remember: These functions help you write code that fits naturally into the existing codebase architecture and avoids duplication.

import "dotenv/config";
import { glob } from "glob";
import { createClient } from "@supabase/supabase-js";
import OpenAI from "openai";
import fs from "fs/promises";
import path from "path";

if (
  !process.env.SUPABASE_URL ||
  !process.env.SUPABASE_SERVICE_ROLE_KEY ||
  !process.env.OPENAI_API_KEY
) {
  throw new Error(
    "Missing environment variables. Make sure to create a .env file with SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, and OPENAI_API_KEY"
  );
}

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

async function getFiles() {
  const gitignore = await fs.readFile(".gitignore", "utf-8");
  const ignorePatterns = gitignore
    .split("\n")
    .filter((line) => line.trim() && !line.startsWith("#"))
    .map((line) => (line.startsWith("/") ? line.substring(1) : `**/${line}`)); // Handle root-level ignores

  const files = await glob("**/*", {
    ignore: [
      "**/node_modules/**",
      "**/.git/**",
      "**/.DS_Store",
      ...ignorePatterns,
    ],
    nodir: true,
    absolute: true,
  });
  return files;
}

async function generateAndIngestEmbeddings() {
  // 1. Get all file paths from the local codebase
  const localFiles = await getFiles();
  const workspaceRoot = process.cwd();
  const localFilePaths = localFiles.map((absolutePath) =>
    path.relative(workspaceRoot, absolutePath)
  );

  // 2. Get all file paths from the Supabase table
  console.log("Fetching existing file paths from Supabase...");
  const { data: dbFiles, error: dbError } = await supabase
    .from("codebase_embeddings")
    .select("file_path");

  if (dbError) {
    console.error("Error fetching file paths from Supabase:", dbError);
    return;
  }

  const dbFilePaths = dbFiles.map((file) => file.file_path);

  // 3. Determine which files to delete from Supabase
  const filesToDelete = dbFilePaths.filter(
    (dbPath) => !localFilePaths.includes(dbPath)
  );

  if (filesToDelete.length > 0) {
    console.log(
      `Found ${filesToDelete.length} files to delete from Supabase...`
    );
    const { error: deleteError } = await supabase
      .from("codebase_embeddings")
      .delete()
      .in("file_path", filesToDelete);

    if (deleteError) {
      console.error("Error deleting files from Supabase:", deleteError);
    } else {
      console.log("Successfully deleted files from Supabase.");
    }
  } else {
    console.log("No files to delete from Supabase.");
  }

  // 4. Upsert embeddings for all local files (handles additions and updates)
  for (const absolutePath of localFiles) {
    try {
      const content = await fs.readFile(absolutePath, "utf-8");
      const stats = await fs.stat(absolutePath);

      // Skip empty files
      if (!content.trim()) {
        continue;
      }

      const relativePath = path.relative(workspaceRoot, absolutePath);

      const metadata = {
        file_extension: path.extname(relativePath),
        file_size_bytes: stats.size,
      };

      console.log(`Generating embedding for ${relativePath}...`);

      const embeddingResponse = await openai.embeddings.create({
        model: "text-embedding-3-small",
        input: content,
      });

      const embedding = embeddingResponse.data[0].embedding;

      console.log(`Ingesting embedding for ${relativePath} into Supabase...`);

      const { data, error } = await supabase.from("codebase_embeddings").upsert(
        {
          file_path: relativePath,
          content,
          embedding,
          metadata,
        },
        { onConflict: "file_path" }
      );

      if (error) {
        console.error(`Error ingesting ${relativePath}:`, error);
      } else {
        console.log(`Successfully ingested ${relativePath}.`);
      }
    } catch (error) {
      console.error(`Error processing file ${absolutePath}:`, error);
    }
  }

  console.log("Embedding generation and ingestion complete.");
}

generateAndIngestEmbeddings();

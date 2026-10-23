import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from "vite";

const projectRoot = dirname(fileURLToPath(import.meta.url));

export default defineConfig(({ command }) => ({
  root: resolve(projectRoot, "frontend"),
  base: process.env.VITE_BASE || (command === "serve" ? "/" : "/static/dist/"),
  plugins: [react(), tailwindcss()],
  build: {
    outDir: resolve(projectRoot, process.env.VITE_OUT_DIR || "app/static/dist"),
    emptyOutDir: true,
    sourcemap: false,
  },
  server: {
    host: "127.0.0.1",
    port: 5173,
    strictPort: true,
    proxy: {
      "/api": "http://127.0.0.1:8088",
      "/static": "http://127.0.0.1:8088",
    },
  },
}));

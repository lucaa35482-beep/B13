import { defineConfig } from 'vite';
import { resolve } from 'node:path';
export default defineConfig({build:{rollupOptions:{input:{main:resolve(__dirname,'index.html'),member:resolve(__dirname,'member.html'),leader:resolve(__dirname,'leader.html')}}}});

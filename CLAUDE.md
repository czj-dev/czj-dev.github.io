# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a personal blog built with Hexo, a fast static site generator. The site is hosted on GitHub Pages at `https://czj-dev.github.io` and uses the Archer theme. The blog primarily contains technical posts about Android development, programming concepts, and software engineering topics.

## Development Commands

### Core Hexo Commands
- `npm run build` - Generate static files (equivalent to `hexo generate`)
- `npm run clean` - Clean cache and generated files (equivalent to `hexo clean`)
- `npm run server` - Start local development server (equivalent to `hexo server`)
- `npm run deploy` - Deploy to GitHub Pages (equivalent to `hexo deploy`)

### Common Development Workflow
1. Create new post: `hexo new post "post-title"`
2. Create new page: `hexo new page "page-name"`
3. Start dev server: `npm run server`
4. Build for production: `npm run build`
5. Deploy: `npm run deploy`

## Architecture

### Project Structure
- `_config.yml` - Main Hexo configuration file
- `source/` - Source directory containing posts, pages, and assets
  - `_posts/` - Blog posts in Markdown format
  - `about/` - About page content
  - `img/` - Static images and assets
  - `static-page/` - Static HTML files (skipped in render)
- `scaffolds/` - Templates for new content
- `themes/` - Theme directory (using Archer theme)
- `public/` - Generated static site files (auto-generated)
- `db.json` - Hexo database file

### Theme Configuration
The site uses the Archer theme (`theme: archer`) with extensive customization in `themes/archer/_config.yml`. Key features include:
- Custom fonts (Noto Sans SC)
- Mermaid diagram support
- MathJax for LaTeX equations
- Valine comments integration
- Busuanzi analytics
- Multiple comment system options

### Content Management
Posts follow the naming convention `YYYY-MM-DD-title.md` and are stored in `source/_posts/`. Each post uses the scaffold template from `scaffolds/post.md` with front matter containing title, date, and tags.

### Deployment
The site is configured to deploy to GitHub Pages via the hexo-deployer-git plugin, pushing to the `master` branch of `https://github.com/czj-dev/czj-dev.github.io`.

### Special Configuration
- JSON content generation is enabled for API access
- Static pages in `static-page/` are excluded from Hexo rendering
- Custom font loading is enabled with Chinese font support
- Mermaid v8.11.0 is configured for diagram rendering
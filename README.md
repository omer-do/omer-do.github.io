# od-stack

Personal blog built with [Hugo](https://gohugo.io/) and [PaperMod](https://github.com/adityatelange/hugo-PaperMod). Auto-deploys to GitHub Pages on push to `main`.

## Prerequisites

- [Hugo extended](https://gohugo.io/installation/) (v0.155.3+)
- Git with submodule support

## Local Development

```bash
git clone --recurse-submodules git@github.com:omer-do/omer-do.github.io.git
cd omer-do.github.io
hugo server -D
```

Clean build:

```bash
rm -rf public && hugo
```

## Project Structure

```
hugo.toml                  # Site config (theme, menu, params)
content/posts/             # Blog posts
content/about/             # About page
content/archives.md        # Archive page
assets/css/extended/       # Custom CSS (auto-loaded by PaperMod)
static/img/                # Images
themes/PaperMod/           # Theme (git submodule)
.github/workflows/hugo.yml # CI/CD — build and deploy
```

## New Post

```bash
hugo new posts/YYYY-MM-DD-slug.md
```

Required front matter fields: `title`, `date`, `categories`, `tags`, `summary`.

## Deployment

Push to `main` triggers the GitHub Actions workflow which builds and deploys to GitHub Pages.

## Sanity Check

```bash
./scripts/sanity-check.sh
```

Validates build, expected pages, image references, and front matter.

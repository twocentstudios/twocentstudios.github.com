# TwoCentStudios Blog - Claude Code Instructions

## Project Overview

This is a Jekyll-based blog with a unique dual-branch Git setup for GitHub Pages deployment. See README.md for comprehensive documentation on blog structure, posting, and deployment.

## Key Information from README.md

- **Posts**: Go in `_posts/` folder with format `YYYY-MM-DD-title-with-hyphens.markdown`
- **Images**: Store in `images/` folder, reference as `/images/filename.ext`
- **Tags**: Space-separated in front matter (e.g., `tags: apple ios swiftui`)
- **Development**: `bundle exec jekyll serve --livereload --drafts`
- **Deployment**: `./deploy.sh` (builds to `_site/` and commits to master branch)

## Media Manipulation Commands

### ImageMagick Commands

#### Create Horizontal Row of Images with Uniform Spacing
```bash
# Add individual borders to each image first (50px horizontal for 100px total spacing)
magick image1.png -bordercolor "gray20" -border 50x0 temp_01.png
magick image2.png -bordercolor "gray20" -border 50x0 temp_02.png
# ... repeat for all images

# Append all bordered images with final outer border
magick temp_01.png temp_02.png temp_03.png +append -bordercolor "gray20" -border 50x100 final_image.png

# Resize maintaining aspect ratio
magick final_image.png -resize x400 final_image_400h.png
```

#### Basic Image Operations
```bash
# Resize image to specific height maintaining aspect ratio
magick input.png -resize x400 output.png

# Resize image to specific width maintaining aspect ratio  
magick input.png -resize 800x output.png

# Add border with specific color
magick input.png -bordercolor "gray20" -border 50 output.png

# Convert format
magick input.png output.jpg
```

#### Montage Operations (Alternative Approach)
```bash
# Create grid layout (use with caution for spacing)
magick montage *.png -tile 3x3 -geometry +10+10 -background "gray20" output.png

# Create single row layout (spacing may be uneven)
magick montage *.png -tile 9x1 -geometry +50+0 -background "gray20" output.png
```

### Video Operations

#### FFmpeg Commands
```bash
# Convert MOV to MP4
ffmpeg -i input.mov output.mp4

# Create poster image from video (first frame)
ffmpeg -i input.mov -vframes 1 -f image2 poster.png

# Create poster image from specific time
ffmpeg -i input.mov -ss 00:00:05 -vframes 1 poster.png

# Resize video
ffmpeg -i input.mov -vf scale=800:600 output.mov

# Convert to web-friendly format
ffmpeg -i input.mov -c:v libx264 -crf 23 -c:a aac output.mp4
```

### Optimization Commands

#### Image Compression
```bash
# Optimize PNG (requires pngquant)
pngquant --quality=65-90 input.png --output output.png

# Optimize JPEG (using ImageMagick)
magick input.jpg -quality 85 output.jpg
```

## Blog-Specific Guidelines

- **Always reference images as `/images/filename.ext`** in posts
- **Use caption_img plugin** for captioned images: `{% caption_img /images/image.png w400 h300 Caption text %}`
- **Include poster images for videos** using HTML video tags
- **Test locally** with `bundle exec jekyll serve --livereload --drafts` before deploying
- **Tag appropriately** - use `apple` tag for iOS Dev Directory inclusion

## File Organization

- Keep original/high-res images for future use
- Store working files in temporary directories during processing
- Always clean up temporary files after operations
- Consider web optimization for all images before adding to `/images/`
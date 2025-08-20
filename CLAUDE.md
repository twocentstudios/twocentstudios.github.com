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

**Method 1: Using Selective Borders (Recommended)**
```bash
# For 2 images - add borders to create visible separation
magick image1.png -bordercolor "gray70" -border 25x0 temp1.png
magick image2.png -bordercolor "gray70" -border 25x0 temp2.png
magick temp1.png temp2.png -background "gray70" +smush 50 -bordercolor "gray70" -border 50 -resize 1500x1500\> -quality 85 output.jpg
rm temp1.png temp2.png

# For 3 images - selective borders to avoid artifacts
magick image1.png -bordercolor "gray70" -border 0x0+25+0 temp1.png  # right border only
magick image2.png -bordercolor "gray70" -border 25x0 temp2.png       # both sides
magick image3.png -bordercolor "gray70" -border 0x0+0+25 temp3.png   # left border only
magick temp1.png temp2.png temp3.png +append -bordercolor "gray70" -border 25 -resize 1500x1500\> -quality 85 output.jpg
rm temp1.png temp2.png temp3.png
```

**Method 2: Using +smush (Simple but may lack visible separation)**
```bash
# Combine images with exact spacing and outer border
magick image1.png image2.png image3.png +smush 15 -bordercolor "gray70" -border 50 output.png

# Note: +smush for horizontal, -smush for vertical
# Number specifies exact pixels between images (no doubling)
# Use gray70 for subtle separation, gray20 for darker separation
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

# Create single row layout - NOTE: geometry spacing doubles in final result
magick montage *.png -tile 9x1 -geometry +25+0 -background "gray20" output.png
# Above creates 50px actual spacing between images (25px × 2)

# For precise control, use +smush method instead of montage
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

#### Image Processing and Optimization
```bash
# Standard image processing: resize to smallest edge 1500px (without upscaling) and optimize
magick input.png -resize 1500x1500> -quality 85 output.jpg

# For web optimization, convert to JPEG with quality 85
magick input.png -resize 1500x1500> -quality 85 output.jpg

# Optimize PNG (requires pngquant)
pngquant --quality=65-90 input.png --output output.png
```

## Blog-Specific Guidelines

- **Always reference images as `/images/filename.ext`** in posts
- **Use caption_img plugin** for captioned images: `{% caption_img /images/image.png h400 Caption text %}`
- **Use height-only sizing** in caption_img - specify only height (e.g. `h400`) and omit width for responsive scaling
- **Include poster images for videos** using HTML video tags
- **Test locally** with `bundle exec jekyll serve --livereload --drafts` before deploying
- **Tag appropriately** - use `apple` tag for iOS Dev Directory inclusion

## File Organization

- Keep original/high-res images for future use
- Store working files in temporary directories during processing
- Always clean up temporary files after operations
- Consider web optimization for all images before adding to `/images/`
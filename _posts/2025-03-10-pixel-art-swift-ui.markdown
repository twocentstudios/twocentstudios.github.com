---
layout: post
title: "Rendering Pixel Art with SwiftUI"
date: 2025-03-10 11:08:00
image: /images/pixel-art-title.png
tags: 8bitnails ios apple
---

The main challenge of rendering pixel art is maintaining crisp pixel boundaries when scaling the tiny bitmap to modern displays with lots of pixels.

## Rendering from a native `Image`

If you already have an pixel art image you'd like to display in `Image` (`UIImage`, `CGImage`, etc.) format (e.g. a PNG in your asset catalog or downloaded from a server), add the `.interpolation(.none)` modifier to `Image`.

```swift
struct NativeImageView: View {
    var body: some View {
        Image("color-image-10-10") // 10x10 PNG in Assets.xcassets
            .interpolation(.none) // <-- important
            .resizable()
            .scaledToFit()
    }
}

#Preview("NativeImageView", traits: .sizeThatFitsLayout) {
    NativeImageView()
        .padding()
        .border(.black)
        .padding()
}
```

{% caption_img /images/pixel-art-native-interpolation.png h400 With and without interpolation applied to an existing pixel art image %}

## Bitmap Model

Imagine you want to manipulate color data directly instead of using `CGImage` as the container.

Let's start by creating a simple struct to hold our bitmap data.

```swift
struct Bitmap: Equatable, Sendable {
    // Access via `values[row][column]`
    var values: [[Color]] 

    var rows: Int { values.count }
    var columns: Int { values.first?.count ?? 0 }
    var aspectRatio: CGFloat { CGFloat(columns) / CGFloat(rows) }
}
```

Next let's add a few ways to create a bitmap for testing:

```swift
extension Bitmap {
    init(_ initialColor: Color? = nil, rows: Int, columns: Int) {
        values = .init(repeating: .init(repeating: initialColor ?? .white, count: columns), count: rows)
    }

    mutating func fill(_ color: Color) {
        values = .init(repeating: .init(repeating: color, count: columns), count: rows)
    }

    static func mockGrid(rows: Int, columns: Int) -> Self {
        var instance = Self(rows: rows, columns: columns)
        for row in 0 ..< rows {
            for column in 0 ..< columns {
                instance.values[row][column] = row % 2 == column % 2 ? .black : .white
            }
        }
        return instance
    }

    static func mockRowColors(rows: Int, columns: Int) -> Self {
        var instance = Self(rows: rows, columns: columns)
        for row in 0 ..< rows {
            instance.values[row] = Array(repeating: .init(hue: Double(row) / Double(rows), saturation: 0.7, brightness: 1.0), count: columns)
        }
        return instance
    }
}
```

## Rendering options

There are two ways to render the bitmap: `Image` and `Canvas`.

- `Image` allows you to use `Image`-specific modifiers to further manipulate the view.
- `Image` encodes its native size, making it simpler to apply an aspect ratio.
- `Canvas` draws directly to a `GraphicsContext` at the size provided by the parent view.
- `Canvas` allows you to draw additional elements like dividers.

### Rendering as `Image`

`BitmapImageView` will render the bitmap. It works by using the [`Image(size:label:opaque:colorMode:renderer:)`](https://developer.apple.com/documentation/swiftui/image/init(size:label:opaque:colormode:renderer:)) initializer for `Image` that allows writing directly to the image via a SwiftUI `GraphicsContext` instance.

```swift
struct BitmapImageView: View {
    let bitmap: Bitmap

    var body: some View {
        Image(
            size: .init(width: bitmap.columns, height: bitmap.rows),
            label: nil,
            opaque: true,
            colorMode: .nonLinear
        ) { ctx in
            let cellWidth: CGFloat = 1
            let cellHeight: CGFloat = 1
            for row in 0 ..< bitmap.rows {
                for column in 0 ..< bitmap.columns {
                    let path = Path(
                        CGRect(
                            x: CGFloat(column) * cellWidth,
                            y: CGFloat(row) * cellHeight,
                            width: cellWidth,
                            height: cellHeight
                        )
                    )
                    ctx.fill(path, with: .color(bitmap.values[row][column]))
                }
            }
        }
        .interpolation(.none)
        .resizable()
        .scaledToFit()
    }
}
```

The **size** of the image is small; exactly the number of pixels specified in our bitmap. The other parameters are the defaults.

We loop through the bitmap contents and write each value as a one-point size rectangle in the graphics context.

With the resulting image, we can now apply the usual `Image`-specific modifiers.

The secret sauce is using the `.interpolation(.none)` modifier to preserve the hard edges when the tiny image is scaled up to retina display sizes.

{% caption_img /images/pixel-art-image-interpolation.png h400 With and without interpolation applied to the tiny bitmap %}

`.resizable` makes the image expand to fill the parent.

`.scaledToFit` preserves the square pixels. It's the equivalent of `.aspectRatio(bitmap.aspectRatio, contentMode: .fit)` or `.aspectRatio(nil, contentMode: .fit)`.

Here is a SwiftUI Preview to show our final result:

```swift
#Preview("BitmapImageView", traits: .sizeThatFitsLayout) {
    BitmapImageView(bitmap: .mockGrid(rows: 10, columns: 10))
        .padding()
        .border(.black)
        .padding()
}
```

### Rendering as `Canvas`

```swift
struct BitmapCanvasView: View {
    let bitmap: Bitmap
    
    var body: some View {
        Canvas(
            opaque: true, 
            colorMode: .nonLinear, 
            rendersAsynchronously: false
        ) { ctx, size in
            let cellWidth = (size.width / CGFloat(bitmap.columns))
            let cellHeight = (size.height / CGFloat(bitmap.rows))
            for row in 0 ..< bitmap.rows {
                for column in 0 ..< bitmap.columns {
                    let path = Path(
                        CGRect(
                            x: CGFloat(column) * cellWidth,
                            y: CGFloat(row) * cellHeight,
                            width: cellWidth,
                            height: cellHeight
                        )
                    )
                    ctx.fill(
                        path,
                        with: .color(bitmap.values[row][column]),
                        style: .init(eoFill: false, antialiased: false)
                    )
                }
            }
        }
        .aspectRatio(bitmap.aspectRatio, contentMode: .fit)
    }
}
```

Unlike the `Image` implementation, the `GraphicsContext` within the `Canvas` implementation is drawing at whatever size the parent specifies.

The secret sauce in this version specifying `antialiased: false` in the `FillStyle(eoFill:antialiased:)` parameter. With the default `true`, certain non-integer sizes will render with randomly sized dividers.

{% caption_img /images/pixel-art-canvas-interpolation.png h400 With and without interpolation inside the `fill` command %}

Adding the specific `aspectRatio` modifier ensures the view renders with square pixels.

```swift
#Preview("BitmapCanvasView", traits: .sizeThatFitsLayout) {
    BitmapCanvasView(bitmap: .mockRowColors(rows: 10, columns: 10))
        .frame(width: 409) // Forcing this width will show antialiasing artifacts 
        .border(.black)
        .padding()
}
```

### Rendering as `Canvas` with dividers

One reason you might want to use `Canvas` is to draw dividers showing the pixel boundaries.

```swift
struct BitmapDividersView: View {
    let bitmap: Bitmap
    var lineWidthRatio: CGFloat? = 0.05 // ratio of cell size
    var lineColor: Color? = .white
    
    var body: some View {
        Canvas(
            opaque: true,
            colorMode: .nonLinear,
            rendersAsynchronously: false
        ) { ctx, size in
            let cellWidth = (size.width / CGFloat(bitmap.columns))
            let cellHeight = (size.height / CGFloat(bitmap.rows))
            for row in 0 ..< bitmap.rows {
                for column in 0 ..< bitmap.columns {
                    let path = Path(
                        CGRect(
                            x: CGFloat(column) * cellWidth,
                            y: CGFloat(row) * cellHeight,
                            width: cellWidth,
                            height: cellHeight
                        )
                    )
                    ctx.fill(
                        path,
                        with: .color(bitmap.values[row][column]),
                        style: .init(eoFill: false, antialiased: false)
                    )
                }
            }
            
            if let lineWidthRatio, let lineColor {
                let lineWidthHorizontal = lineWidthRatio * cellHeight
                let lineWidthVertical = lineWidthRatio * cellWidth
                if bitmap.rows > 2 {
                    for row in 1 ... bitmap.rows - 1 {
                        let linePath = Path { p in
                            p.move(to: CGPoint(x: 0, y: CGFloat(row) * cellHeight))
                            p.addLine(to: CGPoint(x: size.width, y: CGFloat(row) * cellHeight))
                        }
                        ctx.stroke(linePath, with: .color(lineColor), lineWidth: lineWidthHorizontal)
                    }
                }
                if bitmap.columns > 2 {
                    for column in 1 ... bitmap.columns - 1 {
                        let linePath = Path { p in
                            p.move(to: CGPoint(x: CGFloat(column) * cellWidth, y: 0))
                            p.addLine(to: CGPoint(x: CGFloat(column) * cellWidth, y: size.height))
                        }
                        ctx.stroke(linePath, with: .color(lineColor), lineWidth: lineWidthVertical)
                    }
                }
            }
        }
        .aspectRatio(bitmap.aspectRatio, contentMode: .fit)
    }
}

#Preview("BitmapDividersView", traits: .sizeThatFitsLayout) {
    BitmapDividersView(bitmap: .mockRowColors(rows: 10, columns: 10))
        .frame(width: 409)
        .padding()
        .border(.black)
        .padding()
        .background(Color.gray)
}
```

{% caption_img /images/pixel-art-canvas-dividers.png h450 Adding dividers to the bitmap rendering %}

The above implementation draws dividers between rows and columns if `lineColor` is specified in the initializer.

I've implemented `lineWidthRatio` as a percentage of the cell width. It will scale somewhat naturally with the view size.

Note: this does not draw the outer border intentionally. If you need the outer border, it's better to draw it using SwiftUI modifiers because inside the `GraphicsContext` callback, borders are drawn with half their width on each side of the path. This means that only half the outer borders will be visible if the `Canvas` is clipping.

{% caption_img /images/pixel-art-title.png h350 Adding dividers and a border to the bitmap rendering %}

```swift
#Preview("BitmapDividersViewWithBorder", traits: .sizeThatFitsLayout) {
    BitmapDividersView(bitmap: .mockRowColors(rows: 10, columns: 10))
        .frame(width: 400)
        .padding(2)
        .border(.white, width: 2)
        .padding()
        .background(Color.black.opacity(0.8))
}
```

It's also reasonable to draw the dividers into a separate `Canvas` instance (with `opaque: false`) and overlay it using the standard SwiftUI tools. However, it will be slower (albeit imperceptibly so for most use cases) since SwiftUI will have to do the compositing again.

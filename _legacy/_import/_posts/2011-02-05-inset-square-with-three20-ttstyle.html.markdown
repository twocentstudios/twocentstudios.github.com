--- 
layout: post
title: Inset Square with Three20 & TTStyle
tags: 
- iOS
- Three20
- TTStyle
status: publish
type: post
published: true
meta: 
  _edit_last: "1"
  _syntaxhighlighter_encoded: "1"
  _wp_old_slug: ""
  sfw_comment_form_password: 6ma2nCRXR8h0
---
<a href="http://three20.info">Three20</a> is a pretty fantastic iOS library. One of the features that took me awhile to get a handle on was using TTView and TTStyles. Here, I'll show how to make a fancy square button that looks like this:

[caption id="attachment_10" align="aligncenter" width="102" caption="The square we&#39;ll be making sans background."]<a href="http://twocentstudios.com/blog/wp-content/uploads/2011/02/red-inset-square.png"><img class="size-full wp-image-10" title="red-inset-square" src="http://twocentstudios.com/blog/wp-content/uploads/2011/02/red-inset-square.png" alt="" width="102" height="94" /></a>[/caption]

I'm not going to go into getting started with Three20, how to create a default style sheet, or any other intro material. Just the meat and bones here.

<h2>The Style</h2>
Let's start with the good stuff. Here is the TTStyle we need to generate the box.

```
 // In our default style sheet
- (TTStyle*)insetSquare{
  return [TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithRadius:8] next:
  [TTLinearGradientFillStyle styleWithColor1:RGBCOLOR(218, 0, 0) color2:RGBCOLOR(140, 0, 0) next:
  [TTInnerShadowStyle styleWithColor:RGBCOLOR(104, 2, 2) blur:3 offset:CGSizeMake(0, 1) next:nil]]];
}
```

We start out by making our shape. In this case, we're using a rounded rectangle with a radius of 8px. "But I thought it was a square!" you may ask. Relax, we'll be specifying dimensions when we create our view in the next section.

If you're unfamiliar with creating TTStyles, each style has a <span style="font-family: Consolas, Monaco, 'Courier New', Courier, monospace; font-size: 12px; line-height: 18px; white-space: pre;">next:</span> input used to string together multiple drawing commands.

Our next command is a linear gradient going from a light to medium red. <span style="font-family: Consolas, Monaco, 'Courier New', Courier, monospace; font-size: 12px; line-height: 18px; white-space: pre;">RGBCOLOR</span> is a nice TT macro for creating colors you dream up in Photoshop. We'll use those as our color1 and color2 inputs.

Lastly, we're going to add an inner shadow to make our square look inset. We'll use an even darker red for this. Experiment with the blur and offset to achieve the desired effect. Blur will expand the size of the shadow while spreading out the effect. Beware, it doesn't work exactly the same as the inner shadow blending property in Photoshop (namely, it doesn't really extend past 10-20px or so).

The offset is a CGSize. We're using a 1px offset down. You'll usually be using y-axis offsets as the default light source is from above the screen. Don't forget about <code>RGBACOLOR</code> as well to experiment with different transparencies for your shadows.

That was pretty easy, right? I recommend checking out the TTCatalog example project custom views section for more great looking style examples.
<h2>Setting Up the View</h2>
Now we need a view to draw our beautiful new style. In your view controller, add the following:

```
  // In our view controller
- (void)viewDidLoad {
	// Create a new TTView
	TTView *insetSquareView = [[TTView alloc] initWithFrame:CGRectMake(40, 20, 240, 240)];

	// Set the style to our insetSquare style via the TTSTYLEVAR convenience macro
	insetSquareView.style = TTSTYLEVAR(insetSquare);

	// Sometimes you'll need to set the background color to clear so that the edges
	// of the rounded rectangle aren't opaque
	insetSquareView.backgroundColor = [UIColor clearColor];

	// Add it to the view and release it.
	[self.view addSubview:insetSquareView];
	TT_RELEASE_SAFELY(insetSquareView);
}
```


The comments should be self explanatory. Setting the style will tell our view how to draw itself.

And the best part about our new inset square? It automatically scales to retina and standard res, and we don't have to worry about loading in tons of image files and bloating up our binary unnecessarily.

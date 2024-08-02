---
layout: post
title: All About TTTableItems & Cells
tags:
- apple
- ios
- three20
status: publish
type: post
published: true
redirect_from: "/blog/2011/02/06/all-about-tttableitems-cells.html"
---

Another tough thing about <a href="http://three20.info">Three20</a> was wrapping my head around the table system. I disliked it at first, but in retrospect, it's much more organized than using the standard SDK system. I found with even mildly complicated systems, my UITableViewController was turning into a mess of all kinds of delegate code, tablecell code, and etc.

TTTableViewController deserves a post in itself, so I won't get it into it at the moment. I'll only focus on the TableItem/Cell relationship and how to get the most of out of them.

<h2>What is a TTTableItem?</h2>
The standard SDK doesn't really have the concept of tableitems. A tableitem is simply a data structure that holds the information used in a single tablecell. It's the M in <a href="http://en.wikipedia.org/wiki/Model%E2%80%93View%E2%80%93Controller">MVC</a>. The cell is therefore the V. And the C is... well some combination of TTTableDataSource and TTTableViewController.

The second reason tableitems exist is so that we can have variable height rows. We'll discuss more about this later.

<h2>Customizing</h2>
When first starting out with Three20, it might be tempting just to use all the built-in Three20 items and cells. For quick prototyping and testing your backend, they are invaluable (I recommend perusing the TTCatalog section of TableItems to get a feel for what's already built-in). When you get to production, however, you'll want to have your own custom classes for each cell type, even if they are direct subclasses.

It may be a little extra work getting all the custom classes made, but in the end you'll be modular, organized, and you won't have to sweat the details.

There are so many subclasses of TTTableItems, you may be wondering which you should subclass.
<ul>
	<li>If your cell will be selected in any way, you'll want to subclass TTTableLinkedItem. This will provide you with a URL field that moves to the next view controller in the TTNavigator system. It will also provide you with an accessory URL field. There's built in functionality for displaying a detail disclosure button and other accessories depending on which URL fields are filled in.</li>
	<li>If you're just displaying data, you can go to the base class of TTTableItem.</li>
	<li>It's not the worst idea to use the higher level classes, but in the end it's probably easier just to add only the fields you need to the class so you don't get confused later wondering what the "text" NSString corresponds to.</li>
</ul>

<h2>Initializers</h2>
Most of the higher level items come with class convenience initializers. An example from TTTableSubtitleItem for context:
`+ (id)itemWithText:(NSString*)text subtitle:(NSString*)subtitle URL:(NSString*)URL;`
If your cell is only displaying a few chunks of data, I would initialize this way. 

When you're working with lots of fields, it's much easier to pass in your model object or NSDictionary. My initializer from a TTTableLinkedItem subclass:
`+ (id)itemWithObject:(TCExampleObject*)xObject;`
When you're doing it this way, you'll have to decide whether you want to manually move strings and data from your model object to table item class variables, or you can store a copy of your model object inside the item. It's a judgement call of whether you want to be tidy or quick and dirty. Just remember which way you did it when you're loading data into your cell.

<h2>Using Cells</h2>
(Don't worry about connecting items to cells yet. We'll cover that later.)

Cells are a little different than Items in the Three20 world. TTTableViewCells subclass from UITableViewCell, so they carry the remnants of the UI class. The UI class comes with two UILabels (textLabel and detailTextLabel) and a UIImageView.

In the Three20 built-in cells, the textLabels are usually used, but not the imageView. I recommend doing the same.

Start by making instance variables for each view element you need. Labels and imageViews are the most common, but any view will do. Next, override the initWithStyle initializer.

```
 // TCExampleCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)identifier {
	if (self = [super initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:identifier]) {
		// If you're using custom backgrounds, initialize them here
		TTView *BackView = [[TTView alloc] initWithFrame:[self frame]];
		self.backgroundView = BackView;
		TT_RELEASE_SAFELY(BackView);
		
		TTView *BackViewSelected = [[TTView alloc] initWithFrame:[self frame]];
		self.selectedBackgroundView = BackViewSelected;
		TT_RELEASE_SAFELY(BackViewSelected);

		// Set the built-in text label properties here
		self.textLabel.backgroundColor = [UIColor clearColor];
		// ... + more
	}
	return self;
}
```

Quick aside: be wary of setting built-in textLabel properties in the initWithStyle method if you're subclassing high-level cells such as TTTableImageItemCell, as these properties are changed in setObject. I spent several hours trying to track this down...

setObject is the method where you'll load your cell with data from the item.

```
- (void)setObject:(id)object {
  if (_item != object) {
    [super setObject:object];

    TCExampleItem* item = object;
    self.textLabel.text = item.firstName;
    self.detailTextLabel.text = item.lastName;
    self.suffixLabel.text = item.suffix;
    self.personPhotoImageView.image = TTImage(item.imageURL);
  }
}
```

Before we get knee-deep in layout, go ahead and create initializers for your other views.

```
- (UILabel*)suffixLabel {
  if (!_suffixLabel) {
    _suffixLabel = [[UILabel alloc] init];
    _suffixLabel.textColor = [UIColor blackColor];
    _suffixLabel.highlightedTextColor = [UIColor whiteColor];
    _suffixLabel.font = TTSTYLEVAR(suffixFont);
    [self.contentView addSubview:_suffixLabel];
  }
  return _suffixLabel;
}
```

Now for the hard part. Maybe. If you're using fixed height cells, it will be as easy as setting the frames of your views and going from there. In this case, your TTTableViewController will have the following in the initializer method:

```
self.tableView.rowHeight = TTSTYLEVAR(tExampleCellRowHeight);     // CGFloat
self.variableHeightRows = NO;
```

If you are using variable height rows, you've got your work cut out for you. The main reason you'll be using variable height rows is if you have dynamic text or other content that you don't know the size of. Start by setting variableHeightRows to YES in your TTTableViewController initializer (opposite of the code above). Next, add the following class method:
`+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)object {`
In essence you will be doing layout twice. The reason you have to do this is because the table needs to know how big each cell will be before it can create and lay out the cell. You can find more discussion on the Three20 Google Group, the main area for Three20 discussion thus far.

It's also difficult because this is a class method. The only information we get to work with is the cell's item and the tableView. In the instance method layoutSubviews, we'll get to work with the cell's instance variables.

In the future, I'll try to do a full example cell layout. Before you start this section, Lay out your cell in Photoshop or have a very good paper sketch of what you're going for. Otherwise, you'll be doing a lot of rework later on.

Use a static const to store your margins, or just use Three20's built in constants (variations of kTableCellVPadding, etc.). Work your way down vertically and add heights to a CGFloat. 

First, you'll need to calculate the maximum width of your text labels. Normally you'll only have one column to do this for. For example, this is from TTTableImageItemCell:
`  CGFloat maxWidth = tableView.width - (imageWidth + kTableCellHPadding*2 + kTableCellMargin*2);`

Add your vertical margins, then calculate what the label sizes will be using the NSString method sizeWithFont:

```
CGSize firstNameSize = [item.firstName sizeWithFont:TTSTYLEVAR(firstNameFont)
                               constrainedToSize:CGSizeMake(maxWidth, CGFLOAT_MAX)
                                   lineBreakMode:UILineBreakModeWordWrap];
totalHeight += firstNameSize.height
```

Once you've calculated the total height, return it and get ready to do it again.

In layout subviews, you'll do the same thing, only this time set the frames of all your views. Calculate the maxWidth again. Use maxWidth in sizeWithFont for each your views. Consult the TTTableImageItemCell source for a good (yet complicated) example of how to do this. This is also the place to set the styles of our cell backgrounds.

```
	[(TTView*)self.backgroundView setStyle:TTSTYLEVAR(tCellBackStyle)];
	[(TTView*)self.selectedBackgroundView setStyle:TTSTYLEVAR(tCellBackStyleSelected)];
```

Don't forget to implement prepareForReuse. Here you'll want to remove the content you added in setObject, but don't release the objects.

<h2>Connecting the Item and Cell</h2>

The last thing we need to do is connect the cell and the item. This is actually pretty easy. In your datasource, override the cellClassForObject method:

```
- (Class)tableView:(UITableView *)tableView cellClassForObject:(id)object {
    if([object isKindOfClass:[TCExampleItem class]])
        return [TCExampleCell class];
    else
        return [super tableView:tableView cellClassForObject:object];
}
```

If you have multiple cell types, add them in else ifs. This is where it comes in handy to have your own subclasses that match items to cells.

<h2>Conclusion</h2>

So that was a lot of information, and I know I glossed over quite a few things, but hopefully this gives you more of an idea of the benefits of using items and cells.

If anyone has any ideas for an example cell, let me know in the comments.

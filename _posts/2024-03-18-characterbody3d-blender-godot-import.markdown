---
layout: post
title: Importing and Auto-updating a CharacterBody3D from Blender into Godot 
date: 2024-03-18 18:17:22
image: /images/char-import-blender-init2.png
---

This is a quick guide related to Godot, Blender, and an auto-update import workflow between the two for rigged 3D characters with animation.

_I'm using Blender 4.0.2 and Godot 4.2.1. Your milage may vary with past and future versions of each._

Follow this tutorial: [Godot 4 / Blender - Third Person Character From Scratch](https://www.youtube.com/watch?v=VasHZZyPpYU).

**After the tutorial I assume you have the following in Blender:**

- A 3D modeled character with one mesh in one object
- ...parented to and rigged with an armature
- ...with one or more animation Actions

{% caption_img /images/char-import-blender-init.png %}
{% caption_img /images/char-import-blender-init2.png %}

**And the following in Godot:**

- An empty Godot project
- The Blender file from above in the same directory as your Godot project

{% caption_img /images/char-import-godot-init.png %}

The goal is to have a **CharacterBody3D-backed Scene** containing the **armature, mesh, and animations** from the Blender file, along with **other child nodes** like CollisionShape3D, AnimationTree, etc. and most importantly, be able to reasonably **add/modify parts of the Blender file** and have the Godot Scene **live autoupdate**.

## Blender setup

The Blender file setup is nearly identical to that of the [YouTube tutorial](https://www.youtube.com/watch?v=VasHZZyPpYU) with a few small details:

- If you have multiple animations (Actions), and they have different lengths, set "Manual Frame Range" in the Action properties bar to the proper start/end times. The file-wide start/end times should be longer than the longest animation time.
    {% caption_img /images/char-import-manual-frame-range.png %}

- Ensure frame rate is set to 30 fps. This is not strictly necessary if you know what you're doing, but it's the Godot default so if you're not particular, use 30.
    {% caption_img /images/char-import-manual-fps.png %}

## Godot setup

There are 2 important steps:

- Setting the node type in Advanced Import Settings
- Creating an Inherited Scene

### Setting the node type in Advanced Import Settings

1. In your Godot project, double click the `.blend` file in the FileSystem pane in the bottom left to open the Advanced Import Settings Window.
    {% caption_img /images/char-import-godot-01.png %}

2. In the right panel, change `Root Type` to CharacterBody3D. Optionally, change the Root Name to e.g. "Player".
    {% caption_img /images/char-import-godot-02.png %}

3. Click the Reimport button at the bottom of the window.
    {% caption_img /images/char-import-godot-03.png %}

_Why change Root Type in Advanced Import Settings?_ If you use `Change Type...` by right clicking the root node within the Inherited Scene, Godot will break the Scene's connection with the Blender file and changes from Blender will no longer be reflected in the Scene.

### Creating an Inherited Scene

1. Right click on the `.blend` file in the FileSystem pane. Click New Inherited Scene. This will create and open an `[unsaved]` scene.
    {% caption_img /images/char-import-godot-04.png %}

2. Notice that the nodes below the root are yellow instead of white indicating that they are linked to the Blender file. If these change to white at any point, you've probably lost the connection between the Blender file.
    {% caption_img /images/char-import-godot-05.png %}

3. Add any additional nodes to the root.
    {% caption_img /images/char-import-godot-06.png %}

4. Go back to the Blender file and try making a change like adding an animation Action. Save it and return to Godot.
    {% caption_img /images/char-import-godot-07.png %}

5. Check the new Action is shown in the AnimationPlayer.
    {% caption_img /images/char-import-godot-08.png %}

## Other notes

- Start by simply instancing Blender files directly in the scene(s) they'll being used. Only create an Inherited Scene (as shown in this post) when you need to add sibling or child nodes, or change the type of the root node.
- It's still possible (although perhaps discouraged) to change attributes of the yellow-colored nodes imported from Blender in the scene's node tree, such as `Transform`.
- I'm not a seasoned Blender/Godot/game developer, so if you find any inaccuracies in this post, please [contact me](/about).
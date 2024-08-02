---
layout: post
title: Indie Game Devlog 04 - Animating Faces
date: 2024-04-01 23:00:00
image: /images/devlog04-07.jpg
tags: indiegame
---

Last time, I'd prototyped a 3D character with an idle and walk animation.

Next, I wanted to prototype face animations.

## Finding the balance in character expression

My game is going to be heavily narrative focused. Meaning I need to tell a good story where the player can quickly connect and empathize with the characters.

Of course you can tell a good story through words alone (a novel) or actions alone (a silent movie). But many media use a balance of the two.

I need to find a balance that supports my story, but is also feasible for a solo developer with my level of experience making a game at this scale.

What does balance mean? What are my options?

- At the low end of fidelity, we have games that have either no faces or a face with a static expression.
- In the middle, we have games with no lip-syncing (or even voice acting), but still a library of facial expressions that match the tone of the current dialogue. Example: The Legend of Zelda - Ocarina of Time.
- At the high end of fidelity, we have AAA games with fully rigged character faces that have fully motion captured or hand-animated lip-syncing for both cut-scenes and gameplay. Example: The Last of Us.

{% caption_img /images/devlog04-01.jpg Saria from Ocarina of Time changes her facial expression to match her written dialogue. There's limited animation between expressions, with blinking being an exception. %}

## My goal: scripted expressions

I'd like to shoot for something similar to the medium fidelity, like Ocarina of Time.

- Make a library of a dozen or so facial expressions per character.
- Don't bother with animating between expressions.
- Support a limited set of looping animations like blinking.
- Allow specific animations to be triggered from the script that contains the dialogue.
- Don't bother with full voice acting.

As great as it'd be to have full voice acting and lip sync, I'm confident it would be way too ambitious.

Even having a dozen facial expressions may be overly ambitious for the number of characters I'm already planning. That's part of what I wanted to find out at this stage of prototyping.

## Options for faces

Since I've yet to decide on an aesthetic for my character/environment art, it's still possible for me to adapt the character style to the difficulty of implementation. In a world with infinite resources the art could 100% drive the implementation, but that's not the world I currently inhabit.

I need full access to change any character's facial expression from the game engine at any time. Identifying all the levers in Godot that allow me to do so is also part of this exploration.

There are 3 art/implementation pairs that fulfill the target requirements I listed above:

### 1. Independent 2D textures projected on static 3D face geometry

This option shrinkwraps a bitmap 2D texture onto the 3D model. All faces can be on one texture like a sprite sheet, or as separate textures that are swapped in and out.

Most characters from Ocarina of Time have faces like this, although noses and ears are usually part of the base model.

{% caption_img /images/devlog04-02.jpg w400 Saria from Ocarina of Time has a bitmap 2D face texture %}

### 2. Independent 3D geometry for each facial expression

This option adds a separate object for each expression on top of the main face/body geometry. Only one object is displayed at a time. The style is similar to (1), but the implementation is different and the 3D geometry allows the face to participate in lighting.

This is the way I modeled Dory.

{% caption_img /images/devlog04-10.jpg Dory has 3D face geometry for its eyes and mouth, but the vertices do not morph and they are not integrated into the main body. They even cast shadows onto the main body. %}

### 3. Single 3D geometry that morphs for each facial expression

This option produces the most "realistic" results. The face will deform the way a human face does.

The downsides are that a humble face rig can take lots of time and expertise to set up, having more control points requires more time spent animating, and it's easy to fall into the uncanny valley where the character looks creepy and unsettling.

The upside is that the current tools for executing this style are well tailored to the job. This even includes live video motion capture from a smartphone that can drive an animated rig.

I found a solo indie dev working on a game called Farewell North who talks about implementing this kind of facial animation [in this devlog](https://www.youtube.com/watch?v=fkB3tK6zZSo).

An easy example is The Last of Us. [A demo from 2013](https://www.youtube.com/watch?v=myZcUvU8YWc) shows some behind the scenes materials on the rigging process.

{% caption_img /images/devlog04-03.jpg The Last of Us like most AAA games targets realism with a full face rig %}

## Independent expressions

At the moment, I'm leaning towards (1) or (2). I'm not confident enough in my character modeling skills or my art direction or time/effort estimation skills to gamble with the downsides of (3).

Designing independent expressions lends itself to stylization, and therefore it may be easier for me to avoid the uncanny valley when eventually finalizing my character designs.

The next decision is whether to use 2D or 3D.

I'm drawn towards the look of 3D, so I decided to explore that implementation first.

## Implementing 3D independent expressions

I started by modeling opened eyes and closed eyes in two separate objects.

{% caption_img /images/devlog04-04.jpg Open and closed eyes, with simple geometry and modifiers added %}

For a simple case like this, using the same object/mesh and using a shape key to tween between open and closed would definitely be possible. However, for the more complicated expressions I'm planning for, deforming a single mesh isn't going to cut it.

I realized quickly that these eye objects needed to be parented and weighted to the existing armature in order to follow the head with its existing idle animation.

As separate meshes, the opened and closed eyes appear in Godot's scene tree automatically.

{% caption_img /images/devlog04-05.jpg h200 Access to objects in the imported Godot scene %}

That means I can reference them in code and turn them on and off with a code snippet.

```gdscript
func toggleEyeBlink():
    $Armature/Skeleton3D/eye_blink.visible = !$Armature/Skeleton3D/eye_blink.visible
    $Armature/Skeleton3D/eye_neutral.visible = !$Armature/Skeleton3D/eye_neutral.visible
```

For testing purposes, I rotated the player model towards the camera and triggered toggling the eye open and close with the existing action button (spacebar).

<video src="/images/devlog04-06.mp4" controls loop width="100%"></video>

Awesome. I've got full manual control over eye meshes. From here it's reasonable to see how expanding this could work:

- I add a bunch more eye shapes as separate objects.
- I add a bunch of mouth shapes as separate objects.
- I create some helpers in code to associate a facial expression with all but one eye object and all but one mouth object visible.
- I trigger a named facial expression from the dialogue script.

## Blender/Godot integration woes

There's a missing piece in the above plan though, and it has to do with Blender integration.

The idle and walk animations are defined on the Blender side and imported into Godot in an AnimationPlayer node.

It's easy to imagine wanting a looping "blink" animation that alternates between opened and closed eyes. So I tried to imagine how I'd implement that animation in Blender. It's surprisingly convoluted! And it's exposing my lack of fundamental understanding of both Blender and Godot.

The first problem is animating visibility. The eye_open object needs to disappear when the eye_closed object appears and vice-versa. If I want to keep all my animations source-of-truth in Blender, I've identified these options:

1. **Scale the object to a near-zero value.** This is not a robust solution for several reasons: Some modifiers will break the geometry, it's not as ergonomic as just having a single boolean, and the rendering engine still needs to account for the scaled-down geometry.
2. **Use the object visibility setting.** This would my preferred option, but it's not possible. In Blender there's a toggle for viewport visibility and render visibility. And it's animatable. It requires changing an import setting in Godot for the blend file under "Blender > Nodes > Visible" to "Renderable". However, this only applies during the import process, so the object in question is either imported or ignored. The setting is not read after import, including during animation.
3. **Move the "hidden" mesh inside the head.** Reasonable, but requires setting up shape keys for every object, and potentially taking a performance hit.
4. **Move the "hidden" mesh far off screen.** This has the benefit of presumably being able to participate in the Godot renderer's automatic distance culling [mesh level of detail](https://docs.godotengine.org/en/stable/tutorials/3d/mesh_lod.html) (LOD) system, and therefore avoid the performance hit. But still makes the animation process unergonomic.
5. **Set the material to transparent.** Might not play nice with whatever material or shader I choose. Presumably takes a performance hit.
6. **Enforce all eyes use the same number of vertices.** This would allow me to use Blender's shape keys as designed. However, it imposes serious limitations on the art style, including using different colors. Modeling all potential eye shapes would end up being a puzzle beyond my current skillset.

Not only does the problem of visibility have no clear solution, but the animation process itself within Blender is not as straightforward as the existing armature animation:

- The separate eye_open and eye_closed objects will have separate animation Actions in Blender. This means I need to create two separate but mirroring animation timelines that toggle the visibility. But I can't even see them on the same dope sheet.
- The bigger problem is that animation actions are only imported from one object. In my case it's the armature. Actions attached to other objects are ignored by Godot. This would require more research to understand its limitations.
- From some investigation, it seems as if the right way to handle this kind of animation is to make a driver system or another armature that combines the eye_open and eye_closed visibility behavior into one parameter. It may require putting all the eye meshes into the single body object. This is all beyond my current understanding of Blender.

{% caption_img /images/devlog04-09.jpg Trying to set up a blinking animation in Blender via the render visibility property. Shown is only one half of the animation. It's not very ergonomic. %}

## Solution: all face animations in Godot

To reduce complexity, I'd prefer to keep all animations Blender. That way, I could continue to use Blender's superior tooling and I wouldn't have to keep track of which program contains which animation.

But in this case, it seems like I've eliminated all the convenient and sustainable options of using Blender for face animations.

My primary use case is going to be triggering facial expression changes from the dialogue. It's the more rare secondary use case of looping animations like blinking that I'm currently investigating. So maybe keeping all face animations within Godot is the least complex strategy after all.

I'm already confident I know how I'd implement facial expression changes from the dialogue in Godot. But I'm not clear on how I'd author animations in Godot on the imported Blender object and have them play nicely with the existing animation from Blender. For example, how do I keep a walk cycle loop going while also having a blink cycle loop with a different frame length?

AnimationTree, Godot's node for combining various animations from an AnimationPlayer, is tied to one AnimationPlayer. The AnimationPlayer it's currently tied to is imported from Blender as read-only. The whole point of AnimationTree is to assist in blending and transitioning between multiple animations, so having more than one is an anti-pattern. However, in this case, since my face animations are completely separate from the body animations, I think it should be okay.

And although I originally thought a second AnimationTree would be required specifically for face animations, I now realize that a second AnimationPlayer alone may be fine in my case. After all, in theory most things that AnimationPlayer and AnimationTree do can be accomplished with raw code (if not very verbosely). The way I see it, I can switch between static face objects (like a frown) and cyclical animations (like a blink cycle) in single function driven by the dialogue script. This would only require a single AnimationPlayer with all the animations configured ahead of time. It wouldn't require an AnimationTree at all.

{% caption_img /images/devlog04-07.jpg Configuration of the blink animation directly in Godot using the separate eye objects from Blender %}

The blinks are automatic on a loop in the demo below.

<video src="/images/devlog04-08.mp4" controls loop preload="none" width="100%"></video>

OK, so this strategy seems pretty reasonable taking into account my current constraints. It's a shame I can't use Blender, but in the end, I have to use all the flexibility available to me to my advantage and not be afraid to commit to making my own systems and tools.

A lingering question is whether I can easily reuse an AnimationPlayer node for the player and all NPCs if all meshes have face objects with the same names. Similarly, how can I reuse code to accept a facial expression name and update the face of the relevant character.

## Next steps

- NPCs represent a crucial concept that's both the same (interactions, face shapes) and different (names, appearances) from existing code/assets. Although I don't want to spend time designing and modeling details of every character yet, I do want to make sure that I understand how to set up NPCs so that I can share the similar bits while allowing enough configuration to support the differing bits. That includes their similarities to both the player character and one another.
- I'd like to explore materials and shaders again. I've been doing a little more aesthetics research and have a few styles I'd like to try.
- Designing the conversation experience – basically the view and interaction patterns while two characters are speaking – is important enough to the overall experience that it deserves its own prototypes.

Sidenote: this is the first post of the devlog series where I was writing while actively experimenting, so please excuse the past/present tense changes.

Until next time.

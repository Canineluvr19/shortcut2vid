# shortcut2vid
ffmpeg wrapper to take images via shortcuts, and create an mp4 video. 
Automatically sorts the images by the LastWriteTime

# Workflow:
- Create a folder, name it something memorable (project/character/whatever)
- Select all the images (from img2img or from anywhere really) that are going to be a part of this video.
- Right click + drag into the newly created empty folder. A context menu will pop up; select "Create Shortcuts Here" option.

# Parameters
- -path
  - [default = "."]
  - Path to shortcut folder of all the image shortcuts
- -framerate
  - [default = 10]
  - [int] Frame rate of output video
- -output_name
  - [default = "ffmpeg_created"]
  - name of the generated video
- -resolution
  - [default = resolution of the second to last unique seen resolution from the images, or if only one is seen, then that]
  - Generating 512x512, 1024x1024, and 2048x2048 images would pick 1024x1024 as the "default"
  - This assumes a workflow of generating lowest res images first, then upsizing for deatails before doing a final upsizing render.

# Example
```
videos\
  shortcut2vid.ps1
  egypt\
    [all the shortcuts to images go here]
```
From the "videos\" path, the command to generate the movie would be:
```
shortcut2vid.ps1 -path egypt\ -output_name egypt
```
Would create a "egypt.mp4" video in the "videos\" directory.

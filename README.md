# 2D Cellular Automata Based on Conway's Game of Life Visualised Using CUDA & OpenGL Interoperability
- Colour Enhancements
- Zoom in,zoom out options
- Move around the world using mouse
- Play god, kill or spawn cells.
- See this post for more: https://steemit.com/life/@bazmus/what-is-cellular-automata-playing-god-in-the-world-you-create-steemit-special
# Compiling and Running
- Clone this project in to visual studio and open the solution
- Copy all the contents in the GL directory to your Windows\system32 or/and Windows\sysWOW64 directories.
- After importing to visual studio, right click on the project selecto properties then choose linker to add a dependency. Please change the "Additional Library Directories" pointing GL directory to your GL directory. Otherwise the program won't compile. 
- Set your world parameters before compiling by changing PanelH and PanelW. Default is 500x500 with 500 generations.
- Compile and run 

Low end devices may not support tcompstart for worlds larger than 500x500 meaning that the framerate will be significantly low
# Algorithm Flowchart
![Algorithm Flowchart](https://github.com/karusb/2DCA-CUDA/raw/master/2DCAFlow1.jpg)
![Algorithm Flowchart2](https://github.com/karusb/2DCA-CUDA/raw/master/2DCAFlow.jpg)

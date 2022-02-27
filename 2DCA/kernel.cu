#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdlib.h>  
#include <stdio.h>
#include <time.h>
#include <string>
#include <sstream>
#include "..\GL\glew.h"
#include "..\GL\freeglut.h"
#include "cuda_gl_interop.h"

// MANUALLY EDIT BELOW 
#define PanelW 500		// Texture Width
#define PanelH 500		// Texture Height
//#define ZeroBoundary		//if defined its only zero boundary at the 4 edges that defines the viewport
//

#include "Globals.hpp"
#include "GLCallbacks.hpp"
#include "HostFunctions.hpp"
#include "CudaHelpers.hpp"
#include "CellularAutomata.cuh"
//
/// CPUInsertGPU: Inserts a cell for the given location on the CPU and passes to GPU
/// Inputs: world width,height,window position of the chosen cell int2(x,y), pointer to CPU memory of the grid
/// IMPORTANT TODO : Location of the inserted cell is not accurate need to implement correct location scaling from window to texture
static void CPUInsertGPU(unsigned int WorldW, unsigned int WorldH, int2 i_loc, bool* CAGrid)
{
	float scalew = newpanelw / WorldW;
	float scaleh = newpanelh / WorldH;
	int myid = 0;
	if (scalew > 2.0 && scaleh > 2.0)
		myid = (i_loc.x / float(newpanelw / WorldW)) + (i_loc.y / float(newpanelh / WorldH)) * WorldW;
	else
		myid = i_loc.x + i_loc.y * newpanelw;
	if (myid <= WorldW * WorldH && myid > 0)CAGrid[myid] = !CAGrid[myid];
}

cudaError_t CudaCAHelper(bool *CAGrid, bool *NextCAGrid, unsigned int size, unsigned int WorldH, unsigned int WorldW, int*argc, char**argv);

///	OpenGLHelper: Initialises texture buffers i
/// Inputs: width and height of the texture
static void OpenGLHelper(unsigned int width,unsigned int height)
{
	glGenTextures(1, &GLtexture);
	glBindTexture(GL_TEXTURE_2D, GLtexture);
	// set basic parameters
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

	// Create texture data (4-component unsigned byte)
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, d_texturedata);

	// Unbind the texture
	glBindTexture(GL_TEXTURE_2D, 0);

	glGenBuffers(1, &GLbufferID);
	glBindBuffer(GL_PIXEL_UNPACK_BUFFER, GLbufferID);
	glBufferData(GL_PIXEL_UNPACK_BUFFER, width * height * sizeof(uchar4), d_bufferdata, GL_STREAM_COPY);
	
	cudaError result = cudaGraphicsGLRegisterBuffer(&cudaPboResource, GLbufferID,
		cudaGraphicsMapFlagsWriteDiscard);
}
/// initGLUT: Initialises GLUT window
/// Inputs: Main function arguments argc,argv then window width,height
static bool initGLUT(int* argc, char** argv, unsigned int width,unsigned int height) {
	glutInit(argc, argv);  // Create GL context.
	glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE);
	glutInitWindowSize(width, height);
	glutCreateWindow("2Dimensional Cellular Automata (Conways Game of Life)");

	glewInit();

	if (!glewIsSupported("GL_VERSION_2_0")) {
		printf( "ERROR: Support for necessary OpenGL extensions missing.\n");
		return false;
	}

	glutReportErrors();
	return true;
}

/// GLUT : displayfunc : Called everytime when screen update is called through GLUT, runs majority of the code as well as the CUDA kernels,
/// All of the global control variables are checked here
void displayfunc()
{
	int WorldW = PanelW;
	int WorldH = PanelH;
	dim3 kernelwsize(WorldW, WorldH);
	dim3 kernelbsize(1);

	glClear(GL_COLOR_BUFFER_BIT); //Clear color buf

	if(cont)
		NextGenKernel << <kernelwsize, kernelbsize >> > (d_CAGrid, d_next_CAGrid, WorldH, WorldW); // NextGeneration Kernel adds neighbours and sets nextCA grid

	cudaDeviceSynchronize();
	if(cont)
		std::swap(d_CAGrid, d_next_CAGrid); //Swaps the values of both pointers

	// cudaDeviceSynchronize waits for the kernel to finish, and returns
	// any errors encountered during the launch.
	if (resetlife || fullresetlife)
	{
		if(resetlife)
			CPUGridInitRand(WorldW, WorldH, h_CAGrid, 5);
		if(fullresetlife)
			CPUGridInitFullRand(WorldW, WorldH, h_CAGrid);

		CudaReportOnError(
			cudaMemset(d_CAGrid, 0, sizeof(d_CAGrid)), CACudaAction::Memset); // reset the current grid

		CudaReportOnError(
			cudaMemcpy(d_CAGrid, h_CAGrid, WorldH * WorldW * sizeof(bool), cudaMemcpyHostToDevice), CACudaAction::DeviceCopy);

		CudaReportOnError(
			cudaMemset(d_next_CAGrid, 0, sizeof(d_next_CAGrid)), CACudaAction::Memset); // reset the next grid

		resetlife = false;
		fullresetlife = false;
	}
	if (givelife)
	{
		CudaReportOnError(
			cudaMemcpy(h_CAGrid, d_CAGrid, WorldH * WorldW * sizeof(bool), cudaMemcpyDeviceToHost), CACudaAction::HostCopy);

		CPUInsertGPU(WorldW,WorldH, loc2, h_CAGrid);

		CudaReportOnError(
			cudaMemcpy(d_CAGrid, h_CAGrid, WorldH * WorldW * sizeof(bool), cudaMemcpyHostToDevice), CACudaAction::DeviceCopy);

		givelife = false;
	}
	if(cont)
		evolution_number++;

	CudaReportOnError(
		cudaGraphicsMapResources(1, &cudaPboResource, 0), CACudaAction::GraphicsResourceMap);

	size_t num_bytes;
	CudaReportOnError(
		cudaGraphicsResourceGetMappedPointer((void**)&GLout, &num_bytes, cudaPboResource), CACudaAction::GraphicsResourceMap, "Texture mapping error: ");

	GLKernel << < kernelwsize, kernelbsize >> > (GLout, d_CAGrid,d_next_CAGrid, WorldH, WorldW,lifecontrol); //Fills GL texture with CA data
																							
	CudaReportOnError(
		cudaGraphicsUnmapResources(1, &cudaPboResource, 0), CACudaAction::GraphicsResourceUnmap); //unmap resource memory
	 
	drawTexture(WorldW, WorldH); // call texture draw function

	glutSwapBuffers(); //swap back buffer with front buffer

	glFlush();
	if (evolutioncontrol)
		glutPostRedisplay(); //for consecutive frame update hence evolution if set
}

int main(int argc,char** argv)
{
	// BEGIN INFO
	printf("Starting GLUT main loop...\n");
	printf("Press [r] to reset the view to a randomized board \n")  ;
	printf("Press [f] to reset the view to a fully randomized board \n");
	printf("Press [ESC] to exit \n" ) ;
	printf("Press the [+] key to zoom in \n")  ;
	printf("Press the [-] key to zoom out \n")  ;
	printf("Press the [up arrow] to move up \n")  ;
	printf("Press the [down arrow] to move down \n")  ;
	printf("Press the [left arrow] to move left \n")  ;
	printf("Press the [right arrow] to move right \n")  ;
	printf("Press the [l] key to switch between colour and colourless \n")  ;
	printf("Press the [space] bar to stop evolution \n")  ;
	printf("Press the [e] key to evolve consecutively \n");
	printf("Press the [d] key to activate mouse functions \n");
	printf("MouseWheelUp = zoom+ - MouseWheelDown = zoom- \n");
	printf("MouseLeftClick and Drag to change viewing position \n");
	printf("MouseRightClick = Spawn or Kill a cell at the mouse location \n");

///// BEGIN GRID INIT
	CPUGridInitLine(WorldW, WorldH, h_CAGrid, 5);
//////
// 	
	// CUDA&GLUT Initialise Function
	cudaError_t cudaStatus = CudaCAHelper(h_CAGrid, h_next_CAGrid, WorldSize, WorldH, WorldW, &argc, argv);
	
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "CudaCAHelper failed!  CUDA Failure");
        return 1;
    }
	printf("----------------------------");

    // cudaDeviceReset must be called before exiting in order for profiling and
    // tracing tools such as Nsight and Visual Profiler to show complete traces.
	CudaReportOnError(
		cudaDeviceReset(), CACudaAction::Reset);

    return 0;
}

/// CudaCAHelper : Allocates Memory for CAGrid and NextCAGrid on GPU for given size
/// Inputs : Pointer to current CAGrid, pointer to NextCAGrid, world size (w*h), world height,width, required generations
cudaError_t CudaCAHelper(bool *CAGrid, bool *NextCAGrid, unsigned int size,unsigned int WorldH,unsigned int WorldW, int*argc,char**argv)
{
	dim3 kernelwsize(WorldW, WorldH);
	dim3 kernelbsize(1);
	cudaError_t status;
	cudaDeviceProp myCUDA;
	status = CudaReportOnError(
		cudaGetDeviceProperties(&myCUDA, 0), CACudaAction::GetProperty, "Is there Nvidia GPU Present?");

	if (status != cudaSuccess)
		return status;

	printf("Using device %d:\n", 0);
	printf("%s; global mem: %dB; compute v%d.%d; clock: %d kHz\n",
		myCUDA.name, (int)myCUDA.totalGlobalMem, (int)myCUDA.major,
		(int)myCUDA.minor, (int)myCUDA.clockRate);
	printf("Max Threads %d", myCUDA.maxThreadsPerBlock);
    
	// Allocate GPU buffers for three vectors (two input, one output).
	status = CudaReportOnError(
		cudaMalloc((void**)&d_CAGrid, sizeof(bool) * size), CACudaAction::Allocation, "First Grid");
	status = CudaReportOnError(
		cudaMalloc((void**)&d_next_CAGrid, sizeof(bool) * size), CACudaAction::Allocation, "Second Grid", [&]() { cudaFree(d_CAGrid); });

	if (status != cudaSuccess)
		return status;

	initGLUT(argc, argv, WorldW, WorldH);
	gluOrtho2D(0, WorldW, WorldH, 0); // Viewport
	glutKeyboardFunc(keyboard);		//keyboard press func
	glutSpecialFunc(handleSpecialKeypress); //arrow keys
	glutMouseFunc(mouseCall);		// mouse clicks
	glutMotionFunc(mouseMove);		// mouse motion
	glutReshapeFunc(reshape);		// windows reshape function
	glutDisplayFunc(displayfunc);	//Display function
	OpenGLHelper(WorldW, WorldH);	//Texture and Buffer bind

	status = CudaReportOnError(
		cudaSetDevice(0), CACudaAction::SetDevice, "Device Id 0", [&]() { cudaFree(d_CAGrid); cudaFree(d_next_CAGrid); });

    // Copy input vectors from host memory to GPU buffers.
	status = CudaReportOnError(
		cudaMemcpy(d_CAGrid, CAGrid, size * sizeof(bool), cudaMemcpyHostToDevice), CACudaAction::DeviceCopy);

	// BEGIN MAIN GLUT LOOP
	glutMainLoop();
	//
    // Copy output vector from GPU buffer to host memory.
	status = CudaReportOnError(
		cudaMemcpy(CAGrid, d_CAGrid, size * sizeof(bool), cudaMemcpyDeviceToHost), CACudaAction::HostCopy);

	// FREE ALLOCATED MEMORY ON LOOP EXIT
	cudaFree(d_CAGrid);
	cudaFree(d_next_CAGrid);
	cudaGraphicsUnregisterResource(cudaPboResource);
	glDeleteBuffers(1, &GLbufferID);
	glDeleteTextures(1, &GLtexture);
    return status;
}


#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdlib.h>  
#include <stdio.h>
#include <algorithm>
#include <time.h>
#include <string>
#include <sstream>
#include <GL\glew.h>
#include <GL\freeglut.h>
#include "cuda_gl_interop.h"


// MANUALLY EDIT BELOW 
#define PanelW 500		// Texture Width
#define PanelH 500		// Texture Height
#define GENS 500		// number of generations to time 
#define tcompstart false	 // starts timing CPU before using GPU for given GENS
//#define ZeroBoundary		//if defined its only zero boundary at the 4 edges that defines the viewport
//



#include "Header.h"
#define nCPUGRAPHICS
#define HEURISTICS


//BEGIN GLOBAL VAR
cudaGraphicsResource* cudaPboResource = nullptr;
GLuint GLtexture;
GLuint GLbufferID;
uchar4 *d_texturedata = nullptr;
uchar4 *d_bufferdata = nullptr;
uchar4 *GLout = nullptr;
bool *d_CAGrid = nullptr;
bool *d_next_CAGrid = nullptr;
bool *tempgrid = nullptr;
int evolution_number = 0;
float totalGPUtime = 0.0;
//
cudaError_t CudaCAHelper(bool *CAGrid, bool *NextCAGrid, unsigned int size, unsigned int WorldH, unsigned int WorldW,unsigned int gen,int*argc,char**argv);
/*
__device__ int NeighboursEval(bool *CAGrid, int x, int y,int WorldH,int WorldW)
{

	const unsigned int pos = (y*WorldW) + x;
	const unsigned int colup = x + ( (y - 1)*WorldW);
	const unsigned int coldwn = x + ((y + 1)*WorldW);
	if (x >= 0 && y >= 0 && x <= WorldW && y <= WorldH)
	{
		return  CAGrid[pos + 1] +
		 CAGrid[pos - 1]+
		 CAGrid[colup - 1]+
		 CAGrid[colup]+
		 CAGrid[colup + 1]+
		 CAGrid[coldwn - 1]+
		 CAGrid[coldwn]+
		 CAGrid[coldwn + 1];
	}
	return 0;
}
__device__ int NeighboursEval_Global(bool *CAGrid, int GlobalID, int WorldH, int WorldW)
{

	unsigned int colup = GlobalID - ((blockIdx.y - 1)*blockDim.x);
	unsigned int coldwn = GlobalID + ((blockIdx.y + 1)*blockDim.x);
	if (GlobalID > 0 && (GlobalID < WorldH * WorldW) && (GlobalID < blockDim.y * blockDim.x))
	{
		return  CAGrid[GlobalID + 1] +
			CAGrid[GlobalID - 1] +
			CAGrid[colup - 1] +
			CAGrid[colup] +
			CAGrid[colup + 1] +
			CAGrid[coldwn - 1] +
			CAGrid[coldwn] +
			CAGrid[coldwn + 1];
	}
	return 0;
}
__device__ int getGlobalIdx()
{
	return blockIdx.x * blockDim.x * blockDim.y + threadIdx.y * blockDim.x + threadIdx.x;
}
__global__ void NextDumbKernel(bool *CAGrid, bool *NextCAGrid)
{
//int id = getGlobalIdx();
//int neighbours = 0;

}
*/
///	OpenGLHelper: Initialises texture buffers i
/// Inputs: width and height of the texture
void OpenGLHelper(unsigned int width,unsigned int height)
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

	//glBindBuffer(GL_PIXEL_UNPACK_BUFFER, 0);
	
	cudaError result = cudaGraphicsGLRegisterBuffer(&cudaPboResource, GLbufferID,
		cudaGraphicsMapFlagsWriteDiscard);


}
/// initGLUT: Initialises GLUT window
/// Inputs: Main function arguments argc,argv then window width,height
bool initGLUT(int* argc, char** argv,unsigned int width,unsigned int height) {
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
/// drawTexture: Iteratively called draw function referenced to GLUT
/// Inputs: Texture width,height
void drawTexture(unsigned int width,unsigned int height) {
	//glColor3f(1.0f, 1.0f, 1.0f);

	gluOrtho2D(0, width*(zoomFactor+1), 0, height*(zoomFactor+1));
	
	//else glViewport(0, 0, width, height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	//glPushMatrix();
	glViewport((loc.x ), (loc.y ), GLsizei(newpanelw*2*(zoomFactor)), GLsizei(newpanelh*2*(zoomFactor)));
	
	//gluPerspective(0, (width+loc.x) / (height+loc.y), GLdouble(loc.x/width), GLdouble(loc.y/height));
	//glTranslatef(loc.x, loc.y, 0);
	if (z1)
	{
		//gluOrtho2D(-(GLdouble)width * (GLdouble)zoomFactor, (GLdouble)width* (GLdouble)zoomFactor, -(GLdouble)height* (GLdouble)zoomFactor, (GLdouble)height* (GLdouble)zoomFactor);
		z2 = false;
		z1 = false;
		//glFlush();
	}
	if (z2)
	{
		z1 = false;
		z2 = false;
	}
	glScalef(zoomFactor, zoomFactor, 1); // scale the matrix
	//if(zoomFactor >= 1.8)glScalef(zoomFactor-0.8, zoomFactor-0.8, 1); // scale the matrix
	//glPopMatrix();
	//glMatrixMode(GL_MODELVIEW);
	//glLoadIdentity();
	

	glBindTexture(GL_TEXTURE_2D, GLtexture);
	//glBindBuffer(GL_PIXEL_UNPACK_BUFFER_ARB, GLbufferID);

	glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, 0);

	glEnable(GL_TEXTURE_2D);
	glBegin(GL_QUADS);
	glTexCoord2f(0.0f, 0.0f);
	glVertex2f(0.0f, 0.0f);
	glTexCoord2f(1.0f, 0.0f);
	glVertex2f(float(width), 0.0f);
	glTexCoord2f(1.0f, 1.0f);
	glVertex2f(float(width), float(height));
	glTexCoord2f(0.0f, 1.0f);
	glVertex2f(0.0f, float(height));


	/////// BELOW CODE DRAWS STRING BUT DOESNT WORK
	// TODO: Integrate string printing with Texture 
	//	glColor3f(1.0f, 1.0f, 1.0f);
	//	glMatrixMode(GL_PROJECTION);
	//	glPushMatrix();
	//	glLoadIdentity();
	//	gluOrtho2D(0, newpanelw, 0, newpanelh);
	//
	//	glMatrixMode(GL_MODELVIEW);
	//	glPushMatrix();
	//	glLoadIdentity();
	//	std::string inf;
	//	std::stringstream strstream;
	//#ifndef ZeroBoundary
	//	inf = "Cyclic World";
	//#else
	//	inf = "Zero Boundary"
	//#endif // !ZeroBoundary
	//		strstream << inf << " Evolution Stage: " << evolution_number;
	//	std::string allinf(strstream.str());
	//	glRasterPos2f(0, 0);
	//	//glWindowPos2i(603, 304);
	//	for (int i = 0; i < allinf.size(); ++i) {
	//		glutBitmapCharacter(GLUT_BITMAP_TIMES_ROMAN_24, allinf[i]);
	//	}
	//	glPopMatrix();
	//
	//	glMatrixMode(GL_PROJECTION);
	//	glPopMatrix();
	glEnd();
	glDisable(GL_TEXTURE_2D);
	//glBindBuffer(GL_PIXEL_UNPACK_BUFFER_ARB, 0);
	glBindTexture(GL_TEXTURE_2D, 0);



	//glPopMatrix();
	//printf("%f", zoomFactor); //DEBUG PURPOSE
	//glFlush();

}
/// CPUGridInitLine: Initialises a line of cells every 2 rows
/// Inputs: world width,height pointer to CPU memory of the grid which only fills given scale (real number >=1)
void CPUGridInitLine(unsigned int WorldW, unsigned int WorldH, bool *CAGrid, unsigned int scale)
{
	//IV
	int row = 0;
	unsigned int WorldSize = WorldH*WorldW;
	for (int i = 1 /*(WorldH/2)*WorldW*/; i < WorldSize - WorldH * 2; i++) //changed boundaries from 0 to worldsize to shown
	{
		//CAGrid[i] = rand() % 2;
		row = i / WorldW;
		if ((i > WorldW * row + WorldW / scale) && (i < WorldW*row + WorldW - WorldW / scale) && (i > WorldW  * (WorldW / scale)) && i < WorldH*WorldW - (((WorldH / scale))*WorldW)) // Magic Code That Defines Boundaries 
		{
			if (row % 2 == 0)CAGrid[i] = 1;

		}
		else CAGrid[i] = 0;
#ifdef CPUGRAPHICS
		if (i % WorldH == 0)
		{
			printf("\n");
		}
		printf("%d", CAGrid[i]);
#endif
	}
}
/// CPUGridInitRand: Initialises a line of random cells every 2 rows
/// Inputs: world width,height pointer to CPU memory of the grid which only fills given scale (real number >=1)
void CPUGridInitRand(unsigned int WorldW, unsigned int WorldH, bool *CAGrid, unsigned int scale)
{
	//IV
	int row = 0;
	unsigned int WorldSize = WorldH*WorldW;
	for (int i = 1 /*(WorldH/2)*WorldW*/; i < WorldSize - WorldH * 2; i++) //changed boundaries from 0 to worldsize to shown
	{
		//CAGrid[i] = rand() % 2;
		row = i / WorldW;
		if ((i > WorldW * row + WorldW / scale) && (i < WorldW*row + WorldW - WorldW / scale) && (i > WorldW  * (WorldW / scale)) && i < WorldH*WorldW - (((WorldH / scale))*WorldW)) // Magic Code That Defines Boundaries 
		{
			if (row % 2 == 0)CAGrid[i] = rand()%2;

		}
		else CAGrid[i] = 0;
	}
}
/// CPUGridInitFullRand: Initialises the grid with random cells (uses rand)
/// Inputs: world width,height pointer to CPU memory 
void CPUGridInitFullRand(unsigned int WorldW, unsigned int WorldH, bool *CAGrid)
{
	//IV

	unsigned int WorldSize = WorldH*WorldW;
	for (int i = 0 /*(WorldH/2)*WorldW*/; i < WorldSize; i++) //changed boundaries from 0 to worldsize to shown
	{
		CAGrid[i] = rand() % 2;
	}
}
/// CPUNeighbours: Calculates neighbours and perform evolution to the grid on CPU
/// Inputs: pointer to CPU memory of the grid, pointer to CPU memory of the next grid,world width,height
void CPUNeighbours(bool *CAGrid, bool *NextCAGrid, int WorldH, int WorldW)
{
	int neighbours;

	for(int i =0; i < (WorldH) * (WorldW) ; i++)
	{
		int colup = i - WorldW;
		int coldwn = i + WorldW;
		int leftn = i - 1;
		int rightn = i + 1;
		if (colup < 0)colup = WorldW*(WorldH - 1) + i;
		if (coldwn > WorldH*WorldW)coldwn = i - WorldW*(WorldH-1);
		if (leftn < 0)leftn = i + WorldW;
		if (rightn > WorldW)rightn = i - WorldW;

		neighbours = CAGrid[rightn] +
			CAGrid[leftn] +
			CAGrid[colup - 1] +
			CAGrid[colup] +
			CAGrid[colup + 1] +
			CAGrid[coldwn - 1] +
			CAGrid[coldwn] +
			CAGrid[coldwn + 1];


		// END OF NEIGHBOUR ADDITION


		if (CAGrid[i] == 1)
		{
			if (neighbours < 2)
			{
				NextCAGrid[i] = 0;
			}
			else if (neighbours > 3)
			{
				NextCAGrid[i] = 0;
			}
			else if (neighbours == 3 || neighbours == 2)
			{
				NextCAGrid[i] = 1;
			}
		}
		else
		{
			if (neighbours == 3) NextCAGrid[i] = 1;
		}
	}
	std::swap(CAGrid, NextCAGrid);
}
/// CPUInsertGPU: Inserts a cell for the given location on the CPU and passes to GPU
/// Inputs: world width,height,window position of the chosen cell int2(x,y), pointer to CPU memory of the grid
/// IMPORTANT TODO : Location of the inserted cell is not accurate need to implement correct location scaling from window to texture
void CPUInsertGPU(unsigned int WorldW,unsigned int WorldH ,int2 i_loc, bool *CAGrid)
{
	float scalew = newpanelw / WorldW;
	float scaleh = newpanelh / WorldH;
	int myid = 0;
	if (scalew > 2.0 && scaleh > 2.0)
		myid = (i_loc.x / float(newpanelw / WorldW)) + (i_loc.y / float(newpanelh / WorldH))*WorldW;
	else
		myid = i_loc.x + i_loc.y * newpanelw;
	if(myid <= WorldW*WorldH && myid>0)CAGrid[myid] = !CAGrid[myid];
}
/// CUDA : NextGenKernel : Calculates the neighbours of each cell and puts the new state of the cell in NextCAGrid
/// Inputs : Pointer to the current CAGrid, pointer to the nextCAGrid, world width,height.
__global__ void NextGenKernel(bool *CAGrid, bool *NextCAGrid,int WorldH,int WorldW)
{
	//int id = blockIdx.x * blockDim.x + threadIdx.x + (blockIdx.y*blockDim.y + threadIdx.y)* WorldH;
	int id = (blockIdx.y * gridDim.x + blockIdx.x); // GLOBAL CELL ID 
	int neighbours = 0; 
	//unsigned int WorldS = WorldH*WorldW; // World Size
	
	unsigned int colup = ((blockIdx.y - 1) * gridDim.x + blockIdx.x); //Upper Row of the Cell	 (block)
	unsigned int coldwn = ((blockIdx.y + 1) * gridDim.x +blockIdx.x); //Lower Row of the Cell (block)
#ifndef ZeroBoundary
	if (blockIdx.y == 0) colup = ((gridDim.y - 1) * gridDim.x + blockIdx.x); //Change Upper Row to lowest Row if the cell is on the first row
	if (blockIdx.y == gridDim.y-1) coldwn = blockIdx.x; // Change Lower Row to first row if the cell is on the last row
#endif

	// NON Working Mapping
	//unsigned int colup = id - ((blockIdx.y - gridDim.x)*gridDim.x);
	//unsigned int coldwn = id + ((blockIdx.y + gridDim.x)*gridDim.x);
	//unsigned int colup = ((id - (id%WorldW)) + WorldS - WorldW) % WorldS;
	//unsigned int coldwn = ((id - (id%WorldW)) + WorldW) % WorldS;
	//unsigned int colup = id - ((blockIdx.y - 1)*blockDim.x);
	//unsigned int coldwn = id + ((blockIdx.y + 1)*blockDim.x);
	

	if (id < (WorldH) * (WorldW) && id>=0 ) // Are we within the boundaries ? 
	{
		//neighbours = NeighboursEval_Global(CAGrid, id, WorldH, WorldW);
		
#ifdef ZeroBoundary // Uses this algorithm if zero boundary is defined




		if (colup <= 0)
		{ 
			if (id - 1 <= 0)
			{
				neighbours = CAGrid[id + 1] +
					CAGrid[coldwn] +
					CAGrid[coldwn + 1];

			}
			else if (id + 1 > PanelW)
			{
				neighbours = CAGrid[id - 1] +
					CAGrid[coldwn - 1] +
					CAGrid[coldwn] +
					CAGrid[coldwn + 1];
			}
			else
			{
				neighbours = CAGrid[id - 1] +
					CAGrid[id + 1] +
					CAGrid[coldwn - 1] +
					CAGrid[coldwn] +
					CAGrid[coldwn + 1];
			}
		}

		else if (coldwn > PanelH*PanelW)
		{
			if (id - 1 <= 0)
			{
				neighbours = CAGrid[id + 1] +
					CAGrid[colup - 1] +
					CAGrid[colup] +
					CAGrid[colup + 1];
			}
			else if (id + 1 > PanelW*PanelH)
			{
				neighbours = CAGrid[id - 1] +
					CAGrid[colup - 1] +
					CAGrid[colup] +
					CAGrid[colup + 1];
			}
			else
			{
				neighbours = CAGrid[id - 1] +
					CAGrid[id + 1] +
					CAGrid[colup - 1] +
					CAGrid[colup] +
					CAGrid[colup + 1];
			}
		}

		//else if (id - 1 <= 0)
		//{
		//	neighbours = CAGrid[id + 1] +
		//		
		//		CAGrid[colup] +
		//		CAGrid[colup + 1] +
		//		
		//		CAGrid[coldwn] +
		//		CAGrid[coldwn + 1];
		//}
		//else if (id + 1 > PanelW)
		//{
		//	neighbours = CAGrid[id - 1] +
		//		CAGrid[colup - 1] +
		//		CAGrid[colup] +

		//		CAGrid[coldwn - 1] +
		//		CAGrid[coldwn];
		//		
		//}
		else
		{

			neighbours = CAGrid[id + 1] +
				CAGrid[id - 1] +
				CAGrid[colup - 1] +
				CAGrid[colup] +
				CAGrid[colup + 1] +
				CAGrid[coldwn - 1] +
				CAGrid[coldwn] +
				CAGrid[coldwn + 1];

		}
		// END OF NEIGHBOUR ADDITION
#else // Cyclic Algorithm
		if (id == 0) // First block
		{
				neighbours = CAGrid[id + 1] +
					CAGrid[gridDim.x - 1] +
					CAGrid[colup - 1] +
					CAGrid[colup] +
					CAGrid[colup -gridDim.x] +
					CAGrid[coldwn - 1] +
					CAGrid[coldwn] +
					CAGrid[coldwn + 1];

		}
		else if (id == gridDim.x*gridDim.y - 1) // Last Block
		{

			neighbours = CAGrid[gridDim.x*gridDim.y -gridDim.x] +
				CAGrid[id - 1] +
				CAGrid[colup - 1] +
				CAGrid[colup] +
				CAGrid[colup + 1] +
				CAGrid[coldwn - 1] +
				CAGrid[coldwn] +
				CAGrid[coldwn + 1];
		}
		else if (id == gridDim.x*gridDim.y - gridDim.x) // Last Row First Block
		{
			neighbours = CAGrid[id + 1] +
				CAGrid[id - 1] +
				CAGrid[colup - 1] +
				CAGrid[colup] +
				CAGrid[colup + 1] +
				CAGrid[gridDim.x-1] +
				CAGrid[coldwn] +
				CAGrid[coldwn + 1];
		}
		else if (id == gridDim.x - 1)	//First Row Last Block
		{
			neighbours = CAGrid[id + 1]; +
				CAGrid[id - 1] +
				CAGrid[colup - 1] +
				CAGrid[colup] +
				CAGrid[colup - gridDim.x + 1] +
				CAGrid[coldwn - 1] +
				CAGrid[coldwn] +
				CAGrid[coldwn + 1];
		}
		else if (id == gridDim.x)	// Second Row First Block
		{
			neighbours = CAGrid[id + 1] +
				CAGrid[id - 1] +
				CAGrid[gridDim.x - 1] +
				CAGrid[colup] +
				CAGrid[colup + 1] +
				CAGrid[coldwn - 1] +
				CAGrid[coldwn] +
				CAGrid[coldwn + 1];
		}
		else
		{
			neighbours = CAGrid[id + 1] +
				CAGrid[id - 1] +
				CAGrid[colup - 1] +
				CAGrid[colup] +
				CAGrid[colup + 1] +
				CAGrid[coldwn - 1] +
				CAGrid[coldwn] +
				CAGrid[coldwn + 1];
		}
#endif // !ZeroBoundary

		if (CAGrid[id] == 1)
		{
			if (neighbours < 2)
			{
				NextCAGrid[id] = 0;
			}
			else if (neighbours > 3)
			{
				NextCAGrid[id] = 0;
			}
			else if (neighbours == 3 || neighbours == 2)
			{
				NextCAGrid[id] = 1;
			}
		}
		else
		{
			NextCAGrid[id] = 0;
			if (neighbours == 3) NextCAGrid[id] = 1;
			
		}
	}
}
/// CUDA : GLKernel : Sets the colour of the texture buffer given the correct inputs
/// Inputs: Pointer to the mapped texture , pointer to the current CAGrid, pointer to the next CAGrid, world width,height,2 state or 4 state choice
__global__ void GLKernel(uchar4 *d_buf,bool *CAGrid,bool *NextCAGrid, int WorldH, int WorldW,bool d_lifecontrol)
{
	int id = (blockIdx.y * gridDim.x + blockIdx.x);

	if (id < (WorldH) * (WorldW) && id >= 0)
	{
		if (d_lifecontrol)
		{

			if (CAGrid[id] == 1)
			{
				d_buf[id].w = 255;
				d_buf[id].x = 255;
				d_buf[id].y = 255;
				d_buf[id].z = 255;
			}
			if (CAGrid[id] == 0)
			{
				d_buf[id].w = 255;
				d_buf[id].x = 0;
				d_buf[id].y = 0;
				d_buf[id].z = 0;
			}
		}

		else
		{

			//d_buf[id].w = 255;
			////d_buf[id].x = 191;
			////d_buf[id].y = 173;
			//d_buf[id].x = 120;
			//d_buf[id].y = 113;
			//d_buf[id].z = 134;

			if (CAGrid[id] == 1 && NextCAGrid[id] == 1) //GETTING OLDER
			{
				d_buf[id].w = 255;
				d_buf[id].x = 22;
				d_buf[id].y = 78;
				d_buf[id].z = 146;
			}
			if (CAGrid[id] == 1 && NextCAGrid[id] == 0) // NEW BORN
			{
				d_buf[id].w = 255;
				d_buf[id].x = 255;
				d_buf[id].y = 255;
				d_buf[id].z = 255;
			}
			//if (CAGrid[id] == 0)	//DEAD
			//{
			//	d_buf[id].w = 255;
			//	d_buf[id].x -= 191;
			//	d_buf[id].y -= 173;
			//	d_buf[id].z -= 134;
			//}
			if (CAGrid[id] == 0 && NextCAGrid[id] == 1) // WAS ALIVE
			{
				d_buf[id].w = 255;
				d_buf[id].x = 146;
				d_buf[id].y = 22;
				d_buf[id].z = 129;
			}
			if (CAGrid[id] == 0 && NextCAGrid[id] == 0) // NO ONE
			{
				d_buf[id].w = 255;
				d_buf[id].x = 0;
				d_buf[id].y = 0;
				d_buf[id].z = 0;
			}

		}
	}
	
}
/// GLUT : displayfunc : Called everytime when  screen update is called through GLUT, runs majority of the code as well as the CUDA kernels,
/// All of the global control variables are checked here
void displayfunc()
{
	int WorldW = PanelW;
	int WorldH = PanelH;
	dim3 kernelwsize(WorldW, WorldH);
	
	dim3 kernelbsize(1);
	cudaEvent_t start, stop; //CUDA timing var
	float ms = 0.0;
	glClear(GL_COLOR_BUFFER_BIT); //Clear color buf
	if (timecompare && evolution_number <= GENS)
	{
		cont = true;
		evolutioncontrol = true;
		
	}
	else if (timecompare && evolution_number >GENS)
	{
		cont = false;
		evolutioncontrol = false;
		printf("Total GPU Time %f ms \n", totalGPUtime);
		timecompare = false;
	}


#ifdef HEURISTICS
		cudaEventCreate(&start);
		cudaEventCreate(&stop);
		cudaEventRecord(start, 0);
#endif
		if(cont)NextGenKernel << <kernelwsize, kernelbsize >> > (d_CAGrid, d_next_CAGrid, WorldH, WorldW); // NextGeneration Kernel adds neighbours and sets nextCA grid
		//NextDumbKernel << <kernelwsize, kernelbsize  >> > (d_CAGrid, d_next_CAGrid);//,d_WorldH,d_WorldW);
		// Check for any errors launching the kernel

#ifdef HEURISTICS
		//cudaThreadSynchronize();
		
		cudaEventRecord(stop, 0);
		cudaEventSynchronize(stop);
		cudaEventElapsedTime(&ms, start, stop);
		totalGPUtime += ms;
		if(!timecompare)printf(" Elapsed GPU Time: %f ms \n", ms);
#endif
		cudaDeviceSynchronize();
		if(cont)std::swap(d_CAGrid, d_next_CAGrid); //Swaps the values of both pointers
		// cudaDeviceSynchronize waits for the kernel to finish, and returns
		// any errors encountered during the launch.
		if (resetlife || fullresetlife)
		{
			bool *tempgrid = (bool *)calloc(WorldH*WorldW, sizeof(bool));
			if(resetlife)CPUGridInitRand(WorldW, WorldH, tempgrid, 5);
			if(fullresetlife)CPUGridInitFullRand(WorldW, WorldH, tempgrid);
			cudaMemset(d_CAGrid, 0, sizeof(d_CAGrid)); // reset the current grid
			if (cudaMemcpy(d_CAGrid, tempgrid, WorldH*WorldW * sizeof(bool), cudaMemcpyHostToDevice) != cudaSuccess) {
				fprintf(stderr, "cudaMemcpy failed!");
			}
			cudaMemset(d_next_CAGrid, 0, sizeof(d_next_CAGrid)); // reset the next grid
			free(tempgrid);
			resetlife = false;
			fullresetlife = false;
		}
		if (givelife)
		{
			bool *tempgrid = (bool *)calloc(WorldH*WorldW, sizeof(bool));
			if (cudaMemcpy(tempgrid, d_CAGrid, WorldH*WorldW * sizeof(bool), cudaMemcpyDeviceToHost) != cudaSuccess) {
				fprintf(stderr, "cudaMemcpy at display function for Device to Host failed!");
			}

			CPUInsertGPU(WorldW,WorldH, loc2, tempgrid);

			if (cudaMemcpy(d_CAGrid, tempgrid, WorldH*WorldW * sizeof(bool), cudaMemcpyHostToDevice) != cudaSuccess) {
				fprintf(stderr, "cudaMemcpy at display function for Host to Device failed!");
			}
			givelife = false;
		}
		if(cont)evolution_number += 1;
		if(!timecompare)printf("Evolution Stage %d", evolution_number);

	



	cudaGraphicsMapResources(1, &cudaPboResource, 0); // map memory
	size_t num_bytes;
	cudaError cudaStatus = cudaGraphicsResourceGetMappedPointer((void**)&GLout, // map to pointed texture
		&num_bytes, cudaPboResource);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "Resource Mapping Error: %s\n", cudaGetErrorString(cudaStatus));
		}
	//cudaGLSetGLDevice(0);
	GLKernel << < kernelwsize, kernelbsize >> > (GLout, d_CAGrid,d_next_CAGrid, WorldH, WorldW,lifecontrol); //Fills GL texture with CA data
																											 
	cudaGraphicsUnmapResources(1, &cudaPboResource, 0); //unmap resource memory
	drawTexture(WorldW, WorldH); // call texture draw function




	glutSwapBuffers(); //swap back buffer with front buffer

	//cudaMemset(d_next_CAGrid, 0, sizeof(d_next_CAGrid)); // reset the next grid
	glFlush();
	if (evolutioncontrol)glutPostRedisplay(); //for consecutive frame update hence evolution if set
	//glutPostRedisplay();


}
int main(int argc,char** argv)
{
    

	const int WorldW = PanelW;
	const int WorldH = PanelH;
	const int WorldSize = WorldH * WorldW;
	bool *CAGrid = (bool *)calloc(WorldSize , sizeof(bool)); // Allocate world 
	bool *next_CAGrid = (bool *)calloc(WorldSize, sizeof(bool));
	
	const int reqGens = GENS;
	// BEGIN INFO
	printf("Starting GLUT main loop...\n");
	printf("Press [r] to reset the view to a randomized board \n")  ;
	printf("Press [f] to reset the view to a fully randomized board \n");
	printf("Press [ESC] to exit \n" ) ;
	printf( "Press the [+] key to zoom in \n")  ;
	printf( "Press the [-] key to zoom out \n")  ;
	printf( "Press the [up arrow] to move up \n")  ;
	printf( "Press the [down arrow] to move down \n")  ;
	printf( "Press the [left arrow] to move left \n")  ;
	printf( "Press the [right arrow] to move right \n")  ;
	printf( "Press the [l] key to switch between colour and colourless \n")  ;
	printf( "Press the [space] bar to stop evolution \n")  ;
	printf("Press the [e] key to evolve consecutively \n");
	printf("Press the [d] key to activate mouse functions \n");
	printf("MouseWheelUp = zoom+ - MouseWheelDown = zoom- \n");
	printf("MouseLeftClick and Drag to change viewing position \n");
	printf("MouseRightClick = Spawn or Kill a cell at the mouse location \n");
	printf("Press the [t] key to activate timing mode for GPU for %d generations \n",GENS);


///// BEGIN GRID INIT
	CPUGridInitLine(WorldW, WorldH, CAGrid, 5);

//////
// BEGIN CPU NEIGHBOUR CALCULATION
#ifdef HEURISTICS
	clock_t start = clock(), diff;
	if(tcompstart)for (int k = 0;k < reqGens ; k++)CPUNeighbours(CAGrid, next_CAGrid, WorldH, WorldW);
	else CPUNeighbours(CAGrid, next_CAGrid, WorldH, WorldW);
	diff = clock() - start;
	int msec = diff * 1000 / CLOCKS_PER_SEC;
	printf("Time taken %d seconds %d milliseconds for CPU", msec / 1000, msec % 1000);
	if (tcompstart)CPUGridInitLine(WorldW, WorldH, CAGrid, 5);
#endif
	
	// CUDA&GLUT Initialise Function
	cudaError_t cudaStatus= CudaCAHelper(CAGrid, next_CAGrid, WorldSize,WorldH,WorldW,reqGens,&argc,argv);
	

	//glutSetOption(GLUT_ACTION_ON_WINDOW_CLOSE, GLUT_ACTION_CONTINUE_EXECUTION);
	
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "CudaCAHelper failed!");
        return 1;
    }
#ifdef CPUGRAPHICS
		for (int i = 0; i < WorldSize; i++)
		{
			if (i % WorldH == 0)
			{
				printf("\n");
			}
			printf("%d", CAGrid[i]);

		}
#endif
		printf("----------------------------");
		//system("CLS");

    // cudaDeviceReset must be called before exiting in order for profiling and
    // tracing tools such as Nsight and Visual Profiler to show complete traces.
    cudaStatus = cudaDeviceReset();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceReset failed!");
        return 1;
    }

    return 0;
}

/// CudaCAHelper : Allocates Memory for CAGrid and NextCAGrid on GPU for given size
/// Inputs : Pointer to current CAGrid, pointer to NextCAGrid, world size (w*h), world height,width, required generations
cudaError_t CudaCAHelper(bool *CAGrid, bool *NextCAGrid, unsigned int size,unsigned int WorldH,unsigned int WorldW,unsigned int gen,int*argc,char**argv)
{
    cudaError_t cudaStatus;
	dim3 kernelwsize(WorldW, WorldH);
	dim3 kernelbsize(1);

	cudaDeviceProp myCUDA;
	if (cudaGetDeviceProperties(&myCUDA, 0) == cudaSuccess)
	{
		printf("Using device %d:\n", 0);
		printf("%s; global mem: %dB; compute v%d.%d; clock: %d kHz\n",
			myCUDA.name, (int)myCUDA.totalGlobalMem, (int)myCUDA.major,
			(int)myCUDA.minor, (int)myCUDA.clockRate);
		printf("Max Threads %d", myCUDA.maxThreadsPerBlock);
	}
	//int threadsPerBlock = myCUDA.maxThreadsPerBlock;
	//int blocksPerGrid = (size + threadsPerBlock - 1) / threadsPerBlock;
    
	// Allocate GPU buffers for three vectors (two input, one output)    .
	/*bool *d_CAGrid; */cudaStatus = cudaMalloc((void**)&d_CAGrid, sizeof(bool) *size); // ALLOCATE THE SAME MEMORY SIZE AS CPU FOR GPU 

	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed with Grid! %d", cudaStatus);
		goto Error;
	}

	/*bool *d_next_CAGrid; */cudaStatus = cudaMalloc((void**)&d_next_CAGrid, sizeof(bool) *size); // ALLOCATE THE SAME MEMORY SIZE AS CPU FOR GPU
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed with nextGrid!");
		goto Error;
	}

	/// START GPU TIMING 
	if (tcompstart)
	{
		cudaEvent_t startgpu, stopgpu; //CUDA timing var
		float mstwo = 0.0;
		cudaEventCreate(&startgpu);
		cudaEventCreate(&stopgpu);
		cudaEventRecord(startgpu, 0);
		for (int i = 0; i < GENS; i++)NextGenKernel << <kernelwsize, kernelbsize >> > (d_CAGrid, d_next_CAGrid, WorldH, WorldW); // NextGeneration Kernel adds neighbours and sets nextCA grid
		cudaEventRecord(stopgpu, 0);
		cudaEventSynchronize(stopgpu);
		cudaEventElapsedTime(&mstwo, startgpu, stopgpu);
		printf(" Elapsed GPU Time: %f ms \n", mstwo);
		cudaMemset(d_CAGrid, 0, sizeof(d_CAGrid));
		cudaMemset(d_next_CAGrid, 0, sizeof(d_next_CAGrid));
		CPUGridInitLine(WorldW, WorldH, CAGrid, 5);
	}
	///

	initGLUT(argc, argv, WorldW, WorldH);
	gluOrtho2D(0, WorldW, WorldH, 0); // VIewport
	glutKeyboardFunc(keyboard);		//keyboard press func
	glutSpecialFunc(handleSpecialKeypress); //arrow keys
	glutMouseFunc(mouseCall);		// mouse clicks
	glutMotionFunc(mouseMove);		// mouse motion
	glutReshapeFunc(reshape);		// windows reshape function
	glutDisplayFunc(displayfunc);	//Display function set
	OpenGLHelper(WorldW, WorldH);	//Texture and Buffer bind
    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
        goto Error;
    }




    // Copy input vectors from host memory to GPU buffers.
	//cudaStatus = cudaMemcpy(d_WorldH, &WorldH,  sizeof(int), cudaMemcpyHostToDevice);
    //cudaStatus = cudaMemcpy(d_WorldW, &WorldW,  sizeof(int), cudaMemcpyHostToDevice);
	cudaStatus = cudaMemcpy(d_CAGrid, CAGrid, size*sizeof(bool), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }


	// BEGIN MAIN GLUT LOOP
	glutMainLoop();
	//
    // Copy output vector from GPU buffer to host memory.
    cudaStatus = cudaMemcpy(CAGrid, d_CAGrid, size * sizeof(bool), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    
	}
	// BEGIN FREE ALLOCATED MEMORY
	free(CAGrid);
	free(tempgrid);
	free(NextCAGrid);
	cudaFree(d_CAGrid);
	cudaFree(d_next_CAGrid);
	cudaGraphicsUnregisterResource(cudaPboResource);
	glDeleteBuffers(1, &GLbufferID);
	glDeleteTextures(1, &GLtexture);
Error:
    cudaFree(d_CAGrid);
    cudaFree(d_next_CAGrid);
	cudaGraphicsUnregisterResource(cudaPboResource);
	glDeleteBuffers(1, &GLbufferID);
	glDeleteTextures(1, &GLtexture);
    return cudaStatus;
	//
}


#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdlib.h>  
#include <stdio.h>
#include <algorithm>
#include <time.h>
#include <string>
#include <sstream>

#define PanelW 1000
#define PanelH 1000
//#define ZeroBoundary
//

//#include <GL\GL.h>
//#include <GL\GLU.h>
//#include <GL\glut.h>
//#include <cudaGL.h>
#include <GL\glew.h>
//#include <GL\glxew.h>
//#include <GL\wglew.h>
#include <GL\freeglut.h>
#include "cuda_gl_interop.h"
#include "Header.h"
#define nCPUGRAPHICS
#define HEURISTICS



cudaGraphicsResource* cudaPboResource = nullptr;
GLuint GLtexture;
GLuint GLbufferID;
uchar4 *d_texturedata = nullptr;
uchar4 *d_bufferdata = nullptr;
uchar4 *GLout = nullptr;
bool *d_CAGrid = nullptr;
bool *d_next_CAGrid = nullptr;
int evolution_number = 0;

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
void drawTexture(unsigned int width,unsigned int height) {
	//glColor3f(1.0f, 1.0f, 1.0f);

	glViewport(loc.x / 2, loc.y / 2, width, height);
	//else glViewport(0, 0, width, height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	//glPushMatrix();

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

	//glPopMatrix();
	//glMatrixMode(GL_MODELVIEW);
	//glLoadIdentity();
	

	glBindTexture(GL_TEXTURE_2D, GLtexture);
	glBindBuffer(GL_PIXEL_UNPACK_BUFFER_ARB, GLbufferID);

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
	glEnd();
	glDisable(GL_TEXTURE_2D);
	glBindBuffer(GL_PIXEL_UNPACK_BUFFER_ARB, 0);
	glBindTexture(GL_TEXTURE_2D, 0);



	//glPopMatrix();
	//glFlush();

}
void reshape(int w, int h)
{
	glViewport(0.0, 0.0, (GLsizei)w, (GLsizei)h);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluOrtho2D(-(GLdouble)w * zoomFactor, (GLdouble)w* zoomFactor, -(GLdouble)h* zoomFactor, (GLdouble)h* zoomFactor);
}
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



		if (neighbours < 2)
		{
			NextCAGrid[i] = 0;
		}
		else if (neighbours > 3)
		{
			NextCAGrid[i] = 0;
		}
		else if (neighbours == 3)
		{
			NextCAGrid[i] = 1;
		}
	}
}

__global__ void NextGenKernel(bool *CAGrid, bool *NextCAGrid,int WorldH,int WorldW)
{
	//int id = blockIdx.x * blockDim.x + threadIdx.x + (blockIdx.y*blockDim.y + threadIdx.y)* WorldH;
	int id = (blockIdx.y * gridDim.x + blockIdx.x); // GLOBAL CELL ID 
	int neighbours = 0; 
	unsigned int WorldS = WorldH*WorldW; // World Size
	
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
		if (id == 0) // First block?
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
			if (neighbours == 3) NextCAGrid[id] = 1;
		}
	}
}
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

			d_buf[id].w = 255;
			d_buf[id].x = 191;
			d_buf[id].y = 173;
			d_buf[id].z = 134;

			if (CAGrid[id] == 1 && NextCAGrid[id] == 1) //GETTING OLDER
			{
				d_buf[id].w = 255;
				d_buf[id].x -= 50;
				d_buf[id].y -= 50;
				d_buf[id].z -= 50;
			}
			if (CAGrid[id] == 1 && NextCAGrid[id] == 0) // NEW BORN
			{
				d_buf[id].w = 255;
				d_buf[id].x += 64;
				d_buf[id].y += 82;
				d_buf[id].z += 121;
			}
			if (CAGrid[id] == 0)	//DEAD
			{
				d_buf[id].w = 255;
				d_buf[id].x -= 191;
				d_buf[id].y -= 173;
				d_buf[id].z -= 134;
			}
			if (CAGrid[id] == 0 && NextCAGrid[id] == 1) // WAS ALIVE
			{
				d_buf[id].w = 255;
				d_buf[id].x += 50;
				d_buf[id].y += 50;
				d_buf[id].z += 50;
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
void displayfunc()
{
	int WorldW = PanelW;
	int WorldH = PanelH;
	dim3 kernelwsize(WorldW, WorldH);
	
	dim3 kernelbsize(1);
	cudaEvent_t start, stop; //CUDA timing var
	float ms;
	glClear(GL_COLOR_BUFFER_BIT);
	if (cont)
	{
#ifdef HEURISTICS
		cudaEventCreate(&start);
		cudaEventCreate(&stop);
		cudaEventRecord(start, 0);
#endif
		NextGenKernel << <kernelwsize, kernelbsize >> > (d_CAGrid, d_next_CAGrid, WorldH, WorldW);
		//NextDumbKernel << <kernelwsize, kernelbsize  >> > (d_CAGrid, d_next_CAGrid);//,d_WorldH,d_WorldW);
		// Check for any errors launching the kernel

#ifdef HEURISTICS
		cudaThreadSynchronize();
		cudaEventRecord(stop, 0);
		cudaEventSynchronize(stop);
		cudaEventElapsedTime(&ms, start, stop);
		printf(" Elapsed GPU Time: %f ms \n", ms);
#endif
		cudaDeviceSynchronize();
		std::swap(d_CAGrid, d_next_CAGrid);
		// cudaDeviceSynchronize waits for the kernel to finish, and returns
		// any errors encountered during the launch.
		evolution_number += 1;
		printf("Evolution Stage %d", evolution_number);

	}



	cudaGraphicsMapResources(1, &cudaPboResource, 0);
	size_t num_bytes;
	cudaError cudaStatus = cudaGraphicsResourceGetMappedPointer((void**)&GLout,
		&num_bytes, cudaPboResource);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "Resource Mapping Error: %s\n", cudaGetErrorString(cudaStatus));
		}
	//cudaGLSetGLDevice(0);
	GLKernel << < kernelwsize, kernelbsize >> > (GLout, d_CAGrid,d_next_CAGrid, WorldH, WorldW,lifecontrol);
	cudaGraphicsUnmapResources(1, &cudaPboResource, 0);
	drawTexture(WorldW, WorldH);
// TODO: Integrate string printing with Texture 
	/*
	std::string inf;
	std::stringstream strstream;
	#ifndef ZeroBoundary
	inf = "Cyclic World";
	#else
	inf = "Zero Boundary"
	#endif // !ZeroBoundary
	strstream << inf << " Evolution Stage: " << evolution_number;
	std::string allinf(strstream.str());
	glColor3f(1.0f, 1.0f, 1.0f);
	glRasterPos2f(-0.5f, 0.5f);
	for (int i = 0; i < allinf.size(); ++i) {
	glutBitmapCharacter(GLUT_BITMAP_TIMES_ROMAN_24, allinf[i]);
	}
	*/
	glutSwapBuffers();
	if (evolutioncontrol)glutPostRedisplay();
	//glutPostRedisplay();

}
int main(int argc,char** argv)
{
    

	const int WorldW = PanelW;
	const int WorldH = PanelH;
	const int WorldSize = WorldH * WorldW;
	bool *CAGrid = (bool *)calloc(WorldSize , sizeof(bool));
	bool *next_CAGrid = (bool *)calloc(WorldSize, sizeof(bool));
	const int reqGens = 1000;

	printf("Starting GLUT main loop...\n");
	printf("Press [r] to reset the view to the original \n")  ;
	printf("Press [ESC] to exit \n" ) ;
	printf( "Press the [+] key to zoom in \n")  ;
	printf( "Press the [-] key to zoom out \n")  ;
	printf( "Press the [up arrow] to move up \n")  ;
	printf( "Press the [down arrow] to move down \n")  ;
	printf( "Press the [left arrow] to move left \n")  ;
	printf( "Press the [right arrow] to move right \n")  ;
	printf( "Press the [l] key to render with colours \n")  ;
	printf( "Press the [space] bar to stop evolution \n")  ;
	printf("Press the [e] key to evolve consecutively \n");


	//IV
	int row = 0;
	for (int i =1 /*(WorldH/2)*WorldW*/; i < WorldSize - WorldH*2; i++) //changed boundaries from 0 to worldsize to shown
	{
		//CAGrid[i] = rand() % 2;
		row = i / WorldW;
		if ((i > WorldW * row + WorldW / 5) && (i < WorldW*row + WorldW - WorldW / 5) && (i > WorldW  * (WorldW / 5)) && i < WorldH*WorldW  - (((WorldH / 5))*WorldW)) // Magic Code That Defines Boundaries 
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
#ifdef HEURISTICS
	clock_t start = clock(), diff;
	CPUNeighbours(CAGrid, next_CAGrid, WorldH, WorldW);
	diff = clock() - start;
	int msec = diff * 1000 / CLOCKS_PER_SEC;
	printf("Time taken %d seconds %d milliseconds for CPU", msec / 1000, msec % 1000);
#endif
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

// Helper function for using CUDA to do its magic 
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
    
	
	initGLUT(argc, argv, WorldW, WorldH);
	gluOrtho2D(0, WorldW, WorldH, 0); // VIewport
	glutKeyboardFunc(keyboard);
	glutSpecialFunc(handleSpecialKeypress);
	glutMouseFunc(mouseCall);
	glutMotionFunc(mouseMove);
	glutReshapeFunc(reshape);
	glutDisplayFunc(displayfunc);	//Display function set
	OpenGLHelper(WorldW, WorldH);	//Texture and Buffer bind
    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
        goto Error;
    }

    // Allocate GPU buffers for three vectors (two input, one output)    .
	/*bool *d_CAGrid; */cudaStatus = cudaMalloc((void**)&d_CAGrid, sizeof(bool) *size); // ALLOCATE THE SAME MEMORY SIZE AS CPU FOR GPU 

    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed with Grid!",cudaStatus);
        goto Error;
    }

	/*bool *d_next_CAGrid; */cudaStatus = cudaMalloc((void**)&d_next_CAGrid, sizeof(bool) *size); // ALLOCATE THE SAME MEMORY SIZE AS CPU FOR GPU
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed with nextGrid!");
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

    // Launch a kernel on the GPU with one thread for each element.
	//REPLACED BY GLUT DISPLAY FUNC
	/*
	for (int i = 0; i < gen; i++)
	{
		NextGenKernel << <kernelwsize, kernelbsize >> > (d_CAGrid, d_next_CAGrid, WorldH, WorldW);
		//NextDumbKernel << <kernelwsize, kernelbsize  >> > (d_CAGrid, d_next_CAGrid);//,d_WorldH,d_WorldW);
		// Check for any errors launching the kernel
		cudaStatus = cudaGetLastError();
		if (cudaStatus != cudaSuccess) {
			fprintf(stderr, "NextGenKernel Start Error: %s\n", cudaGetErrorString(cudaStatus));
			goto Error;
		}
		std::swap(d_CAGrid, d_next_CAGrid);
		// cudaDeviceSynchronize waits for the kernel to finish, and returns
		// any errors encountered during the launch.
		cudaStatus = cudaDeviceSynchronize();
		if (cudaStatus != cudaSuccess) {
			fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching NextGenKernel!\n", cudaStatus);
			goto Error;
		}

		//Display Life Kernel Resource Mapping
		cudaGraphicsMapResources(1, &cudaPboResource, 0);
		size_t num_bytes;
		cudaStatus = cudaGraphicsResourceGetMappedPointer((void**)&GLout,
			&num_bytes, cudaPboResource);
		if (cudaStatus != cudaSuccess) {
			fprintf(stderr, "Resource Mapping Error: %s\n", cudaGetErrorString(cudaStatus));
			goto Error;
		}
		//cudaGLSetGLDevice(0);
		GLKernel << < kernelwsize, kernelbsize >> > (GLout, d_CAGrid, WorldH, WorldW);
		// cudaDeviceSynchronize waits for the kernel to finish, and returns
		// any errors encountered during the launch.
		cudaStatus = cudaDeviceSynchronize();
		if (cudaStatus != cudaSuccess) {
			fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching NextGenKernel!\n", cudaStatus);
			goto Error;
		}
		cudaGraphicsUnmapResources(1, &cudaPboResource, 0);
		drawTexture(WorldW, WorldH);
		glutSwapBuffers();
		

		
	}
	*/
	glutMainLoop();

    // Copy output vector from GPU buffer to host memory.
    cudaStatus = cudaMemcpy(CAGrid, d_CAGrid, size * sizeof(bool), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    
	}
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
}

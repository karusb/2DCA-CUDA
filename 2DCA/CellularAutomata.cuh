#ifndef CA_CELLULAR_AUTOMATA_KERNEL
#define CA_CELLULAR_AUTOMATA_KERNEL

/// CUDA : NextGenKernel : Calculates the neighbours of each cell and puts the new state of the cell in NextCAGrid
/// Inputs : Pointer to the current CAGrid, pointer to the nextCAGrid, world width,height.
__global__ void NextGenKernel(bool* CAGrid, bool* NextCAGrid, int WorldH, int WorldW)
{
	int id = (blockIdx.y * gridDim.x + blockIdx.x); // GLOBAL CELL ID 
	int neighbours = 0;
	unsigned int colup = ((blockIdx.y - 1) * gridDim.x + blockIdx.x); //Upper Row of the Cell (block)
	unsigned int coldwn = ((blockIdx.y + 1) * gridDim.x + blockIdx.x); //Lower Row of the Cell (block)
#ifndef ZeroBoundary
	if (blockIdx.y == 0) colup = ((gridDim.y - 1) * gridDim.x + blockIdx.x); //Change Upper Row to lowest Row if the cell is on the first row
	if (blockIdx.y == gridDim.y - 1) coldwn = blockIdx.x; // Change Lower Row to first row if the cell is on the last row
#endif

	if (id < (WorldH) * (WorldW) && id >= 0) // Are we within the boundaries ? 
	{	
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
		else if (coldwn > PanelH * PanelW)
		{
			if (id - 1 <= 0)
			{
				neighbours = CAGrid[id + 1] +
					CAGrid[colup - 1] +
					CAGrid[colup] +
					CAGrid[colup + 1];
			}
			else if (id + 1 > PanelW * PanelH)
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
				CAGrid[colup - gridDim.x] +
				CAGrid[coldwn - 1] +
				CAGrid[coldwn] +
				CAGrid[coldwn + 1];
		}
		else if (id == gridDim.x * gridDim.y - 1) // Last Block
		{
			neighbours = CAGrid[gridDim.x * gridDim.y - gridDim.x] +
				CAGrid[id - 1] +
				CAGrid[colup - 1] +
				CAGrid[colup] +
				CAGrid[colup + 1] +
				CAGrid[coldwn - 1] +
				CAGrid[coldwn] +
				CAGrid[coldwn + 1];
		}
		else if (id == gridDim.x * gridDim.y - gridDim.x) // Last Row First Block
		{
			neighbours = CAGrid[id + 1] +
				CAGrid[id - 1] +
				CAGrid[colup - 1] +
				CAGrid[colup] +
				CAGrid[colup + 1] +
				CAGrid[gridDim.x - 1] +
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
				NextCAGrid[id] = 0;
			else if (neighbours > 3)
				NextCAGrid[id] = 0;
			else if (neighbours == 3 || neighbours == 2)
				NextCAGrid[id] = 1;
		}
		else
		{
			NextCAGrid[id] = 0;
			if (neighbours == 3)
				NextCAGrid[id] = 1;
		}
	}
}
/// CUDA : GLKernel : Sets the colour of the texture buffer given the correct inputs
/// Inputs: Pointer to the mapped texture , pointer to the current CAGrid, pointer to the next CAGrid, world width,height,2 state or 4 state choice
__global__ void GLKernel(uchar4* d_buf, bool* CAGrid, bool* NextCAGrid, int WorldH, int WorldW, bool d_lifecontrol)
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
#endif

#ifndef CA_HOST_FUNCTIONS_HPP
#define CA_HOST_FUNCTIONS_HPP
#include <algorithm>

/// CPUGridInitLine: Initialises a line of cells every 2 rows
/// Inputs: world width,height pointer to CPU memory of the grid which only fills given scale (real number >=1)
static void CPUGridInitLine(unsigned int WorldW, unsigned int WorldH, bool* CAGrid, unsigned int scale)
{
	//IV
	int row = 0;
	unsigned int WorldSize = WorldH * WorldW;
	for (int i = 1 /*(WorldH/2)*WorldW*/; i < WorldSize - WorldH * 2; i++) //changed boundaries from 0 to worldsize to shown
	{
		//CAGrid[i] = rand() % 2;
		row = i / WorldW;
		if ((i > WorldW * row + WorldW / scale) && (i < WorldW * row + WorldW - WorldW / scale) && (i > WorldW * (WorldW / scale)) && i < WorldH * WorldW - (((WorldH / scale)) * WorldW)) // Magic Code That Defines Boundaries 
			if (row % 2 == 0)
				CAGrid[i] = 1;
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
static void CPUGridInitRand(unsigned int WorldW, unsigned int WorldH, bool* CAGrid, unsigned int scale)
{
	//IV
	int row = 0;
	unsigned int WorldSize = WorldH * WorldW;
	for (int i = 1 /*(WorldH/2)*WorldW*/; i < WorldSize - WorldH * 2; i++) //changed boundaries from 0 to worldsize to shown
	{
		//CAGrid[i] = rand() % 2;
		row = i / WorldW;
		if ((i > WorldW * row + WorldW / scale) && (i < WorldW * row + WorldW - WorldW / scale) && (i > WorldW * (WorldW / scale)) && i < WorldH * WorldW - (((WorldH / scale)) * WorldW)) // Magic Code That Defines Boundaries 
		{
			if (row % 2 == 0)CAGrid[i] = rand() % 2;

		}
		else CAGrid[i] = 0;
	}
}
/// CPUGridInitFullRand: Initialises the grid with random cells (uses rand)
/// Inputs: world width,height pointer to CPU memory 
static void CPUGridInitFullRand(unsigned int WorldW, unsigned int WorldH, bool* CAGrid)
{
	//IV
	unsigned int WorldSize = WorldH * WorldW;
	for (int i = 0; i < WorldSize; i++) //changed boundaries from 0 to worldsize to shown
	{
		CAGrid[i] = rand() % 2;
	}
}
/// CPUNeighbours: Calculates neighbours and perform evolution to the grid on CPU
/// Inputs: pointer to CPU memory of the grid, pointer to CPU memory of the next grid,world width,height
static void CPUNeighbours(bool* CAGrid, bool* NextCAGrid, int WorldH, int WorldW)
{
	int neighbours;

	for (int i = 0; i < (WorldH) * (WorldW); i++)
	{
		int colup = i - WorldW;
		int coldwn = i + WorldW;
		int leftn = i - 1;
		int rightn = i + 1;
		if (colup < 0)colup = WorldW * (WorldH - 1) + i;
		if (coldwn > WorldH * WorldW)coldwn = i - WorldW * (WorldH - 1);
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

#endif 

#ifndef CA_GLOBALS_HPP
#define CA_GLOBALS_HPP

// BEGIN GLOBAL VAR
constexpr int WorldW = PanelW;
constexpr int WorldH = PanelH;
constexpr int WorldSize = WorldH * WorldW;
bool h_CAGrid[WorldSize]; // Allocate world 
bool h_next_CAGrid[WorldSize];

static int2 loc = { 0, 0 };
static int2 mloc = { PanelW/2,PanelH/2 };
static int2 loc2 = { 0,0 };
static bool z1 = false; // mouse tracking mode
static bool z2 = false;
static bool cont = false;
static bool lifecontrol = false;
static bool evolutioncontrol = false;
static bool dragMode = false;
static bool resetlife = false;
static bool fullresetlife = false;
static bool givelife = 0;
static float zoomFactor = 0.5;
static int mousebutton = 0;
static int newpanelw = PanelW;
static int newpanelh = PanelH;
//

static cudaGraphicsResource* cudaPboResource = nullptr;
static GLuint GLtexture;
static GLuint GLbufferID;
static uchar4* d_texturedata = nullptr;
static uchar4* d_bufferdata = nullptr;
static uchar4* GLout = nullptr;
static bool* d_CAGrid = nullptr;
static bool* d_next_CAGrid = nullptr;
static int evolution_number = 0;
static float totalGPUtime = 0.0;
#define DELTA ((PanelW/10)) // pixel increment for arrow keys
#endif
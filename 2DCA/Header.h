#pragma once
 int2 loc = { 0, 0 };
 int2 mloc = { 0,0 };
 bool z1 = false; // mouse tracking mode
 bool z2 = false;
 bool cont = false;
 bool lifecontrol = false;
 bool evolutioncontrol = false;
 bool dragMode = false;
 float zoomFactor = 1.0;
 int mousebutton = 0;

#define DELTA ((PanelW/10)) // pixel increment for arrow keys
void keyboard(unsigned char key, int x, int y) {
	if (key == '+') {
		z1 = !z1; 
		zoomFactor += 0.2;
	}
	if (key == '-') {
		z2 = !z2;
		zoomFactor -= 0.2;
		if (zoomFactor < 0) zoomFactor = 0;
	}

	if (key == 27)  exit(0);
	if (key == 32)cont = !cont;
	if (key == 'l')lifecontrol = !lifecontrol;
	if (key == 'e')evolutioncontrol = !evolutioncontrol;
	
	if (key == 'd') dragMode = !dragMode;
	glutPostRedisplay();

}
void mouseCall(int button, int call, int x, int y) {
	if (!dragMode) return;

	if (button == 3 || button == 4)
	{
		if (call == GLUT_UP)return;
		if (button == 3)zoomFactor += 0.2;
		if (button == 4)zoomFactor -= 0.2;
		if (zoomFactor < 0) zoomFactor = 0;
	}
	if (button == 0 && call == GLUT_UP)mousebutton = 1;
	else if (call == GLUT_DOWN)mousebutton = 1;
	else mousebutton = 0;
	mloc.x = x;
	mloc.y = y;
	glutPostRedisplay();

}
void mouseMove(int x, int y) {
	if (!dragMode) return;
	int dx = x - mloc.x;
	int dy = y - mloc.y;

	if (mousebutton == 1)
	{
		loc.x += dx;
		loc.y -= dy;
	}
	mloc.x = x;
	mloc.y = y;
	glutPostRedisplay();

}

void mouseDrag(int x, int y) {
	if (!dragMode) return;
	loc.x = x;
	loc.y = y;
	glutPostRedisplay();

}

void handleSpecialKeypress(int key, int x, int y) {
	if (key == GLUT_KEY_LEFT)  loc.x -= DELTA;
	if (key == GLUT_KEY_RIGHT) loc.x += DELTA;
	if (key == GLUT_KEY_UP)    loc.y += DELTA;
	if (key == GLUT_KEY_DOWN)  loc.y -= DELTA;
	glutPostRedisplay();

}

void printInstructions() {
	printf("a: toggle mouse tracking mode\n");
	printf("arrow keys: move ref location\n");
	printf("esc: close graphics window\n");

}

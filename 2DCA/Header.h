#pragma once
 int2 loc = { PanelW / 2, PanelH / 2 };
 bool z1 = false; // mouse tracking mode
 bool z2 = false;
 bool cont = false;
 bool dragMode = false;
#define DELTA 5 // pixel increment for arrow keys
void keyboard(unsigned char key, int x, int y) {
	if (key == 'a') z1 = !z1; // toggle tracking mode
	if (key == 27)  exit(0);
	if (key == 32)cont = !cont;
	if (key == 'z') z2 = !z2;
	if (key == 'd') dragMode = !dragMode;
	glutPostRedisplay();

}

void mouseMove(int x, int y) {
	if (dragMode) return;
	loc.x = x;
	loc.y = y;
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
	if (key == GLUT_KEY_UP)    loc.y -= DELTA;
	if (key == GLUT_KEY_DOWN)  loc.y += DELTA;
	glutPostRedisplay();

}

void printInstructions() {
	printf("a: toggle mouse tracking mode\n");
	printf("arrow keys: move ref location\n");
	printf("esc: close graphics window\n");

}

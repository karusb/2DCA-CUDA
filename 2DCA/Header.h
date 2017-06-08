#pragma once

// BEGIN GLOBAL VAR
 int2 loc = { 0, 0};
 int2 mloc = { 0,0 };
 int2 loc2 = { 0,0 };
 bool z1 = false; // mouse tracking mode
 bool z2 = false;
 bool cont = false;
 bool lifecontrol = false;
 bool evolutioncontrol = false;
 bool dragMode = false;
 bool resetlife = false;
 bool fullresetlife = false;
 bool givelife = 0;
 float zoomFactor = 0.5;
 int mousebutton = 0;
 int newpanelw = PanelW;
 int newpanelh = PanelH;
 bool timecompare = false;
 //
#define DELTA ((PanelW/10)) // pixel increment for arrow keys

 //keyboard press handler sets global vars that interact with displayfunc
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
	if (key == 't')timecompare = !timecompare;
	if (key == 'd') dragMode = !dragMode;
	if (key == 'r') resetlife = !resetlife;
	if (key == 'f') fullresetlife = !fullresetlife;
	glutPostRedisplay();

}
// Mouse click handler that sets global vars for other interaction with displayfunc
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
	else if (button == 0 && call == GLUT_DOWN)mousebutton = 1;
	else mousebutton = 0;
	if (button == 2 && call == GLUT_DOWN)
	{
		givelife = 1;
		loc2.x = x;
		loc2.y = y;
	}
	else givelife = 0;
	mloc.x = x;
	mloc.y = y;
	printf("Call xy: %d %d \n", x, y);
	glutPostRedisplay();

}
// Mouse Move handler with reference to mouse click handler
void mouseMove( int x, int y) {
	if (!dragMode) return;
	int dx = x - mloc.x;
	int dy = y - mloc.y;

	if (mousebutton == 1 )
	{
		loc.x += dx;
		loc.y -= dy;
	}

	mloc.x = x;
	mloc.y = y;
	printf("Move xy: %d %d \n", x, y);
	printf("loc: %d %d \n", loc.x, loc.y);
	printf("loc2: %d %d \n", loc2.x, loc2.y);
	glutPostRedisplay();

}
// non used location mouse drag location handler
void mouseDrag(int x, int y) {
	if (!dragMode) return;
	loc.x = x;
	loc.y = y;
	glutPostRedisplay();

}
// Moving texture on the screen keyboard func
void handleSpecialKeypress(int key, int x, int y) {
	if (key == GLUT_KEY_LEFT)  loc.x += DELTA;
	if (key == GLUT_KEY_RIGHT) loc.x -= DELTA;
	if (key == GLUT_KEY_UP)    loc.y -= DELTA;
	if (key == GLUT_KEY_DOWN)  loc.y += DELTA;
	glutPostRedisplay();

}
void reshape(int w, int h)
{
	glViewport(0.0, 0.0, (GLsizei)w, (GLsizei)h);
	newpanelw = w; // set the global panelw
	newpanelh = h; // set the global panelh
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	//glViewport((loc.x), (loc.y), GLsizei(w), GLsizei(h));
	glutPostRedisplay();
	//gluOrtho2D(-(GLdouble)w , (GLdouble)w, -(GLdouble)h, (GLdouble)h);
}
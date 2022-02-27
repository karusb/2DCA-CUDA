#ifndef CA_GL_CALLBACKS_HPP
#define CA_GL_CALLBACKS_HPP

//keyboard press handler sets global vars that interact with displayfunc
void keyboard(unsigned char key, int x, int y) {
	if (key == '+') {
		z1 = !z1; 
		zoomFactor += 0.2f;
	}
	if (key == '-') {
		z2 = !z2;
		zoomFactor -= 0.2f;
		if (zoomFactor < 0) zoomFactor = 0;
	}

	if (key == 27)  exit(0);
	if (key == 32)  cont = !cont;
	if (key == 'l') lifecontrol = !lifecontrol;
	if (key == 'e') evolutioncontrol = !evolutioncontrol;
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
		if (call == GLUT_UP)
			return;
		if (button == 3)
			zoomFactor += 0.2f;
		if (button == 4)
			zoomFactor -= 0.2f;
		if (zoomFactor < 0) 
			zoomFactor = 0;
	}
	if (button == 1 && call == GLUT_UP)
		loc = { 0, 0 };
	if (button == 0 && call == GLUT_UP)
		mousebutton = 1;
	else if (button == 0 && call == GLUT_DOWN)
		mousebutton = 1;
	else 
		mousebutton = 0;
	if (button == 2 && call == GLUT_DOWN)
	{
		givelife = 1;
		loc2.x = x;
		loc2.y = y;
	}
	else if (button == 2 && call == GLUT_UP)
		givelife = 0;
	mloc.x = x;
	mloc.y = y;
	printf("Call b: %d c: %d xy: %d,%d \n", button, call, x, y);
	glutPostRedisplay();
}
// Mouse Move handler with reference to mouse click handler
void mouseMove(int x, int y) {
	if (!dragMode) return;
	int dx = x - mloc.x;
	int dy = y - mloc.y;

	if (mousebutton == 1 )
	{
		loc.x += dx;
		loc.y -= dy;
	}
	if (givelife == 1)
	{
		loc2.x = x;
		loc2.y = y;
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
//Window Reshape func
void reshape(int w, int h)
{
	GLfloat aspect;
	newpanelw = w; // set the global panelw
	newpanelh = h; // set the global panelh
	glViewport(0, 0, (GLsizei)w, (GLsizei)h);

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();

	if (w <= h) {
		aspect = (GLfloat)h / (GLfloat)w;
		glOrtho(-1.5, 1.5, -1.5 * aspect, 1.5 * aspect, -10.0, 10.0);
	}
	else {
		aspect = (GLfloat)w / (GLfloat)h;
		glOrtho(-1.5 * aspect, 1.5 * aspect, -1.5, 1.5, -10.0, 10.0);
	}

	glutPostRedisplay();
}

void BeginText() {
	glMatrixMode(GL_PROJECTION);

	// Save the current projection matrix
	glPushMatrix();

	// Make the current matrix the identity matrix
	glLoadIdentity();

	// Set the projection (to 2D orthographic)
	gluOrtho2D(0, PanelW, 0, PanelH);

	glMatrixMode(GL_MODELVIEW);
}

void EndText() {
	glMatrixMode(GL_PROJECTION);

	// Restore the original projection matrix
	glPopMatrix();

	glMatrixMode(GL_MODELVIEW);
}

void RenderCharacter(float x, float y, void* font, std::string str)
{
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_BLEND);

	glMatrixMode(GL_PROJECTION);
	glPushMatrix();
	glLoadIdentity();
	gluOrtho2D(0, PanelW + 200, 0, PanelH + 200);

	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	glLoadIdentity();
	glRasterPos2i(10, PanelH - 10);  // move in 10 pixels from the left and bottom edges
	for (int i = 0; i < str.size(); ++i) {
		glutBitmapCharacter(GLUT_BITMAP_TIMES_ROMAN_24, str.c_str()[i]);
	}
	glPopMatrix();

	glMatrixMode(GL_PROJECTION);
	glPopMatrix();
	glMatrixMode(GL_MODELVIEW);
}

void RenderString(float x, float y, void* font, std::string str)
{
	glColor3f(255, 255, 255);
	glRasterPos2f(x, y);
	glutBitmapString(font, reinterpret_cast < const unsigned char*>("YO YO YO "));
}

/// drawTexture: Iteratively called draw function referenced to GLUT
/// Inputs: Texture width,height
void drawTexture(unsigned int width, unsigned int height) {
	std::stringstream strstream;
	strstream << " Evolution Stage: " << evolution_number;

	gluOrtho2D(0, width * (zoomFactor + 1), 0, height * (zoomFactor + 1));
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();

	glViewport((loc.x), (loc.y), GLsizei(newpanelw * 2 * (zoomFactor)), GLsizei(newpanelh * 2 * (zoomFactor)));

	if (z1)
	{
		z2 = false;
		z1 = false;
	}
	if (z2)
	{
		z1 = false;
		z2 = false;
	}
	glScalef(zoomFactor, zoomFactor, 1); // scale the matrix

	glBindTexture(GL_TEXTURE_2D, GLtexture);
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

	//BeginText();
	//RenderString(200, 400, GLUT_BITMAP_TIMES_ROMAN_24, strstream.str());
	//DrawString(100.0f, 100.0f, 0.0f, strstream.str().c_str());
	//EndText();

	glDisable(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D, 0);
	RenderString(200, 400, GLUT_BITMAP_TIMES_ROMAN_24, strstream.str());
	glEnd();
}
#endif

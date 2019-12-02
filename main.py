# -*- coding: utf-8 -*-

# -*- coding: utf-8 -*-
"""
Created on Wed Nov 20 12:19:43 2019

@author: dj.bigelow
"""
import pygame
from pygame.locals import *

from OpenGL.GL import *
from OpenGL.GLU import * 

import math

WINDOW_WIDTH = 500
WINDOW_HEIGHT = 500



def drawSquare():
    #Beginning of quad definition
    glBegin(GL_QUADS)
    
    #Bottom left
    glVertex2f(0, 0)
    
    #Bottom right
    glVertex2f(WINDOW_WIDTH, 0)
    
    #Top right
    glVertex2f(WINDOW_WIDTH, WINDOW_HEIGHT)
    
    #Top left
    glVertex2f(0, WINDOW_HEIGHT)
    
    glEnd()




def main():
    
    r = 0.0
    g = 1.0
    b = 1.0
    
    pygame.init()
    display = (WINDOW_WIDTH, WINDOW_HEIGHT)
    
    #Open window
    pygame.display.set_mode(display, DOUBLEBUF | OPENGL)
    
    #glTranslatef(0.0, 0.0, 0.0)
    
    #glRotatef(0, 0, 0, 0)

    glColor3f(r, g, b)
    
    while True:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                
                quit()
        r += 0.005
        g += 0.005
        b += 0.001
                
        #Clear screen
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        glMatrixMode(GL_PROJECTION)
        glLoadIdentity()
        
        #Set view to orthographic to map square directly to display 
        glOrtho(0.0, WINDOW_WIDTH, 0.0, WINDOW_HEIGHT, 0.0, 1.0)
        glMatrixMode(GL_MODELVIEW)
        
        #Set the color of the rendered quad
        glColor3f((math.sin(r) + 1) / 2, 
                  (math.cos(g) + 1) / 2,
                  (math.sin(r) + 1) / 2)
        glLoadIdentity()
        drawSquare()
        pygame.display.flip()
        pygame.time.wait(10)
        
    
main()

    
    

    
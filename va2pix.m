function pix=va2pix(va, scr)

pix = scr.subDist*tan(va*pi/180)/(scr.width/(10*scr.xres));

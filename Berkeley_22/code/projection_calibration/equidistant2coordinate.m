function [phi, theta] = equidistant2coordinate(fpx, xShift, yShift, x, y)
x = x-xShift; 
y = y-yShift;

[phi, rho] = cart2pol(x,y);
theta = rho / fpx;

end
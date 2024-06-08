function color = correct_vignett(pic, X, Y, xShift, yShift, fpx)
% Correct Vignetting effect for this Sigma lens. Removes all data for theta
% > pi/2. 
% 

% Create x and y matrices for the pixels
xBase = 0:1:(X-1);
x = repmat(xBase,Y,1);
yBase = (0:1:(Y-1))';
y = repmat(yBase,1,X);

% Shift the x and y matrices to align the origin as the center of the photo
% measurement.
x = x-xShift; 
y = y-yShift;

[~, rho] = cart2pol(x,y);

color = pic;

theta = rho / fpx;

for aa = 1:size(color, 1)
    for bb = 1:size(color, 2)
        if theta(aa, bb) > pi/2
            color(aa, bb) = 0;
        else
            theta_d = theta(aa, bb) / pi * 180;
            color(aa, bb) = color(aa, bb) / (-7e-5 * theta_d^2 + 0.0003 * theta_d + 0.9932);
        end
    end
end

end
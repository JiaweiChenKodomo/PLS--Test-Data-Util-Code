function illu = equidist2illu(pic, X, Y, xShift, yShift, fpx)
% Calculates illuminance from the equidistant image. E = \sum L \cos\theta
% d\Omega = \sum L \cos\theta dA / R^2. Summation is by pixel. 
% Mapping function for equisolid: r = f * theta
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

ind = rho <= fpx * pi / 2; % Only half plane used to calculate illuminance.

rho = rho(ind);
color = pic(ind);

theta = rho / fpx;

ind2 = theta > 0;
theta = theta(ind2);
color = color(ind2);

dOmega = sin(theta) ./ theta;
dOmega = dOmega * 2 * pi / sum(dOmega); % Geometric constraint.
%dOmega = dOmega * pi / sum(dOmega ); % Energy constraint. May be better as rho == fpx pixels are not considered.

illu = sum(color .* cos(theta) .* dOmega);

end
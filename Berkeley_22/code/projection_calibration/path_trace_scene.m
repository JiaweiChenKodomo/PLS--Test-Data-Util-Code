function [xoo, yoo] = path_trace_scene(fpx, Xout, Yout, map_option)
% Maps images of equisolid projection to one with spherical projection.
% Mapping function for equisolid: r = alpha * f * sin( beta * theta)
% Mapping function for hemispherical: r = f * sin(theta)
% Mapping function for equidistant: r = f * theta

% Create x and y matrices for the pixels
[xo, yo] = meshgrid((0:(Xout-1)), (0:(Yout-1)));
x = xo - Xout / 2;
y = yo - Yout / 2;

[phi, rho] = cart2pol(x,y);

switch map_option.type
    case "Equisolid"
        if ~isfield(map_option,'alpha')
            alpha = 2;
        else
            alpha = map_option.alpha;
        end
        if ~isfield(map_option, 'beta')
            beta = 1/2; 
        else 
            beta = map_option.beta;
        end

        rho_max = alpha * fpx * sin(beta * pi / 2);

        ind = rho < rho_max;
        rho = rho(ind);
        theta = asin(rho / (alpha * fpx)) / beta;

    case "Hemispherical"
        rho_max = fpx;
        ind = rho < rho_max;
        rho = rho(ind);
        theta = asin(rho / fpx);

    case "Equidistant"
        rho_max = fpx * pi / 2;
        ind = rho < rho_max;
        rho = rho(ind);
        theta = rho / fpx;

    otherwise
        disp("Projection not supported.")
        return
end

xo = xo(ind);
yo = yo(ind);
phi = phi(ind);

x_check = sin(theta) .* cos(phi);
z_check = cos(theta);
gam = atan(x_check ./ z_check); %

xoo = [];
yoo = [];

for aa = -9:9
    ind = find(gam < (aa * pi / 18 + pi / 180) & gam > (aa * pi / 18 - pi / 180));
    xoo = [xoo; xo(ind)];
    yoo = [yoo; yo(ind)];
end

end
% Reconstruct position of camera in Rhino coordinate system from image
% points.

% 5 points on image.

% xy_in_image = zeros(5, 2);
% for aa = 1:5
%     xy_in_image(aa, :) = cursor_info(aa).Position;
% end

% xy_in_image = [389   215
%                265   246
%                256   243
%                296   204
%                259   200
%                382   298
%                333   205
%                246   194
%                332   205
%                267   246
%                233   86
%                224   122
%                221   150
%                220   172
%                403   200];
xy_in_image = [389   215
               265   246
               256   243
               296   204
               259   200
               382   298
               333   205
               246   194
               332   205
               267   246
               389   215
               337   211
               338   310
               378   231
               314   203];

%% Reorganize
x_img = xy_in_image(:, 1);
y_img = xy_in_image(:, 2);

fpixel_ed = 147.3287; % From linear regression of standard specimen.
xShift = 360;
yShift = 237;

[phi_cam, theta_cam] = equidistant2coordinate(fpixel_ed, xShift, yShift, x_img, y_img);

%% Get coordinates in Rhino
xyz_in_wld = [0.0381,0.0762,1.96215;
    2.77177,0.0889,1.2319;
    2.91465,0.0889,1.27;
    2.30505,0.0889,1.8796;
    2.91465,0.0889,1.8796;
    0.32385,0.0889,0;
    1.59385,0.0889,1.96215;
    3.13373,0.0889,1.96215;
    2.99085,0.0889,1.96215;
    2.73367,0.0889,1.2319;
    0.32385,0.0889,1.83515;
    1.51765,0.0889,1.83515;
    1.51765,0.0889,0;
    0.40005,0.0508,1.5494;
    1.9558,0.0889,1.96215];



%% Find coordinates of camera.
myfun = @(x) cam_pos_loss_func(x, xyz_in_wld([1:9, 10:15],:), theta_cam([1:9, 10:15]));
nvars = 5;
lb = [3.1964739525, 2.75855859084, 1.37, -pi/18, pi];
ub = [3.3, 2.9, 1.41, pi/18, 1.5 * pi];

x = particleswarm(myfun,nvars,lb,ub);

check_result(x, xyz_in_wld(1:15,:), xy_in_image(1:15,:), fpixel_ed, xShift, yShift);

alpha = x(4); % Pitch angle, around 0.
beta = x(5); % pi <= beta <= 1.5 * pi
v = [cos(alpha)*sin(beta), cos(alpha) * cos(beta), sin(alpha)];

%% Find coordinates of camera.
myfun = @(x) cam_pos_loss_func2(x, xyz_in_wld([1:9, 10:15],:), xShift, yShift, x_img, y_img);
nvars = 6;
lb = [3.1964, 2.7585, 1.3, -pi/9, pi, 146];
ub = [3.1965, 2.7586, 1.37, pi/9, 1.5 * pi, 200];

x = particleswarm(myfun,nvars,lb,ub);

check_result(x, xyz_in_wld(1:15,:), xy_in_image(1:15,:), x(6), xShift, yShift);

alpha = x(4); % Pitch angle, around 0.
beta = x(5); % pi <= beta <= 1.5 * pi
v = [cos(alpha)*sin(beta), cos(alpha) * cos(beta), sin(alpha)];

angle = 480/x(6)/pi*180;

%% Find coordinates of camera.
myfun = @(x2) cam_pos_loss_func3(x2, xyz_in_wld([1:9, 10:15],:), xShift, yShift, x_img, y_img);
nvars = 4;
lb = [1.00, -pi/9, pi, 146];
ub = [1.41, pi/9, 1.5 * pi, 200];

x2 = particleswarm(myfun,nvars,lb,ub);
x = [3.1964739525, 2.75855859084, x2];

check_result(x, xyz_in_wld(1:15,:), xy_in_image(1:15,:), x(6), xShift, yShift);

alpha = x(4); % Pitch angle, around 0.
beta = x(5); % pi <= beta <= 1.5 * pi
v = [cos(alpha)*sin(beta), cos(alpha) * cos(beta), sin(alpha)];

angle = 480/x(6)/pi*180;

%% loss function

function loss = cam_pos_loss_func(x, xyz_in_wld, theta)
xCam = x(1);
yCam = x(2);
zCam = x(3);
alpha = x(4); % Pitch angle, around 0.
beta = x(5); % pi <= beta <= 1.5 * pi
loss = 0;
v = [cos(alpha)*sin(beta), cos(alpha) * cos(beta), sin(alpha)];

for aa = 1:length(theta)
    d = xyz_in_wld(aa, :) - [xCam, yCam, zCam];
    %loss = loss + abs(dot(v, d) - norm(d) * cos(theta(aa)));
    %loss = loss + abs(dot(v, d)/norm(d) - cos(theta(aa)));
    loss = loss + abs(acos(dot(v, d)/norm(d)) - (theta(aa)));
end
end

function loss = cam_pos_loss_func2(x, xyz_in_wld, xShift, yShift, x_c, y_c)
xCam = x(1);
yCam = x(2);
zCam = x(3);
alpha = x(4); % Pitch angle, around 0.
beta = x(5); % pi <= beta <= 1.5 * pi
fpx = x(6);

[~, theta] = equidistant2coordinate(fpx, xShift, yShift, x_c, y_c);
loss = 0;
v = [cos(alpha)*sin(beta), cos(alpha) * cos(beta), sin(alpha)];

for aa = 1:length(theta)
    d = xyz_in_wld(aa, :) - [xCam, yCam, zCam];
    %loss = loss + abs(dot(v, d) - norm(d) * cos(theta(aa)));
    %loss = loss + abs(dot(v, d)/norm(d) - cos(theta(aa)));
    loss = loss + abs(acos(dot(v, d)/norm(d)) - (theta(aa)));
end
end

function loss = cam_pos_loss_func3(x, xyz_in_wld, xShift, yShift, x_c, y_c)
xCam = 3.1964739525; 
yCam =  2.75855859084;
zCam = x(1);
alpha = x(2); % Pitch angle, around 0.
beta = x(3); % pi <= beta <= 1.5 * pi
fpx = x(4);

[~, theta] = equidistant2coordinate(fpx, xShift, yShift, x_c, y_c);
loss = 0;
v = [cos(alpha)*sin(beta), cos(alpha) * cos(beta), sin(alpha)];

for aa = 1:length(theta)
    d = xyz_in_wld(aa, :) - [xCam, yCam, zCam];
    %loss = loss + abs(dot(v, d) - norm(d) * cos(theta(aa)));
    %loss = loss + abs(dot(v, d)/norm(d) - cos(theta(aa)));
    loss = loss + abs(acos(dot(v, d)/norm(d)) - (theta(aa)));
end
end

function check_result(x, xyz_in_wld, xy_in_image, fpixel_ed, xShift, yShift)
xCam = x(1);
yCam = x(2);
zCam = x(3);
alpha = x(4); % Pitch angle, around 0.
beta = x(5); % pi <= beta <= 1.5 * pi

v = [cos(alpha)*sin(beta), cos(alpha) * cos(beta), sin(alpha)];

figure;
scatter(xy_in_image(:,2), xy_in_image(:, 1), 'o');
hold on;

for aa = 1:size(xyz_in_wld, 1)
    d = xyz_in_wld(aa, :) - [xCam, yCam, zCam];
    theta = acos(dot(v, d) / norm(d));
    rho = fpixel_ed * theta;
    viscircles([yShift, xShift], rho);
end
axis equal;
set ( gca, 'ydir', 'reverse' )
end

function [phi, theta] = equidistant2coordinate(fpx, xShift, yShift, x, y)
x = x-xShift; 
y = y-yShift;

[phi, rho] = cart2pol(x,y);
theta = rho / fpx;

end
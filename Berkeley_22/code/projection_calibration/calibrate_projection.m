% Calibrate for the projection function of the Sigma Fisheye camera.
%% Load the images.
sumImage = zeros(480, 720, 3);
n = 0;
for aa = 4:5
    n = n + 1;
    filename = "IMG_" + sprintf("%04d", aa + 4) + ".JPG";
    imageRead = imread(filename);
    %imgGrey = rgb2gray(imageRead);
    imageReadDouble = double(imageRead);
    sumImage = sumImage + imageReadDouble;
end
sumImage = sumImage / n;
%% Pick the data points.
x = [153, 179, 204, 230, 256, 282, 308, 333, 358, 384, 409, 435, 461, 487, 513, 539, 566, 589];
%% Draw the image.
figure;
imshow(uint8(sumImage));
hold on
xline(360);
yline(237);
plot(x, 237 * ones(1, 18), '*');
%%
r_center = abs(x - 358);
theta_center = [80:-10:10, 0:10:90] / 180 * pi;
fpixel_ed = theta_center' \ r_center';
map_option.type = "Equidistant";
%map_option.type = "Equisolid";
map_option.alpha = 1.77;
%map_option.beta = 0.7172;
map_option.beta = 0.5;
%map.beta = 0.54;
fpixel_es = max(r_center) / (map_option.alpha * sin(pi / 2 * map_option.beta));
[xoo, yoo] = path_trace_scene(fpixel_ed, 720, 480, map_option);
%[xoo, yoo] = path_trace_scene(fpixel_es, 720, 480, map_option);

%% 
figure;
imshow(uint8(sumImage));
hold on
xline(360);
yline(237);
scatter(xoo, yoo, ".");
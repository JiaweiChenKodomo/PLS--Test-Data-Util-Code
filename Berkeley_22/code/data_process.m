%% Load view matrix

vmtx2 = importdata("v_office2.mtx") ;
vmtx2_dt = vmtx2.data(end,1:3:end);
vmtx_dt_dense = vmtx2.data(1:end-1,1:3:end);

vmtx_dt = vmtx2_dt; 


%% 
location = importdata("office_grid2.pts");

location = location(1:end-1, 1:2);
for aa = linspace(size(location, 1), 1, size(location, 1))
    location(aa, :) = location(aa, :) - location(1, :);
end

%% Put all in a cell DS
calIllu_cell = cell(3,1);
calTime_cell = cell(3,1);
totTime_cell = cell(3,1);
totalIllu_cell = cell(3,1);
lumi_cell = cell(3,1);

%% List of folder pathes
folderPathList = ["./2022-10-28/";
    "./2022-10-29/";
    "./2022-10-30/"];
%% Load luminance readings
%% Loop
for cc = 1:length(folderPathList)
    folderPath = folderPathList(cc);
    totalInfo = dir(folderPath);
    fileNames = {totalInfo.name};
    timeStamps = cell(length(fileNames), 1);
    lumVal = zeros(145, length(fileNames));
    for aa = 1:length(fileNames)
        fileName = fileNames{aa};
        if contains(fileName, 'txt')
            fid = fopen(folderPath+fileName);
            M   = textscan( fid, '%f'            ...
                    ,   'Whitespace' , '[] ' ...   
                    , 'CollectOutput', true  );
            lumVal(:,aa) = M{1};
            fclose(fid);
            timeStamps(aa) = textscan(fileName,'%d-%d-%d_%d-%d-%d.txt', ...
                'CollectOutput',true);
        end
    end
    calIllu = (vmtx_dt * lumVal(:,3:end))';
    % Time stamps
    calTimeY = zeros(length(fileNames)-2, 6);
    
    for aa = 3:length(fileNames)
        for bb = 1:6
            calTimeY(aa-2, bb) = timeStamps{aa}(bb);
        end
    end
    calTime = datetime(calTimeY);
    
    lumi_cell{cc} = lumVal(:,3:end);
    calIllu_cell{cc} = calIllu;
    calTime_cell{cc} = calTime;
   
end

%% Recalculate illu w/o reading lum again
for cc = 1:length(folderPathList)
    
    calIllu = (vmtx_dt * lumi_cell{cc})';
    
    calIllu_cell{cc} = calIllu;
end

%% Read convensional sensor readings
fileList = ["./10_28/28_Oct_2022.txt";
    "./10_29/29_Oct_2022.txt";
    "./10_30/30_Oct_2022.txt"];
dateList = [2022, 10, 28;
            2022, 10, 29;
            2022, 10, 30];
for cc = 1:length(fileList)
    fileName = fileList(cc);
    fid = fopen(fileName);
    
    M   = textscan( fid, '%d:%d:%d %f'            ...
                    , 'CollectOutput', true  );
    
    fclose(fid);
    
    totTime_cell{cc} = datetime([repmat(dateList(cc,:), [size(M{1,1}, 1), 1]), M{1,1}]);
    totalIllu_cell{cc} = M{1,2};
    
   
end

%% Linear regression to figure out scaling factor. This is done as we don't have up-to-date calibration data for reference luxmeter.
scale = zeros(3, 1);
totalIlluLong = [];
calIlluLong = [];
for aa = 1:3
    scale(aa) = totalIllu_cell{aa}\calIllu_cell{aa};
    totalIlluLong = [totalIlluLong; totalIllu_cell{aa}];
    calIlluLong = [calIlluLong; calIllu_cell{aa}];
end
scale2 = totalIlluLong\calIlluLong;


%% Plot and check. FINAL
for aa = 1:3
    figure;
    
    yyaxis left
    totTimeDura = totTime_cell{aa} - totTime_cell{aa}(1);
    plot(totTimeDura, totalIllu_cell{aa}*scale2, '-', 'Color', [0 0.4470 0.7410], LineWidth=1.0, DisplayName='Conventional');
    hold on
    calTimeDura = calTime_cell{aa} - totTime_cell{aa}(1);
    plot(calTimeDura, calIllu_cell{aa}, '-', 'Color', [0.8500 0.3250 0.0980], LineWidth=1.0, DisplayName='HiL');
    hold on
    ylim([0, 2000])
    
    yyaxis right

    totIlluInterp = interp1(totTimeDura,totalIllu_cell{aa}*scale2,calTimeDura, "linear", "extrap");

    if var(detrend(totIlluInterp))>0.0001
        
        % Symmetric percentage error
        bar(calTimeDura, abs(calIllu_cell{aa}-totIlluInterp)./(totIlluInterp + calIllu_cell{aa}) * 200,'EdgeColor','none', 'FaceColor', [0.4660 0.6740 0.1880], DisplayName='SAPE');
        ylim([0, 200]);
    end
    
    if aa == 1
        xlim([hours(0), max(totTimeDura)]);
        xticks([hours(0:1:6), max(totTimeDura)]);
        xticklabels({string(calTime_cell{aa}(1), "HH:mm"),' ','+2h',' ','+4h',' ', ...
            '+6h', string(totTime_cell{aa}(end), "HH:mm")});
    else 
        xlim([hours(0), max(totTimeDura)]);
        xticks([hours(0:1:10), max(totTimeDura)]);
        xticklabels({string(calTime_cell{aa}(1), "HH:mm"),' ','+2h',' ','+4h',' ', ...
            '+6h', '', '+8h', '', '+10h', string(totTime_cell{aa}(end), "HH:mm")});
    end

    xlabel(string(calTime_cell{aa}(1), "MMM d, uuuu"));

    ax = gca;
    
    yyaxis left
    ylabel('Illuminance (Lx)');
    ax.YAxis(1).Color = 'k';
    
    yyaxis right
    ylabel('Symmetric Absolute Percentage Error (%)');
    ax.YAxis(2).Color = 'k';
    
    
    hL = legend('Location','northwest');
    
    if aa == 1
        set(gcf, 'Position', [0,0,350,250])
    else
        set(gcf, 'Position', [0,0,500,250])
    end
    saveas(gcf, ['f5_',num2str(aa)],'png');
    close
end

%% Read in hdr bases

hdr_base9 = zeros(480, 480, 145);
for aa = 1:145
    filename = sprintf('./hdr9/test%03d.hdr', aa-1);
    hdr = hdrread(filename);
    hdr_base9(:, :, aa) = hdr(:, :, 1);
end

%% Simulation result represented with HDR images. FINAL
folderName = ["./10_28/", "./10_29/", "./10_30/"];
saveFolderName = ["./hdr28_3/", "./hdr29_3/", "./hdr30_3/"];

plot_sizeX = 225*2;
plot_sizeY = 200*2;

for aa = 1:3

    for bb = 1 : size(lumi_cell{aa}, 2)
    
        hdr_img = sum(pagemtimes(hdr_base9, reshape(lumi_cell{aa}(:,bb),1,1,145)),3);

        Yout = 480;
        Xout = 480;
        
        fpx_ed = 147.3287;
        
        max_range = max(ceil(mean(hdr_img, 'all')) * 2, 1); % 
        figure; 
        surf(hdr_img, 'EdgeColor', 'none');

        set(gcf, 'Position', [0,0,plot_sizeX,plot_sizeY]);
        axis equal;
        hcb = colorbar;
        clim([0 max_range]);
        colormap('hot');
        hcb.Label.String = 'Luminance (nit)';
        view([0,0,-1]);
        axis off;

        fileName = num2str(aa) + "_sim_" + string(calTime_cell{aa}(bb),"HH-mm") + ".png";

        saveas(gcf, fileName);

        close;

        try 
            a = hdrread(folderName(aa) + "hdrScene" + string(bb-1) + ".hdr");
        catch
            disp("Error at time " + string(calTime_cell{aa}(bb),"HH-mm") + " on Day " + num2str(aa));
        end
        a = a(:,:,[3 2 1]); % OpenCV assumes BGR, but Matlab and others assumes RGB.
        a(:, :, 2) = correct_vignett(a(:, :, 2), X, Y, xShift, yShift, fpx_ed);
        
        scale5 = 13.5480; %Scale factor that maps camera image to correct illuminance level.
%         
        figure;
        surf(a(:, 121:600, 2) * scale5, 'EdgeColor', 'none')
        
        set(gcf, 'Position', [0,0,plot_sizeX,plot_sizeY]);
        axis equal;
        hcb = colorbar;
        clim([0 max_range]);
        colormap('hot');
        hcb.Label.String = 'Luminance (nit)';
        view([0,0,-1]);
        axis off;

        fileName = num2str(aa) + "_cam_" + string(calTime_cell{aa}(bb),"HH-mm") + ".png";


        saveas(gcf, fileName);

        close;
        

        figure;
        rel_err = (hdr_img - a(:, 121:600, 2) * scale5)./(a(:, 121:600, 2) * scale5) * 100;
        rel_err = 200 * rel_err ./ (200 + rel_err);
        surf(rel_err, 'EdgeColor', 'none')
        set(gcf, 'Position', [0,0,plot_sizeX,plot_sizeY]);
        axis equal;
        hcb = colorbar;
        clim([-100 100]);
        colormap('jet');
        hcb.Label.String = 'Symmetric Percentage Error (%)';
        view([0,0,-1]);
        axis off;

        fileName = num2str(aa) + "_spe_" + string(calTime_cell{aa}(bb),"HH-mm") + ".png";


        saveas(gcf, fileName);

        close;
        

    end
end


%% PLS measurement plots. FINAL
folderName = ["./10_28/", "./10_29/", "./10_30/"];
saveFolderName = ["./hdr28_3/", "./hdr29_3/", "./hdr30_3/"];

plot_sizeX = 225*2;
plot_sizeY = 200*2;

for aa = 1:3 

    for bb = 1 : size(lumi_cell{aa}, 2)

        plotKlems2(lumi_cell{aa}(:, bb), 0);

        set(gcf, 'Position', [0,0,plot_sizeX,plot_sizeY]);

        xlim([120, 600]);
        ylim([-20, 520]);

        hcb = colorbar;
        hcb.Label.String = "Luminance (nit)";

        axis off;
        set(gca,'xdir','reverse');

        fileName = num2str(aa) + "_patch_" + string(calTime_cell{aa}(bb),"HH-mm") + ".png";

        saveas(gcf, fileName);

        close;
        

    end
end


%% Check if hdr image is linear with illuminance. (Verification step)

testFolderName = "./hdr_test/";

fid = fopen(testFolderName + "09_Apr_2023.txt");
    
M   = textscan( fid, '%d:%d:%d %f'            ...
                , 'CollectOutput', true  );

fclose(fid);

illuTestLst = M{1, 2};

hdrIlluLst = zeros(60, 1);

X = 720;
Y = 480;
xShift = 360;
yShift = 237;

% Must calculate the focual length in pixels. This is the projection
% equation for a equidistant, circular fisheye lens expressing the
% focal length in terms of the radius and pixel distance at that radius.
% Measured from test images (see /projection_calibration).
fpx_ed = 147.3287;

for bb = 1:60
    a = hdrread(testFolderName + "hdrScene" + string(bb-1) + ".hdr");
    a(:, :, 2) = correct_vignett(a(:, :, 2), X, Y, xShift, yShift, fpx_ed);

    hdrIlluLst(bb) = equidist2illu(a(:, :, 2), X, Y, xShift, yShift, fpx_ed);
end

%% Plot 
figure;         
plot(illuTestLst, hdrIlluLst, 'b*');

hold on;
% K is the ratio between illuminance sensor and camera readings. 
% scale2 is the ratio between HWiL result and iluminance sensor. 
% Therefore, the scale between HWiL result and camera result is K * scale2
% and recorded as scale5.
K = hdrIlluLst \ illuTestLst;

plot(illuTestLst, illuTestLst/K, 'r-');

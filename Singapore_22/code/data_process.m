% To run all the data processing process, place this file under the /data directory.

%% Load view matrix

vmtx = importdata("v_office.mtx") ;
vmtx_dt = vmtx.data(end-11:end,1:3:end);

%%
vmtx_dt_dense = vmtx.data(1:end-12,1:3:end);
%% 
location = importdata("office_grid.pts");

location = location(1:end-12, 1:2);
for aa = linspace(size(location, 1), 1, size(location, 1))
    location(aa, :) = location(aa, :) - location(1, :);
end
%% Mapping from numbering of PI to numbering here. 
index = [8:2:12,7:2:11,2:2:6,1:2:5];
%% Put all in a cell DS
calIllu_cell = cell(14,1);
calTime_cell = cell(14,1);
totTime_cell = cell(14,1);
totalIllu_cell = cell(14,1);
lumi_cell = cell(14,1);
%% List of folder pathes
folderPathList = ["./measurements/2022-07-09/1/";
    "./measurements/2022-07-09/2/";
    "./measurements/2022-07-09/3/";
    "./measurements/2022-07-10/";
    "./measurements/2022-07-17/1/";
    "./measurements/2022-07-17/2/";
    "./measurements/2022-07-17/3/";
    "./measurements/2022-07-17/4/";
    "./measurements/2022-07-23/";
    "./measurements/2022-07-24/";
    "./measurements/2022-07-30/";
    "./measurements/2022-07-31/";
    "./measurements/2022-08-06/";
    "./measurements/2022-08-07/"];
%% Load luminance readings
%% Loop
for cc = 1:length(folderPathList)
    folderPath = folderPathList(cc);
    totalInfo = dir(folderPath);
    fileNames = {totalInfo.name};
    timeStamps = cell(length(fileNames)-1, 1);
    lumVal = zeros(145, length(fileNames)-3);
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
        elseif contains(fileName, 'xlsx')
            totalIllu = importdata(folderPath+fileName);
            totalIllu = totalIllu(:,index);
        end
    end
    calIllu = (vmtx_dt * lumVal(:,3:end))';
    % Time stamps
    calTimeY = zeros(length(fileNames)-3, 6);
    
    for aa = 3:length(fileNames)-1
        for bb = 1:6
            calTimeY(aa-2, bb) = timeStamps{aa}(bb);
        end
    end
    calTime = datetime(calTimeY);
    
    totTimeY = calTimeY;
    totTimeY(:, end) = 0;
    totTimeY = [totTimeY; totTimeY(end,:)];
    totTimeY(end, 5) = totTimeY(end, 5)+1;
    totTime = datetime(totTimeY);
    
    lumi_cell{cc} = lumVal(:,3:end);
    calIllu_cell{cc} = calIllu;
    calTime_cell{cc} = calTime;
    totTime_cell{cc} = totTime;
    totalIllu_cell{cc} = totalIllu;
end
% Test peiods: 
% 8-6: 14:43 to 17:42
% 8-7: 11:25 to 14:25
% 7-31: 12:34 to 13:34
% 7-30: 11:25 to 14:25
% 7-24: 10:37 to 13:37
% 7-23: 13:00 to 16:00
% 7-17: 8:08 to 10:08
% 7-17: 10:10 to 10:45
% 7-17: 12:00 to 13:25
% 7-17: 13:35 to 15:35
% 7-10: 15:24 to 17:24
% 7-9: 12:58 to 13:58
% 7-9: 14:07 to 16:07
% 7-9: 16:06 to 17:06

%% Recalculate illu w/o reading lum again
for cc = 1:length(folderPathList)
    
    calIllu = (vmtx_dt * lumi_cell{cc})';
    
    calIllu_cell{cc} = calIllu;
end


%% Plot and check
for aa = 1:12
    figure;
    plot(totTime, totalIllu(:,aa),DisplayName='Conventional');
    hold on
    plot(calTime, calIllu(:,aa),DisplayName='HWiL');
    legend show
end

%% Recalibrate all sensor data once based on 7/23 to 8/7 data. This is done because
%  the preinstalled illuminance sensors have not been calibrated for long.
%  Only 6 days' data is used to avoid overfitting.
scaleFactor = zeros(12, 1);
for aa = 1:12
    allTotalIllu = [];
    allCalIllu = [];
    for bb = 9:14
        
        if var(detrend(totalIllu_cell{bb}(:,aa)))>0.0001
            totIlluInterp = interp1(totTime_cell{bb},totalIllu_cell{bb}(:,aa),calTime_cell{bb});
            allTotalIllu = [allTotalIllu; totIlluInterp];
            allCalIllu = [allCalIllu; calIllu_cell{bb}(:,aa)];
        else
            disp([aa, bb]);
        end
    end
    scaleFactor(aa) = allTotalIllu \ allCalIllu;
end

%% Same sensor, all data. Same days go to same plot. FINAL
ind = {7:8, 9, 11, 14};
for aa = [1,5,7,10]
    figure;
    tcl = tiledlayout(1,4, 'TileSpacing', 'tight', 'Padding','compact');
    for bb = 1:4
        nexttile(tcl)
        for cc = ind{bb}
            yyaxis left
            if var(detrend(totalIllu_cell{cc}(:,aa)))>0.0001
                totTimeDura = totTime_cell{cc} - totTime_cell{ind{bb}(1)}(1);
                plot(totTimeDura, totalIllu_cell{cc}(:,aa) * scaleFactor(aa), '-', 'Color', [0 0.4470 0.7410], LineWidth=1.0, DisplayName='Conventional');
                hold on 
            else
                disp([aa, cc]);
            end
            
            calTimeDura = calTime_cell{cc} - totTime_cell{ind{bb}(1)}(1);
            plot(calTimeDura, calIllu_cell{cc}(:,aa), '-', 'Color', [0.8500 0.3250 0.0980], LineWidth=1.0, DisplayName='HiL');
            ylim([0, 45]);
            hold on

            yyaxis right

            totIlluInterp = interp1(totTime_cell{cc},totalIllu_cell{cc}(:,aa),calTime_cell{cc})*scaleFactor(aa);

            if var(detrend(totIlluInterp))>0.0001
                
                bar(calTimeDura, abs(calIllu_cell{cc}(:,aa)-totIlluInterp)./(totIlluInterp+calIllu_cell{cc}(:,aa)) * 200,'EdgeColor','none', 'FaceColor', [0.4660 0.6740 0.1880], DisplayName='SAPE');
                ylim([0, 200]);
            end
            

            
        end
        xlim(minutes([0,180]));
        xticks(minutes(0:30:180));
        
        xticklabels({string(calTime_cell{ind{bb}(1)}(1), "HH:mm"),' ','+1h',' ','+2h',' ',string(calTime_cell{ind{bb}(1)}(1)+hours(3), "HH:mm")});
        xlabel(string(calTime_cell{ind{bb}(1)}(1), "MMM d, uuuu"));
        ax = gca;
        
        if bb == 1
            yyaxis left
            ylabel('Illuminance (Lx)');
            ax.YAxis(1).Color = 'k';
        else
            ax.YAxis(1).Visible = 'off';
        end
        
        if bb == 4
            hL = legend();
            yyaxis right
            
            ylabel('Symmetric Absolute Percentage Error (%)');
            ax.YAxis(2).Color = 'k';
        else 
            ax.YAxis(2).Visible = 'off';
        end
        

    end
    
    hL.Layout.Tile = 'South';
    set(gcf, 'Position', [0,0,600,300])
    saveas(gcf, ['new5_f',num2str(aa)],'png');
    close
end

%% General stats of error. FINAL
figure;
totalCount = [];
grouping = [];
bounds = zeros(12, 2);
for aa = 1:12

    local_count = [];
    
    for bb = 1:14
        % First interpoate total illumination
        totIlluInterp = interp1(totTime_cell{bb},totalIllu_cell{bb}(:,aa),calTime_cell{bb})*scaleFactor(aa);
        if var(detrend(totIlluInterp))>0.0001
            rel_err = (calIllu_cell{bb}(:,aa)-totIlluInterp)./(totIlluInterp+calIllu_cell{bb}(:,aa))*200;
            local_count = [local_count; rel_err];
            totalCount = [totalCount; rel_err];
            grouping = [grouping; repmat(aa, length(totIlluInterp),1)];
        
        end
    end
    
    bounds(aa, :) = quantile(local_count, [0.05, 0.95]);
    
end

hAx = axes;
boxplot(totalCount,grouping);
hold on
lines = hAx.Children;
uw = findobj(lines, 'tag', 'Upper Whisker');
set(uw, 'LineWidth', 1.0)
lw = findobj(lines, 'tag', 'Lower Whisker'); 
set(lw, 'LineWidth', 1.0)
uav = findobj(lines, 'tag', 'Upper Adjacent Value');
set(uav, 'LineWidth', 1.0)
lav = findobj(lines, 'tag', 'Lower Adjacent Value'); 
set(lav, 'LineWidth', 1.0)
set(gcf, 'Position', [0,0,400,300])
xlabel('Sensor Location #');
ylabel('Symmetric Percentage Error (%)');
xticks(1:12);
ylim([-100, 100]);
grid on
plot(bounds, 'bo');

%% General stats of error. FINAL
figure;
totalCount = [];
grouping = [];
bounds = zeros(12, 2);
for aa = 1:12

    local_count = [];
    
    for bb = 13:14
        % First interpoate total illumination
        
        totIlluInterp = interp1(totTime_cell{bb},totalIllu_cell{bb}(:,aa),calTime_cell{bb})*scaleFactor(aa);
        if var(detrend(totIlluInterp))>0.0001

            rel_err = (calIllu_cell{bb}(:,aa)-totIlluInterp)./(totIlluInterp+calIllu_cell{bb}(:,aa))*200;
            local_count = [local_count; rel_err];
            totalCount = [totalCount; rel_err];

            grouping = [grouping; repmat(aa, length(totIlluInterp),1)];
        
        end
    end
    
    bounds(aa, :) = quantile(local_count, [0.05, 0.95]);
    
end
totalCount = [totalCount; -150; -150];
grouping = [grouping; 3; 6];
hAx = axes;
boxplot(totalCount,grouping);
hold on
lines = hAx.Children;
uw = findobj(lines, 'tag', 'Upper Whisker');
set(uw, 'LineWidth', 1.0)
lw = findobj(lines, 'tag', 'Lower Whisker'); 
set(lw, 'LineWidth', 1.0)
uav = findobj(lines, 'tag', 'Upper Adjacent Value');
set(uav, 'LineWidth', 1.0)
lav = findobj(lines, 'tag', 'Lower Adjacent Value'); 
set(lav, 'LineWidth', 1.0)

set(gcf, 'Position', [0,0,400,300])
xlabel('Sensor Location #');
ylabel('Symmetric Percentage Error (%)');
ylim([-100, 100]);
grid on
plot(bounds, 'bo');
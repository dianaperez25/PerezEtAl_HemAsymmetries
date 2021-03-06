%% Count number/proportion of vertices and surface area for each network across hemispheres
% input: group average cifti file
% output: a matrix with 4 measures for each hemisphere (optional: a scatter
% plot of the proportion of surface area for each network)
% 1. number of vertices
% 2. proportion of vertices
% 3. surface area accounted for by each network
% 4. proportion of surface area
%
clear all
%-------------------------------------------------------------------------
%% PATHS
%-------------------------------------------------------------------------
root_dir = '/Users/dianaperez/Desktop/lateralization_code/'; % location of code directory
addpath(genpath(root_dir))
cd(root_dir)
out_dir = [root_dir 'testing_output/network_symmetry/'];
if ~exist(out_dir, 'file')
    mkdir(out_dir)
end

%-------------------------------------------------------------------------
%% VARIABLES
%-------------------------------------------------------------------------
% select sample
washU_120 = 1; 
HCP384 = 0; 
MSC = 0; 
yeo_7nets = 0; 
yeo_17nets = 0; 

plot_results = 1;

% load group average cifti
if washU_120
    out_str = 'WashU120';
    group_avg = ft_read_cifti_mod([root_dir 'group_avgs/120_LR_minsize400_recolored_manualconsensus_LR.dlabel.nii']);
elseif HCP384
    out_str = 'HCP384';
    group_avg = ft_read_cifti_mod([root_dir 'group_avgs/HCP384_infoMap_conBensus_minsize350_recolored.dtseries.nii']);
elseif MSC
    out_str = 'MSC';
    group_avg = ft_read_cifti_mod([root_dir 'group_avgs/MSCavg_rawassn_minsize400_regularized_recolored_cleaned.dscalar.nii']);
elseif yeo_7nets
    out_str = 'Yeo7nets';
    group_avg = ft_read_cifti_mod([root_dir 'group_avgs/Yeo_7nets.dtseries.nii']);
elseif yeo_17nets
    out_str = 'Yeo17nets';
    group_avg = ft_read_cifti_mod([root_dir 'group_avgs/Yeo_17nets.dtseries.nii']);
end
[rgb_colors, network_names] = get_rgb_names(out_str);
left_hem = group_avg.data(1:29696);
right_hem = group_avg.data(29697:59412);

%load surf area file
surf_areas = ft_read_cifti_mod([root_dir 'needed_files/surf_areas_verts.dtseries.nii']);
lh_surf = surf_areas.data(1:29696);
rh_surf = surf_areas.data(29697:end);

%initialize variable
net_size = [];

for net = 1:numel(network_names)
    lh_verts = find(left_hem==net);
    rh_verts = find(right_hem==net);
    net_size(net,1) = length(lh_verts); %number of vertices in left hemisphere
    net_size(net,2) = length(lh_verts)/length(left_hem); %proportion of vertices in left hemisphere
    net_size(net,3) = sum(lh_surf(lh_verts)); % surface area in left hemisphere
    net_size(net,4) = sum(lh_surf(lh_verts))/sum(lh_surf); % proportion of surface area in left hemisphere
    net_size(net,5) = length(rh_verts); %number of vertices in right hemisphere
    net_size(net,6) = length(rh_verts)/length(right_hem); %proportion of vertices in right hemisphere
    net_size(net,7) = sum(rh_surf(rh_verts)); %surface area in right hemisphere
    net_size(net,8) = sum(rh_surf(rh_verts))/sum(rh_surf); %proportion of surface area in right hemisphere
end

save([out_dir out_str '_network_sizes_across_hems.mat'], 'net_size');

if plot_results
    x = net_size(:,4); y = net_size(:,8);
    scatter(x, y, 80, rgb_colors, 'filled')
    ax_max = max([x;y])+(std([x;y]/2))
    axis([0 ax_max 0 ax_max]);
    line = refline(1,0);
    line.Color = 'black';
    xlabel('Left Hemisphere')
    ylabel('Right Hemisphere')
    ax = gca;
    ax.FontSize = 24;
    print(gcf, [out_dir out_str '_groupavg_nets_surfarea_scatter.jpg'], '-dpng', '-r300')
    close gcf
end    
    


function [rgb names] = get_rgb_names(sample)
if strcmp(sample, 'Yeo7nets')
    names = {'Medial Wall', 'DAN', 'FPN', 'DMN', 'Visual', 'Limbic', 'Somatomotor', 'VAN'};
    rgb = [0,0,0;
    0,0.463000000000000,0.0550000000000000;
    0.902000000000000,0.576000000000000,0.129000000000000;
    0.804000000000000,0.239000000000000,0.306000000000000;
    0.471000000000000,0.0710000000000000,0.522000000000000;
    0.863000000000000,0.973000000000000,0.639000000000000;
    0.275000000000000,0.510000000000000,0.706000000000000;
    0.769000000000000,0.224000000000000,0.976000000000000];
elseif strcmp(sample, 'Yeo17nets');
    names = {'Medial Wall', 'Visual Central', 'DMN A', 'DAN B', 'Control A', 'Limbic A', 'DAN A', 'Control B', 'DMN B', 'DMN C', 'Visual Peripheral', 'Somatomotor B', 'Limbic B', 'Control C', 'Somatomotor A', 'Salience', 'VAN', 'DMN D (Aud)'}; 
    rgb = [0         0         0;
    1.0000         0         0;
    1.0000    1.0000         0;
         0    0.4630    0.0550;
    0.9020    0.5760    0.1290;
    0.4750    0.5250    0.1920;
    0.2860    0.6080    0.2310;
    0.5250    0.1920    0.2860;
    0.8040    0.2390    0.3060;
         0         0    0.5100;
    0.4710    0.0710    0.5220;
    0.1650    0.8000    0.6390;
    0.8630    0.9730    0.6390;
    0.4670    0.5450    0.6860;
    0.2750    0.5100    0.7060;
    1.0000    0.5920    0.8310;
    0.7690    0.2240    0.9760;
    0.0430    0.1840    1.0000];
else
    rgb = [1 0 0; %DMN   
    0 0 .6; %Vis
    1 1 0; %FP
    .67 .67 .67; %Unassigned
    0 .8 0; %DAN
      .67 .67 .67; %Unassigned2
      0 .6 .6;%VAN
      0 0 0; % Sal
      .3 0 .6; %CON
      .2 1 1; %SMd
      1 .5 0; % SMl
      .6 .2 1; %Aud
      .2 1 .2; %Tpole
      0 .2 .4; %MTL
      0 0 1; %PMN
      .8 .8 .6]; %PON
    names = {'DMN','Vis','FP','Unassigned','DAN','Unassigned','VAN','Sal','CO','SMd','SMl','Aud','Tpole','MTL','PMN','PON'};
end
end


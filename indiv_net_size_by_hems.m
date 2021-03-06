%% Symmetry of individualized networks

clear all

%--------------------------------------------------------------------------
%% PATHS 
root_dir = '/Users/dianaperez/Desktop/'; % location of code directory
data_loc = '/Volumes/fsmresfiles/PBS/Gratton_Lab/HCP/Variants/HCP_template_match_to_WU120/';
temp_match_str = '_dice_to_template_kden0.05_wta_map.dtseries.nii';
output_dir = '/Users/dianaperez/Desktop/lateralization_code/testing_output/indiv_net_symm/';
outfile = [output_dir '/HCP384_indiv_network_size_by_hems.mat'];
if ~exist(output_dir)
    mkdir(output_dir)
end
if ~exist(outfile, 'file')
    
    % load subjects list
    load([root_dir '/lateralization_code/needed_files/goodSubs384.mat'])
    all_subs = goodSubs384(:,1);
    network_names = {'DMN','Vis','FP','Unassigned','DAN','Unassigned2','VAN','Sal','CO','SMd','SMl','Aud','Tpole','MTL','PMN','PON'};
    % surface areas for each hem
    surf_areas = ft_read_cifti_mod([root_dir 'lateralization_code/needed_files/surf_areas_verts.dtseries.nii']);
    surf_areas_LHem = surf_areas.data(1:29696);
    surf_areas_RHem = surf_areas.data(29697:end);
    clear surf_areas

    % for each subject, load their template-match network map
    for s = 1:length(all_subs)
        cifti = ft_read_cifti_mod([data_loc num2str(all_subs(s)) temp_match_str]);
        left_hem = cifti.data(1:29696);
        right_hem = cifti.data(29697:end);
        for net = 1:numel(network_names)
            left_hem_verts(s,net) = length(find(left_hem==net));
            right_hem_verts(s,net) = length(find(right_hem==net));
            diff_num_verts(s,net) = left_hem_verts(s,net) - right_hem_verts(s,net);
            left_hem_surf(s,net) = sum(surf_areas_LHem(find(left_hem==net)));
            right_hem_surf(s,net) = sum(surf_areas_RHem(find(right_hem==net)));
            diff_surf(s,net) = left_hem_surf(s,net) - right_hem_surf(s,net);
        end
    end

    indiv_nets_size = [];
    indiv_nets_size.left_hem.num_verts = left_hem_verts;
    indiv_nets_size.right_hem.num_verts = right_hem_verts;
    indiv_nets_size.diff.num_verts = diff_num_verts;
    indiv_nets_size.left_hem.surf_area = left_hem_surf;
    indiv_nets_size.right_hem.surf_area = right_hem_surf;
    indiv_nets_size.diff.surf_area = diff_surf;
    save([output_dir '/HCP384_indiv_network_size_by_hems.mat'], 'indiv_nets_size')
else
    load(outfile)
end

%% for plot
names = {'DMN','Vis','FP',' ','DAN',' ','VAN','Sal','CO','SMd','SMl','Aud','Tpole','MTL','PMN','PON'};
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
for n = 1:numel(names)
rgb_for_plot{n} = rgb(n,:);
end
diff_surf_area = indiv_nets_size.diff.surf_area;
avg_diff = mean(diff_surf_area);
diff_surf_area(385,:) = avg_diff;
ind = zeros(385,1);
ind(385) = 1;
net_inds = [ind ind ind ind ind ind ind ind ind ind ind ind ind ind ind ind];
handles = plotSpread(diff_surf_area, 'categoryMarkers', {'x', '.'}, 'categoryLabels', {'Indiv_diff_scores','Average'}, 'distributionColors', rgb_for_plot', 'categoryIdx', net_inds, 'xNames', names)
scatter(1:16, avg_diff, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'k', 'SizeData', 50)
scatter(8,avg_diff(1,6), 'MarkerEdgeColor', 'w', 'MarkerFaceColor', 'w', 'SizeData', 50)
ylabel('Difference in surface area of individual-specific networks')
print(gcf,[output_dir 'HCP384_indiv_nets_diff_surf_area.jpg'],'-dpng','-r300');
close gcf

%% corelation between individualized network surface area and number of variants
load('/Users/dianaperez/Desktop/lateralization_code/testing_output/HCP384_new_split_networksxHem.mat')
diff_numvars_all =[];
diff_sizenets_all = [];   
for net = 1:16
    %diff_numvars = networksxHem.clustersLH(:,net) - networksxHem.clustersRH(:,net);
    diff_numvars = networksxHem.verticesLH(:,net) - networksxHem.verticesRH(:,net);
    diff_size_nets = indiv_nets_size.left_hem.surf_area(:,net) - indiv_nets_size.right_hem.surf_area(:,net);
    diff_numvars_all = [diff_numvars_all; diff_numvars];
    diff_sizenets_all = [diff_sizenets_all; diff_size_nets];
    [r p] = corr(diff_numvars, diff_size_nets);
    rvals(net) = r;
    pvals(net) = p;
    scatter(diff_numvars, diff_size_nets)
    hold on
    p = polyfit(diff_numvars, diff_size_nets,1);
    px = [min(diff_numvars) max(diff_numvars)];
    py = polyval(p, px);
    plot(px, py, 'LineWidth', 2);
    title(names{net});
    close gcf
end
        
[p_fdr, p_masked] = FDR(pvals, 0.025)
    
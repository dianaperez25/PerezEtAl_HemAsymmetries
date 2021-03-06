%% Analyze networks represented in operculum cluster that shows big difference between left and right hemisphere
%clear all

%--------------------------------------------------------------------------
%% PATHS 
%--------------------------------------------------------------------------
root_dir = '/Users/dianaperez/Desktop/lateralization_code/';
output_dir = [root_dir '/testing_output/'];
data_dir = '/Volumes/RESEARCH_HD/HCP_Variants/new_split_vars/reassigned/';
diffmap = ft_read_cifti_mod('/Users/dianaperez/Desktop/Lateralization/Spatial_Location/HCP/HCP_newsplitvars_diffMap_afterclustercorrect_allSubs.dtseries.nii');
maskA_loc = [output_dir 'HCP384_mask_clusterA_moreRHvars.dtseries.nii'];
maskB_loc = [output_dir 'HCP384_mask_clusterB_moreLHvars.dtseries.nii'];
neigh_file_loc = '/Volumes/RESEARCH_HD/Cifti_surf_neighbors_LR_normalwall.mat';
varmap_str = '_uniqueIDs_afterReassign.dtseries.nii';
netvarmap_str = '_reassigned.dtseries.nii';
clusterA_outfile = [output_dir 'HCP384_highAsym_clusterA_moreRHvars_nets.mat'];
clusterB_outfile = [output_dir 'HCP384_highAsym_clusterB_moreLHvars_nets.mat'];
net_assign_mat_loc = [root_dir 'HCP384_net_assignments.mat'];
unique_IDs_mat_loc = [root_dir 'HCP384_unique_IDs.mat'];
plot = 1;

numVerts = 59412; %29696
clusterA_seed = 16620; % identified using wb_view
clusterB_seed = 7704;

if ~exist(net_assign_mat_loc, 'file') || ~exist(unique_IDs_mat_loc, 'file')
    load('goodSubs384.mat')
    subs = goodSubs384;
    clear goodSubs384
    for sub = 1:length(subs)
        net_assign = ft_read_cifti_mod([data_dir num2str(subs(sub)) netvarmap_str]);
        net_assign_mat(:,sub) = net_assign.data;
        unique_IDs_hem = ft_read_cifti_mod([data_dir num2str(subs(sub)) varmap_str]);
        varmap_mat(:,sub) = unique_IDs_hem.data;            
    end
    save(net_assign_mat_loc, 'net_assign_mat')
    save(unique_IDs_mat_loc, 'varmap_mat')
else
    load(net_assign_mat_loc);
    load(unique_IDs_mat_loc);
end
    

neigh = load(neigh_file_loc);
neigh = neigh.neighbors;
min_subject_threshold= 0.05;
template = diffmap;
if ~exist(maskA_loc, 'file')
    RH_diffmap_bin= logical(diffmap.data<=(min_subject_threshold*-1));
    [clusterA_mask] = make_mask(clusterA_seed, neigh, RH_diffmap_bin, numVerts, template, maskA_loc);
else
    clusterA_mask = ft_read_cifti_mod(maskA_loc);
    clusterA_mask = clusterA_mask.data;
end

if ~exist(maskB_loc, 'file')
    LH_diffmap_bin= logical(diffmap.data>=min_subject_threshold);
    [clusterB_mask] = make_mask(clusterB_seed, neigh, LH_diffmap_bin, numVerts, template, maskB_loc);
else
    clusterB_mask = ft_read_cifti_mod(maskB_loc);
    clusterB_mask = clusterB_mask.data;
end
clusterA_seed = find(clusterA_mask(1:29696)==1);
clusterB_seed = find(clusterB_mask(1:29696)==1);

% initialize variables
clusterA_LH = []; clusterA_RH = []; clusterB_LH = []; clusterB_RH = [];

% separate into left and right hemispheres
unique_IDs_mat = insert_nonbrain(varmap_mat, 'both', template);
net_assign_mat = insert_nonbrain(net_assign_mat, 'both', template);    
unique_IDs_LH = unique_IDs_mat(1:32492,:);
unique_IDs_RH = unique_IDs_mat(32493:end,:);
net_assign_LH = net_assign_mat(1:32492, :);
net_assign_RH = net_assign_mat(32493:end, :);
    
 
for sub = 1:size(unique_IDs_LH,2)
     %% LEFT HEM
     [subInfo, clusterA.left_hem.proportion(sub,:), clusterA.left_hem.number(sub,:)] = extract_nets(unique_IDs_LH(:,sub), net_assign_LH(:,sub), clusterA_seed);    
     clusterA_LH = [clusterA_LH; subInfo];
     [subInfo, clusterA.right_hem.proportion(sub,:), clusterA.right_hem.number(sub,:)] = extract_nets(unique_IDs_RH(:,sub), net_assign_RH(:,sub), clusterA_seed);    
     clusterA_RH = [clusterA_RH; subInfo];
     [subInfo, clusterB.left_hem.proportion(sub,:), clusterB.left_hem.number(sub,:)] = extract_nets(unique_IDs_LH(:,sub), net_assign_LH(:,sub), clusterB_seed);    
     clusterB_LH = [clusterB_LH; subInfo];
     [subInfo, clusterB.right_hem.proportion(sub,:), clusterB.right_hem.number(sub,:)] = extract_nets(unique_IDs_RH(:,sub), net_assign_RH(:,sub), clusterB_seed);    
     clusterB_RH = [clusterB_RH; subInfo];
end

clusterA.left_hem.vars = clusterA_LH;
clusterB.left_hem.vars = clusterB_LH;        
clusterA.right_hem.vars = clusterA_RH;              
clusterB.right_hem.vars = clusterB_RH;
       
save(clusterA_outfile, 'clusterA')
save(clusterB_outfile, 'clusterB')


if plot
    figure;
    rgb = [1 0 0; %DMN   
    0 0 .6; %Vis
    1 1 0; %FP
    %.67 .67 .67; %Unassigned
    0 .8 0; %DAN
      %.67 .67 .67; %Unassigned2
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
    network_names = {'DMN','Vis','FP','DAN','VAN','Sal','CO','SMd','SMl','Aud','Tpole','MTL','PMN','PON'};
    good_nets_LH = [clusterA.left_hem.number(:,1:3) clusterA.left_hem.number(:,5) clusterA.left_hem.number(:,7:end)];
    good_nets_RH = [clusterA.right_hem.number(:,1:3) clusterA.right_hem.number(:,5) clusterA.right_hem.number(:,7:end)];
    scatter((.75:1:13.75), sum(good_nets_LH,1), 150, rgb, 'd', 'filled')
    hold on
    scatter((1.25:1:14.25), sum(good_nets_RH,1), 150, rgb, 'filled')
    xticks([1:14])
    xticklabels(network_names)
    max_ax = max(max(sum(good_nets_LH,1)))+(min((std(sum(good_nets_LH))/2)));
    min_ax = min(min(sum(good_nets_LH,1)))-(min((std(sum(good_nets_LH))/2)));
    axis([0.5, 14.5, min_ax, max_ax])
    ax = gca;
    ax.FontSize = 24;
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.3, 0.3, 0.7, 0.5]); %first and second control position on screen, third controls width, and fourth controls height
    print(gcf, '/Users/dianaperez/Desktop/HCP384_high_asymm_clusterA_nets.jpg', '-dpng', '-r300')
    close gcf
    good_nets_LH = [clusterB.left_hem.number(:,1:3) clusterB.left_hem.number(:,5) clusterB.left_hem.number(:,7:end)];
    good_nets_RH = [clusterB.right_hem.number(:,1:3) clusterB.right_hem.number(:,5) clusterB.right_hem.number(:,7:end)];
    scatter((.75:1:13.75), sum(good_nets_LH,1), 150, rgb, 'd', 'filled')
    hold on
    scatter((1.25:1:14.25), sum(good_nets_RH,1), 150, rgb, 'filled')
    xticks([1:14])
    xticklabels(network_names)
    max_ax = max(max(sum(good_nets_RH,1)))+(min((std(sum(good_nets_RH))/2)));
    min_ax = min(min(sum(good_nets_RH,1)))-(min((std(sum(good_nets_RH))/2)));
    axis([0.5, 14.5, min_ax, max_ax])
    ax = gca;
    ax.FontSize = 24;
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.3, 0.3, 0.7, 0.5]); %first and second control position on screen, third controls width, and fourth controls height
    print(gcf, '/Users/dianaperez/Desktop/HCP384_high_asymm_clusterB_nets.jpg', '-dpng', '-r300')
    close gcf
end

%%%
load('/Users/dianaperez/Desktop/lateralization_code/testing_output/operc_nets_righthemcluster_righthem.mat')
clusterA_RH_nets = cluster;
load('/Users/dianaperez/Desktop/lateralization_code/testing_output/operc_nets_righthemcluster_lefthem.mat')
clusterA_LH_nets = cluster;
load('/Users/dianaperez/Desktop/lateralization_code/testing_output/operc_nets_lefthemcluster_righthem.mat')
clusterB_RH_nets = clusterB;
load('/Users/dianaperez/Desktop/lateralization_code/testing_output/operc_nets_lefthemcluster_lefthem.mat')
clusterB_LH_nets = clusterB;
clear LH_cluster RH_cluster
%%%

function [mask] = make_mask(seed_verts, neigh, diffmap_bin, numVerts, template, outfile)
    mask = zeros(numVerts, 1);
    for x=1:30
        for vert = 1:length(seed_verts)
            neigh_verts = neigh(seed_verts(vert),:);
            for n = 1:length(neigh_verts)
                if isnan(neigh_verts(n))
                    continue;
                elseif diffmap_bin(neigh_verts(n)) == 1
                    seed_verts = [seed_verts; neigh_verts(n)];
                end
            end
        end
        seed_verts = unique(seed_verts);
    end
    
    mask(seed_verts) = 1;
    mask_64k = insert_nonbrain(mask, 'both', template)
    mask_64k = [mask_64k(1:32492); mask_64k(1:32492)];
    mask = mask_64k(template.brainstructure>0);
    template.data = mask;
    ft_write_cifti_mod(outfile, template)
end

function [sub_data, proportion, numvars] = extract_nets(unique_IDs_hem, net_assign, cluster_verts)
    unique_IDs = unique(unique_IDs_hem(cluster_verts));
    if unique_IDs(1) == 0
        unique_IDs(1) = [];
    end
    sub_data(:,1) = unique_IDs;
    for var = 1:length(unique_IDs)
        verts = find(unique_IDs_hem==sub_data(var,1));
        sub_data(var,2) = verts(1);
        sub_data(var,3) = net_assign(verts(1));
    end
    for net = 1:16
        if isempty(sub_data)
            proportion(net) = 0;
            numvars(net) = 0;
        else
            proportion(net) = length(find(sub_data(:,3)==net))/size(sub_data,1);
            numvars(net) = length(find(sub_data(:,3)==net));
        end
    end
end
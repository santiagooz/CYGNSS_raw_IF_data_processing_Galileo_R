function [ meta ] = L1metaRead( L1meta_filename, DRT0_vars, time_to_process, plot_tracks )
% Reads netCDF file and saves relevant variables in the output struct "meta".

variables_to_read = {'ddm_timestamp_gps_sec', 'prn_code', 'sp_lat', 'sp_lon', 'sc_lat', 'sc_lon', 'sp_rx_gain',...
    'sc_pos_x', 'sc_pos_y', 'sc_pos_z', 'sc_vel_x', 'sc_vel_y', 'sc_vel_z'};
outstrct=struct('filename', L1meta_filename);
for i=1:length(variables_to_read)         % loop over the number of variables in variables_to_read
    eval(['a=ncread(L1meta_filename,''' variables_to_read{i} ''');'])    % reads in variable data
    outstrct = setfield(outstrct, variables_to_read{i}, a);
    clear a
end

S = outstrct.ddm_timestamp_gps_sec;

time_resolution = mode(diff(outstrct.ddm_timestamp_gps_sec(1:20)));
num_samples = ceil(time_to_process/time_resolution);

% Using the timing reference in the netCDF file and the starting time of the binary file,
% the start_index is obtained to get the PRN, central Doppler and SNR of
% the on board processed DDM (ddmID) during the time interval selected (time_to_process).
[~, start_index] = min(abs(S-DRT0_vars.GPSSeconds_Start));
end_index = start_index + num_samples - 1;

PRN = outstrct.prn_code;
sp_lat = outstrct.sp_lat;
sp_lon = outstrct.sp_lon;
sc_lat = outstrct.sc_lat;
sc_lon = outstrct.sc_lon;
sp_rx_gain = outstrct.sp_rx_gain;


meta.ddm_timestamp = outstrct.ddm_timestamp_gps_sec(start_index : end_index);

meta.sc_pos_x = outstrct.sc_pos_x(start_index : end_index);
meta.sc_pos_y = outstrct.sc_pos_y(start_index : end_index);
meta.sc_pos_z = outstrct.sc_pos_z(start_index : end_index);
meta.sc_vel_x = outstrct.sc_vel_x(start_index : end_index);
meta.sc_vel_y = outstrct.sc_vel_y(start_index : end_index);
meta.sc_vel_z = outstrct.sc_vel_z(start_index : end_index);

% If plot_tracks flag is 1, it plots the tracks of the 4 DDMs processed on
% board, with the antenna receiver gain value for that reflection
% represented by their color as reported in the metadata.

if plot_tracks == 1
    % geobasemap 'satellite'
    geobasemap 'landcover'
    colormap winter
    for dd = 1:4
            geoscatter(sp_lat(dd, start_index : end_index-1), sp_lon(dd, start_index : end_index-1),36,sp_rx_gain(dd, start_index : end_index-1), 'Filled');
            a = colorbar;a.Label.String = 'Rx Gain [dB]';
            hold on
            geoplot(sp_lat(dd, end_index), sp_lon(dd, end_index),'*','Color',[0, 0, 100]/256,'linewidth',2);
            text(sp_lat(dd,end_index),sp_lon(dd,end_index)+.1,sprintf('GPS SVID = %i',PRN(dd, end_index)),'FontSize',15,'Color',[0, 0, 155]/256)
    end
    geoplot(sc_lat(start_index : end_index-1), sc_lon(start_index : end_index-1),'*','Color',[255, 153, 51]/256,'linewidth',2);
    geoplot(sc_lat(end_index), sc_lon(end_index),'*','Color',[100, 20, 0]/256,'linewidth',2);
    text(sc_lat(end_index),sc_lon(end_index)+.1,"CYGNSS satellite",'FontSize',10,'Color',[155, 20, 0]/256)
    geolimits([min(min(sp_lat(:, start_index : end_index))) max(max(sp_lat(:, start_index : end_index)))], [min(min(sp_lon(:, start_index : end_index))) max(max(sp_lon(:, start_index : end_index)))])
end

end


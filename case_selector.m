%% project: CYGNSS_raw_IF_data_processing_Galileo_R
%
% Script that defines the names of the binary and netCDF files to read the
% Level 1 Raw Intermediate Frequency Data Record containing the signal
% samples and the Level 1 Science Data Record used to load necessary
% metadata. It also defines the rinex navigation file path.
%
% To process new registers copy them to the files directory (folder_path)
% and add a new case in the switch below initializing the variables "file",
% "L1MetaFilename" and "rinex_filename".
% Additionaly, it estimates the specular reflection point position, delay
% and Doppler shift.

%% File names initialization for each case

% Each case is defined by its dataset (bin, meta and rinex, same date!) and gal_ID.
% For each case the preferred channel must be defined (0: zenith antenna,
% 1: starboard nadir antenna, 2: port nadir antenna, if present).

switch caseID

    case 0 % T.C. Harvey cyg06

        file = char("cyg06_raw_if_s20170825_141030_e20170825_141130");
        L1meta_filename = folder_path+"cyg06.ddmi.s20170825-000228-e20170825-235959.l1.power-brcs.a21.d21.nc";
        % gal_ID = 1; channel = 2;
        gal_ID = 2; channel = 1;
        rinex_filename = folder_path + 'ABMF00GLP_R_20172370000_01D_EN.rnx'; % filename: Galileo rinex file

    case 1 % Mississippi River cyg06

        file = char("cyg06_raw_if_s20190323_010954_e20190323_011038");
        L1meta_filename = folder_path+"cyg06.ddmi.s20190323-000000-e20190323-235959.l1.power-brcs.a31.d32.nc";
        % gal_ID = 2; channel = 2;
        gal_ID = 4; channel = 1;
        rinex_filename = folder_path + 'ABMF00GLP_R_20190820000_01D_EN.rnx'; % filename: Galileo rinex file

    case 2 % H. Iota Central America cyg04

        file = char("cyg04_raw_if_s20201117_002514_e20201117_002614");
        L1meta_filename = folder_path+"cyg04.ddmi.s20201117-000000-e20201117-235959.l1.power-brcs.a31.d32.nc";
        % gal_ID = 2; channel = 1;
        gal_ID = 3; channel = 2;
        rinex_filename = folder_path + 'ABPO00MDG_R_20203220000_01D_EN.rnx'; % filename: Galileo rinex file
    
    case 3  % Registro dante
        file = char("cyg08_raw_if_s20220305_155152_e20220305_155252");
        L1meta_filename = folder_path+"cyg08.ddmi.s20220305-000000-e20220305-235959.l1.power-brcs.a31.d32.nc";
        % gal_ID = 4; channel = 1;
        gal_ID = 5; channel = 2;
        rinex_filename = folder_path + 'ABPO00MDG_R_20220640000_01D_EN.rnx'; % filename: Galileo rinex file

    case 4
        file = char("cyg04_raw_if_s20230916_224422_e20230916_224522");
        L1meta_filename = folder_path+"cyg04.ddmi.s20230916-000000-e20230916-232251.l1.power-brcs.a31.d32.nc";
        gal_ID = 3; channel = 2;
        % gal_ID = 4; channel = 1;
        rinex_filename = folder_path + 'ADIS00ETH_R_20232590000_01D_EN.rnx'; % filename: Galileo rinex file

    case 5 % SWOT A Amazon
        file = char("cyg06_raw_if_s20220429_110235_e20220429_110335");
        L1meta_filename = folder_path+"cyg06.ddmi.s20220429-000000-e20220429-235959.l1.power-brcs.a31.d32.nc";
        gal_ID = 3; channel = 2;
        rinex_filename = folder_path + 'ABPO00MDG_R_20221190000_01D_EN.rnx'; % filename: Galileo rinex file

end

date_str = file(15:18) + "-" + file(19:20) + "-" + file(21:22) + ...
    " " + file(24:25) + ":" + file(26:27) + ":" + file(28:29);
t_rnx_init =  datetime(date_str); % initial time and date

bin_filename = folder_path + sprintf("%s_data.bin",file);

%% Read necessary metadata for processing

% First we read the DRT0 packet in the header of the bin file. The
% important values are stored in the struct DRT0_vars, which are: starting
% time of the register in GPS weeks and seconds, data format as detailed in
% the report "CYGNSS Raw IF Data File Format", sample rate, and local
% oscillator frequencies for each channel
format = 'uint8';
fileID = fopen(bin_filename,'r');
if fileID == -1, error('Cannot open file: %s', bin_filename); end
DRT0_vars = DRT0packetRead(fileID, format); % function that reads the DRT0 packet in the bin file
fs = DRT0_vars.SampleRate;                  % sample rate
num_channels = DRT0_vars.DataFormat + 1;    % number of channels
fOL = DRT0_vars.CH0LOFreq;                  % LO frequency


% Then we read the netCDF file with information about the DDMs processed on
% board during the time interval of the bin file. We use this information
% to know which are the PRNs of the present reflections.
% If plot_tracks flag is 1, it plots the tracks of the 4 DDMs processed on
% board, with the antenna receiver gain value for that reflection
% represented by their color as reported in the metadata.
if isfile(L1meta_filename)
    meta = L1metaRead(L1meta_filename, DRT0_vars, time_to_process, plot_tracks);
else
    error("netCDF file not found:\n\n'%s' missing",L1meta_filename)
end


%%
% Galileo satellites orbital parameters
data = rinexread(rinex_filename);
galData = data.Galileo;
[~,satIdx] = unique(galData.SatelliteID);
galData = galData(satIdx,:);
num_gal_sats = length(satIdx); % number of GPS satellites in the simulation

%% Estimation and interpolation of the central delay and Doppler to get a value every Ti


leo_pos = [meta.sc_pos_x, meta.sc_pos_y, meta.sc_pos_z];
leo_vel = [meta.sc_vel_x, meta.sc_vel_y, meta.sc_vel_z];


% Galileo satellites orbits during the processing time
t0 = meta.ddm_timestamp - meta.ddm_timestamp(1);
t_rnx = t_rnx_init + t0/24/3600;
[gal_pos0, ~, satID] = gnssconstellation(t_rnx(1), galData, GNSSFileType="RINEX");
sc_lla = ecef2lla(leo_pos(1,:));
for ss = 1:length(satID)
    [az,elev(ss),slantRange] = ecef2aer(gal_pos0(ss,1),gal_pos0(ss,2),gal_pos0(ss,3),sc_lla(1),sc_lla(2),sc_lla(3),wgs84Ellipsoid);
end

% Filter by minimum elevation and select gal_ID case
elev0 = elev(elev>25);
visible_sats = satID(elev>25);
SVID = visible_sats(gal_ID);


% Calculation of SP position for the selected satellite
clear gal_pos gal_vel
tic
wb = waitbar(0, '   Calculating specular reflection points position: 0% completed    ');
for nn = 1:length(t0)
    [gal_pos(nn,:,:), gal_vel(nn,:,:), satID] = gnssconstellation(t_rnx(nn), galData, GNSSFileType="RINEX");

    sv_idx = find(satID == SVID);
    sp_pos_aux(nn, :) = SpecularReflectionPoint(gal_pos(nn, sv_idx,:), leo_pos(nn,:)); % Specular reflection point position
    sp_lla(nn, :) = ecef2lla(sp_pos_aux(nn, :));


    % progression bar
    time_past = toc;
    time_per_loop = time_past/nn;
    time_left = (length(t0)-nn)*time_per_loop;
    time_left_h = floor(time_left/3600);
    time_left_m = floor((time_left - time_left_h*3600)/60);
    time_left_s = floor(time_left - time_left_h*3600 - time_left_m*60);
    msg = sprintf('   Calculating specular reflection points position: %i%% completed   \n%i:%i:%i remaining', floor(nn/length(t0)*100), time_left_h, time_left_m, time_left_s);
    waitbar(nn/length(t0), wb, msg)
end
close(wb)

gal_pos = squeeze(gal_pos(:,sv_idx,:));
gal_vel = squeeze(gal_vel(:,sv_idx,:));

% Direct and reflected signal delay computation
dir_delay = vecnorm(leo_pos-gal_pos,2,2)/3e8*1.023e6;
ref_delay = (vecnorm(leo_pos-sp_pos_aux,2,2)+vecnorm(gal_pos-sp_pos_aux,2,2))/3e8*1.023e6;
rel_delay = ref_delay - dir_delay;

% Direct and reflected signal Doppler shift computation
m = (gal_pos - sp_pos_aux)./vecnorm(gal_pos-sp_pos_aux,2,2);
n = (sp_pos_aux - leo_pos)./vecnorm(leo_pos-sp_pos_aux,2,2);
d = (gal_pos - leo_pos)./vecnorm(gal_pos-leo_pos,2,2);
ref_Doppler = 1575.42e6/3e8*(diag(-gal_vel*m' + leo_vel*n'));
dir_Doppler = 1575.42e6/3e8*(diag((-gal_vel + leo_vel)*d'));


sp_lla(sp_lla(:,2)<0,2) = sp_lla(sp_lla(:,2)<0,2) + 360;

Doppler_central0 = ref_Doppler;
delay_central0 = ref_delay;

% Plot Galileo reflection ground track
if plot_tracks == 1
    figure(1);geoplot(sp_lla(:, 1), sp_lla(:, 2),'*','Color','k','linewidth',2);
    text(sp_lla(end,1),sp_lla(end,2)+.1,sprintf('Gal. SVID = %i', SVID),'FontSize',15,'Color','k')
end

% Interpolates delay and Doppler every Ti seconds
if time_to_process ~= 1
    t2 = (0:Ti:time_to_process-Ti);
    linear_param = polyfit(t0, Doppler_central0,1);
    Doppler_central = polyval(linear_param, t2);
    linear_param = polyfit(t0, delay_central0, 1);
    delay_central = polyval(linear_param,t2);
else
    Doppler_central = Doppler_central0;
end
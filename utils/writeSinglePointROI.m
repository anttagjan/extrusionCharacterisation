function writeSinglePointROI(filename, ROI)
% writeSinglePointROI
% Writes a VALID ImageJ Point ROI with Header2 (C,Z,T)
% Fully compatible with Roi.getPosition() and setSlice()

fid = fopen(filename,'w','ieee-be');

%% ================= IMAGEJ ROI HEADER =================
fwrite(fid,'Iout','char');     % magic
fwrite(fid,217,'int16');       % ROI version

fwrite(fid,10,'uint8');        % ROI type = Point
fwrite(fid,0,'uint8');         % unused

% ---- integer pixel coordinates (NO subpixel)
x = round(ROI.mfCoordinates(1));
y = round(ROI.mfCoordinates(2));

top    = y;
left   = x;
bottom = y + 1;
right  = x + 1;

fwrite(fid,[top left bottom right],'int16');
fwrite(fid,1,'uint16');        % number of points = 1

% ---- required unused fields
fwrite(fid,zeros(4,1),'float32'); % x1,y1,x2,y2
fwrite(fid,0,'int16');            % stroke width
fwrite(fid,0,'uint32');           % shape size
fwrite(fid,0,'uint32');           % stroke color
fwrite(fid,0,'uint32');           % fill color
fwrite(fid,0,'int16');            % subtype
fwrite(fid,0,'int16');            % options (NO subpixel)
fwrite(fid,0,'uint8');            % arrow style
fwrite(fid,0,'uint8');
fwrite(fid,0,'int16');

% ---- legacy position (still required)
frame = max(1, round(ROI.vnPosition(3)));
fwrite(fid, frame, 'uint32');

%% ================= HEADER2 =================
header2_offset = 64;
fwrite(fid, header2_offset, 'uint32');

% ---- pad to header2
cur = ftell(fid);
fwrite(fid, zeros(header2_offset - cur,1),'uint8');

% ---- C Z T  
fwrite(fid, [1 1 1 frame], 'uint32');   % channel=1, slice=1, frame=T

% ---- ROI name parameters
name = ROI.strName;
name_offset = header2_offset + 12 + 8; % after C/Z/T + name params
fwrite(fid, [numel(name)], 'uint32'); %name_offset?

% ---- required header2 fields
fwrite(fid, 0, 'uint32');   % overlay label color
fwrite(fid, 0, 'int16');    % overlay font size
fwrite(fid, 0, 'uint8');    % opacity
fwrite(fid, 0, 'uint32');   % image size
fwrite(fid, 0, 'float32');  % stroke width
fwrite(fid, [0 0], 'uint32'); % ROI props
fwrite(fid, 0, 'uint32');   % counters offset

%% ================= ROI NAME =================
cur = ftell(fid);
fwrite(fid, zeros(name_offset - cur,1),'uint8');
fwrite(fid, name, 'uint16');   % UTF-16

fclose(fid);
end

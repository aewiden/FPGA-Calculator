%% Creating a COE file for the Xilinx memory generator 
%  E.W. Hansen, Engs 31 14X

%% Copy and paste your code for computing memory contents here; your results will
%  normally be positive integers less than 255 (for 8 bit-wide memory) or 65535 (for
%  16-bit wide memory).  If you want to do negative numbers or fractions, talk to me.
%
%  The results of your calculation must be in a vector called y.
%-----------




%------------
%% Write a .coe file for the Xilinx memory cores

%  File browser box for choosing a filename
[fname, pname] = uiputfile(...
    {'*.coe', 'COE files (*.coe)'; '*.*', 'All Files (*.*)'},...
    'Save coefficients as', 'myROM.coe');

fid = fopen([pname,fname], 'w+t');	% open the file for writing

fprintf(fid, '; Block ROM, created %s\n', datestr(now));
fprintf(fid, 'MEMORY_INITIALIZATION_RADIX=16;\n');
fprintf(fid, 'MEMORY_INITIALIZATION_VECTOR=\n');

MAX = 999
fprintf(fid, "%03d,\n", 0:MAX-1);
fprintf(fid, '%03d;\n', MAX);		% last value is followed by semicolon

fclose(fid);						% close the file
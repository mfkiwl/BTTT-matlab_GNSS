function [] = WriteObs3(obs_file)

%%
% function [] = WriteObs3(obs_file)
% Read the given RINEX file ver3. and writes out 'QM file'
% Copyright: Mi-So, Kim , January 20, 2015
%
% --- Modifications, Mi-So, Kim, January 26, 2015
% 수정사항 1) GPS/GLO/BDS가 아닌 위성(Gaileo, SBAS, QZSS)에 대한 줄바뀜 컨드롤
%         2) 헤더에는 있지만 실제로는 기록이 안된 데이터는 QM file에 기록되지 않도록 함
%         3) GLONASS 데이터 200번대에서 →300번대, Beidou 데이터 300번대에서 → 200번대
% --- Modifications, Mi-So, Kim, July 2, 2015
% 수정사항 : GPS/BDS/GLO 모두 기록되어 있는 데이터 → GPS/BDS or GPS/GLO or GPS/BDS/GLO
% --- Modifications, Jong-Seok, Kim, January 26, 2017
% 수정사항 : 1) 출력결과 gs 소수점 3자리까지 표기
%                 2) file close 추가
%%
% GPS
% GObs = char('C1C','C1P','C2P','C2C','L1C','L2C','D1C','D2C','S1C','S2C');
%             [120   121   122   123   111   112   131   132   141   142]
% Beidou
% CObs = char('C1I','C1Q','C7Q','C7I','L1I','L2Q','D1I','D7I','S1I','S2Q');
%             [220   221   222   223   211   212   231   232   241   242]
% GLONASS
% RObs = char('C1C','C1P','C2P','C2C','L1C','L2C','D1C','D2C','S1C','S2C');
%             [320   321   322   323   311   312   331   332   341   342]

%% 함수만들기 전 테스트
% clc; clear all;
% obs_file = 'jfng0100.15o';
% obs_file ='dgnss_4-5.obs';
%% 헤더 파악
fid_obs = fopen(obs_file,'r');
fid_out = fopen('QMfile','w');

[SatType] = GetSatType(obs_file);
[ObsSeq] = GetObsSeq3(obs_file,SatType);
Get2END(fid_obs);

Type1 = [120 121 122 123 111 112 131 132 141 142];
%% 데이터 기록
while ~feof(fid_obs)
    s = fgets(fid_obs);
    if ~isempty(s)
        if length(s) > 7
            st = s(3:29); NoSats = str2num(s(34:35));
            Epoch(1,1:6) = sscanf(st,'%f',6);
            Y4 = Epoch(1,1); MM = Epoch(1,2); DDD = Epoch(1,3); HH = Epoch(1,4); MIN = Epoch(1,5); SS = Epoch(1,6);
            [gw,gs] = date2gwgs(Y4,MM,DDD,HH,MIN,SS);       
            arrSat = zeros(NoSats,1);
            arrPRN = zeros(NoSats,1);
            for i = 1:NoSats
                s = fgets(fid_obs);  if s == -1, break, end
                Type = s(1); PRN = str2num(s(2:3));
                IN_Sat = strmatch(Type,SatType);
                
                aObs = zeros(10,1);
                if isempty(IN_Sat)
                    continue;
                else
                    arrSat(i,1) = IN_Sat;
                    arrPRN(i) = PRN;
                    aObs = ObsSeq(:,IN_Sat);
                    tObs = find(aObs(:,1) ~= 0);
                    for j = 1:length(tObs)
                        tt = aObs(tObs(j,1),1);
                        TYPE = Type1(tObs(j,1));
                        in1 = 5 + 16 * (tt - 1);
                        in2 = in1 + 12;
                        if in1 < length(s)
                            Obs1 = str2num(s(in1:in2));
                            if Type == 'G'; % GPS
                                TYPE = TYPE;
                            elseif Type == 'C'; % Beidou
                                TYPE = TYPE + 100;
                            elseif Type == 'R'; % GLONASS
                                TYPE = TYPE + 200;
                            end
                            if ~isempty(Obs1)
                                if Type1(tObs(j,1)) == 120
                                    fprintf(fid_out,'%8.3f %4d %5d %16.7f \n',gs, arrPRN(i), TYPE, Obs1);
                                else fprintf(fid_out,'%8.3f %4d %5d %16.3f \n',gs, arrPRN(i), TYPE, Obs1); end
                            else
                                continue;
                            end
                        else
                            continue;
                        end
                    end % for j = 1:length(ObsSeq)
                end % if length(IN_sat) == 0
            end % for i = 1:NoSats
        end % if length(s) > 7
    else
        break;
    end % if ~isempty(s)
end % while ready == 0
fclose('all');



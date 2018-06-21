function [estm] = PP_gr(QMfile,eph,TruePos, DOY, YY)

%
%   function [estm] = PP_gr(QMfile,eph,TruePos, DOY, YY)
%
%   Read the files(QMfile, eph, TruePos, DOY, YY) and estimate Position(GPS/BDS)
%
%   input QMfile
%   input eph matrix : ex> readEPH_all(navfile)
%   input TruePos : 1 X 3 ecef coordinates
%
%   Example : [anything] = PP_gc(QMfile, eph, TruePos, 17, 016)
%
%   coded by Joonseong Gim, Feb 10, 2017
%
%
warning off;
%
% clear all;
% close all;
% % % %
% QMfile = 'QM170125_A';
% QMfile = 'QM170322_Bs_1';
% QMfile = 'QTHS2_18059';        % 2018-02-28 teheran septentrio1

% navfile = 'brdm0250.17p';
% navfile = 'brdm0810.17p';
% TruePos = [-3041235.578 4053941.677 3859881.013];
% YY = 17; DOY =025;
% YY = 17; DOY =081;
% load('eph180228.mat'); DOY = 059; YY  = 18;        % 2018-02-28 teheran
% TruePos = [-3058799.61420451,4083265.35912516,3814946.87192938];
% TruePos = [-3108706.97103816,4078522.84147406,3779757.23816543];    % 오송
%% 불변 변수 설정: 빛의 속도, 관측치
CCC = 299792458.;   % CCC = Speed of Light [m/s]
%% 임계고도각 설정
eleCut = 15;
%% 윤초 핸들링
LeapSec = 18;           % GLO

%% 사용할 관측치 선정
g_ObsType = 120; % gps C1
c_ObsType = 220; % bds C1
r_ObsType = 320; % bds C1

%% QM 파일 읽어들여서 행렬로 저장하고, 사용할 관측치 추출
[arrQM, FinalPRNs, FinalTTs] = ReadQM(QMfile);
% arrQM = arrQM(find(arrQM(:,3) < 300),:);
arrQM = arrQM(find(arrQM(:,3) < 200 | arrQM(:,3) > 300),:);
% arrQM = arrQM(find(arrQM(:,3) > 300),:);
QM = SelectQM_gcr(arrQM, g_ObsType, c_ObsType, r_ObsType);
QM_snr = SelectQM_gcr(arrQM, 141, 241, 341);
FinalPRNs = unique(QM(:,2));
FinalTTs = unique(QM(:,1));

%% Navigation file load
FileNav = strcat('brdm', num2str(DOY,'%03d'), '0.', num2str(YY,'%02d'), 'p');   %: Navigation RINEX file
[gw, gd] = ydoy2gwgd(YY, DOY); %: GPS WEEK 결정
TauC = ReadTauC2(FileNav);

%% eph 생성
% [eph, trashPRN, trashT]=ReadEPH_all(FileNav);

ephGLO = eph;
ephGLO=ephGLO(ephGLO(:,1)<400&ephGLO(:,1)>300,:);ephGLO(:,1)=ephGLO(:,1);

%% 항법메시지를 읽어들여서 행렬로 저장하고, Klobuchar 모델 추출
gps_nav = strcat('brdm', num2str(DOY,'%03d'), '0.', num2str(YY,'%02d'), 'p');   %: Navigation RINEX file
fid = fopen(gps_nav,'r');
if fid == -1
    al = zeros(4,1); be = zeros(4,1);
else
    [al, be] = GetALBE(gps_nav);
end

%% 항법메시지 파일 이름을 이용해 YY, DOY 생성
[gw, gd] = ydoy2gwgd(YY, DOY); %: GPS WEEK 결정

%% 좌표 초기치 설정 및 위경도 변환
AppPos = TruePos;
gd = xyz2gd(AppPos); AppLat = gd(1); AppLon = gd(2);
%% 추정을 위한 매개변수 설정
Maxiter = 10;
EpsStop = 1e-4;
ctr = 1; ctr2 = 1; ctr3 = 1;
eleCut = 15; deltat = 60;
x = [AppPos ctr ctr2]';          % All system
% x = [AppPos ctr ctr2]';                 % dual system
% x = [AppPos ctr]';                 % alone system
%%
NoEpochs = length(FinalTTs);
estm = zeros(NoEpochs, 7);
SatPosArr_before=zeros(24,26);icolArr_before=zeros(24,2);
nEst = 0;
usedSats = zeros(1,length(FinalPRNs)+1);
usedSats(1,2:length(FinalPRNs)+1) = FinalPRNs';
tic;
QM = QM(find(QM(:,2) ~= 132),:);
for j = 1:NoEpochs % 60:65%
    
    % for j = 1:1000
    gs = FinalTTs(j);
    indexQM = find(QM(:,1) == gs);
    indexQM_snr = find(QM_snr(:,1) == gs);
    QM1e = QM(indexQM,:);
    QM1e_snr = QM_snr(indexQM_snr,:);
    existprn = intersect(QM1e(:,2), unique(eph(find(eph(:,22) == 0),18)));
%     %% teheran 180228_1
%     existprn = existprn(find(existprn(:) ~= 114 & existprn(:) ~= 303 & existprn(:) ~= 311 &...
%         existprn(:) ~= 301));       
    %% teheran 180228_1
    existprn = existprn(find(existprn(:) ~= 103 & existprn(:) ~= 110 & existprn(:) ~= 112 &...
        existprn(:) ~= 302 & existprn(:) ~= 304 & existprn(:) ~= 323 & existprn(:) ~= 116));       
    NoSats = length(existprn);
    if length(find(existprn < 200)) < 1 | length(find(existprn > 300)) < 1
        continue
    end
    for iter = 1:Maxiter
        
        HTH = zeros(5,5);
        HTy = zeros(5,1);
        NoSatsUsed = 0;
        NoGPSsUsed = 0;
        NoBDSsUsed = 0;
        NoGLOsUsed = 0;
        
        cnt2=1;         % 관측행렬, Y행렬 생성을 위한 변수
        
        if NoSats <= 5
            break
        end
        vec_site = x(1:3)';
        ZHD = TropGPTh(TruePos, gw, gs); %: TROP: GPT
        for i = 1:NoSats
            
            prn = existprn(i);
            obs = QM1e(find(QM1e(:,2) == prn),4);
            snr = QM1e_snr(find(QM1e_snr(:,2) == prn),4);
            if prn < 300
                icol = PickEPH(eph, prn, gs);
                toe = eph(icol, 8); a = eph(icol, 19); b = eph(icol, 20); c = eph(icol, 21); Tgd = eph(icol, 23);
                %             STT=0;
                STT = GetSTTbrdm(gs, eph, icol, x(1:3)); % 신호전달시간 계산
                
                if prn > 100 && prn < 200
                    tc = gs - STT ;             % 신호전달시간 보정
                elseif prn > 200 && prn < 300
                    tc = gs - STT- LeapSecBDS;  % 신호전달 시간 보정... bds윤초 반영
                end
                SatPos = GetSatPosNC_GC(eph, icol, tc); % 위성위치 산출
                SatPos = RotSatPos(SatPos, STT); % 지구자전효과 고려
            elseif prn > 300
                icol = PickEPH_GLO2(ephGLO, prn, gs);
                TauN = ephGLO(icol,12); % : tau & gamma - 시계오차 보정에 필요
                GammaN = ephGLO(icol,13);
                ch_num = ephGLO(icol,16); % : channel number - 전리층 보정에 필요
                STT = GetSTTbrdc_GLO(gs, ephGLO, icol, x(1:3), deltat); % 방송궤도력으로 신호전달시간 계산
                tc = gs - STT;
                tc = tc - LeapSec - TauC;
                [SatPos,SatVel,SatLS] = GetSatPosGLO(ephGLO,icol,tc,deltat); % 방송궤도력으로 위성위치 계산
                SatPos = RotSatPos(SatPos, STT); % 지구자전효과 고려
                
            end
            vec_rho = SatPos - vec_site';
            rho = norm(vec_rho);
            [az,el] = xyz2azel(vec_rho, AppLat, AppLon);
            
            if prn > 100 && prn < 200
                dIono = klobuchar(al, be, gs, az, el, x(1:3)); % 이온층 보정(Klobuchar 모델)
                dTrop = ZHD2SHD(gw, gs, TruePos, el, ZHD); % 대류권 보정
                dRel = GetRelBRDC(eph, icol, tc); % 상대성효과
                dtSat = a + b*(tc - toe) + c*(tc - toe)^2 - Tgd + dRel; % 위성시계오차 계산... 그룹딜레이, 상대성효과 보정
            elseif prn > 200 && prn < 300
                dIono = klobuchar(al, be, gs, az, el, x(1:3)); % 이온층 보정(Klobuchar 모델)
                dTrop = ZHD2SHD(gw, gs, TruePos, el, ZHD); % 대류권 보정
                dRel = GetRelBRDC(eph, icol, tc); % 상대성효과
                dtSat = a + b*(tc - toe) + c*(tc - toe)^2 - Tgd + dRel; % 위성시계오차 계산... 그룹딜레이, 상대성효과 보정
            elseif prn > 300 && prn < 400
                dIono = klobuchar(al, be, gs, az, el, x(1:3)); % 이온층 보정(Klobuchar 모델)
                dTrop = ZHD2SHD(gw, gs, TruePos, el, ZHD); % 대류권 보정
                dRel = (-2/CCC^2) * dot(SatPos, SatVel); % 상대론적 효과
                tb = ephGLO(icol,2) + LeapSec;
                dtSat = TauN - GammaN*(tc-tb) + TauC + dRel;
            end
            
            
            if el >=eleCut % 임계고도각
                 %% el+snr 가중치 적용
                 W(cnt2,cnt2) = 1;
%                 if ~isempty(snr)
%                     W(cnt2,cnt2) = sind(el)*sind(snr+30);
%                 else
%                     W(cnt2,cnt2) = 0.1;
%                 end
                %                 W = MakeW_elsnr(el,snr);
                if prn > 100 && prn < 200
                    com = rho + x(4) - CCC*dtSat + dTrop + dIono ; % gps 계산값
                    H(cnt2,:) = [-vec_rho(1)/rho -vec_rho(2)/rho -vec_rho(3)/rho 1 0];
                    NoGPSsUsed = NoGPSsUsed + 1;
                elseif prn > 300 && prn < 400
                    com = rho + x(5) - CCC*dtSat + dTrop + dIono;
                    H(cnt2,:) = [-vec_rho(1)/rho -vec_rho(2)/rho -vec_rho(3)/rho 1 1];
                    NoGLOsUsed = NoGLOsUsed + 1;
                end
                y(cnt2,1) = obs - com;
                cnt2=cnt2+1;
                NoSatsUsed = NoSatsUsed + 1;
                usedSats(j+1,1) = gs;
                usedSats(j+1,find(usedSats(1,:) == prn)) = prn;
            end
        end
        if NoGPSsUsed == 0 | NoGLOsUsed == 0
            break; end
            HTH = H(1:cnt2-1,:)'*inv(W(1:cnt2-1,1:cnt2-1))*H(1:cnt2-1,:);
            HTy = H(1:cnt2-1,:)'*inv(W(1:cnt2-1,1:cnt2-1))*y(1:cnt2-1,:);
            xhat = inv(HTH) * HTy;
            x = x + xhat;
            if norm(xhat) < EpsStop;
                nEst = nEst + 1;
                estm(nEst,1) = gs;
                %             estm(nEst,2:5) = x(1:4);
                %             estm(nEst,2:6) = x(1:5);
                estm(nEst,2:6) = x(1:5);
                estm(nEst,7) = NoGPSsUsed;
                estm(nEst,8) = NoBDSsUsed;
                estm(nEst,9) = NoGLOsUsed;
                estm_gd(nEst,1) = gs;
                estm_gd(nEst,2:4) = xyz2gd(x(1:3));
                fprintf('%8d : %3d : %8.2f : %8.2f\n', j, iter, x(1)' - TruePos(1), x(2)' - TruePos(2));
                break;
            elseif cnt2-1 <= 5
                break;
            end

    end
end

%% 측위오차 분석 & 그래프 작성
estm = estm(1:nEst, :);
toc;
% [dXYZ, dNEV] = PosTErrorsJOON(estm(:,1), TruePos, estm(:,2:5));
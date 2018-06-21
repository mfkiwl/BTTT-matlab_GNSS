% 이중차분 시 베이스와 로버의 obs 에 따라 평균 STT를 구해, 위성 위치를 계산하여 처리하는 코드
% VRS 좌표와 정확도를 비교하는 코드
% Weighting 대신 cofactor_matrix를 적용한 코드

%% 코드의사거리 이중차분 알고리즘
% 07/01/2016 : Joonseong
close all; clear all;
% load('DD_gc_test.mat');

%% 항법 시스템 선택 (1=GPS, 2=BDS, 4=GPS/BDS)
SYS = 4;
Dynamic = 0;
%% 계산 날짜 설정
% DOY = 025; YY  = 17;        % 대성
% DOY = 047; YY  = 17;        % 신항대로
% DOY = 081; YY  = 17;        % 오송
% DOY = 082; YY  = 17;        % 강남 1
% DOY = 087; YY  = 17;        % 강남 2
DOY = 128; YY  = 17;        % 강남 2
%% 좌표 참값
% Truedis = 1.41;         % 신항대로 실험
% Truedis = 9.9209;       % 대성 AB
Truedis = 1.3;       % 강남 앞뒤
% TruePos = [-3041235.57800000,4053941.67700000,3859881.01300000];        % 대성 A
% TruePos = [-3041241.74100000,4053944.14300000,3859873.64000000];        % 대성 B
% TruePos = [-3027386.463213997 4071581.638074351 3852036.292033684]; % 현우집앞
% TruePos = [-3108706.97103816,4078522.84147406,3779757.23816543];    % 오송 1
% TruePos = [-3108697.15866998,4078501.37490046,3779789.12574991];    % 오송 2
% TruePos = [-3051683.19233025,4044464.46325792,3861660.30965950];    % 강남 2
TruePos = [-3053365.29481677,4039290.16703344,3865445.80715444];      % 집앞
obsfile = '170509_r2.obs';
TruePos = App_pos(obsfile);
%% QM 파일 핸들링
% QMfileBs = 'QM170125_A';
% QMfileRv = 'QM170125_B';
% QMfileBs = 'QMfile_Bs_8';
% QMfileRv = 'QMfile_Rv_8';
% QMfileBs = 'ublox_joon';
% QMfileRv = 'ublox_hyunu';
% QMfileBs = 'QM170322_Bs_1';        % 오송 bs 1
% QMfileRv = 'QM170322_Rv_1';        % 오송 rv 1
% QMfileBs = 'QM170322_Bs_2';        % 오송 bs 2
% QMfileRv = 'QM170322_Rv_2';        % 오송 rv 2
% QMfileBs = 'QM170328_Bs_2';        % 강남 bs 2
% QMfileRv = 'QM170328_Rv_2';        % 강남 rv 2
% QMfileBs = 'QM170323_Bs';        % 오송 bs 2
% QMfileRv = 'QM170323_Rv';        % 오송 rv 2
QMfileBs = 'QM170509_Bs4';        % 오송 bs 2
QMfileRv = 'QM170509_Rv4';        % 오송 rv 2
% load('modifiedQM.mat');

%% VRS load
% Base_vrs = load('DD1Bs_adm.txt');
% Rover_vrs = load('DD1Rv_adm.txt');
% Base_vrs = load('DD2Bs_adm.txt');
% Rover_vrs = load('DD2Rv_adm.txt');
% Base_vrs = load('PTCO4_joon_170216_adm.txt');
% Rover_vrs = load('PTCO4_hyunu_170216_adm.txt');


%% 불변 변수 설정 : 빛의 속도, 관측치
CCC = 299792458.;   % CCC = Speed of Light [m/s]
Freq_L1 = 1575.42e6;        % L1 주파수
Lambda_L1 = CCC/Freq_L1;    % L1 파장
ObsType = 120;      % 사용할 관측지 설정 - 120 : C/A = C1
ObsType2 = 141;      % 사용할 관측치 설정 - 141: snr = S1
%% 임계고도각 설정
eleCut = 15;
%% 윤초 핸들링
LeapSecBDS = 14;
%% True Distance
[gw, gd] = ydoy2gwgd(YY, DOY); %: GPS WEEK 결정

%% 항법메시지 호출
navfile = strcat('brdm', num2str(DOY,'%03d'), '0.', num2str(YY,'%02d'), 'p');   %: Navigation RINEX file
% [eph, trashPRN, trashT]=ReadEPH_all(navfile);
load('eph170508.mat');

%% 사용할 관측치 선정
g_ObsType = 120; % gps C1
g_ObsType_snr = 141;
g_ObsType_L1 = 111;    % L1
c_ObsType = 220; % bds C1
c_ObsType_snr = 241;
c_ObsType_L1 = 211;    % L1
r_ObsType = 320; % bds C1
r_ObsType_snr = 341;
r_ObsType_L1 = 311;    % L1

%% QM 파일 읽어들여서 행렬로 저장하고, 사용할 관측치 추출
% 베이스 QM
[arrQM_Bs, FinalPRNs_Bs, FinalTTs_Bs] = ReadQM(QMfileBs);
arrQM_Bs = arrQM_Bs(find(arrQM_Bs(:,3) < 300),:);
arrQM_Bs(:,1) = round(arrQM_Bs(:,1));
QM_Bs = SelectQM_gc(arrQM_Bs, g_ObsType, c_ObsType);
QM_Bs_snr = SelectQM_gc(arrQM_Bs, g_ObsType_snr, c_ObsType_snr);
QM_Bs_L1 = SelectQM_gc(arrQM_Bs, g_ObsType_L1, c_ObsType_L1);
if DOY == 47 & YY ==17
    arrQM_song = arrQM_Bs(min(find(arrQM_Bs(:,1) == 387531)):max(find(arrQM_Bs(:,1) == 387842)),:);
    arrQM_no = arrQM_Bs(max(find(arrQM_Bs(:,1) == 387842))+1:end,:);
    arrQM_gps = arrQM_song(find(arrQM_song(:,3) < 200),:);
    arrQM_bds = arrQM_song(find(arrQM_song(:,3) > 200),:);
    arrQM_gps = arrQM_gps(find(arrQM_gps(:,2) ~= 1 & arrQM_gps(:,2) ~= 7 & arrQM_gps(:,2) ~= 4 & arrQM_gps(:,2) ~= 30 & arrQM_gps(:,2) ~= 26),:);
    arrQM_bds = arrQM_bds(find(arrQM_bds(:,2) ~= 4),:);
    arrQM_song = [arrQM_gps; arrQM_bds];
    arrQM_song = arrQM_song(find(arrQM_song(:,2) ~= 7 & arrQM_song(:,3) > 200),:);
    arrQM_song = arrQM_song(find(arrQM_song(:,2) ~= 1 & arrQM_song(:,2) ~= 23 &...
        arrQM_song(:,2) ~= 30 & arrQM_song(:,2) ~= 9),:);
    
    arrQM_song = arrQM_song(find(arrQM_song(:,2) ~= 30 & arrQM_song(:,2) ~= 3 &...
        arrQM_song(:,2) ~= 26 & arrQM_song(:,2) ~= 7 & arrQM_song(:,2) ~= 9 & arrQM_song(:,2) ~= 23 & arrQM_song(:,2) ~= 4),:);
    arrQM_Bs = [arrQM_song;arrQM_no];
end
% 로버 QM
[arrQM_Rv, FinalPRNs_Rv, FinalTTs_Rv] = ReadQM(QMfileRv);
arrQM_Rv = arrQM_Rv(find(arrQM_Rv(:,3) < 300),:);
arrQM_Rv(:,1) = round(arrQM_Rv(:,1));
QM_Rv = SelectQM_gc(arrQM_Rv, g_ObsType, c_ObsType);
QM_Rv_snr = SelectQM_gc(arrQM_Rv, g_ObsType_snr, c_ObsType_snr);
QM_Rv_L1 = SelectQM_gc(arrQM_Rv, g_ObsType_L1, c_ObsType_L1);
if DOY == 47 & YY ==17
    arrQM_song = arrQM_Rv(min(find(arrQM_Rv(:,1) == 387531)):max(find(arrQM_Rv(:,1) == 387842)),:);
    arrQM_no = arrQM_Rv(max(find(arrQM_Rv(:,1) == 387842))+1:end,:);
    arrQM_gps = arrQM_song(find(arrQM_song(:,3) < 200),:);
    arrQM_bds = arrQM_song(find(arrQM_song(:,3) > 200),:);
    arrQM_gps = arrQM_gps(find(arrQM_gps(:,2) ~= 1 & arrQM_gps(:,2) ~= 7 & arrQM_gps(:,2) ~= 4 & arrQM_gps(:,2) ~= 30 & arrQM_gps(:,2) ~= 26),:);
    arrQM_bds = arrQM_bds(find(arrQM_bds(:,2) ~= 4),:);
    arrQM_song = [arrQM_gps; arrQM_bds];
    arrQM_song = arrQM_song(find(arrQM_song(:,2) ~= 7 & arrQM_song(:,3) > 200),:);
    arrQM_song = arrQM_song(find(arrQM_song(:,2) ~= 1 & arrQM_song(:,2) ~= 23 &...
        arrQM_song(:,2) ~= 30 & arrQM_song(:,2) ~= 9),:);
    
    arrQM_song = arrQM_song(find(arrQM_song(:,2) ~= 30 & arrQM_song(:,2) ~= 3 &...
        arrQM_song(:,2) ~= 26 & arrQM_song(:,2) ~= 7 & arrQM_song(:,2) ~= 9 & arrQM_song(:,2) ~= 23 & arrQM_song(:,2) ~= 4),:);
    arrQM_Rv = [arrQM_song;arrQM_no];
end

%% 항법메시지를 읽어들여서 행렬로 저장하고, Klobuchar 모델 추출
gps_nav = strcat(navfile(1:3),'c',navfile(5:8),'.',navfile(10:11),'n');
fid = fopen(gps_nav,'r');
if fid == -1
    al = zeros(4,1); be = zeros(4,1);
else
    [al, be] = GetALBE(navfile);
end

%% 라이넥스 파일에서 대략적인 관측소 좌표를 뽑아냄
AppPos = TruePos;

%% 라이넥스 파일에서 Base Station의 좌표를 계산함
Bs = PP_gc(QMfileBs,eph,TruePos,DOY,YY);              % with Correction
% Bs = PP_gc_kf2(QMfileBs,eph,TruePos,DOY,YY);              % with Correction
% Bs = PP_gc_woc(QMfileBs,eph,TruePos,DOY,YY);              % without Correction
% Bs = PP_gc_kf(QMfileBs,eph,TruePos,DOY,YY);              % without Correction
% load('DD_gc_Bs.mat');
% load('DD_gc_Bs_joon_m.mat');
Bs(:,1) = round(Bs(:,1));


%% 두 QM 파일에서 공통시각(epoch) 추출
FinalTTs = intersect(Bs(:, 1), QM_Rv(:, 1));
   

%% 추정에 필요한 초기치 설정
MaxIter = 10;
MaxIter = 4;
EpsStop = 1e-4;
if SYS == 4
    x = [AppPos'; 0];
else
    x = [AppPos'];
end



%% 추정과정 시작
NoEpochs = length(FinalTTs);
% estm = zeros(NoEpochs, 4);  % : c1(gs), c2/3/4(X/Y/Z of Rv), c5(#Sats_obs), c6(#Sats_used)
nEst = 0;

% load('DD_kf_test.mat');
% load('DD_170323_gc.mat');
cnt = 1;

FinalTTs(find(FinalTTs == 370157)) = [];

for j = 100:length(FinalTTs)
% for j = 1193:1193
    gs = FinalTTs(j);
    %% 해당 시각 Bs의 위치 값 찾기(PP-LS)
    Base(j,:) = Bs(find(Bs(:,1) == gs),:);
    TruePosBs_PP = Base(j,2:4);                                             % 베이스 좌표를 기준좌표로 설정

    %     TruePosBs_PP = TruePos;                                             % 고정 좌표를 기준좌표로 설정
    %% base의 gd
    base_gd(j,1) = gs;
    base_gd(j,2:4) = xyz2gd(TruePosBs_PP(1:3));                             % Base의 xyz값 gd 로 변환
    rover_gd(j,1:4) = [gs, xyz2gd(x(1:3)')];
    LatBs = base_gd(j,2); LonBs = base_gd(j,3);
    LatRv = rover_gd(j,2); LonRv = rover_gd(j,3);
    %% 해당 시각 gs의 베이스 관측치 선별
    indexQM1 = find(QM_Bs(:,1) == gs);
    QM_Bs_1e = QM_Bs(indexQM1,:);                                           % Base Pseudo-Range(gs)
    indexQM1 = find(QM_Bs_snr(:,1) == gs);
    QM_Bs_snr_1e = QM_Bs_snr(indexQM1,:);                                   % Base SNR(gs)
    indexQM1 = find(QM_Bs_L1(:,1) == gs);
    QM_Bs_L1_1e = QM_Bs_L1(indexQM1,:);                                   % Base L1(gs)
    
    %% 해당 시각 gs의 로버 관측치 선별
    indexQM2 = find(QM_Rv(:,1) == gs);
    QM_Rv_1e = QM_Rv(indexQM2,:);                                           % Rover Pseudo-Range(gs)
    indexQM2 = find(QM_Rv_snr(:,1) == gs);
    QM_Rv_snr_1e = QM_Rv_snr(indexQM2,:);                                   % Rover SNR(gs)
    indexQM2 = find(QM_Rv_L1(:,1) == gs);
    QM_Rv_L1_1e = QM_Rv_L1(indexQM2,:);                                   % Base L1(gs)
    
    Sats = intersect(QM_Bs_1e(:, 2), QM_Rv_1e(:, 2));
    Sats = intersect(Sats, unique(eph(find(eph(:,22) == 0),18)));
    NoSats = length(Sats);
    
    if NoSats >= 6 & length(Sats(find(Sats(:,1) > 200),:)) > 2
%     if NoSats >= 6
        %% 기준위성 RS와 다른위성 OS 선별/ SatsEl - c1(gs), c2(prn), c3(el)
        [SatsEl, indxRS] = PickRSel_gc(gs, Sats, eph, TruePosBs_PP);  % : RS 기준위성
        GPS = SatsEl(find(SatsEl(:,2) < 200),:);                                % SatsEl 중 GPS 위성군 선택
        BDS = SatsEl(find(SatsEl(:,2) > 200),:);                                % SatsEl 중 BDS 위성군 선택
        GPSRS = GPS(find(GPS(:,3) == max(GPS(:,3))),2);                         % GPS Reference Sat 선택
        BDSRS = BDS(find(BDS(:,3) == max(BDS(:,3))),2);                         % BDS Reference Sat 선택
        GPSindexRS = find(GPS(:,3) == max(GPS(:,3)));                           % GPS Reference Sat Index
        BDSindexRS = find(BDS(:,3) == max(BDS(:,3)));                           % BDS Reference Sat Index
        RS = Sats(indxRS); RefSV(j,1) = RS;
        RefSV(j,1:3) = [GPSRS, BDSRS, RS];                                          % 기준위성 PRN 저장
        
        %% gs, 공통위성 수, Base GPS, Rover GPS, Base GLO, Rover GLO...
        %% [gs, 전체 관측 위성수, 베이스 GPS 관측 수, 로버 GPS 관측수,...
        %%  베이스 BDS 관측 수, 로버 BDS 관측 수, 베이스 전체 관측수, 로버 전체 관측수]
        visiSat(j,1) = gs; visiSat(j,2) = length(GPS(:,1)) + length(BDS(:,1));
        visiSat(j,3) = length(QM_Bs_1e(find(QM_Bs_1e(:,2) < 200), 2));
        visiSat(j,4) = length(QM_Rv_1e(find(QM_Rv_1e(:,2) < 200), 2));
        visiSat(j,5) = length(QM_Bs_1e(find(QM_Bs_1e(:,2) > 200), 2));
        visiSat(j,6) = length(QM_Rv_1e(find(QM_Rv_1e(:,2) > 200), 2));
        visiSat(j,7) = visiSat(j,3)+visiSat(j,5);
        visiSat(j,8) = visiSat(j,4)+visiSat(j,6);
        
        %% GPS/BDS 기준 위성 snr 값 추출
        GPS_snr_Bs_RS = QM_Bs_snr_1e(find(QM_Bs_snr_1e(:,2) == GPSRS),4);           % 베이스, GPS 기준 위성 snr 값
        BDS_snr_Bs_RS = QM_Bs_snr_1e(find(QM_Bs_snr_1e(:,2) == BDSRS),4);           % 베이스, BDS 기준 위성 snr 값
        GPS_snr_Rv_RS = QM_Rv_snr_1e(find(QM_Rv_snr_1e(:,2) == GPSRS),4);           % 베이스, GPS 기준 위성 snr 값
        BDS_snr_Rv_RS = QM_Rv_snr_1e(find(QM_Rv_snr_1e(:,2) == BDSRS),4);           % 베이스, BDS 기준 위성 snr 값
        snr_Bs_RS = QM_Bs_snr_1e(find(QM_Bs_snr_1e(:,2) == RS),4);           % 베이스, GPS 기준 위성 snr 값
        snr_Rv_RS = QM_Rv_snr_1e(find(QM_Rv_snr_1e(:,2) == RS),4);           % 베이스, GPS 기준 위성 snr 값
        L1_Bs_RS = QM_Bs_L1_1e(find(QM_Bs_L1_1e(:,2) == RS),4);           % 베이스, GPS 기준 위성 snr 값
        L1_Rv_RS = QM_Rv_L1_1e(find(QM_Rv_L1_1e(:,2) == RS),4);           % 베이스, GPS 기준 위성 snr 값
        %% Iteration 시작
        for Iter = 1:MaxIter
            
            cnt2=1;
            %% 전체 기준위성 좌표 먼저 계산 - Bs 기준
            icol = PickEPH(eph, RS ,gs);
            %% 진이 학생 아이디어
            t_delay = QM_Bs_1e(find(QM_Bs_1e(:,2) == RS),4)/CCC;
            t_delay = (QM_Rv_1e(find(QM_Rv_1e(:,2) == RS),4)/(CCC+t_delay))/2;
            STT = GetSTTbrdm(gs, eph, icol, TruePosBs_PP');                     % 신호전달시간 계산
            tc = gs - t_delay;                                                  % 진이학생 아이디어
            vec_RS = GetSatPosNC_GC(eph, icol, tc);
            vec_RS = RotSatPos(vec_RS, t_delay);                              % 지구 자전효과 고려 진이학생
            %% GPS 기준위성 좌표 먼저 계산 - Bs 기준
            icol = PickEPH(eph, GPSRS ,gs);
            t_delay = QM_Bs_1e(find(QM_Bs_1e(:,2) == GPSRS),4)/CCC;
            t_delay = (QM_Rv_1e(find(QM_Rv_1e(:,2) == GPSRS),4)/(CCC+t_delay))/2;
            tc = gs - t_delay;
            vec_GPSRS = GetSatPosNC_GC(eph, icol, tc);
            vec_GPSRS = RotSatPos(vec_GPSRS, t_delay);                              % 지구 자전효과 고려
            %% BDS 기준위성 좌표 먼저 계산 - Bs 기준
            icol = PickEPH(eph, BDSRS ,gs);
            t_delay = QM_Bs_1e(find(QM_Bs_1e(:,2) == BDSRS),4)/CCC;
            t_delay = (QM_Rv_1e(find(QM_Rv_1e(:,2) == BDSRS),4)/(CCC+t_delay))/2;
            tc = gs - t_delay;
            vec_BDSRS = GetSatPosNC_GC(eph, icol, tc);
            vec_BDSRS = RotSatPos(vec_BDSRS, t_delay);                              % 지구 자전효과 고려
            NoGPSSatsUsed = length(GPS(:,1));                                   % GPS 사용 위성수 초기값
            NoBDSSatsUsed = length(BDS(:,1));                                   % BDS 사용 위성수 초기값
            NoSatsUsed = length(Sats(:,1));                                      % 전체 사용 위성수 초기값
            
            %% 선택 시스템 추정
            switch SYS
                case 1
                    %% GPS DD part
                    for kS = 1:length(GPS(:,1))
                        if kS == GPSindexRS || GPS(kS, 3) < eleCut
                            if GPS(kS, 3) < eleCut
                                NoGPSSatsUsed = NoGPSSatsUsed - 1;
                                disp([GPSRS GPS(kS, 2)])
                            end
                            continue
                        end
                        %% DD 관측치 생성 파트
                        GPSOS = GPS(kS,2);
                        OtherGPSSats(kS,1) = GPSOS;
                        GPS_snr_Bs_OS = QM_Bs_snr_1e(find(QM_Bs_snr_1e(:,2) == GPSOS),4);           % 베이스, GPS 기준 위성 snr 값
                        GPS_snr_Rv_OS = QM_Rv_snr_1e(find(QM_Rv_snr_1e(:,2) == GPSOS),4);           % 베이스, GPS 기준 위성 snr 값
                        
                        obs_BsRS = QM_Bs_1e(find(QM_Bs_1e(:, 2) == GPSRS), 4);
                        obs_RvRS = QM_Rv_1e(find(QM_Rv_1e(:, 2) == GPSRS), 4);
                        obs_BsOS = QM_Bs_1e(find(QM_Bs_1e(:, 2) == GPSOS), 4);
                        obs_RvOS = QM_Rv_1e(find(QM_Rv_1e(:, 2) == GPSOS), 4);
                        obs = (obs_BsRS - obs_RvRS) - (obs_BsOS - obs_RvOS);
                        %% DD 계산치 생성 파트 - 기타위성 좌표 계산(기준위성 좌표는 이미 계산 완료)
                        icol = PickEPH(eph, GPSOS, gs);
                        t_delay = QM_Bs_1e(find(QM_Bs_1e(:,2) == GPSOS),4)/CCC;
                        t_delay = (QM_Rv_1e(find(QM_Rv_1e(:,2) == GPSOS),4)/(CCC+t_delay))/2;
                        STT = GetSTTbrdm(gs, eph, icol, x(1:3)); % :  OS 위성위치를 추정좌표 기준으로 변경 11/9/14
                        tc = gs - t_delay;
                        vec_GPSOS = GetSatPosNC_GC(eph, icol, tc);
                        vec_GPSOS = RotSatPos(vec_GPSOS, t_delay);
                        %% DD 계산치 생성 파트 - 거리계산치를 각각 계산한 다음 DD 계산치 계산
                        vec_BsRS = vec_GPSRS - TruePosBs_PP';  com_BsRS = norm(vec_BsRS);
                        vec_RvRS = vec_GPSRS - x(1:3);    com_RvRS = norm(vec_RvRS);
                        vec_BsOS = vec_GPSOS - TruePosBs_PP';  com_BsOS = norm(vec_BsOS);
                        vec_RvOS = vec_GPSOS - x(1:3);    com_RvOS = norm(vec_RvOS);
                        com = (com_BsRS - com_RvRS) - (com_BsOS - com_RvOS);
                        y = obs - com;
                        Y(cnt2,1) = y;
                        
                        if Iter == 1
                            %% 각 위성 az, el 저장
                            [azBsRS,elBsRS] = xyz2azel(vec_BsRS, LatBs, LonBs);
                            azelBsRS(j,:) = [azBsRS, elBsRS, GPSRS];
                            [azBsOS,elBsOS] = xyz2azel(vec_BsOS, LatBs, LonBs);
                            [azRvOS,elRvOS] = xyz2azel(vec_RvOS, LatRv, LonRv);
                            azelBsOS(cnt,:) = [azBsOS, elBsOS, GPSOS];
                            %% Weighting
                            SNRRS(j,:) = [GPS_snr_Bs_RS, GPS_snr_Rv_RS,gs,GPSRS];
                            SNROS(cnt,:) = [GPS_snr_Bs_OS, GPS_snr_Rv_OS,gs,GPSOS];
                            DDel(cnt,:) = [elBsRS, elBsOS,gs,GPSOS];

                            cnt = cnt + 1;
                            el = elBsOS;
                        end
                        if el >= eleCut
                            % 가중치 계산 파트
                            RS_snr = [GPS_snr_Bs_RS, GPS_snr_Rv_RS,gs,GPSRS];
                            OS_snr = [GPS_snr_Bs_OS, GPS_snr_Rv_OS,gs,GPSOS];
                            if cnt2 == 1
                                elsnr_Bs(cnt2,1:2) = [elBsRS, GPS_snr_Bs_RS];
                                elsnr_Rv(cnt2,1:2) = [elBsRS, GPS_snr_Rv_OS];
                            end
                            elsnr_Bs(cnt2+1,1:2) = [elBsOS, GPS_snr_Bs_OS];
                            elsnr_Rv(cnt2+1,1:2) = [elRvOS, GPS_snr_Rv_OS];
                            %                 H(1,1) = vec_RvRS(1)/com_RvRS - vec_RvOS(1)/com_RvOS;
                            %                 H(1,2) = vec_RvRS(2)/com_RvRS - vec_RvOS(2)/com_RvOS;
                            %                 H(1,3) = vec_RvRS(3)/com_RvRS - vec_RvOS(3)/com_RvOS;
                            H(cnt2,1) = vec_RvRS(1)/com_RvRS - vec_RvOS(1)/com_RvOS;
                            H(cnt2,2) = vec_RvRS(2)/com_RvRS - vec_RvOS(2)/com_RvOS;
                            H(cnt2,3) = vec_RvRS(3)/com_RvRS - vec_RvOS(3)/com_RvOS;
                            cnt2= cnt2 + 1;
                            %                 HTH = HTH + H'*W*H;
                            %                 HTy = HTy + H'*W*y;
                        end
                    end
                case 2
                    %% BDS DD part
                    for kS = 1:length(BDS(:,1))
                        if kS == BDSindexRS || BDS(kS, 3) < eleCut
                            if BDS(kS, 3) < eleCut
                                NoBDSSatsUsed = NoBDSSatsUsed - 1;
                                disp([BDSRS BDS(kS, 2)])
                            end
                            continue
                        end
                        %% DD 관측치 생성 파트 --- 추후에 for 루프 밖으로 빼야 함 11/8/14
                        BDSOS = BDS(kS,2);
                        OtherBDSSats(kS,1) = BDSOS;
                        BDS_snr_Bs_OS = QM_Bs_snr_1e(find(QM_Bs_snr_1e(:,2) == BDSOS),4);           % 베이스, BDS 기준 위성 snr 값
                        BDS_snr_Rv_OS = QM_Rv_snr_1e(find(QM_Rv_snr_1e(:,2) == BDSOS),4);           % 베이스, BDS 기준 위성 snr 값
                        
                        obs_BsRS = QM_Bs_1e(find(QM_Bs_1e(:, 2) == BDSRS), 4);
                        obs_RvRS = QM_Rv_1e(find(QM_Rv_1e(:, 2) == BDSRS), 4);
                        obs_BsOS = QM_Bs_1e(find(QM_Bs_1e(:, 2) == BDSOS), 4);
                        obs_RvOS = QM_Rv_1e(find(QM_Rv_1e(:, 2) == BDSOS), 4);
                        obs = (obs_BsRS - obs_RvRS) - (obs_BsOS - obs_RvOS);
                        %% DD 계산치 생성 파트 - 기타위성 좌표 계산(기준위성 좌표는 이미 계산 완료)
                        icol = PickEPH(eph, BDSOS, gs);
                        t_delay = QM_Bs_1e(find(QM_Bs_1e(:,2) == BDSOS),4)/CCC;
                        t_delay = (QM_Rv_1e(find(QM_Rv_1e(:,2) == BDSOS),4)/(CCC+t_delay))/2;
                        STT = GetSTTbrdm(gs, eph, icol, x(1:3)); % :  OS 위성위치를 추정좌표 기준으로 변경 11/9/14
                        tc = gs - t_delay;
                        vec_BDSOS = GetSatPosNC_GC(eph, icol, tc);
                        vec_BDSOS = RotSatPos(vec_BDSOS, t_delay);
                        %% DD 계산치 생성 파트 - 거리계산치를 각각 계산한 다음 DD 계산치 계산
                        vec_BsRS = vec_BDSRS - TruePosBs_PP';  com_BsRS = norm(vec_BsRS);
                        vec_RvRS = vec_BDSRS - x(1:3);    com_RvRS = norm(vec_RvRS);
                        vec_BsOS = vec_BDSOS - TruePosBs_PP';  com_BsOS = norm(vec_BsOS);
                        vec_RvOS = vec_BDSOS - x(1:3);    com_RvOS = norm(vec_RvOS);
                        com = (com_BsRS - com_RvRS) - (com_BsOS - com_RvOS);
                        y = obs -com;
                        Y(cnt2,1) = y;
                        if Iter == 1
                            %% 각 위성 az, el 저장
                            [azBsRS,elBsRS] = xyz2azel(vec_BsRS, LatBs, LonBs);
                            azelBsRS(j,:) = [azBsRS, elBsRS, BDSRS];
                            [azBsOS,elBsOS] = xyz2azel(vec_BsOS, LatBs, LonBs);
                            [azRvOS,elRvOS] = xyz2azel(vec_RvOS, LatRv, LonRv);
                            azelBsOS(cnt,:) = [azBsOS, elBsOS, BDSOS];
                            %% Weighting
                            SNRRS(j,:) = [BDS_snr_Bs_RS, BDS_snr_Rv_RS,gs,BDSRS];
                            SNROS(cnt,:) = [BDS_snr_Bs_OS, BDS_snr_Rv_OS,gs,BDSOS];
                            DDel(cnt,:) = [elBsRS, elBsOS,gs,BDSOS];
                            
                            cnt = cnt + 1;
                            el = elBsOS;
                        end
                        if el >= eleCut
                            % 가중치 계산 파트
                            RS_snr = [BDS_snr_Bs_RS, BDS_snr_Rv_RS,gs,BDSRS];
                            OS_snr = [BDS_snr_Bs_OS, BDS_snr_Rv_OS,gs,BDSOS];
                            if cnt2 == 1
                                elsnr_Bs(cnt2,1:2) = [elBsRS, BDS_snr_Bs_RS];
                                elsnr_Rv(cnt2,1:2) = [elBsRS, BDS_snr_Rv_OS];
                            end
                            elsnr_Bs(cnt2+1,1:2) = [elBsOS, BDS_snr_Bs_OS];
                            elsnr_Rv(cnt2+1,1:2) = [elRvOS, BDS_snr_Rv_OS];
                            %% H 행렬 계산 파트
                            %             H(1,1) = vec_RvRS(1)/com_RvRS - vec_RvOS(1)/com_RvOS;
                            %             H(1,2) = vec_RvRS(2)/com_RvRS - vec_RvOS(2)/com_RvOS;
                            %             H(1,3) = vec_RvRS(3)/com_RvRS - vec_RvOS(3)/com_RvOS;
                            H(cnt2,1) = vec_RvRS(1)/com_RvRS - vec_RvOS(1)/com_RvOS;
                            H(cnt2,2) = vec_RvRS(2)/com_RvRS - vec_RvOS(2)/com_RvOS;
                            H(cnt2,3) = vec_RvRS(3)/com_RvRS - vec_RvOS(3)/com_RvOS;
                            cnt2= cnt2 + 1;
                            %             HTH = HTH + H'*W*H;
                            %             HTy = HTy + H'*W*y;
                        end
                    end
                case 4
                    for kS = 1:NoSats
                        if kS == indxRS || SatsEl(kS, 3) < eleCut
                            if SatsEl(kS, 3) < eleCut
                                NoSatsUsed = NoSatsUsed - 1;
                                if SatsEl(kS, 3) < 200
                                    NoGPSSatsUsed = NoGPSSatsUsed - 1;
                                else
                                    NoBDSSatsUsed = NoBDSSatsUsed - 1;
                                end
                                disp([RS SatsEl(kS, 2)])
                            end
                            continue
                        end
                        %% DD 관측치 생성 파트
                        OS = Sats(kS,1);
                        OtherGPSSats(kS,1) = OS;
                        snr_Bs_OS = QM_Bs_snr_1e(find(QM_Bs_snr_1e(:,2) == OS),4);           % 베이스, GPS 기준 위성 snr 값
                        snr_Rv_OS = QM_Rv_snr_1e(find(QM_Rv_snr_1e(:,2) == OS),4);           % 베이스, GPS 기준 위성 snr 값
                        
                        L1_Bs_OS = QM_Bs_L1_1e(find(QM_Bs_L1_1e(:,2) == OS),4);           % 베이스, GPS 기준 위성 snr 값
                        L1_Rv_OS = QM_Rv_L1_1e(find(QM_Rv_L1_1e(:,2) == OS),4);           % 베이스, GPS 기준 위성 snr 값
                        
                        obs_BsRS = QM_Bs_1e(find(QM_Bs_1e(:, 2) == RS), 4);
                        obs_RvRS = QM_Rv_1e(find(QM_Rv_1e(:, 2) == RS), 4);
                        obs_BsOS = QM_Bs_1e(find(QM_Bs_1e(:, 2) == OS), 4);
                        obs_RvOS = QM_Rv_1e(find(QM_Rv_1e(:, 2) == OS), 4);
                        
                        obs = (obs_BsRS - obs_RvRS) - (obs_BsOS - obs_RvOS);
                        obs2 = (L1_Bs_RS - L1_Rv_RS) - (L1_Bs_OS - L1_Rv_OS);
                        
                        OBS(cnt,1:2) = [(obs_BsRS - obs_RvRS) (obs_BsOS - obs_RvOS)];
%                         OBS2(cnt,1:2) = [(L1_Bs_RS - L1_Rv_RS) (L1_Bs_OS - L1_Rv_OS)];
                        %% DD 계산치 생성 파트 - 기타위성 좌표 계산(기준위성 좌표는 이미 계산 완료)
                        icol = PickEPH(eph, OS, gs);
                        t_delay = QM_Bs_1e(find(QM_Bs_1e(:,2) == OS),4)/CCC;
                        t_delay = (QM_Rv_1e(find(QM_Rv_1e(:,2) == OS),4)/(CCC+t_delay))/2;
                        STT = GetSTTbrdm(gs, eph, icol, x(1:3)); % :  OS 위성위치를 추정좌표 기준으로 변경 11/9/14
%                         tc = gs - STT;
                        tc = gs - t_delay;                                                  % 진이학생 아이디어I
                        vec_OS = GetSatPosNC_GC(eph, icol, tc);
%                         vec_OS = RotSatPos(vec_OS, STT);
                        vec_OS = RotSatPos(vec_OS, t_delay);                              % 지구 자전효과 고려 진이학생
                        %% DD 계산치 생성 파트 - 거리계산치를 각각 계산한 다음 DD 계산치 계산
                        vec_BsRS = vec_RS - TruePosBs_PP';  com_BsRS = norm(vec_BsRS);
                        vec_RvRS = vec_RS - x(1:3);    com_RvRS = norm(vec_RvRS);
                        vec_BsOS = vec_OS - TruePosBs_PP';  com_BsOS = norm(vec_BsOS);
                        vec_RvOS = vec_OS - x(1:3);    com_RvOS = norm(vec_RvOS);
                        com = (com_BsRS - com_RvRS) - (com_BsOS - com_RvOS);
                        y = obs - com;
                        Y(cnt2,1) = y;
                        
                        if Iter == 1
                            %% 각 위성 az, el 저장
                            [azBsRS,elBsRS] = xyz2azel(vec_BsRS, LatBs, LonBs);
                            azelBsRS(j,:) = [azBsRS, elBsRS, RS];
                            [azBsOS,elBsOS] = xyz2azel(vec_BsOS, LatBs, LonBs);
                            [azRvOS,elRvOS] = xyz2azel(vec_RvOS, LatRv, LonRv);
                            azelBsOS(cnt,:) = [azBsOS, elBsOS, OS];
                            %% Weighting
                            SNRRS(j,:) = [snr_Bs_RS, snr_Rv_RS,gs,RS];
                            SNROS(cnt,:) = [snr_Bs_OS, snr_Rv_OS,gs,OS];
                            DDel(cnt,:) = [elBsRS, elBsOS,gs,OS];
                            cnt = cnt + 1;
                            el = elBsOS;
                        end
                        if el >= eleCut 
%                             if OS == 110 | OS == 131 | OS == 202 | OS == 207 | OS == 210 | OS == 112 | OS == 124
                            % 가중치 계산 파트
                            RS_snr = [snr_Bs_RS, snr_Rv_RS,gs,RS];
                            OS_snr = [snr_Bs_OS, snr_Rv_OS,gs,OS];
                            w = 1;
                            if cnt2 == 1
                                elsnr_Bs(cnt2,1:2) = [elBsRS, snr_Bs_RS];
                                elsnr_Rv(cnt2,1:2) = [elBsRS, snr_Rv_OS];
                            end
                            if Iter == 1
                                elsnr_Bs(cnt2+1,1:2) = [elBsOS, snr_Bs_OS];
                                elsnr_Rv(cnt2+1,1:2) = [elRvOS, snr_Rv_OS];
                            end
                            % H 행렬 계산 파트
                            %                 H(1,1) = vec_RvRS(1)/com_RvRS - vec_RvOS(1)/com_RvOS;
                            %                 H(1,2) = vec_RvRS(2)/com_RvRS - vec_RvOS(2)/com_RvOS;
                            %                 H(1,3) = vec_RvRS(3)/com_RvRS - vec_RvOS(3)/com_RvOS;
                            H(cnt2,1) = vec_RvRS(1)/com_RvRS - vec_RvOS(1)/com_RvOS;
                            H(cnt2,2) = vec_RvRS(2)/com_RvRS - vec_RvOS(2)/com_RvOS;
                            H(cnt2,3) = vec_RvRS(3)/com_RvRS - vec_RvOS(3)/com_RvOS;
                            if OS < 200
                                H(cnt2,4) = 0;
                            else
                                H(cnt2,4) = 1;
                            end
                            cnt2= cnt2 + 1;
                            %                 HTH = HTH + H'*W*H;
                            %                 HTy = HTy + H'*W*y;
                        end
                    end
%                     end
            end
            W = DD_cofactor_matrix(elsnr_Bs(:,1), elsnr_Rv(:,1), elsnr_Bs(:,2), elsnr_Rv(:,2), 4);
            HTH = H(1:cnt2-1,:)'*inv(W(1:cnt2-1,1:cnt2-1))*H(1:cnt2-1,:);
            HTy = H(1:cnt2-1,:)'*inv(W(1:cnt2-1,1:cnt2-1))*Y(1:cnt2-1,:);
            
            xhat = inv(HTH) * HTy;
%             x = x(1:3) + xhat(1:3);
            x = x + xhat;
            XHAT(j,1:2) =[gs, norm(xhat)];
%             if norm(xhat(1:3)) < EpsStop;
                if Iter == MaxIter
                nEst = nEst + 1;
                estm(nEst,1) =gs;
                estm(nEst,2:4) =x(1:3);
                estm(nEst,5) = length(GPS(:,1));        % GPS 관측 위성 수
                estm(nEst,6) = length(BDS(:,1));        % BDS 관측 위성 수
                estm(nEst,7) = NoGPSSatsUsed;           % : snr issue 가 없을때
                estm(nEst,8) = NoBDSSatsUsed;           % : snr issue 가 없을때
                estm(nEst,9) = NoSatsUsed;           % : snr issue 가 없을때
                break;
            end
            
        end
    end
    
    %% rover's longi, lati
    if nEst > 1
        Rover_gd(nEst,1) = gs;
        Rover_gd(nEst,2:4) = xyz2gd(estm(nEst,2:4)); % rover의 xyz값 gd 로 변환
        Base_gd(nEst,1) = gs;
        Base_gd(nEst,2:4) = xyz2gd(Bs(find(Bs(:,1) == gs),2:4)); % rover의 xyz값 gd 로 변환
    end
%     AppLat = rover_gd(nEst,2); AppLon = rover_gd(nEst,3);
    
end

%% smoothing
estm_x = smooth(estm(:,2),5,'rlowess');
estm_y = smooth(estm(:,3),5,'rlowess');
estm_z = smooth(estm(:,4),5,'rlowess');
estm_new = estm;
estm_new(:,2:4) = [estm_x, estm_y, estm_z];

azel_sum = [azelBsOS; azelBsRS];
snr_sum = [SNROS;SNRRS];
data = [azel_sum(:,3), azel_sum(:,2), azel_sum(:,1), snr_sum(:,1)];
%% 측위오차 분석 & 그래프 작성
% estm = estm(1:nEst, :);
Base_ex = Base(find(Base(:,1) == 387531):find(Base(:,1) == 387842),:);
estm_ex = estm(find(estm(:,1) == 387531):find(estm(:,1) == 387842),:);
[DDdXYZ, DDdNEV, DDdis, DDrms, DDstd] = PostErrorsDDmv3(estm(100:end,:), Base(100:end,:), Truedis,0, 10, SYS);    % 임의의 장소에서 이동 측위시
% [DDdXYZ, DDdNEV, DDdis, DDrms, DDstd] = PostErrorsDD4(estm, Base, A, B ,8, 12, SYS);    % 임의의 장소에서 이동 측위시

%% 각 위성별 SNR Plot
% DDPlotQM(QM11, QM22, 141, 'Base', 'Rover')

% skyplot = SkyPlot();
% for i=1:length(data)
% prn = data(i,1);
% az = data(i,2);
% el = data(i,3);
% SNR =data(i,4);
% skyplot.add(prn,az,el,SNR);
% end
% skyplot.PLOT();

% if DOY == 47 & YY == 17
%     estm = estm(find(estm(:,1) > 387842),:);
%     Base = Base(find(Base(:,1) > 387842),:);
% end
%% dynamic에 따라 그래프 그리는 방법 선택
if Dynamic == 0
    [DDdXYZ, DDdNEV, DDdis, DDrms, DDstd] = PostErrorsDDstatic(estm(100:end,:), Base(100:end,:), Truedis,0, 10, SYS);    % 임의의 장소에서 이동 측위시
elseif Dynamic == 1
    [DDdXYZ, DDdXYZ_vrs, DDdNEV, DDdNEV_vrs, DDdis, DDrms, result] = PostErrorsDDkine(estm(100:end,:), Base(100:end,:), Base_vrs, Rover_vrs, -2, 2, SYS);    % 임의의 장소에서 이동 측위시
end

figure()
hold on; grid on;
plot(Base_gd(100:end,3), Base_gd(100:end,2),'b.')
plot(Rover_gd(100:end,3), Rover_gd(100:end,2),'r.')
plot_google_map

% [dXYZ, dNEV, result] = PostErrorskine(estm, Rover_vrs, SYS);
FinalTTs = intersect(Base_gd(2:end,1), Rover_gd(2:end,1));

figure(509)
subplot(2,1,1)
hold on; grid on;
xlim([127.02306497574483 127.06449779933797])
ylim([37.49102751458101 37.51444531135456])
% axis([37.486789423903886 37.519210576096114 127.01631872267242 127.07368127732761])
plot_google_map
subplot(2,1,2)
hold on; grid on;
xlim([min(FinalTTs) max(FinalTTs)])
ylim([0 5])
plot([min(FinalTTs),max(FinalTTs)],[1.3,1.3],'r-')

under2m = DDdis(find(DDdis(:,2) < 1.8 & DDdis(:,2) > 0.8),:);
FinalTTs = intersect(under2m(:,1), FinalTTs);
for i =1:length(FinalTTs)
    gs = FinalTTs(i);
    new_estm(i,:) = estm(find(estm(:,1) == gs),:);
    new_base(i,:) = Base(find(Base(:,1) == gs),:);
    dis2d(i,1) = DDdis(find(DDdis(:,1) == gs),2);
    bsgd(i,1:2) = Base_gd(find(Base_gd(:,1) == gs),2:3);
    rvgd(i,1:2) = Rover_gd(find(Rover_gd(:,1) == gs),2:3);
    figure(509)
    subplot(2,1,1)
    hold on; grid on;
    plot(bsgd(i,2), bsgd(i,1),'b.')
    plot(rvgd(i,2), rvgd(i,1),'r.')
%     plot_google_map
%     drawnow
subplot(2,1,2)
hold on; grid on;
if ~isempty(dis2d(i,1))
plot(gs, dis2d(i,1),'ro');end
% drawnow
% pause(0.2)
end

figure()
hold on; grid on;
plot(bsgd(:,2), bsgd(:,1),'b.')
plot(rvgd(:,2), rvgd(:,1),'r.')
plot_google_map
[DDdXYZ, DDdNEV, DDdis, DDrms, DDstd] = PostErrorsDDstatic(new_estm, new_base, Truedis,0, 10, SYS);    % 임의의 장소에서 이동 측위시
% figure(509)
% hold on; grid on;
% plot(Base_gd(2:end,3), Base_gd(2:end,2),'bo-')
% plot(Rover_gd(2:end,3), Rover_gd(2:end,2),'ro-')
% plot_google_map
% 
% 
% Rover_vrs(:,1) = Rover_vrs(:,1) +18 ;
% FinalTTs=intersect(Rover_vrs(:,1),rover_gd(:,1));
% for i= 1:length(FinalTTs)
%     gs = FinalTTs(i);
%     Rover_VRS_GD = Rover_vrs(find(Rover_vrs(:,1) == gs), 2:3);
%     Rover_DD_GD = rover_gd(find(rover_gd(:,1) == gs),2:3);
%     figure(99)
%     hold on; grid on;
%     plot(Rover_VRS_GD(2),Rover_VRS_GD(1),'r.')
%     plot(Rover_DD_GD(2),Rover_DD_GD(1),'b.')
% %     pause(0.3)
% end
% 
% Rv = PP_gc(QMfileRv,eph,TruePos,DOY,YY);
% 
% FinalTTs = intersect(estm(:,1), Rv(:,1));
% for i =1:length(FinalTTs)
%     estm_rv(i,:) = [gs, estm(find(estm(:,1) == FinalTTs(i)),2:4), Rv(find(Rv(:,1) == FinalTTs(i)),2:4)];
%     estm_rv_gd(i,:) = [gs, xyz2gd(estm(find(estm(:,1) == FinalTTs(i)),2:4)), xyz2gd(Rv(find(Rv(:,1) == FinalTTs(i)),2:4))];
%     aver_estm_rv(i,:) = [gs, (estm(find(estm(:,1) == FinalTTs(i)),2:4) + Rv(find(Rv(:,1) == FinalTTs(i)),2:4))/2];
%     aver_estm_rv_gd(i,:) = [gs, xyz2gd((estm(find(estm(:,1) == FinalTTs(i)),2:4) + Rv(find(Rv(:,1) == FinalTTs(i)),2:4))/2)];
% end
% for i=1:length(aver_estm_rv)
%     gs = aver_estm_rv(i,1);
%     idx = find(estm(:,1) == gs);
%     estm(idx,2:4) = aver_estm_rv(i,2:4);
% end
% figure()
% hold on; grid on;
% % plot(estm_rv_gd(:,3), estm_rv_gd(:,2),'b.')
% plot(Rover_vrs(:,3),Rover_vrs(:,2),'b.')
% % plot(estm_rv_gd(:,6), estm_rv_gd(:,5),'r.')
% plot(aver_estm_rv_gd(:,3), aver_estm_rv_gd(:,2),'g.')
% 
% [dXYZ, dNEV, result] = PostErrorskine(estm, Rover_vrs, SYS);
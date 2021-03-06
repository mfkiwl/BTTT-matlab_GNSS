%% GPS & BDS 통합 측위 코드 (DGNSS)
% tic;
clear all; close all;
warning off;
%% 상수 정의
CCC = 299792458.;   % CCC = Speed of Light [m/s]
%% QM 파일, 날짜 핸들링
%-----------170112 테스트---------%
RTCM = load('PPS1_170112.t41');
DOY = 012;YY  = 17;
%% Navigation file load
FileNav = strcat('brdm', num2str(DOY,'%03d'), '0.', num2str(YY,'%02d'), 'p');   %: Navigation RINEX file
[eph, trashPRN, trashT]=ReadEPH_all(FileNav);

for LR=1:24
    LR
    tic;
    switch LR
                case 1
                        FileQM='J_1Hz_L1';
        case 2
            
            FileQM='J_1Hz_R1';
        case 3
        
            FileQM='J_1Hz_L2';
        case 4
                    FileQM='J_1Hz_R2';
        case 5
                    FileQM='J_1Hz_L3';
        case 6
                    FileQM='J_1Hz_R3';
        case 7
            FileQM='J_1Hz_L4';
        case 8
            FileQM='J_1Hz_R4';
        case 9
            FileQM='J_5Hz_L1';
        case 10
            FileQM='J_5Hz_R1';
        case 11
            FileQM='J_5Hz_L2';
        case 12
            FileQM='J_5Hz_R2';
        case 13
            FileQM='J_5Hz_L3';
        case 14
            FileQM='J_5Hz_R3';
        case 15
            FileQM='J_5Hz_L4';
        case 16
            FileQM='J_5Hz_R4';
        case 17
            FileQM='J_10Hz_L1';
        case 18
            FileQM='J_10Hz_R1';
        case 19
            FileQM='J_10Hz_L2';
        case 20
            FileQM='J_10Hz_R2';
        case 21
            FileQM='J_10Hz_L3';
        case 22
            FileQM='J_10Hz_R3';
        case 23
            FileQM='J_10Hz_L4';
        case 24
            FileQM='J_10Hz_R4';
    end
   
    %-----------------------------------------------------%
    [arrQM, FinalPRNs, FinalTTs] = ReadQM(FileQM);
    arrQM = arrQM(find(arrQM(:,3) < 300),:);
    % break
    yyS = num2str(YY,'%02d');
    doyS = num2str(DOY,'%03d');
    [gw, gd] = ydoy2gwgd(YY, DOY); %: GPS WEEK 결정
    [bw, bd] = ydoy2bwbd(YY, DOY); %: BDS WEEK 결정
    
    %% 좌표 참값
    TruePos = [-3012527.5380 4078281.3285 3856555.4327]; %170112 인천공항 초기좌표
    %% 윤초 핸들링
    LeapSecBDS = 14;
    
    %% brdm파일에는 al/be가 없기 때문에 brdc파일에서 가져옴
    al=[0 0 0 0];   be=[0 0 0 0];
    
    %% 사용할 관측치 선정
    g_ObsType = 120; % gps C1
    g_ObsType_snr = 141;
    c_ObsType = 220; % bds C1
    c_ObsType_snr = 241;
    
    %% QM 준비
    QM = SelectQM_gc(arrQM, g_ObsType, c_ObsType);
    QM_snr = SelectQM_gc(arrQM, g_ObsType_snr, c_ObsType_snr);
    %     FinalPRNs = unique(QM(:,2));
    %     FinalTTs = unique(QM(:,1));
    
    %% Doppler smoothing을 위한 QM 핸들링
    QMd =qmHandle(arrQM);
    
    %% 좌표 초기치 설정 및 위경도 변환
    AppPos = TruePos;
    gd = xyz2gd(AppPos); AppLat = gd(1); AppLon = gd(2);
    
    %% 추정을 위한 매개변수 설정
    Maxiter = 10;
    EpsStop = 1e-4;
    ctr = 1; ctr2 = 1;
    eleCut = 15;
    x = [AppPos ctr ctr2]';
    %%
    NoEpochs = length(FinalTTs);
    estm = zeros(NoEpochs, 6);
    Scount = zeros(NoEpochs, 1);
    nEst = 0;
    for j = 1:NoEpochs % 60:65%
        x = [AppPos ctr ctr2]';
        for iter = 1:Maxiter
            gs = FinalTTs(j);
            HTH = zeros(5,5);
            HTy = zeros(5,1);
            clear -global PAST_QM
            QMe_ = qmHandle(QMd.pickQM(gs,':',':'));
            QMe = dopplerSM(QMe_.getQM(),5);
            indexQM = find(QM(:,1) == gs);
            QM1e = QM(indexQM,:);
            QM1e(:,4) = QMe(find(QMe(:,3) < 320),4);
            QM1e_snr = QM_snr(indexQM,:);
            NoSats = length(QM1e);
            NoSatsUsed = 0;
            
            if NoSats < 5
                break
            end
            vec_site = x(1:3)';
            ZHD = TropGPTh(TruePos, gw, gs); %: TROP: GPT
            for i = 1:NoSats
                prn = QM1e(i,2);
                obs = QM1e(i,4);
                snr = QM1e_snr(i,4);
                icol = PickEPH(eph, prn, gs);
                toe = eph(icol, 8); a = eph(icol, 19); b = eph(icol, 20); c = eph(icol, 21); Tgd = eph(icol, 23);
                %             STT=0;
                STT = GetSTTbrdc(gs, eph, icol, x(1:3)); % 신호전달시간 계산
                if prn > 100 && prn < 200
                    tc = gs - STT ;             % 신호전달시간 보정
                elseif prn > 200 && prn < 300
                    tc = gs - STT- LeapSecBDS;  % 신호전달 시간 보정... bds윤초 반영
                end
                SatPos = GetSatPosNC_GC(eph, icol, tc); % 위성위치 산출
                SatPos = RotSatPos(SatPos, STT); % 지구자전효과 고려
                vec_rho = SatPos - vec_site';
                rho = norm(vec_rho);
                [az,el] = xyz2azel(vec_rho, AppLat, AppLon);
                if prn > 100 && prn < 200
                    %                     dIono = 0;
                    %                     dTrop = 0;
                    dIono = ionoKlob(al, be, gs, az, el, x(1:3)); % 이온층 보정(Klobuchar 모델)
                    dTrop = ZHD2SHD(gw, gs, TruePos, el, ZHD); % 대류권 보정
                elseif prn > 200 && prn < 300
                    %                     dIono = 0;
                    %                     dTrop = 0;
                    dIono = ionoKlob(al, be, gs, az, el, x(1:3)); % 이온층 보정(Klobuchar 모델)
                    dTrop = ZHD2SHD(gw, gs, TruePos, el, ZHD); % 대류권 보정
                end
                %             dRel=0;
                dRel = GetRelBRDC(eph, icol, tc); % 상대성효과
                dtSat = a + b*(tc - toe) + c*(tc - toe)^2 - Tgd + dRel; % 위성시계오차 계산... 그룹딜레이, 상대성효과 보정
                if el >=eleCut % 임계고도각
                    %                 W = 1;
                    W = MakeW_elsnr(el,snr);
                    if prn > 100 && prn < 200
                        %                         PRC = PickPRC(RTCM,prn,gs);
                        PRC = 0;
                        com = rho + x(4) - CCC*dtSat + dTrop + dIono - PRC; % gps 계산값
                        H = [-vec_rho(1)/rho -vec_rho(2)/rho -vec_rho(3)/rho 1 0];
                    elseif prn > 200
                        %                         PRC = PickPRC(RTCM,prn,gs);
                        PRC = 0;
                        com = rho + x(5) - CCC*dtSat + dTrop + dIono - PRC; % bds 계산값
                        H = [-vec_rho(1)/rho -vec_rho(2)/rho -vec_rho(3)/rho 0 1];
                    end
                    y = obs - com;
                    HTH = HTH + H'*W*H;
                    HTy = HTy + H'*W*y;
                    NoSatsUsed = NoSatsUsed + 1;
                end
            end
            P = inv(HTH);
            xhat = inv(HTH) * HTy;
            x = x + xhat;
            if norm(xhat) < EpsStop;
                nEst = nEst + 1;
                estm(nEst,1) = gs;
                estm(nEst,2:6) = x(1:5);
                estm(nEst,7) = NoSatsUsed;
                Scount(nEst,1) = NoSatsUsed;
                %                 fprintf('%8d : %3d : %8.2f : %8.2f\n', j, iter, x(1)' - TruePos(1), x(2)' - TruePos(2));
                break;
            end
        end
    end
    estm = estm(1:nEst,:);
    Scount=Scount(1:nEst, :);
    
    
    fixed_tmp = ([FileQM,'=estm;']);
    eval(fixed_tmp);
    toc;
end

% figure(101);
% [dXYZ, dNEV]=PosErrors(estm(:,1), TruePos,estm(:,2:5),Scount);
% break
%
% %% 입력받은 자료의 크기 및 참값에 해당하는 위경도 결정
% NoPos = length(estm(:,1));
% gd = xyz2gd(TruePos); TrueLat = gd(1); TrueLon = gd(2);
% %% 추정된 XYZ와 참값 XYZ의 차이값 결정
% dXYZ = zeros(NoPos,3);
% for k = 1:NoPos
%     gd(k,:) = xyz2gd(estm(k,2:4));
% end
% estm_L=estm;
% estm_R=estm;
% % toc
% % break
%
%
% open ariport_final2.fig
% hold on
% plot(gd(:,2),gd(:,1),'o:')
% axis([126.45219 126.45255 37.44295 37.44325])
% xlabel('longitude')
% ylabel('latitude')
% title('161223 인천공항 Pole 1')
% break


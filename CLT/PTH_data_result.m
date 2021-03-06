clear all
close all

%% VRS load
load('PTCO1_170116_adm.txt');
vrs= PTCO1_170116_adm;
vrs(:,1) = vrs(:,1)+18;

% loaddata = 'PTH_PP.mat';
% loaddata = 'PTH_PP_dop.mat';
loaddata = 'PTH_DGNSS.mat';
% loaddata = 'PTH_DGNSS_dop.mat';

load(loaddata);



TruePos = [-3058799.61420451,4083265.35912516,3814946.87192938];
gd = xyz2gd(TruePos); TrueLat = gd(1); TrueLon = gd(2);
cnt=1; 
for j=1:4
    if j == 1 || j == 3
        temp1 = (['test',num2str(j),'_L']);
        temp2 = (['test',num2str(j),'_R']);
        temp3 = (['test',num2str(j),'_average']);
    end
    for k=1:3
        if j==2
            if k < 3
                temp1 = (['test',num2str(j),'_',num2str(k),'_L']);
                temp2 = (['test',num2str(j),'_',num2str(k),'_R']);
                temp3 = (['test',num2str(j),'_',num2str(k),'_average']);
            end
        elseif j==4
            temp1 = (['test',num2str(j),'_',num2str(k),'_L']);
            temp2 = (['test',num2str(j),'_',num2str(k),'_R']);
            temp3 = (['test',num2str(j),'_',num2str(k),'_average']);
        end
        temp4 = (['FinalTTs=intersect(',temp1,'(:,1),',temp2,'(:,1));']);
        eval(temp4);
        for i=1:length(FinalTTs)
            gs = FinalTTs(i,1);
            vrs_coordi = vrs(find(vrs(:,1)==gs),5:7);
            
            temp5 =([temp3,'(i,1)= gs;']);
            temp6 =([temp3,'(i,2:4)=','(',temp1,'(find(',temp1,'(:,1)==gs),2:4)+',...
                temp2,'(find(',temp2,'(:,1)==gs),2:4))/2;']);
            temp11 = ([temp3,'(i,5:6)=[',temp1,'(i,7),',temp2,'(i,7)];']);
            eval(temp5);
            eval(temp6);
            eval(temp11);
            temp7 =(['GGA=',temp3,'(i,[2,3,4,5,6]);']);
            eval(temp7);
            dXYZ = [GGA(1), GGA(2), GGA(3)] - TruePos;
            
            Scount = [GGA(4:5)];
            dNEV = xyz2topo(dXYZ, TrueLat, TrueLon);
            
            dN = dNEV(:,1); dE = dNEV(:,2); dV = dNEV(:,3);
            
            dNE = sqrt(dN^2 + dE^2);        %rmsH = myRMS(dNE);
            
            d2D(i,1) = dNE;
            
            d3 = sqrt(dN.^2 + dE.^2 + dV.^2); %rms3 = myRMS(d3);
            
            d3D(i,1) = d3;
            
            temp8 = ([temp3,'_result(i,:) = [gs, dN, dE, dV, dNE, d3, Scount];']);
            
            eval(temp8)
            
            if ~isempty(vrs_coordi)
                
                dXYZ_vrs = vrs_coordi - TruePos;
                dXYZ_vrs2 = [GGA(1), GGA(2), GGA(3)] - vrs_coordi;
                dNEV_vrs = xyz2topo(dXYZ_vrs, TrueLat, TrueLon);
                gd2 = xyz2gd(vrs_coordi); TrueLat2 = gd2(1); TrueLon2 = gd2(2);
                dNEV_vrs2 = xyz2topo(dXYZ_vrs2, TrueLat2, TrueLon2);
                dN_vrs = dNEV_vrs(:,1); dE_vrs = dNEV_vrs(:,2); dV_vrs = dNEV_vrs(:,3);
                dN_vrs2 = dNEV_vrs2(:,1); dE_vrs2 = dNEV_vrs2(:,2); dV_vrs2 = dNEV_vrs2(:,3);
                dNE_vrs = sqrt(dN_vrs^2 + dE_vrs^2);        %rmsH = myRMS(dNE);
                dNE_vrs2 = sqrt(dN_vrs2^2 + dE_vrs2^2);        %rmsH = myRMS(dNE);
                d2D_vrs(i,1) = dNE_vrs;
                d2D_vrs2(cnt,1) = dNE_vrs2;
                d3_vrs = sqrt(dN_vrs.^2 + dE_vrs.^2 + dV_vrs.^2); %rms3 = myRMS(d3);
                d3_vrs2 = sqrt(dN_vrs2.^2 + dE_vrs2.^2 + dV_vrs2.^2); %rms3 = myRMS(d3);
                d3D_vrs(i,1) = d3_vrs;
                d3D_vrs2(cnt,1) = d3_vrs2;
                temp13 = ([temp3,'_result_vrs(i,:) = [gs, dN_vrs, dE_vrs, dV_vrs, dNE_vrs, d3_vrs];']);
                temp14 = ([temp3,'_result_vrs2(cnt,:) = [gs, dN_vrs2, dE_vrs2, dV_vrs2, dNE_vrs2, d3_vrs2];']);
                eval(temp13)
                eval(temp14)
                cnt=cnt+1;
            end
        end
        cnt=1;
    end
end

sigma_1_test1 = sigma_range(test1_average_result_vrs2(:,5), 1);
sigma_2_test1 = sigma_range(test1_average_result_vrs2(:,5), 2);
under1m_test1 = length(test1_average_result_vrs2(find(test1_average_result_vrs2(:,5) <= 1),5))/length(test1_average_result_vrs2(:,5));
under1_2m_test1 = length(test1_average_result_vrs2(find(test1_average_result_vrs2(:,5) <= 1.2),5))/length(test1_average_result_vrs2(:,5));

sigma_1_test2_1 = sigma_range(test2_1_average_result_vrs2(:,5), 1);
sigma_2_test2_1 = sigma_range(test2_1_average_result_vrs2(:,5), 2);
under1m_test2_1 = length(test2_1_average_result_vrs2(find(test2_1_average_result_vrs2(:,5) <= 1),5))/length(test2_1_average_result_vrs2(:,5));
under1_2m_test2_1 = length(test2_1_average_result_vrs2(find(test2_1_average_result_vrs2(:,5) <= 1.2),5))/length(test2_1_average_result_vrs2(:,5));

sigma_1_test2_2 = sigma_range(test2_2_average_result_vrs2(:,5), 1);
sigma_2_test2_2 = sigma_range(test2_2_average_result_vrs2(:,5), 2);
under1m_test2_2 = length(test2_2_average_result_vrs2(find(test2_2_average_result_vrs2(:,5) <= 1),5))/length(test2_2_average_result_vrs2(:,5));
under1_2m_test2_2 = length(test2_2_average_result_vrs2(find(test2_2_average_result_vrs2(:,5) <= 1.2),5))/length(test2_2_average_result_vrs2(:,5));

sigma_1_test3 = sigma_range(test3_average_result_vrs2(:,5), 1);
sigma_2_test3 = sigma_range(test3_average_result_vrs2(:,5), 2);
under1m_test3 = length(test3_average_result_vrs2(find(test3_average_result_vrs2(:,5) <= 1),5))/length(test3_average_result_vrs2(:,5));
under1_2m_test3 = length(test3_average_result_vrs2(find(test3_average_result_vrs2(:,5) <= 1.2),5))/length(test3_average_result_vrs2(:,5));

sigma_1_test4_1 = sigma_range(test4_1_average_result_vrs2(:,5), 1);
sigma_2_test4_1 = sigma_range(test4_1_average_result_vrs2(:,5), 2);
under1m_test4_1 = length(test4_1_average_result_vrs2(find(test4_1_average_result_vrs2(:,5) <= 1),5))/length(test4_1_average_result_vrs2(:,5));
under1_2m_test4_1 = length(test4_1_average_result_vrs2(find(test4_1_average_result_vrs2(:,5) <= 1.2),5))/length(test4_1_average_result_vrs2(:,5));

sigma_1_test4_2 = sigma_range(test4_2_average_result_vrs2(:,5), 1);
sigma_2_test4_2 = sigma_range(test4_2_average_result_vrs2(:,5), 2);
under1m_test4_2 = length(test4_2_average_result_vrs2(find(test4_2_average_result_vrs2(:,5) <= 1),5))/length(test4_2_average_result_vrs2(:,5));
under1_2m_test4_2 = length(test4_2_average_result_vrs2(find(test4_2_average_result_vrs2(:,5) <= 1.2),5))/length(test4_2_average_result_vrs2(:,5));

sigma_1_test4_3 = sigma_range(test4_3_average_result_vrs2(:,5), 1);
sigma_2_test4_3 = sigma_range(test4_3_average_result_vrs2(:,5), 2);
under1m_test4_3 = length(test4_3_average_result_vrs2(find(test4_3_average_result_vrs2(:,5) <= 1),5))/length(test4_3_average_result_vrs2(:,5));
under1_2m_test4_3 = length(test4_3_average_result_vrs2(find(test4_3_average_result_vrs2(:,5) <= 1.2),5))/length(test4_3_average_result_vrs2(:,5));

bias_test1 = [mean(test1_average_result_vrs2(:,2)), mean(test1_average_result_vrs2(:,3))];
bias_test2_1 = [mean(test2_1_average_result_vrs2(:,2)), mean(test2_1_average_result_vrs2(:,3))];
bias_test2_2 = [mean(test2_2_average_result_vrs2(:,2)), mean(test2_2_average_result_vrs2(:,3))];
bias_test3 = [mean(test3_average_result_vrs2(:,2)), mean(test3_average_result_vrs2(:,3))];
bias_test4_1 = [mean(test4_1_average_result_vrs2(:,2)), mean(test4_1_average_result_vrs2(:,3))];
bias_test4_2 = [mean(test4_2_average_result_vrs2(:,2)), mean(test4_2_average_result_vrs2(:,3))];
bias_test4_3 = [mean(test4_3_average_result_vrs2(:,2)), mean(test4_3_average_result_vrs2(:,3))];

deltaH_whole_sedan_1m = [test1_average_result_vrs2(:,5);test2_1_average_result_vrs2(:,5);...
    test2_2_average_result_vrs2(:,5)];
deltaH_whole_suv_1m = [test4_1_average_result_vrs2(:,5);test4_2_average_result_vrs2(:,5);...
    test4_3_average_result_vrs2(:,5)];
deltaH_whole_sedan_1_m_pc = length(deltaH_whole_sedan_1m(find(deltaH_whole_sedan_1m(:,1) <= 1),1))/length(deltaH_whole_sedan_1m) * 100
deltaH_whole_suv_1_m_pc = length(deltaH_whole_suv_1m(find(deltaH_whole_suv_1m(:,1) <= 1),1))/length(deltaH_whole_suv_1m) * 100

deltaH_whole_sedan_12_m_pc = length(deltaH_whole_sedan_1m(find(deltaH_whole_sedan_1m(:,1) <= 1.2),1))/length(deltaH_whole_sedan_1m) * 100
deltaH_whole_suv_12_m_pc = length(deltaH_whole_suv_1m(find(deltaH_whole_suv_1m(:,1) <= 1.2),1))/length(deltaH_whole_suv_1m) * 100
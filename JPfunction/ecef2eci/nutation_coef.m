function [Ai, Bi, Ci, Di, ai] = nutation_coef

ai = [0,0,0,0,1;0,0,0,0,2;-2,0,2,0,1;2,0,-2,0,0;-2,0,2,0,2;1,-1,0,-1,0;0,-2,2,-2,1;2,0,-2,0,1;0,0,2,-2,2;0,1,0,0,0;0,1,2,-2,2;0,-1,2,-2,2;0,0,2,-2,1;2,0,0,-2,0;0,0,2,-2,0;0,2,0,0,0;0,1,0,0,1;0,2,2,-2,2;0,-1,0,0,1;-2,0,0,2,1;0,-1,2,-2,1;2,0,0,-2,1;0,1,2,-2,1;1,0,0,-1,0;2,1,0,-2,0;0,0,-2,2,1;0,1,-2,2,0;0,1,0,0,2;-1,0,0,1,1;0,1,2,-2,0;0,0,2,0,2;1,0,0,0,0;0,0,2,0,1;1,0,2,0,2;1,0,0,-2,0;-1,0,2,0,2;0,0,0,2,0;1,0,0,0,1;-1,0,0,0,1;-1,0,2,2,2;1,0,2,0,1;0,0,2,2,2;2,0,0,0,0;1,0,2,-2,2;2,0,2,0,2;0,0,2,0,0;-1,0,2,0,1;-1,0,0,2,1;1,0,0,-2,1;-1,0,2,2,1;1,1,0,-2,0;0,1,2,0,2;0,-1,2,0,2;1,1,2,2,2;1,1,0,2,0;2,2,2,-2,2;0,0,0,2,1;0,0,2,2,1;1,1,2,-2,1;0,0,0,-2,1;1,1,0,0,0;2,2,2,0,1;0,0,0,-2,0;1,1,-2,0,0;0,0,0,1,0;1,1,0,0,0;1,1,2,0,0;1,1,2,0,2;-1,-1,2,2,2;-2,-2,0,0,1;3,3,2,0,2;0,0,2,2,2;1,1,2,0,2;-1,-1,2,-2,1;2,2,0,0,1;1,1,0,0,2;3,3,0,0,0;0,0,2,1,2;-1,-1,0,0,2;1,1,0,-4,0;-2,-2,2,2,2;-1,-1,2,4,2;2,2,0,-4,0;1,1,2,-2,2;1,0,2,2,1;-2,0,2,4,2;-1,0,4,0,2;1,-1,0,-2,0;2,0,2,-2,1;2,0,2,2,2;1,0,0,2,1;0,0,4,-2,2;3,0,2,-2,2;1,0,2,-2,0;0,1,2,0,1;-1,-1,0,2,1;0,0,-2,0,1;0,0,2,-1,2;0,1,0,2,0;1,0,-2,-2,0;0,-1,2,0,1;1,1,0,-2,1;1,0,-2,2,0;2,0,0,2,0;0,0,2,4,2;0,1,0,1,0];
Ai = [-171996;2062;46;11;-3;-3;-2;1;-13187;1426;-517;217;129;48;-22;17;-15;-16;-12;-6;-5;4;4;-4;1;1;-1;1;1;-1;-2274;712;-386;-301;-158;123;63;63;-58;-59;-51;-38;29;29;-31;26;21;16;-13;-10;-7;7;-7;-8;6;6;-6;-7;6;-5;5;-5;-4;4;-4;-3;3;-3;-3;-2;-3;-3;2;-2;2;-2;2;2;1;-1;1;-2;-1;1;-1;-1;1;1;1;-1;-1;1;1;-1;1;1;-1;-1;-1;-1;-1;-1;-1;1;-1;1];
Bi = [-174.200000000000;0.200000000000000;0;0;0;0;0;0;-1.60000000000000;-3.40000000000000;1.20000000000000;-0.500000000000000;0.100000000000000;0;0;-0.100000000000000;0;0.100000000000000;0;0;0;0;0;0;0;0;0;0;0;0;-0.200000000000000;0.100000000000000;-0.400000000000000;0;0;0;0;0.100000000000000;-0.100000000000000;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0];
Ci = [92025;-895;-24;0;1;0;1;0;5736;54;224;-95;-70;1;0;0;9;7;6;3;3;-2;-2;0;0;0;0;0;0;0;977;-7;200;129;-1;-53;-2;-33;32;26;27;16;-1;-12;13;-1;-10;-8;7;5;0;-3;3;3;0;-3;3;3;-3;3;0;3;0;0;0;0;0;1;1;1;1;1;-1;1;-1;1;0;-1;-1;0;-1;1;0;-1;1;1;0;0;-1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0];
Di = [8.90000000000000;0.500000000000000;0;0;0;0;0;0;-3.10000000000000;-0.100000000000000;-0.600000000000000;0.300000000000000;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-0.500000000000000;0;0;-0.100000000000000;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0];

% ai = [0,0,0,0,1;0,0,2,-2,2;0,0,2,0,2;0,0,0,0,2;0,1,0,0,0;1,0,0,0,0;0,1,2,-2,2;0,0,2,0,1;1,0,2,0,2;0,-1,2,-2,2;1,0,0,-2,0;0,0,2,-2,1;-1,0,2,0,2;1,0,0,0,1;0,0,0,2,0;-1,0,2,2,2;-1,0,0,0,1;1,0,2,0,1;2,0,0,-2,0;-2,0,2,0,1;0,0,2,2,2;2,0,2,0,2;2,0,0,0,0;1,0,2,-2,2;0,0,2,0,0;0,0,2,-2,0;-1,0,2,0,1;0,2,0,0,0;0,2,2,-2,2;-1,0,0,2,1];
% Ai = [-171996;-13187;-2274;2062;1426;712;-517;-386;-301;217;-158;129;123;63;63;-59;-58;-51;48;46;-38;-31;29;29;26;-22;21;17;-16;16];
% Bi = [-174.200000000000;-1.60000000000000;-0.200000000000000;0.200000000000000;-3.40000000000000;0.100000000000000;1.20000000000000;-0.400000000000000;0;-0.500000000000000;0;0.100000000000000;0;0.100000000000000;0;0;-0.100000000000000;0;0;0;0;0;0;0;0;0;0;-0.100000000000000;0.100000000000000;0];
% Ci = [92025;5736;977;-895;54;-7;224;200;129;-95;-1;-70;-53;-33;-2;26;32;27;1;-24;16;13;-1;-12;-1;0;-10;0;7;-8];
% Di = [8.90000000000000;-3.10000000000000;-0.500000000000000;0.500000000000000;-0.100000000000000;0;-0.600000000000000;0;-0.100000000000000;0.300000000000000;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0];
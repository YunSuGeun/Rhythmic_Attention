%% trend Coefficient stats

clear;clc;

load("C:\Users\user\Desktop\Rhythmic_Attention\Figure\Figure3\Coeff.mat");

post_slope = [];
for i = 2:5
    post_slope = [post_slope;Coeff{i,2}(1);Coeff{i,3}(1)];
end

mean(post_slope)
std(post_slope)


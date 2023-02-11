function py_test_plot()

global AOS_InitialiseStruct

CC = AOS_InitialiseStruct.Outputs.CropGrowth(:,10);
time_axi = AOS_InitialiseStruct.Outputs.CropGrowth(:,4);
Dr = AOS_InitialiseStruct.Outputs.WaterFluxes(:,7);
loc = find(CC == -999);
time_axi(loc) = [];
CC(loc) = [];
Dr(loc) = [];
% Finish simulation
AOS_Finish();

%% plot
figure(1)
subplot(2,1,1)
plot(time_axi, CC ,'r-')
subplot(2,1,2)
plot(time_axi, Dr ,'b-')
set(gca,'YDir','reverse'); 
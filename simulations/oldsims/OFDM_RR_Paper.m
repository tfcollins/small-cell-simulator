% clear all
% clc
%function collisions = twoENBsim()
% Creat sim
sim1 = Simulation;
sim1.MapDims = [10,10];
sim1.Duration = sim1.TTIDuration*1e6;

% Add Base Stations
N = 100;
sim1.AddeNBs(N);

% Add UE's to eNB's
sim1.AddUEToEach(1);

% Set some properties to all
K = 5;
sim1.SetAlleNBs('LicensedChannels',1:K);


%% Run sim
pp = gcp;
cores = pp.NumWorkers;
%cores = 2;
G = linspace(0.1,10,cores*2);
TransmitProbabilities = G./N;
runs = 1e3;
DataPacketSize = 10; % TTIs

% Stats
RATime = zeros(length(TransmitProbabilities),1);
TxTime = zeros(length(TransmitProbabilities),1);

parfor y=1:length(TransmitProbabilities)
    
    [RATimes,TxTimes] = RunSimulationOFDMA_RR(sim1,TransmitProbabilities(y),DataPacketSize);
    
    disp(['Worker finished: ',num2str(y)]);
    
    RATime(y) = RATimes;
    TxTime(y) = TxTimes;
    
end

Throughput = TxTime./(RATime+TxTime);

plot(G,Throughput);
xlabel('TransmitProbabilities');
ylabel('Throughput');
grid on;
axis([0 10 0 1]);


%end
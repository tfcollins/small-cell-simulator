%% Authors
% Travis Collins
% traviscollins@wpi.edu
% Wireless Innovation Lab

%% Simulation

% Creat sim
sim1 = Simulation;

% Add Base Stations
sim1.AddeNBs(100);

% Add UE's to eNB's
sim1.AddUEToEach(1);

% Set some properties to all eNB
K = 5;
sim1.SetAlleNBs('LicensedChannels',1:K);


%% Run sim
pp = gcp;cores = pp.NumWorkers;
G = linspace(0.1,10,cores);
TransmitProbabilities = G./N;
DataPacketSize = 10; % TTIs of active transmission slot, after random access phase

% Stats
RATime = zeros(length(TransmitProbabilities),1);
TxTime = zeros(length(TransmitProbabilities),1);

parfor y=1:length(TransmitProbabilities)
    
    [RATime(y),TxTime(y)] = RunSimulationOFDMA_RR(sim1,TransmitProbabilities(y),DataPacketSize,testThroughput,debug);
    
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
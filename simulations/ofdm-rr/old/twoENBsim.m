% Travis Collins
% traviscollins@wpi.edu
% Wireless Innovation Lab

% Creat sim
sim1 = Simulation;
sim1.MapDims = [10,10];

% Add Base Stations
sim1.AddeNBs(100);

% Add UE's to eNB's
sim1.AddUEToEach(1);

% Set some properties to all eNB
K = 5;
sim1.SetAlleNBs('LicensedChannels',1:K);

% Place eNBs
sim1.eNBs(1).Position = [3,5];
sim1.eNBs(2).Position = [7,5];

% Place UEs
radius = 2;
sim1.eNBs(1).PlaceUEsUniformly(radius);
sim1.eNBs(2).PlaceUEsUniformly(radius);

% Set Channels
sim1.eNBs(1).SetUEChannels(1,2);
sim1.eNBs(2).SetUEChannels(1,2);

% Show placements of eNBs and UEs
sim1.UpdateSINRForUEs();
% showSINR = true;
% sim1.ShowMap(showSINR);

%% Run sim
G = 1:10;
TransmitProbabilities = G./N;
runs = 1e5;
DataPacketSize = 10; % TTIs

% Stats
RAMeanDuration = zeros(length(TransmitProbabilities),1);
TxMeanDuration = zeros(length(TransmitProbabilities),1);

% flags
testThroughput = false;
debug = false;

for y=1:length(TransmitProbabilities)
    
    RATimes = zeros(runs,1);
    TxTimes = zeros(runs,1);
    for x=1:runs
        [RATime,TxTime] = RunSimulationOFDMA_RR(sim1,TransmitProbabilities(y),DataPacketSize,testThroughput,debug);
    end
    
    RAMeanDuration(y) = mean(RATimes);
    TxMeanDuration(y) = mean(TxTimes);
    
end

plot(TransmitProbabilities,RAMeanDuration);
xlabel('TransmitProbabilities');
ylabel('Throughput');
grid on;



%end
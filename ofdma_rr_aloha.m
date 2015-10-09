%% Authors
% Travis Collins
% traviscollins@wpi.edu
% Wireless Innovation Lab

% This simulation correctly simualates:
% An OFDM-Aware Reservation Random Access Protocol for Interference Mitigation in OFDMA Femtocells

%% Simulation

% Creat sim and set duration
sim1 = Simulation;
sim1.Duration = sim1.TTIDuration*1e5;

% Add Base Stations
N = 100;
sim1.AddeNBs(N);

% Add UE's to eNB's
sim1.AddUEToEach(1);

%% Run sim
pp = gcp;cores = pp.NumWorkers; % Set sim points based on number of cpu cores
G = linspace(0.1,10,cores);
TransmitProbabilities = G./N;

% Reservation to Data Packet duration ratio
a = 0.1;

ReservationPacketSize = 1; % Do not change
DataPacketSize = ReservationPacketSize/a; % TTIs of active transmission slot, after random access phase

% Stats
RATime = zeros(length(TransmitProbabilities),1);
TxTime = zeros(length(TransmitProbabilities),1);

% Flags
testThroughput = false;
debug = false;

Ks = [2,5,10];

for K=1:length(Ks)
    
% Set some properties to all eNB
sim1.SetAlleNBs('LicensedChannels',1:Ks(K));

parfor y=1:length(TransmitProbabilities)
    
    [RATime(y,K),TxTime(y,K)] = RunSimulationOFDMA_RR(sim1,TransmitProbabilities(y),DataPacketSize,testThroughput,debug);
    
    disp(['Worker finished: ',num2str(y)]);
    
end

end

% Calculate offered load
offeredLoad = TxTime./(RATime+TxTime);

hold on;
plot(G,offeredLoad);
xlabel('Offered Load');
ylabel('Throughput');
grid on;
axis([0 10 0 1]);
hold off;

legend('K=2','K=5','K=10');

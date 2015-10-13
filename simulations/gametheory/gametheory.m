% Travis Collins
% traviscollins@wpi.edu
% Wireless Innovation Lab

% Game theory SINR balancing scenario
% Reproducing: http://ieeexplore.ieee.org/lpdocs/epic03/wrapper.htm?arnumber=6868315

%% Creat sim
sim1 = Simulation;
MaxTries = 1e3;  % Game round to reach equilibrium
sim1.Duration = sim1.TTIDuration*MaxTries;
sim1.MapDims = [10,10];

%% Add Base Stations
sim1.AddeNBs(10);

% Add UEs to eNB
sim1.AddUEToEach(1);

%% Set some properties to all eNB
TotalChannels = 5;
sim1.SetAlleNBs('LicensedChannels',1:TotalChannels);

%% Place eNBs
sim1.eNBs(1).Position = [3,5];
sim1.eNBs(2).Position = [7,5];

%% Place UEs
radius = 1;
for eNB=1:length(sim1.eNBs)
    sim1.eNBs(eNB).PlaceUEsUniformly(radius);
end

%% Set Channels
sim1.eNBs(1).SetUEChannels(1,2);
sim1.eNBs(2).SetUEChannels(1,2);

%% Add Game Model to each eNB
% Create constants Fn and beta
K = TotalChannels;
Kn = 4; % eNB max allowed 
Fn = 0; % Sum of capacity of channels without interferers
beta = 0.1; % Look at table for other values
epsilon = 1e-5; % Look a graph for more values
gm = struct('Fn',Fn,'beta',beta,'epsilon',epsilon,...
    'Personality','radical',...
    'StrategyIndexes',[],...
    'StrategyCounter',zeros(1,nchoosek(K,Kn)),...
    'PossibleStrategies',generateStrategies(K,Kn));

sim1.SetAlleNBs('GameModel',gm);

% % Show placements of eNBs and UEs
%sim1.UpdateSINRForUEs();
%showSINR = true;
%sim1.ShowMap(showSINR);

%% Run game
RunSimulation_GameTheory(sim1,Kn);


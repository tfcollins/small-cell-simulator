% Travis Collins
% traviscollins@wpi.edu
% Wireless Innovation Lab

% Game theory SINR balancing scenario
% Reproducing: http://ieeexplore.ieee.org/lpdocs/epic03/wrapper.htm?arnumber=6868315

clear;

%% Creat sim
sim1 = Simulation;
MaxTries = 1e4;  % Game round to reach equilibrium
sim1.Duration = sim1.TTIDuration*MaxTries;
sim1.MapDims = [70,30];

%% Add Base Stations
sim1.AddeNBs(14);

% Add UEs to eNB
sim1.AddUEToEach(1);

%% Set some properties to all eNB
TotalChannels = 5;
sim1.SetAlleNBs('LicensedChannels',1:TotalChannels);

%% Place eNBs
offset = 2;
numInRow = 5;
spacing = 10;

row = 1;
for eNB = 1:length(sim1.eNBs)
    row = row + double(mod(eNB-1,3)==0)*spacing;
    col =              mod(eNB-1,3)*spacing;
    sim1.eNBs(eNB).Position = [offset+row,offset+col];
end
% sim1.eNBs(1).Position = [4,5];
% sim1.eNBs(2).Position = [5,5];
% sim1.eNBs(3).Position = [4,4];
% sim1.eNBs(4).Position = [5,4];


%% Place UEs
radius = 10;
for eNB=1:length(sim1.eNBs)
    sim1.eNBs(eNB).PlaceUEsUniformly(radius);
end

%% Set Channels
% for eNB=1:length(sim1.eNBs)
%     sim1.eNBs(eNB).SetUEChannels(1,1:TotalChannels);
% end


%% Add Game Model to each eNB
% Create constants Fn and beta
K = TotalChannels;
Kn = 3; % eNB max allowed 
Fn = 0; % Sum of capacity of channels without interferers
beta = 0.1; % Look at table for other values
epsilon = 1e-5; % Look a graph for more values
gm = struct(...
    'Fn',Fn,... % Tobe set later
    'beta',beta,...
    'epsilon',epsilon,...
    'Personality','radical',...
    'StrategyIndexes',[],...  % History of strategies used
    'StrategyCounter',zeros(1,nchoosek(K,Kn)),... % Tally of strategies used
    'Utilities',[],... % History of Utilites over time
    'Qn',zeros(1,nchoosek(K,Kn)),... % Probability of selecting a strategy
    'PossibleStrategies',generateStrategies(K,Kn)); % Binary enumeration relating strategies to channel selections

sim1.SetAlleNBs('GameModel',gm);

% Set UE subchannels
for eNB=1:length(sim1.eNBs)
    sim1.eNBs(eNB).UEs(1).UsingChannels = 1:Kn;
end

% Set bandwidths
subchannelBW = 100e3;
totalBW = subchannelBW*length(sim1.eNBs(1).LicensedChannels);
sim1.SetAlleNBs('Bandwidth',totalBW);

% Set Fn based on physical arrangement
setFn(sim1,Kn);

% Show placements of eNBs and UEs
sim1.UpdateSINRForUEs();
showSINR = false;
sim1.ShowMap(showSINR);

%% Run game
RunSimulation_GameTheory(sim1,Kn);


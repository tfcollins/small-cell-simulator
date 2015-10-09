% Travis Collins
% traviscollins@wpi.edu
% Wireless Innovation Lab

% Simple simulation to show SINR of co-located eNB's

% Creat sim
sim1 = Simulation;
sim1.MapDims = [10,10];

% Add Base Stations
sim1.AddeNBs(2);

% Add UE's to eNB's
sim1.AddUEToEach(1);

% Set some properties to all eNB
sim1.SetAlleNBs('LicensedChannels',1:2);

% Place eNBs
sim1.eNBs(1).Position = [3,5];
sim1.eNBs(2).Position = [7,5];

% Place UEs
radius = 1;
sim1.eNBs(1).PlaceUEsUniformly(radius);
sim1.eNBs(2).PlaceUEsUniformly(radius);

% Set Channels
sim1.eNBs(1).SetUEChannels(1,2);
sim1.eNBs(2).SetUEChannels(1,2);

% Show placements of eNBs and UEs
sim1.UpdateSINRForUEs();
showSINR = true;
sim1.ShowMap(showSINR);

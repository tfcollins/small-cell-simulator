%% Plot resource utilization per call over a period of time
% Should show VoIP has a very small percentage of overall traffic at a Base
% station

duration = 60; % seconds

VAF = 0.5; % Faction of duration spent talking
bw = 5; % (MHz) Bandwidth

numCalls = 300;

%% Calculations
percentBlocksUsed = zeros(15,1);

for MCSIndex = 1:15
    
voip = traffic.VoIP;
mcs = MCS;

silentPeriod = (1-VAF)*duration;
talkingPeriod = VAF*duration;

silentPackets = silentPeriod/voip.SilencePacketPeriods;
talkingPackets = talkingPeriod/voip.TalkingPacketPeriods;

totalBits = voip.SilencePacketBits*silentPackets + ...
            voip.TalkingPacketBits*talkingPackets;

requiredPRBs = mcs.NeededPRBs(MCSIndex,totalBits)*numCalls;

% Total blocks possible
totalPRBs = mcs.TotalPRBs(bw,duration);
        
percentBlocksUsed(MCSIndex) = requiredPRBs/totalPRBs;

end

MCSIndex = 1:15;
bar(MCSIndex,percentBlocksUsed)
xlabel('MCS Index');
ylabel('Percentage of Resources Used (1==Fully Utilized)');
title(['Single VoIP Call VAF: ',num2str(VAF)]);
grid on;



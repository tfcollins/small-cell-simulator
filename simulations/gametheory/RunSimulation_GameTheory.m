function  RunSimulation_GameTheory(sim,Kn)

% Initialization Requirements
% 1. [X] t=0
% 2. [X] All personalities set to radical
% 3. [X] Reset strategy counters Cn
% 4. [X] Each eNB randomly selects a strategy (channel subset)
% 5. [X] Each player must calculate the utility of that stragety randomly
% selected

% Update commonly used values
sim.GetMaxUEsOfAnyeNB();

% Max number of subchannels eNB's are allowed to pick
numChannels = Kn;

%% Run
% Initialize some things

% Randomly pick subchannels for eNBs and save to StrategyIndex
for eNB=1:length(sim.eNBs)
    sim.eNBs(eNB).PickRandomChannels(numChannels);
end

% Update and save utilities of round
sim.UpdateSINRForUEs();% Update SINR measurements at the UEs attached to each eNB
sim.GetMeanSubchannelSINRs();% Average over UE SINR subchannels to get single SINR per subchannel vector
UpdateUtilities(sim);

%% Start Sim
% Iterate Through Game Theory Rounds
for TTI = 0:sim.TTIDuration:sim.Duration
    
    
    %% Update state profile
    
    % Update Qn
    UpdateStrategies(sim);

    % Choose a new strategy and save to history
    UpdateCurrentStrategy(sim)
    
    % Update and save utilities of round
    sim.UpdateSINRForUEs();% Update SINR measurements at the UEs attached to each eNB
    sim.GetMeanSubchannelSINRs();% Average over UE SINR subchannels to get single SINR per subchannel vector
    UpdateUtilities(sim);
    
    % Update Personalities (these historically dont need to be kept)
    UpdatePersonalities(sim);
    
    % Update Strategy counter (only done for conservative eNBs)
    UpdateCounter(sim);
    
    %     %% Extra
    %     % Update observations of round
    %     sim.SaveChannels(); % Not used yet
    %
    %     % View subchannel power levels network wide
    %     % sim.ViewSubchannels();
    if TTI>(sim.Duration*0.1)
        ViewCounts(sim,true);
        ViewUtilities(sim);
    end
    
    
end


end


%% Personality updating algorithm
function UpdatePersonalities(sim)

for eNB = 1:length(sim.eNBs)
    
    % Get game relevant values
    LastChannelSelections = sim.eNBs(eNB).GameModel.StrategyIndexes(end-1);
    CurrentChannelSelections = sim.eNBs(eNB).GameModel.StrategyIndexes(end);
    LastUtility = sim.eNBs(eNB).GameModel.Utilities(end-1);
    CurrentUtility = sim.eNBs(eNB).GameModel.Utilities(end);
    
    % Extract Constants
    beta = sim.eNBs(eNB).GameModel.beta;
    Fn = sim.eNBs(eNB).GameModel.Fn;
    epsilon = sim.eNBs(eNB).GameModel.epsilon;
    
    % Update personalities
    if strcmpi(sim.eNBs(eNB).GameModel.Personality,'conservative')
        
        if isequal(LastChannelSelections,CurrentChannelSelections) &&...
                isequal(LastUtility,CurrentUtility)
            sim.eNBs(eNB).GameModel.Personality = 'conservative';
        else
            % SAME
            pC = epsilon^(1-(CurrentUtility/Fn)^beta);
            pR = 1 - pC;
            if pR>pC
                sim.eNBs(eNB).GameModel.Personality = 'radical';
            else
                sim.eNBs(eNB).GameModel.Personality = 'conservative';
            end
        end
    else
        % SAME
        pC = epsilon^(1-(CurrentUtility/Fn)^beta);
        pR = 1 - pC;
        if pR>pC
            sim.eNBs(eNB).GameModel.Personality = 'radical';
        else
            sim.eNBs(eNB).GameModel.Personality = 'conservative';
        end
    end
    
end

end

%% Calculate Utility
function UpdateUtilities(sim)

for eNB = 1:length(sim.eNBs)
    
    Utility = 0;
    
    % Sum capacities over channels to get utilites
    for chan = 1:length(sim.eNBs(eNB).ChannelsInUse)
        Utility = Utility +...
            sim.eNBs(eNB).Bandwidth/length(sim.eNBs(eNB).LicensedChannels)*...
            log2(1 + sim.eNBs(eNB).MeanSubchannelSINR(chan));
    end
    
    % Save new utility to history
    sim.eNBs(eNB).GameModel.Utilities = ...
        [sim.eNBs(eNB).GameModel.Utilities, Utility];
    
end

end


%% Update mixed strategies UDSA (Update Qn)
function UpdateStrategies(sim)

w = ceil(length(sim.eNBs)*1.2); % Bigger than N (# users)

for eNB=1:length(sim.eNBs)

    if strcmpi(sim.eNBs(eNB).GameModel.Personality,'radical')
       
        % Make all strategies equally likely
        indexes = 1:length(sim.eNBs(eNB).GameModel.StrategyCounter);
        sim.eNBs(eNB).GameModel.Qn(indexes) = ...
            1/length(sim.eNBs(eNB).GameModel.StrategyCounter);
        
    else
        % Choose strageties not chosen in previous round
        % TODO: Recheck this, Qn seems to just slam to 1 value
        indexes = 1:length(sim.eNBs(eNB).GameModel.StrategyCounter);
        
        previouslyChosen = sim.eNBs(eNB).GameModel.StrategyIndexes(end);
        indexes(previouslyChosen) = [];
        
        sim.eNBs(eNB).GameModel.Qn(indexes)...
            = sim.eNBs(eNB).GameModel.epsilon^w/...
            (length(sim.eNBs(eNB).GameModel.StrategyCounter)-1);
        
        sim.eNBs(eNB).GameModel.Qn(previouslyChosen)...
            = 1-sim.eNBs(eNB).GameModel.epsilon^w;
        
    end
    
    % Check if Qn within tolerance
    if abs(sum(sim.eNBs(eNB).GameModel.Qn)-1) > sqrt(eps)
       error('Qn incorrect'); 
    end
    
end


end

%% Make channel choices
function UpdateCurrentStrategy(sim)

for eNB = 1:length(sim.eNBs)

    % Probability vector
    P = sim.eNBs(eNB).GameModel.Qn;
    
    % Strategy Indexes
    X = 1:length(sim.eNBs(eNB).GameModel.StrategyCounter);
    
    % Randomly pick strategy
    ChosenStrategyIndex = X(find(rand<cumsum(P),1,'first')); % BROKEN< FIXZXCZXCZXC
    
    % Convert strategy index to channel selection
    vec = sim.eNBs(eNB).GameModel.PossibleStrategies(ChosenStrategyIndex,:);
    indexes = 1:length(sim.eNBs(eNB).LicensedChannels);
    sim.eNBs(eNB).ChannelsInUse = indexes(vec==1);
    % Update UE too (Needed to SINR measurements)
    for UE = 1:length(sim.eNBs(eNB).UEs)
        sim.eNBs(eNB).UEs(UE).UsingChannels = indexes(vec==1);
    end
    
    % Save strategy index to history
    sim.eNBs(eNB).GameModel.StrategyIndexes = ...
        [sim.eNBs(eNB).GameModel.StrategyIndexes, ChosenStrategyIndex];
    if length(sim.eNBs(eNB).GameModel.StrategyIndexes)<2
        error('Something broke');
    end

end

end

% Update Strategy counter
function UpdateCounter(sim)

for eNB = 1:length(sim.eNBs)

    if strcmpi(sim.eNBs(eNB).GameModel.Personality,'conservative')
        
        index = sim.eNBs(eNB).GameModel.StrategyIndexes(end);
        
        sim.eNBs(eNB).GameModel.StrategyCounter(index) = ...
            sim.eNBs(eNB).GameModel.StrategyCounter(index) + 1;
        
    end
    
end

end

% View tally on each strategy by eNBs
function ViewCounts(sim,printSelections)

% rows are groups of bars == subchannel
% columns == eNB

% Build input to bargraph
tally = zeros(length(sim.eNBs(1).GameModel.StrategyCounter),length(sim.eNBs));

for eNB = 1:length(sim.eNBs)
    tally(:,eNB) =...
        sim.eNBs(eNB).GameModel.StrategyCounter;
end
% Plot
figure(1);
%subplot(2,1,1);

bar(tally);
xlabel('strategy Index');
ylabel('Counts');
% Create legend
leg = {};
for eNB = 1:length(sim.eNBs)
    leg = {leg{:},['eNB=',num2str(eNB)]};
end

legend(leg);
drawnow;
if printSelections
for eNB=1:length(sim.eNBs)
   disp(['eNB Subchannels: (',num2str(eNB),') ',num2str(sim.eNBs(eNB).ChannelsInUse)]); 
end
disp('------------------------');
end
pause(0.001);

end


% View utilities of each eNB compared to best (Fn)
function ViewUtilities(sim)

current = zeros(length(sim.eNBs),length(sim.eNBs(1).GameModel.Utilities));
best = zeros(length(sim.eNBs),1);

for eNB = 1:length(sim.eNBs)
    
    best(eNB) = sim.eNBs(eNB).GameModel.Fn;
    current(eNB,:) = real(sim.eNBs(eNB).GameModel.Utilities);
    
end

    figure(2);
    %subplot(2,1,2);
    hold on;
    x = 0:sim.TTIDuration:sim.TTIDuration*(length(current(1,:))-1);
    plot(x,sum(current,1),'b');
    x = 0:sim.TTIDuration:sim.Duration;
    plot(x,repmat(sum(best),1,length(x)),'r');
    xlabel('Time');
    ylabel('Utility');
    axis([0 sim.Duration 0 max(sum(best))*1.1]);
    hold off;

end






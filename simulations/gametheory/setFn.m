function setFn(sim,subchannels)

    % Fn is simply the SINR of the received signal without interference,
    % only thermal noise
    
    % Determine Fn for each eNB assuming 1 UE attached
    for eNB = 1:length(sim.eNBs)
        % Sum over used channels
        for chan = 1:subchannels
            sigPowerReceived = ...
                sim.eNBs(eNBofUE).TxPower ...
                + sim.eNBs(eNBofUE).AntennaGain ...
                - sim.PathlossModel.GetPathloss(distance,'Signal') ...
                - FadingLoss ...
                + sim.eNBs(eNBofUE).UEs(UE).AntennaGain;
            
            thermalNoise = -174+10*log10(obj.eNBs(eNB).Bandwidth); % TODO: Relook this up
        end
        
        sim.eNBs(eNB).GameModel.Fn = Fn;
    end

end
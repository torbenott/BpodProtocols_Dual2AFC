function Olf2AFC
% Reproduction on Bpod of protocol used in the PatonLab, MATCHINGvFix

global BpodSystem
%% Task parameters
TaskParameters = BpodSystem.ProtocolSettings;
if isempty(fieldnames(TaskParameters))
    TaskParameters.GUI.iti = 0; % (s)
    TaskParameters.GUI.rewardAmount = 3;
    %TaskParameters.GUI.ChoiceDeadLine = 5;
    %TaskParameters.GUI.timeOut = 5; % (s)
    %TaskParameters.GUI.rwdDelay = 0; % (s)
    TaskParameters.GUI = orderfields(TaskParameters.GUI);
end
BpodParameterGUI('init', TaskParameters);

%% Initializing data (trial type) vectors

BpodSystem.Data.Custom.OutcomeRecord = nan;
BpodSystem.Data.Custom.TrialValid = true;
% BpodSystem.Data.Custom.BlockNumber = 1;
% BpodSystem.Data.Custom.BlockLen = drawBlockLen(TaskParameters);
BpodSystem.Data.Custom.ChoiceLeft = NaN;
BpodSystem.Data.Custom.Rewarded = NaN;
BpodSystem.Data.Custom = orderfields(BpodSystem.Data.Custom);
BpodSystem.Data.Custom.OdorID = randi(2,1,100);
%BpodSystem.Data.Custom.OdorContrast = randsample([0 logspace(log10(.05),log10(.6), 3)],100,1);

%% Olfactometer Madness

if ~BpodSystem.EmulatorMode
    SetCarrierFlowRate(900);
    OlfIp = FindOlfactometer;
end
BpodSystem.SoftCodeHandlerFunction = 'Deliver_Odor';

%% Initialize plots
BpodSystem.ProtocolFigures.SideOutcomePlotFig = figure('Position', [200 200 1000 200],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.SideOutcomePlot = axes('Position', [.075 .3 .89 .6]);
Olf2AFC_PlotSideOutcome(BpodSystem.GUIHandles.SideOutcomePlot,'init');
BpodNotebook('init');

%% Main loop
RunSession = true;
iTrial = 1;

while RunSession
    TaskParameters = BpodParameterGUI('sync', TaskParameters);
    
    sma = stateMatrix(TaskParameters,iTrial);
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;
    if ~isempty(fieldnames(RawEvents))
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents);
        SaveBpodSessionData;
    end
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.BeingUsed == 0
        return
    end
    
    updateCustomDataFields;%(TaskParameters)
    Olf2AFC_PlotSideOutcome(BpodSystem.GUIHandles.SideOutcomePlot,'update',iTrial);
    iTrial = iTrial + 1;
end
end

function sma = stateMatrix(TaskParameters,iTrial)
global BpodSystem
ValveTimes  = GetValveTimes(TaskParameters.GUI.rewardAmount, [1 3]);
LeftValveTime = ValveTimes(1);
RightValveTime = ValveTimes(2);
clear ValveTimes

if BpodSystem.Data.Custom.OdorID(iTrial) == 2
    LeftPokeAction = 'rewarded_Lin';
    RightPokeAction = 'unrewarded_Rin';
elseif BpodSystem.Data.Custom.OdorID(iTrial) == 1
    LeftPokeAction = 'unrewarded_Lin';
    RightPokeAction = 'rewarded_Rin';
else
    error('Bpod:Olf2AFC:unknownOdorID','Undefined Odor ID')
end

sma = NewStateMatrix();
sma = AddState(sma, 'Name', 'wait_Cin',...
    'Timer', 0,...
    'StateChangeConditions', {'Port2In', 'odor_delivery'},...
    'OutputActions', {'PWM2',255});
sma = AddState(sma, 'Name', 'odor_delivery',...
    'Timer', 0,...
    'StateChangeConditions', {'Port2Out','wait_Sin'},...
    'OutputActions', {'SoftCode',BpodSystem.Data.Custom.OdorID(iTrial)});
sma = AddState(sma, 'Name', 'wait_Sin',...
    'Timer',0,...
    'StateChangeConditions', {'Port1In',LeftPokeAction,'Port3In',RightPokeAction},...
    'OutputActions',{'PWM1',255,'PWM3',255});
sma = AddState(sma, 'Name', 'rewarded_Lin',...
    'Timer', 0,...
    'StateChangeConditions', {'Tup','water_L'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'rewarded_Rin',...
    'Timer', 0,...
    'StateChangeConditions', {'Tup','water_R'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'unrewarded_Lin',...
    'Timer', 0,...
    'StateChangeConditions', {'Tup','ITI'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'unrewarded_Rin',...
    'Timer', 0,...
    'StateChangeConditions', {'Tup','ITI'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'water_L',...
    'Timer', LeftValveTime,...
    'StateChangeConditions', {'Tup','ITI'},...
    'OutputActions', {'ValveState', 1});
sma = AddState(sma, 'Name', 'water_R',...
    'Timer', RightValveTime,...
    'StateChangeConditions', {'Tup','ITI'},...
    'OutputActions', {'ValveState', 4});
sma = AddState(sma, 'Name', 'ITI',...
    'Timer',TaskParameters.GUI.iti,...
    'StateChangeConditions',{'Tup','exit'},...
    'OutputActions',{});
% sma = AddState(sma, 'Name', 'state_name',...
%     'Timer', 0,...
%     'StateChangeConditions', {},...
%     'OutputActions', {});
end

function updateCustomDataFields()
global BpodSystem
%% OutcomeRecord
% Searches for state names and not number, so won't be affected by
% modifications on state matrix
stOI = find(strcmp('rewarded_Lin',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}) |...
    strcmp('rewarded_Rin',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}) |...
    strcmp('unrewarded_Lin',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}) |...
    strcmp('unrewarded_Rin',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end})); % States of interest
if any(ismember(stOI,BpodSystem.Data.RawData.OriginalStateData{end}))
    BpodSystem.Data.Custom.OutcomeRecord(end) = stOI(ismember(stOI,BpodSystem.Data.RawData.OriginalStateData{end}));
    if strcmp('rewarded_Lin',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}(BpodSystem.Data.Custom.OutcomeRecord(end)))
        BpodSystem.Data.Custom.ChoiceLeft(end) = 1;
        BpodSystem.Data.Custom.Rewarded(end) = 1;
    elseif strcmp('rewarded_Rin',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}(BpodSystem.Data.Custom.OutcomeRecord(end)))
        BpodSystem.Data.Custom.ChoiceLeft(end) = 0;
        BpodSystem.Data.Custom.Rewarded(end) = 1;
    elseif strcmp('unrewarded_Lin',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}(BpodSystem.Data.Custom.OutcomeRecord(end)))
        BpodSystem.Data.Custom.ChoiceLeft(end) = 1;
        BpodSystem.Data.Custom.Rewarded(end) = 0;
    elseif strcmp('unrewarded_Rin',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}(BpodSystem.Data.Custom.OutcomeRecord(end)))
        BpodSystem.Data.Custom.ChoiceLeft(end) = 0;
        BpodSystem.Data.Custom.Rewarded(end) = 0;
    end
    disp(BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}(BpodSystem.Data.Custom.OutcomeRecord(end)))
end
BpodSystem.Data.Custom.OutcomeRecord(end+1) = nan;
BpodSystem.Data.Custom.ChoiceLeft(end+1) = NaN;
BpodSystem.Data.Custom.Rewarded(end+1) = NaN;
if numel(BpodSystem.Data.Custom.OutcomeRecord) > numel(BpodSystem.Data.Custom.OdorID)
    BpodSystem.Data.Custom.OdorID = [BpodSystem.Data.Custom.OdorID, randi(2,1,100)];
    %BpodSystem.Data.Custom.OdorContrast = [BpodSystem.Data.Custom.OdorContrast, randsample([0 logspace(log10(.05),log10(.6), 3)],100,1)];
end
%% Block count
% nTrialsThisBlock = sum(BpodSystem.Data.Custom.BlockNumber == BpodSystem.Data.Custom.BlockNumber(end));
% if nTrialsThisBlock >= TaskParameters.GUI.blockLenMax
%     % If current block len exceeds new max block size, will transition
%     BpodSystem.Data.Custom.BlockLen(end) = nTrialsThisBlock;
% end
% if nTrialsThisBlock >= BpodSystem.Data.Custom.BlockLen(end)
%     BpodSystem.Data.Custom.BlockNumber(end+1) = BpodSystem.Data.Custom.BlockNumber(end)+1;
%     BpodSystem.Data.Custom.BlockLen(end+1) = drawBlockLen(TaskParameters);
%     BpodSystem.Data.Custom.LeftHi(end+1) = ~BpodSystem.Data.Custom.LeftHi(end);
% else
%     BpodSystem.Data.Custom.BlockNumber(end+1) = BpodSystem.Data.Custom.BlockNumber(end);
%     BpodSystem.Data.Custom.LeftHi(end+1) = BpodSystem.Data.Custom.LeftHi(end);
% end
%display(BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}(BpodSystem.Data.RawData.OriginalStateData{end}))

end

% function BlockLen = drawBlockLen(TaskParameters)
% BlockLen = 0;
% while BlockLen < TaskParameters.GUI.blockLenMin || BlockLen > TaskParameters.GUI.blockLenMax
%     BlockLen = ceil(exprnd(sqrt(TaskParameters.GUI.blockLenMin*TaskParameters.GUI.blockLenMax)));
% end
% end
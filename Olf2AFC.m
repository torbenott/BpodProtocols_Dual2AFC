function Olf2AFC
% Reproduction on Bpod of protocol used in the PatonLab, MATCHINGvFix

global BpodSystem
%% Task parameters
global TaskParameters
TaskParameters = BpodSystem.ProtocolSettings;
if isempty(fieldnames(TaskParameters))
    TaskParameters.GUI.ITI = 0; % (s)
    TaskParameters.GUI.RewardAmount = 30;    
    %TaskParameters.GUI.ChoiceDeadLine = 5;
    TaskParameters.GUIPanels.General = {'ITI','RewardAmount'};
    %%
    TaskParameters.GUI.StimDelayAutoincrement = 1;
    TaskParameters.GUIMeta.StimDelayAutoincrement.Style = 'checkbox';
    TaskParameters.GUI.StimDelayMin = 0;
    TaskParameters.GUI.StimDelayMax = 0.6;
    TaskParameters.GUI.StimDelayIncr = 0.01;
    TaskParameters.GUI.StimDelayDecr = 0.01;
    TaskParameters.GUI.StimDelay = TaskParameters.GUI.StimDelayMin;
    TaskParameters.GUIMeta.StimDelay.Style = 'text';
    TaskParameters.GUIPanels.StimDelay = {'StimDelayAutoincrement','StimDelayMin','StimDelayMax','StimDelayIncr','StimDelayDecr','StimDelay'};
    TaskParameters.GUI.FeedbackDelayAutoincrement = 1;
    TaskParameters.GUIMeta.FeedbackDelayAutoincrement.Style = 'checkbox';
    TaskParameters.GUI.FeedbackDelayMin = 0;
    TaskParameters.GUI.FeedbackDelayMax = 1;
    TaskParameters.GUI.FeedbackDelayIncr = 0.01;
    TaskParameters.GUI.FeedbackDelayDecr = 0.01;
    TaskParameters.GUI.FeedbackDelay = TaskParameters.GUI.FeedbackDelayMin;
    TaskParameters.GUIMeta.FeedbackDelay.Style = 'text';
    TaskParameters.GUIPanels.FeedbackDelay = {'FeedbackDelayAutoincrement','FeedbackDelayMin','FeedbackDelayMax','FeedbackDelayIncr','FeedbackDelayDecr','FeedbackDelay'};
    %%
    TaskParameters.GUI.TimeOut = 0; % (s)
    TaskParameters.GUI.TrialSelection = 3;
    TaskParameters.GUIMeta.TrialSelection.Style = 'popupmenu';
    TaskParameters.GUIMeta.TrialSelection.String = {'Flat','Manual','BiasCorrecting'};
    TaskParameters.GUIPanels.BiasControl = {'TimeOut','TrialSelection'};
    TaskParameters.GUI.OdorA_bank = 3;
    TaskParameters.GUI.OdorB_bank = 4;
    TaskParameters.GUIPanels.Olfactometer = {'OdorA_bank', 'OdorB_bank'};
    TaskParameters.GUI = orderfields(TaskParameters.GUI);
end
BpodParameterGUI('init', TaskParameters);

%% Initializing data (trial type) vectors

BpodSystem.Data.Custom.OutcomeRecord = nan;
BpodSystem.Data.Custom.TrialValid = true;
BpodSystem.Data.Custom.FixBroke = false;
BpodSystem.Data.Custom.FixDur = NaN;
% BpodSystem.Data.Custom.BlockNumber = 1;
% BpodSystem.Data.Custom.BlockLen = drawBlockLen(TaskParameters);
BpodSystem.Data.Custom.ChoiceLeft = NaN;
BpodSystem.Data.Custom.Rewarded = NaN;
BpodSystem.Data.Custom.OdorID = randi(2,1,20);
BpodSystem.Data.Custom.OdorContrast = ones(1,20)*.9; % Future: control difficulties via GUI
BpodSystem.Data.Custom.OdorPair = ones(1,20); % DEBUG THIS. SHOULD BE: Valve1=MinOil. Future: Present more than one pair
BpodSystem.Data.Custom.OdorFracA = NaN;
BpodSystem.Data.Custom.OST = NaN;
BpodSystem.Data.Custom.OdorA_bank = TaskParameters.GUI.OdorA_bank;
BpodSystem.Data.Custom.OdorB_bank = TaskParameters.GUI.OdorB_bank;
if TaskParameters.GUI.StimDelayAutoincrement
    BpodSystem.Data.Custom.StimDelay = TaskParameters.GUI.StimDelayMin;
else
    BpodSystem.Data.Custom.StimDelay = random('unif',TaskParameters.GUI.StimDelayMin,TaskParameters.GUI.StimDelayMax);
end
if TaskParameters.GUI.FeedbackDelayAutoincrement
    BpodSystem.Data.Custom.FeedbackDelay = TaskParameters.GUI.FeedbackDelayMin;
else
    BpodSystem.Data.Custom.FeedbackDelay = TaskParameters.GUI.FeedbackDelayMax;
end
BpodSystem.Data.Custom.TrialNumber = 1;
BpodSystem.Data.Custom.Feedback = true;
BpodSystem.Data.Custom.FeedbackTime = NaN;
BpodSystem.Data.Custom = orderfields(BpodSystem.Data.Custom);

%BpodSystem.Data.Custom.OdorContrast = randsample([0 logspace(log10(.05),log10(.6), 3)],100,1);

%% Olfactometer Madness

if ~BpodSystem.EmulatorMode
    BpodSystem.Data.Custom.OlfIp = FindOlfactometer;
    if isempty(BpodSystem.Data.Custom.OlfIp)
        error('Bpod:Olf2AFC:OlfComFail','Failed to connect to olfactometer')
    end
    %SetCarrierFlowRate()
    OdorContrast = BpodSystem.Data.Custom.OdorContrast(1);
    OdorID = BpodSystem.Data.Custom.OdorID(1);
    if OdorID == 1
        OdorA_flow = 100*(.5 + OdorContrast/2);
        OdorB_flow = 100*(.5 - OdorContrast/2);
    else
        OdorA_flow = 100*(.5 - OdorContrast/2);
        OdorB_flow = 100*(.5 + OdorContrast/2);
    end
    BpodSystem.Data.Custom.OdorFracA(1) = OdorA_flow;
    SetBankFlowRate(BpodSystem.Data.Custom.OlfIp, BpodSystem.Data.Custom.OdorA_bank, OdorA_flow)
    SetBankFlowRate(BpodSystem.Data.Custom.OlfIp, BpodSystem.Data.Custom.OdorB_bank, OdorB_flow)
    clear Odor* flow*
else
    BpodSystem.Data.Custom.OlfIp = '198.162.0.0';
end
BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler';

%% Initialize plots
BpodSystem.ProtocolFigures.SideOutcomePlotFig = figure('Position', [200 200 1000 400],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.OutcomePlot.HandleOutcome = axes('Position', [.075 .15 .89 .3]);
BpodSystem.GUIHandles.OutcomePlot.HandlePsyc = axes('Position', [.075 .6 .12 .3]);
BpodSystem.GUIHandles.OutcomePlot.HandleTrialRate = axes('Position', [2*.075+.12 .6 .12 .3]);
BpodSystem.GUIHandles.OutcomePlot.HandleFix = axes('Position', [3*.075+2*.12 .6 .12 .3]);
BpodSystem.GUIHandles.OutcomePlot.HandleOST = axes('Position', [4*.075+3*.12 .6 .12 .3]);
BpodSystem.GUIHandles.OutcomePlot.HandleFeedback = axes('Position', [5*.075+4*.12 .6 .12 .3]);

MainPlot(BpodSystem.GUIHandles.OutcomePlot,'init');
%BpodNotebook('init');

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
        BpodSystem.Data.TrialSettings(iTrial) = TaskParameters;
        SaveBpodSessionData;
    end
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.BeingUsed == 0
        return
    end
    
    updateCustomDataFields;
    MainPlot(BpodSystem.GUIHandles.OutcomePlot,'update',iTrial);
    iTrial = iTrial + 1;
    BpodSystem.Data.Custom.TrialNumber(iTrial) = iTrial;    
end
end
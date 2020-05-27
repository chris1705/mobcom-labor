% Autor:   Christian Martin Fender
% Datum:   03.02.2020

clear;
close all;
clc;

% Parametrisierung
n = 2000;       % Transmitted bits

% Konstanten
M = 4;            % Modulation order
ovs = 8;          % Samples per symbol
span = 10;        % Filter span in symbols
rolloff = 0.25;   % Rolloff factor
skipSymbols = 86; % Bits die der Übertragung vorangestellt werden (Einschwingen)

% Vorberechnungen
bps = log2(M);    % Bits/symbol
filtDelay = bps*span;

% Erzeugt einen DQPSK Modulator und Demodulator, die beide Bits als Input
% erwarten. Die Phasenrotation ist standardmäßig pi/4.
dqpskmod = comm.DQPSKModulator('BitInput', true);
dqpskdemod = comm.DQPSKDemodulator('BitOutput', true);

txfilter = comm.RaisedCosineTransmitFilter('RolloffFactor',rolloff, ...
    'FilterSpanInSymbols',span,'OutputSamplesPerSymbol',ovs);

rxfilter = comm.RaisedCosineReceiveFilter('RolloffFactor',rolloff, ...
    'FilterSpanInSymbols',span,'InputSamplesPerSymbol',ovs, ...
    'DecimationFactor', 1);

% Berechnet die Fehlerraten, liefert als Rückgabe einen Vektor mit den
% Werten: Relative Fehlerrate, Absolute Fehleranzahl und gesamt Anzahl an
% Werten
errorRate = comm.ErrorRate('ReceiveDelay',filtDelay);

% Die Bitsequenz muss bei DPQSK ein vielfaches von 2 sein, da pro
% Übertragungsschritt ein Symbol aus 2 Bits übertragen wird
% bitsequence = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ]';
bitsequence = randi([0 1], n, 1);

% Berechnung der Bits, die an die eigentliche Übertragung vorgestellt
% werden sollen, damit das Einschwingen des Filters 
prepend = zeros(skipSymbols, 1);

% Berechnung des modulierten Signals. Das Ergebnis ist ein Vektor mit
% Komplexen Zahlen.
modSig = dqpskmod(vertcat(prepend, bitsequence));

txSig = txfilter(modSig);

plot(txSig); % Figure 1

% Störung auf der Strecke hinzufügen

rxSig = rxfilter(txSig);
scatterplot(rxSig); % Figure 2

if skipSymbols == 0
    displaySkip = 1;
else
    displaySkip = skipSymbols;
end

eyediagram(rxSig(displaySkip:1000 + displaySkip),ovs); % Figure 3

figure()
plot(real(rxSig(displaySkip:displaySkip + 100))) % Figure 4

figure()

% FRAGE: Warum ist das Konstellationsdiagramm leer?
constDiagram = comm.ConstellationDiagram('SamplesPerSymbol',ovs, ...
    'SymbolsToDisplaySource','Property','SymbolsToDisplay',1000);
constDiagram(modSig); % Figure 5

% Downsampling
rxDown = rxSig(1:ovs:end)

% Berechnung des demodulierten Signals
rxData = dqpskdemod(rxDown);

% Entfernen der vorgestellten Bits (Einschwingen)
rxData = rxData(skipSymbols + 1:end)

% Auswertung der Fehler
errorStats = errorRate(bitsequence, rxData);

rate = errorStats(1)
errors = errorStats(2)
total = errorStats(3)

sprintf("Der ErrrorStet: %f\n", errorStats);
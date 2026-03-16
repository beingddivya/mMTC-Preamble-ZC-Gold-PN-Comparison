clear all;
close all;

NumSamples = 500000;

K = 40;         % Number of devices
L = 21;         % Preamble length
pa = 0.01;       % Activation probability
snr_db = 10;    % Target SNR in dB

sigma2z = 0.1;  % Noise variance

% Generate complex Gold sequences (real + imag)
A = zeros(L, K);  % Initialize preamble matrix

for k = 1:K
    % Generate real part of Gold sequence
    gold_real = comm.GoldSequence(...
        'FirstPolynomial', 'x^11 + x^2 + 1', ...
        'SecondPolynomial', 'x^11 + x^8 + x^5 + x^2 + 1', ...
        'FirstInitialConditions', [0 0 0 0 0 0 0 0 0 0 1], ...
        'SecondInitialConditions', [0 0 0 0 0 0 0 0 0 0 1], ...
        'Index', k, ...
        'SamplesPerFrame', L);
    
    seq_real = 2 * double(gold_real()) - 1;  % Bipolar {-1, +1}

    % Generate imaginary part of Gold sequence (offset Index for diversity)
    gold_imag = comm.GoldSequence(...
        'FirstPolynomial', 'x^11 + x^2 + 1', ...
        'SecondPolynomial', 'x^11 + x^8 + x^5 + x^2 + 1', ...
        'FirstInitialConditions', [1 0 0 0 0 0 0 0 0 0 1], ...
        'SecondInitialConditions', [1 0 0 0 0 0 0 0 0 0 1], ...
        'Index', k+K, ...  % different index to avoid same output
        'SamplesPerFrame', L);
    
    seq_imag = 2 * double(gold_imag()) - 1;

    % Combine and normalize to match energy of L
    seq_complex = (seq_real + 1i * seq_imag) / sqrt(2);
    seq_complex = sqrt(L) * seq_complex / norm(seq_complex);
    A(:, k) = seq_complex;
end

% ? Insert correlation analysis here
% ----- Correlation Analysis -----
CorrMatrix = abs(A' * A);
CorrMatrixNorm = CorrMatrix / L;

figure;
imagesc(CorrMatrixNorm);
colorbar;
title('Normalized Cross-Correlation Magnitude of Gold Sequences');
xlabel('Device Index');
ylabel('Device Index');
axis square;

% ----- Histogram of Cross-Correlation (excluding self) -----
cross_corr_vals = CorrMatrixNorm(~eye(K));  % Remove diagonal (self-correlations)
figure;
histogram(cross_corr_vals, 30);
xlabel('Cross-Correlation Magnitude');
ylabel('Frequency');
title('Histogram of Cross-Correlation Magnitudes');




% Allocate dataset arrays
Dataset_features = zeros(NumSamples, 2*L);
Dataset_target = zeros(NumSamples, K);
Dataset_ak = zeros(L, 1, NumSamples) + 1i * zeros(L, 1, NumSamples);

% Generate dataset
for s = 1:NumSamples
    h = (randn(K,1) + 1i*randn(K,1)) / sqrt(2);  % Rayleigh fading

    alpha = double(rand(K,1) < pa);  % Activation
    x = alpha .* h;

    active_indices = find(alpha == 1); 
    ak_sample = sum(A(:, active_indices), 2);  % Active sum
    Dataset_ak(:, :, s) = ak_sample;

    % Scale to match target SNR
    signal_power = mean(abs(A * x).^2);
target_signal_power = sigma2z * 10^(snr_db/10);

if signal_power > 0
    scaling_factor = sqrt(target_signal_power / signal_power);
    x = scaling_factor * x;
end


    % Add noise
    z = sqrt(sigma2z) * (randn(L,1) + 1i*randn(L,1)) / sqrt(2);
    y = A * x + z;

    % Save input/output
    Dataset_features(s, :) = [real(y).' imag(y).'];

    Dataset_target(s, :) = alpha;
end

% Save to .mat file
save(fullfile(getenv('USERPROFILE'), 'Downloads', 'AUD_Dataset_Gold0point01_complex.mat'), ...
    'Dataset_features', 'Dataset_target', 'Dataset_ak', 'A');


% Count NaNs in Dataset_features
num_nans_features = sum(isnan(Dataset_features), 'all');
disp(['NaNs in Dataset_features: ', num2str(num_nans_features)]);

% Count NaNs in Dataset_target
num_nans_target = sum(isnan(Dataset_target), 'all');
disp(['NaNs in Dataset_target: ', num2str(num_nans_target)]);

% Count NaNs in Dataset_ak
num_nans_ak = sum(isnan(Dataset_ak), 'all');
disp(['NaNs in Dataset_ak: ', num2str(num_nans_ak)]);




% Final SNR check
final_signal_power = mean(abs(A * x).^2);
final_snr = 10 * log10(final_signal_power / sigma2z);
disp(['Final SNR: ', num2str(final_snr), ' dB']);

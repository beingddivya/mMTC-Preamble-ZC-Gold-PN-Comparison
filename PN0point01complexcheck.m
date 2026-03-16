clear all;
close all;

%% Parameters
NumSamples = 500000;
K = 40;         % Number of devices
L = 21;         % Preamble length
pa = 0.01;      % Activation probability
snr_db = 10;    % Target SNR in dB
sigma2z = 0.1;  % Fixed noise variance

%% ---- PN Sequence Generation ----
m = 5;  % Number of Flip-Flops; results in sequence length 2^m - 1 = 31 > L
tap_positions = [5 2];  % Example taps for LFSR: x^5 + x^2 + 1

% Generate one long PN sequence
pn_full = generate_pn_sequence(m, tap_positions);  % Now QPSK-like complex values

% Use cyclic shifts to assign different sequences to each user
A = zeros(L, K);
for k = 1:K
    shift = mod(k-1, length(pn_full));  % To ensure enough unique shifts
    pn_shifted = circshift(pn_full, shift);
    A(:,k) = pn_shifted(1:L).';
end

% Normalize each column to have norm sqrt(L)
A_norm = vecnorm(A);
A = sqrt(L) * A ./ A_norm;

%% ---- Dataset Initialization ----
Dataset_features = zeros(NumSamples, 2*L);  % [real, imag]
Dataset_target = zeros(NumSamples, K);
Dataset_ak = zeros(L, 1, NumSamples) + 1i * zeros(L, 1, NumSamples);

H_all = zeros(K, NumSamples);

%% ---- Sample Generation ----
valid_sample_count = 0;
s = 1;

target_signal_power = sigma2z * 10^(snr_db/10);

while valid_sample_count < NumSamples
    h = (randn(K,1) + 1i*randn(K,1))/sqrt(2);  % Rayleigh fading
    alpha = double(rand(K,1) < pa);           % Active devices
    x = alpha .* h;

    active_indices = find(alpha == 1);
    ak_sample = sum(A(:, active_indices), 2);

    signal_power = mean(abs(A * x).^2);

    if signal_power == 0
        s = s + 1;
        continue;  % Skip zero signal power cases
    end

    % Adjust signal power to match target SNR
    scaling_factor = sqrt(target_signal_power / signal_power);
    x = scaling_factor * x;

    % Add noise
    z = sqrt(sigma2z) * (randn(L,1) + 1i*randn(L,1))/sqrt(2);
    y = A * x + z;

    valid_sample_count = valid_sample_count + 1;

    Dataset_features(valid_sample_count, :) = [real(y); imag(y)];
    Dataset_target(valid_sample_count, :) = alpha;
    Dataset_ak(:, :, valid_sample_count) = ak_sample;
    H_all(:, valid_sample_count) = h;

    % Optional: progress display
    if mod(valid_sample_count, 50000) == 0
        disp(['Collected ', num2str(valid_sample_count), ' valid samples...']);
    end

    s = s + 1;
end

%% ---- Final Trimming ----
Dataset_features = Dataset_features(1:valid_sample_count, :);
Dataset_target = Dataset_target(1:valid_sample_count, :);
Dataset_ak = Dataset_ak(:, :, 1:valid_sample_count);
H_all = H_all(:, 1:valid_sample_count);

%% ---- Save Dataset ----
save(fullfile(getenv('USERPROFILE'), 'Downloads', 'AUD_Dataset_PN0point01_complex.mat'), ...
    'Dataset_features', 'Dataset_target', 'Dataset_ak', 'H_all', 'A');

%% ---- Check for NaNs ----
num_nans_features = sum(isnan(Dataset_features), 'all');
disp(['NaNs in Dataset_features: ', num2str(num_nans_features)]);

num_nans_target = sum(isnan(Dataset_target), 'all');
disp(['NaNs in Dataset_target: ', num2str(num_nans_target)]);

num_nans_ak = sum(isnan(Dataset_ak), 'all');
disp(['NaNs in Dataset_ak: ', num2str(num_nans_ak)]);

%% ---- Final Statistics ----
disp(['? Total valid samples collected: ', num2str(valid_sample_count)]);

final_signal_power = mean(abs(A * x).^2);
final_snr = 10 * log10(final_signal_power / sigma2z);
disp(['? Final SNR: ', num2str(final_snr, '%.2f'), ' dB']);

%% ---- Function to generate QPSK-mapped complex PN sequence ----
function pn_seq = generate_pn_sequence(m, taps)
    reg = ones(1, m);  % Initial state (non-zero)
    seq_length = 2^m - 1;
    pn_seq_binary = zeros(1, seq_length);

    for i = 1:seq_length
        pn_seq_binary(i) = reg(end);  % Output bit
        feedback = mod(sum(reg(taps)), 2);  % XOR of tapped bits
        reg = [feedback reg(1:end-1)];
    end

    % Convert binary to {-1, 1}
    pn_seq = 2 * pn_seq_binary - 1;

    % Map binary PN to QPSK-style complex values
    pn_seq = (pn_seq == 1) * (1 + 1j)/sqrt(2) + ...
             (pn_seq == -1) * (1 - 1j)/sqrt(2);
end

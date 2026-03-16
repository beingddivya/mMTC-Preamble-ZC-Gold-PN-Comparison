function ZC_L21_Pa0point3_warning()
clear all;
close all;

NumSamples = 500000;
K = 40;         % Number of devices
L = 21;         % Preamble length (ZC sequence length)
pa = 0.3;       % Activation probability
snr_db = 10;    % Target SNR in dB

% Parameters for Noise
sigma2z = 0.1;
noise_power = sigma2z * L;  % Total noise power

% ----------------- REPLACE RANDOM GAUSSIAN SEQUENCES WITH ZC SEQUENCES -----------------
A = zeros(L, K);  % Matrix to store preambles

% ----------------- FIND VALID ZC ROOTS -----------------
% ----------------- FIND VALID ZC ROOTS -----------------
valid_roots = [];
for r = 1:L-1
    if gcd(r, L) == 1  % Check if r is relatively prime to L
        valid_roots = [valid_roots, r];
    end
end

Nr = ceil(K / L);  % Minimum number of roots required
if length(valid_roots) < Nr
    error('Not enough valid roots to support all devices.');
end

selected_roots = valid_roots(1:Nr);  % Pick only the required number of roots
disp('Selected ZC roots:');
disp(selected_roots);

% ----------------- ASSIGN UNIQUE (ROOT, SHIFT) PAIRS TO DEVICES -----------------
device_count = 0;
A = zeros(L, K);
device_info = zeros(K, 2);  % [root, shift] for debugging or analysis

for i = 1:Nr
    root_r = selected_roots(i);
    for shift_q = 0:L-1
        device_count = device_count + 1;
        if device_count > K
            break;
        end
        A(:, device_count) = zcseq(L, root_r, shift_q);
        A(:, device_count) = sqrt(L) * A(:, device_count) / norm(A(:, device_count));
        device_info(device_count, :) = [root_r, shift_q];
    end
end

disp('Assigned (root, shift) pairs for first few devices:');
disp(device_info(1:min(10,K), :));

% Cross-correlation matrix check (optional)
cross_corr_matrix = abs(A' * A);
disp('Cross-Correlation Matrix Sample:');
disp(cross_corr_matrix(1:5, 1:5));


% ----------------- GENERATE DATASET -----------------
Dataset_features = zeros(NumSamples, 2*L);
Dataset_target = zeros(NumSamples, K);
Dataset_ak = zeros(L, 1, NumSamples); % 3D array with L×1 per sample

H_all = zeros(K, NumSamples);  % Initialize storage for all h values

s = 1;
while s <= NumSamples
    h = (randn(K,1) + 1i*randn(K,1))/sqrt(2); % Channel gains
    alpha = double(rand(K,1) < pa);  % Activation of devices

    % Skip if all devices are inactive
    if all(alpha == 0)
        continue;
    end

    x = alpha .* h;  % Transmitted signal

    raw_signal_power = sum(abs(A * x).^2) / L;

    % Skip if signal power is zero (just in case)
    if raw_signal_power == 0 || isnan(raw_signal_power)
        continue;
    end

    % Compute the required scaling factor for target SNR
    target_signal_power = 10^(snr_db/10) * noise_power;
    scaling_factor = sqrt(target_signal_power / raw_signal_power);

    % Apply scaling to the transmitted signal
    x = scaling_factor * x;

    % Add noise
    z = sqrt(sigma2z) * (randn(L,1) + 1i*randn(L,1))/sqrt(2);
    y = A * x + z;

    % Store the dataset
    Dataset_features(s, :) = [real(y); imag(y)];
    Dataset_target(s, :) = alpha;

    active_indices = alpha == 1;
    Dataset_ak(:, :, s) = sum(A(:, active_indices), 2);

    s = s + 1;  % Move to next sample
end

assert(all(~isnan(Dataset_features(:))), 'NaNs still exist in Dataset_features!');





% ----------------- Save Dataset -----------------
save(fullfile(getenv('USERPROFILE'), 'Downloads', 'AUD_Dataset_ZC0point3_L21_active.mat'), ...
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





disp('Dataset saved successfully in Downloads.');

% Compute Final SNR
final_signal_power = sum(abs(A * x).^2) / L;
final_snr = 10 * log10(final_signal_power / noise_power);
disp(['Final SNR: ', num2str(final_snr), ' dB']);

end  

% ----------------- LOCAL FUNCTION -----------------
function y = zcseq(N, R, Q)
    if gcd(N, R) ~= 1
        error('ZC sequence length N and parameter R should be relatively prime. %d and %d are not relative prime', N, R);
    else
        y = exp(-1j * R * pi * (0:N-1) .* ((0:N-1) + bitand(N,1) + 2*Q) / N);
    end
end

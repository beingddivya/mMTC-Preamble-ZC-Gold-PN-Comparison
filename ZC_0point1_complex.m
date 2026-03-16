function ZC_0point1_complex()
clear all;
close all;

NumSamples = 500000;
K = 40;         % Number of devices
L = 21;         % Preamble length (ZC sequence length)
pa = 0.1;       % Activation probability
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

    if sum(alpha) == 0
        continue;  % Skip and regenerate
    end

    x = alpha .* h;  % Transmitted signal

    active_indices = alpha == 1;
    ak_sample = sum(A(:, active_indices), 2);
    Dataset_ak(:, :, s) = ak_sample;

    raw_signal_power = sum(abs(A * x).^2) / L;
    target_signal_power = 10^(snr_db/10) * noise_power;
    scaling_factor = sqrt(target_signal_power / raw_signal_power);

    x = scaling_factor * x;

    z = sqrt(sigma2z) * (randn(L,1) + 1i*randn(L,1))/sqrt(2);
    y = A * x + z;

    Dataset_features(s, :) = [real(y); imag(y)].';
    assert(~any(isnan(Dataset_features(s, :))), 'NaN found in sample %d', s);

    Dataset_target(s, :) = alpha;

    s = s + 1;  % Only increment for valid sample
end


% ----------------- Save Dataset -----------------
save(fullfile(getenv('USERPROFILE'), 'Downloads', 'AUD_Dataset_ZC0point1_complex.mat'), ...
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


disp(['Number of samples: ', num2str(size(Dataset_features, 1))]);


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

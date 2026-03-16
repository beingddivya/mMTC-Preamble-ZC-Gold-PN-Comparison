# Impact of Preamble Sequence Design on Device Activity Detection in mMTC

## A Comparison of Zadoff-Chu, Gold, and PN Sequences

This repository contains the MATLAB and PyTorch implementation used in the research paper:

**Divya Yadav, Saikat Majumder, Ajay Singh Raghuvanshi**
*Impact of Preamble Sequence Design on Device Activity Detection in mMTC: A Comparison of Zadoff-Chu, Gold, and PN Sequences*
IEEE 6th India Council International Subsections Conference (INDISCON), 2025.
DOI: https://doi.org/10.1109/INDISCON66021.2025.11253618

---

# Overview

Massive Machine-Type Communication (mMTC) is a key technology enabling large-scale Internet of Things (IoT) connectivity.
In grant-free random access systems, reliable **Device Activity Detection (DAD)** is required to identify which devices are active in the network.

This work investigates how **preamble sequence design affects device activity detection performance**.
Three types of preamble sequences are compared:

* Zadoff-Chu (ZC) sequences
* Gold sequences
* Pseudo-Noise (PN) sequences

A **Deep Multilayer Perceptron (DMLP)** model is used to detect active devices from the received signal at the base station.

Simulation results show that **ZC sequences achieve superior detection performance due to their excellent correlation properties.**

---

# System Model

The considered system consists of:

* A single-cell uplink communication system
* **M machine-type devices** connected to a base station
* A **single-antenna base station**

Each device transmits a preamble during the random access phase.
The received signal at the base station is expressed as:

y = Ax + z

where:

* **A** : preamble matrix
* **x** : activity-channel vector
* **z** : additive white Gaussian noise

The objective of device activity detection is to identify the set of **active devices** from the received signal.

---

# Preamble Sequences

Three types of non-orthogonal preamble sequences are evaluated.

### Zadoff-Chu (ZC)

* Complex polyphase sequences
* Constant amplitude
* Ideal autocorrelation properties
* Provide better interference suppression

### Gold Sequences

* Generated from two m-sequences
* Balanced cross-correlation characteristics
* Constructed as complex sequences using real and imaginary components

### PN Sequences

* Generated using Linear Feedback Shift Registers (LFSR)
* Simple sequence generation
* Higher interference compared to ZC sequences

---

# Deep Multilayer Perceptron (DMLP)

The DMLP model processes the **real and imaginary components of the received signal** to detect active devices.

Network architecture:

Layer 1: Fully Connected + ReLU
Layer 2: Fully Connected + ReLU
Output Layer: Fully Connected + Sigmoid

The output layer produces activity probabilities for all devices.

A hard decision threshold is applied to determine whether a device is **active (1)** or **inactive (0)**.

---

# Simulation Parameters

| Parameter              | Value                   |
| ---------------------- | ----------------------- |
| Number of devices      | M = 40                  |
| Preamble length        | N = 21                  |
| Activation probability | Pact ∈ {0.01, 0.1, 0.3} |
| Noise variance         | 0.1                     |
| Signal-to-Noise Ratio  | 10 dB                   |
| Channel model          | Rayleigh fading         |

Dataset size used for evaluation:

100000 samples

Hidden layer sizes used in the DMLP model:

Nh = 80, 160, 320

---

# Results

The following performance evaluations are conducted:

1. Empirical CDF of SINR for ZC, Gold, and PN sequences
2. Training and validation loss of the DMLP model
3. Optimal threshold analysis for device detection
4. ROC curve comparison for sequence performance

Key observations:

* ZC sequences provide higher SINR values
* Larger hidden layer sizes improve model convergence
* ZC sequences achieve the best ROC performance among the three sequences

---

# Requirements

MATLAB R2019b or later

Python 3.x

Required Python libraries:

* PyTorch
* NumPy
* Matplotlib

---

# Citation

If you use this repository in your research, please cite:

D. Yadav, S. Majumder, and A. S. Raghuvanshi,
"Impact of Preamble Sequence Design on Device Activity Detection in mMTC: A Comparison of Zadoff-Chu, Gold, and PN Sequences,"
in *Proc. IEEE 6th India Council International Subsections Conference (INDISCON)*,
Rourkela, India, Aug. 2025, doi:10.1109/INDISCON66021.2025.11253618.

## BibTeX

```
@inproceedings{yadav2025preamble,
  author={Yadav, Divya and Majumder, Saikat and Raghuvanshi, Ajay Singh},
  title={Impact of Preamble Sequence Design on Device Activity Detection in mMTC: A Comparison of Zadoff-Chu, Gold, and PN Sequences},
  booktitle={IEEE 6th India Council International Subsections Conference (INDISCON)},
  year={2025},
  doi={10.1109/INDISCON66021.2025.11253618}
}
```



---

# License

This repository is provided for **research and academic purposes only**.

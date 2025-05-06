# ?? Verilog-Based Artificial Neural Network (ANN)

This project implements an Artificial Neural Network (ANN) entirely in Verilog, simulating a basic feedforward neural architecture. The goal of this design is to accurately classify images from the MNIST handwritten digit dataset. The implementation follows a modular approach for clarity and scalability.

## ??? Architecture Overview

The ANN is composed of the following modules:

### ?? `complete_neuron.v`
 It implements the core functionality of a single neuron. It computes:
- Weighted sum of inputs
- Adds a bias to the accumulated sum
- Applies ReLu activation function and generates the output.

### ?? `complete_neuron_layer1.v`, `complete_neuron_layer2.v`, `complete_neuron_layer3.v`
Each of these files represents a layer in the neural network, where layer1 and layer2 contain 30 neurons, and layer3 contains 10 neurons. Each layer is implemented using a generate statement. The layers consist of multiple instantiated single neurons operating in parallel.


### ?? `top_nn.v`
Top-level module that:
- Connects all layers in a feedforward manner and includes a parallel to serial shift register between the layers to reduce the hardware overhead.
- Manages the input-to-output signal flow
- Forms a complete neural network

### ?? `include.v`
Contains configurable constants and parameters such as:
- Bit widths
- Number of neurons per layer
- Activation thresholds etc

This file ensures the design is easily scalable and maintainable.

### ?? `max_find.v`
Implements a **hard max** operation:
- Takes all output neuron values
- Outputs the index of the maximum value 

---

## ?? File Structure

```bash
+-- complete_neuron.v        # Implements single neuron functionality
+-- complete_neuron_layer1.v        # First layer of neurons
+-- complete_neuron_layer2.v        # Second layer of neurons
+-- complete_neuron_layer3.v        # Third layer of neurons
+-- top_nn.v       # Top-level integration of all layers
+-- max_find.v             # Max value selector module
+-- include.v             # Parameter/configuration header
+-- testbench/             # (Optional) Simulation testbenches

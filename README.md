# Newb-fpga-verilog-project
verilog project

---CNN lenet5 using verilog---
This project is a model that implements Lenet-5 using verilog.
This model is a lightweight model with the following structure, and the accuracy is 93%.

        input size = 28x28
        Convolution1 size = 1x5x5x3 (no bias only weight)
        Convolution2 size = 3x5x5x3 (no bias only weight)
        FC size = 48x10 (bias+weight)

Not only the verilog file, but also the weights and bias values are attached as mem.h files.
A file used as input in the test bench file is where the "test_image/num0to9/test_num_all_10timesl.mem" file.

Simulation can be done immediately and the results can be achieved. The result value is the o_result value when the o_end signal is 1.

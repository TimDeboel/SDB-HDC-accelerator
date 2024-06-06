# Script to generate random hypervectors and
# the connectivity matrices for the hypervector
# manipulator (MAN) modules
import numpy as np

# Set parameters
D = 1024
M = 50   # Number of ones
IM_size = 30 # Number of HV's stored in the IM
print("Density: " + str(M/D))


def gen_rand_hv(D):

    # Sanity checker
    if (D % 2):
        print("Error - D can't be an odd number")
        return 0

    hv = np.zeros(D, dtype = int)
    indices = np.random.permutation(D)

    hv[indices >= M] = 0
    hv[indices < M] = 1

    hv = "".join(str(x) for x in hv)
    hv = str(D) + "'b" + hv

    return hv

item_mem = ""
for hv_num in range(IM_size):
    # item_mem = item_mem + gen_rand_hv(D) + "\n"
    item_mem = item_mem + "6'd" + str(hv_num) + ": " + "im_man_out = " + gen_rand_hv(D) + ";\n"


f = open("./hw_v1/hv_generators/im_man.txt", "w")
f.write(item_mem)
f.close()
print("Output written in: im_man.txt")

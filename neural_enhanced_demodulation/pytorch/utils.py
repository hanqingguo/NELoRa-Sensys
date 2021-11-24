"""Helpful functions for project."""
import os
import torch
from torch.autograd import Variable

from random import shuffle
import numpy as np
import functools
import operator


def to_var(x):
    """Converts numpy to variable."""
    if torch.cuda.is_available():
        x = x.cuda()
    return Variable(x)


def convertTuple(tup):
    str = functools.reduce(operator.add, (tup))
    return str


def spec_to_network_input(x, opts):
    """Converts numpy to variable."""
    freq_size = opts.freq_size
    # trim
    trim_size = freq_size // 2
    # up down 拼接
    y = torch.cat((x[:, -trim_size:, :], x[:, 0:trim_size, :]), 1)

    if opts.normalization:
        y_abs = torch.abs(y)
        y_abs_max = torch.tensor(
            list(map(lambda x: torch.max(x), y_abs)))
        y_abs_max = to_var(torch.unsqueeze(torch.unsqueeze(y_abs_max, 1), 2))
        y = torch.div(y, y_abs_max)

    if opts.x_image_channel == 2:
        y = torch.view_as_real(y)  # [B,H,W,2]
        y = torch.transpose(y, 2, 3)
        y = torch.transpose(y, 1, 2)
    else:
        y = torch.angle(y)  # [B,H,W]
        y = torch.unsqueeze(y, 1)  # [B,H,W]
    return y  # [B,2,H,W]


def generate_dataset(root_path, data_dir, ratio_bt_train_and_test,
                     code_list, snr_list, bw_list, sf_list,
                     instance_list, sorting_type):
    data_src = os.path.join(root_path, data_dir)
    for _, _, files in os.walk(data_src):
        files_filtered = list(
            filter(
                lambda x:
                (int(x[:-4].split('_')[1]) in snr_list) and
                (int(x[:-4].split('_')[2]) in sf_list) and
                (int(x[:-4].split('_')[3]) in bw_list) and
                (int(x[:-4].split('_')[4]) in instance_list), files))
        if sorting_type != 0:
            files_filtered.sort(
                key=lambda x: (int(x[:-4].split('_')[sorting_type]), float(x[:-4].split('_')[0])))
        num_files = len(files_filtered)
        num_train = int(num_files * ratio_bt_train_and_test)
        files_filtered = np.array(files_filtered)

        files_train = files_filtered[0:num_train].tolist()
        shuffle(files_train)
        files_test = files_filtered[num_train:num_files].tolist()
        shuffle(files_test)

        print("length of training and testing data is {},{}".format(len(files_train), len(files_test)))
    return [files_train, files_test]

def set_gpu(free_gpu_id):
    """Converts numpy to variable."""
    torch.cuda.set_device(free_gpu_id)


def to_var(x):
    """Converts numpy to variable."""
    if torch.cuda.is_available():
        x = x.cuda()
    return Variable(x)


def to_data(x):
    """Converts variable to numpy."""
    if torch.cuda.is_available():
        x = x.cpu()
    return x.data.numpy()


def create_dir(directory):
    """Creates a directory if it does not already exist.
    """
    if not os.path.exists(directory):
        os.makedirs(directory)


def print_opts(opts):
    """Prints the values of all command-line arguments.
    """
    print('=' * 80)
    print('Opts'.center(80))
    print('-' * 80)
    for key in opts.__dict__:
        if opts.__dict__[key]:
            try:
                print('{:>30}: {:<30}'.format(key, opts.__dict__[key]).center(80))
            except:
                pass
    print('=' * 80)

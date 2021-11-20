# data_loader.py

import os
import torch
from torch.utils.data import DataLoader
from torch.utils import data
import torch.nn.functional as F

from torchvision import datasets
from torchvision import transforms

import scipy.io as scio
import numpy as np
from PIL import Image


class lora_dataset(data.Dataset):
    'Characterizes a dataset for PyTorch'

    def __init__(self, opts, files_list, transform=None, groundtruth=False):
        'Initialization'
        # self.scaling_for_intensity = opts.scaling_for_intensity
        self.featrue_name = opts.feature_name  # get from config.create_parser
        self.transform = transform
        self.data_dir = opts.data_dir
        self.data_lists = files_list
        self.groundtruth = groundtruth
        self.groundtruth_code = opts.groundtruth_code

    def __len__(self):
        'Denotes the total number of samples'

        return len(self.data_lists)

    def __getitem__(self, index):
        'Generates one sample of data'
        data_file_name = self.data_lists[index]
        if self.groundtruth:
            data_file_name = data_file_name.split("_")
            data_file_name[1] = self.groundtruth_code
            data_file_name = ('_').join(data_file_name)
        data_file_per = os.path.join(self.data_dir, data_file_name)

        lora_img = np.array(
            scio.loadmat(data_file_per)[self.featrue_name].tolist())
        lora_img = np.squeeze(lora_img)
        data_per = torch.tensor(lora_img, dtype=torch.cfloat)

        label_per = data_file_name[:-4]
        return data_per, label_per


# receive the csi feature map derived by the ray model as the input
def lora_loader(opts, files_train, files_test, groundtruth):
    """Creates training and test data loaders.
    """
    transform = transforms.Compose([
        transforms.ToTensor(),
    ])

    training_dataset = lora_dataset(opts, files_train, transform, groundtruth)
    testing_dataset = lora_dataset(opts, files_test, transform, groundtruth)

    training_dloader = DataLoader(dataset=training_dataset,
                                  batch_size=opts.batch_size,
                                  shuffle=False,
                                  num_workers=opts.num_workers)
    testing_dloader = DataLoader(dataset=testing_dataset,
                                 batch_size=opts.batch_size,
                                 shuffle=False,
                                 num_workers=opts.num_workers)
    return training_dloader, testing_dloader

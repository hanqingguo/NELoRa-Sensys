"""Main script for project."""
from __future__ import print_function
from utils import generate_dataset, create_dir, set_gpu, print_opts
import config
import datasets.data_loader as data_loader
import end2end
import os


def main(opts):
    """Loads the data, creates checkpoint and sample directories, and starts the training loop.
    """
    [files_train, files_test
     ] = generate_dataset(opts.root_path, opts.data_dir, opts.ratio_bt_train_and_test,
                          opts.code_list, opts.snr_list, opts.bw_list, opts.sf_list,
                          opts.instance_list, opts.sorting_type)
    # Create train and test dataloaders for images from the two domains X and Y

    training_dataloader_X, testing_dataloader_X = data_loader.lora_loader(
        opts, files_train, files_test, False)
    training_dataloader_Y, testing_dataloader_Y = data_loader.lora_loader(
        opts, files_train, files_test, True)

    # Create checkpoint and sample directories
    create_dir(opts.checkpoint_dir)
    if not opts.server:
        create_dir(opts.sample_dir)
        create_dir(opts.testing_dir)

    # Start training
    set_gpu(opts.free_gpu_id)

    # select the model

    if opts.network == 'end2end':
        end2end.training_loop(training_dataloader_X, training_dataloader_Y, testing_dataloader_X,
                              testing_dataloader_Y, opts)


if __name__ == "__main__":
    parser = config.create_parser()
    opts = parser.parse_args()
    if opts.server:
        opts.root_path = '/srv/node/sdb1/lcn/mobisys2021_server'

    opts.n_classes = 2 ** opts.sf
    opts.stft_nfft = opts.n_classes * opts.fs // opts.bw

    opts.stft_window = opts.n_classes // 2
    opts.stft_overlap = opts.stft_window // 2
    opts.conv_dim_lstm = opts.n_classes * opts.fs // opts.bw
    opts.freq_size = opts.n_classes
    opts.dir_comment = opts.dir_comment

    opts.evaluations_path = os.path.join(opts.root_path, opts.evaluations_dir)

    opts.sample_dir = os.path.join(opts.evaluations_path, opts.dir_comment + "_" + opts.sample_dir)

    opts.checkpoint_dir = os.path.join(opts.evaluations_path, opts.dir_comment + "_" + opts.checkpoint_dir)

    opts.testing_dir = os.path.join(opts.evaluations_path, opts.dir_comment + "_" + opts.testing_dir)

    if opts.load:
        opts.sample_dir += ("_" + opts.load)
        opts.testing_dir += ("_" + opts.load)

    print_opts(opts)

    main(opts)

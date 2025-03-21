import numpy as np
import glob, os
import imageio
import cv2
import scipy


def myglob(dir, pat):
    result = list()
    for file in os.listdir(dir):
        if file.endswith(pat):
            result.append(os.path.join(dir, file))
    return result


def load_images(paths):
    imgs = list()
    for i in range(0, len(paths), 1):
        x = scipy.ndimage.imread(paths[i])
        if (len(x.shape) == 3):
            if (x.shape[2] == 3):
                x = rgb2ycbcr(x)
                x = x[:, :, 0]
        # print('{0:.3f}    {1:.3f}    {2:.3f}'.format(np.amin(x), np.amax(x), np.mean(x.ravel())))
        x = im2double(x)
        imgs.append(x)
    return imgs

def im2double(im):
    # min_val = np.min(im.ravel())
    # max_val = np.max(im.ravel())
    # out = (im.astype('float') - min_val) / (max_val - min_val)
    out = im.astype('float')/255
    return out

def rgb2ycbcr(im_rgb):
    im_rgb = im_rgb.astype(np.float)
    im_ycrcb = cv2.cvtColor(im_rgb, cv2.COLOR_RGB2YCR_CB)
    im_ycbcr = im_ycrcb[:, :, (0, 2, 1)].astype(np.float)
    im_ycbcr[:, :, 0] = (im_ycbcr[:, :, 0] * (235 - 16) + 16) / 255.0  # to [16/255, 235/255]
    im_ycbcr[:, :, 1:] = (im_ycbcr[:, :, 1:] * (240 - 16) + 16) / 255.0  # to [16/255, 240/255]
    return im_ycbcr

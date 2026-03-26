# -*- coding: utf-8 -*-
"""
Created on Thu Mar 12 14:33:48 2026

@author: ataguaja
"""

import glob
import skimage.io as ski_io
import skimage.measure
import pandas as pd
import numpy as np
import trackpy as tp
from tqdm import tqdm
import os

filepath = 'D:/Antonio/epyseg/ecadGFP'

# Folder for outputs
os.makedirs(f"{filepath}/labeled", exist_ok=True)
os.makedirs(f"{filepath}/tracked", exist_ok=True)
os.makedirs(f"{filepath}/dataframes", exist_ok=True)
#%% PARAMETERS

list_param = ('centroid', 'label', 'area','perimeter')
# area_threshold = 2000   # Maximum area to keep
pixel_range = 18        # TrackPy search range
min_track_length = 5    # Optional: remove very short tracks

# Import contours images 
files = glob.glob(f'{filepath}/*.tif')
sorted_files = sorted(files)

#%% Loop through files
for file in sorted_files:

    print("Processing:", file)
    stack = ski_io.imread(file)  # 3D TIFF (time, y, x)
    
    labeled_stack = []
    df = pd.DataFrame()
    
   # --- LOOP THROUGH FRAMES ---
    for t in range(stack.shape[0]):
        label_image = stack[t]
        
        # Convert to binary
        binary = label_image < 1
        
        # Label regions
        label_image = skimage.measure.label(binary, connectivity=1)
        labeled_stack.append(label_image)
        
        # Extract properties
        props = skimage.measure.regionprops_table(
            label_image=label_image,
            intensity_image=None,
            properties=list_param
        )
        
        df_int = pd.DataFrame(props)
        df_int['frame'] = t
        df_int['file'] = os.path.basename(file)
        
        df = pd.concat([df, df_int], ignore_index=True)
    
    # Convert labeled stack to 3D array
    labeled_stack = np.array(labeled_stack)
    
    # Save labeled stack
    out_name = os.path.basename(file).replace('.tif', '_labeled.tif')
    ski_io.imsave(f"{filepath}/labeled/{out_name}", labeled_stack.astype(np.uint16))
    
    # --- FILTER BIG CELLS ---
    # df = df[df['area'] < area_threshold].copy()
    
    # Rename centroid columns for TrackPy
    df = df.rename(columns={"centroid-0": "y", "centroid-1": "x"})
    
    # --- TRACK CELLS ---
    if not df.empty:
        df = tp.link(
            df,
            search_range=pixel_range,
            adaptive_stop=5,
            adaptive_step=0.95,
            t_column='frame',
            memory=1
        )
        df['particle'] = df['particle'] + 1  # particle numbering starts at 1
        
        # Remove short tracks
        # lifespan_dict = {p: len(df[df['particle']==p]) for p in df['particle'].unique()}
        # valid_particles = [p for p,l in lifespan_dict.items() if l >= min_track_length]
        # df = df[df['particle'].isin(valid_particles)]
        
        # --- CREATE TRACKED STACK ---
        # tracked_stack = np.zeros_like(labeled_stack, dtype=np.uint16)
        # for _, row in df.iterrows():
        #     f = int(row['frame'])
        #     y = int(row['y'])
        #     x = int(row['x'])
        #     tracked_stack[f, y, x] = int(row['particle'])
        
        # Save tracked stack
        # tracked_name = os.path.basename(file).replace('.tif', '_tracked.tif')
        # ski_io.imsave(f"{filepath}/tracked/{tracked_name}", tracked_stack.astype(np.uint16))
    
    # --- SAVE DATAFRAME ---
    df_filename = os.path.basename(file).replace('.tif','')
    df.to_pickle(f"{filepath}/dataframes/{df_filename}.pkl")
    df.to_csv(f"{filepath}/dataframes/{df_filename}.csv", index=False)
    
    print("Finished:", file)

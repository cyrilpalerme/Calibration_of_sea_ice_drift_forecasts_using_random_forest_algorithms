#$ -S /bin/bash
#$ -l h_rt=00:30:00
#$ -q research-el7.q
#$ -l h_vmem=10G
#$ -t 1-10
#$ -o /lustre/storeB/users/cyrilp/Svalnav/data_processing_files/OUT/OUT_$JOB_NAME.$JOB_ID.$HOSTNAME.$TASK_ID
#$ -e /lustre/storeB/users/cyrilp/Svalnav/data_processing_files/ERR/ERR_$JOB_NAME.$JOB_ID.$HOSTNAME.$TASK_ID
#$ -cwd

echo "Got $NSLOTS slots for job $SGE_TASK_ID."

module load Python/3.7.2

cat > "/lustre/storeB/users/cyrilp/Svalnav/data_processing_files/PROG/model_IB_SAR_""$SGE_TASK_ID"".py" << EOF
################################################
import matplotlib
matplotlib.use('Agg')
import os
from netCDF4 import Dataset
import numpy as np
import glob
from datetime import datetime, timedelta
import time
import sys
import pickle
import pandas as pd
from pandas import *
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
#from sklearn.externals import joblib
from collections import defaultdict
#############################################################################################################
# Paths 
#############################################################################################################
fraction_selected = 0.02
fraction_str = str(int(100 * fraction_selected)) + '_percents'
#
path_data = '/lustre/storeB/project/copernicus/svalnav/April_2021/RF_training_data/Trained_with_SAR/201801_202005_2_percents/'
path_models = '/lustre/storeB/project/copernicus/svalnav/April_2021/RF_models/Trained_with_SAR/Direction_201801_202005_2_percents_without_dayofyear/'
#############################################################################################################
# Input parameters
#############################################################################################################
#
# Random forest parameters
#
criterion = 'mse'
bootstrap = True
max_depth = None
max_features = 3
min_samples_leaf = 1
min_samples_split = 2
n_estimators = 200
n_jobs = 1
#
rf_param_str = 'nestimators_' + str(n_estimators) + '_maxfeatures_' + str(max_features) +  '_bootstrap_' + str(bootstrap) + '_maxdepth_' + str(max_depth) + \
	       '_minsamplessplit_' + str(min_samples_split) + '_minsamplesleaf_' + str(min_samples_leaf)
#
model = RandomForestRegressor(n_estimators = n_estimators, max_features = max_features, max_depth = max_depth, criterion = criterion, \
	min_samples_split = min_samples_split, min_samples_leaf = min_samples_leaf, bootstrap = bootstrap, n_jobs = n_jobs)
#
# Datasets train - test
#
date_min_train = '20180104'
date_max_train = '20200528'
#############################################################################################################
lead_time_start = $SGE_TASK_ID - 1
lead_time_end = lead_time_start + 1
leadtime_str = str(lead_time_start) + '-' + str(lead_time_end) 
#####################################################################################################
# Load data 
#####################################################################################################
###
### Dataset for training
###
file_input_train = 'RF_variables_T4grid_daily_' + date_min_train + '-' + date_max_train + '_' + str(lead_time_start) + '-' + str(lead_time_end) + '_days.dat'
#
df_RF_train = pd.read_csv(path_data + file_input_train, delimiter = '\t')
df_RF_train = df_RF_train.dropna(how='all', axis=1)  # Remove unnamed columns containing nan
#
Target_train = np.array(df_RF_train['SAR_drift_initial_bearing'])
df_feat_train = df_RF_train.drop('SAR_drift_magnitude', axis = 1)
df_feat_train = df_feat_train.drop('SAR_drift_initial_bearing', axis = 1)
df_feat_train = df_feat_train.drop('Start_date', axis = 1)
#
Features_train = df_feat_train.sort_index(axis = 1)
Feature_train_names = list(Features_train.columns)
Features_train = np.array(Features_train)
#####################################################################################################
# Random forests
#####################################################################################################
model.fit(Features_train, Target_train)
#
model_filename = file_input_train.replace('RF_variables_T4grid_daily_', 'RF_model_IB_' + rf_param_str + '_').replace('.dat', '.pkl')
with open(path_models + model_filename, 'wb') as file:
	pickle.dump(model, file)
##############################################################################################################
EOF

python3 "/lustre/storeB/users/cyrilp/Svalnav/data_processing_files/PROG/model_IB_SAR_""$SGE_TASK_ID"".py"

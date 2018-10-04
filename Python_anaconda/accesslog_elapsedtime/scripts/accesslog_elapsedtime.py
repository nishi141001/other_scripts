# -*- coding: utf-8 -*-
###################################
# input     :../tmp/.log
#           :../log/*.*
# output    :../output/.log
#           :../graph/*.*
###################################

import os
import os.path
import pandas as pd
import shutil
import datetime
import re
import numpy as np
import ConfigParser
import seaborn as sns
import matplotlib.dates as mdates
import matplotlib.pyplot as plt

# visual setting
font = {'family' : 'meiryo'}

# scripts root path
script_path = os.path.dirname(os.path.abspath('__file__'))
os.chdir(script_path)
os.chdir('..')
base = os.getcwd()


# read config
inifile = ConfigParser.SafeConfigParser()
inifile.read(r'.\conf\config.ini')
input_path  = inifile.get('file-path', 'input')
output_path = inifile.get('file-path', 'output')
graph_path  = inifile.get('file-path', 'graph')
temp_path   = inifile.get('file-path', 'temp')
script_path = inifile.get('file-path', 'script')
        
output_path = base + '\\' + output_path
graph_path  = base + '\\' + graph_path
temp_path   = base + '\\' + temp_path


    
# remove output folder
# check exists and make dir
os.chdir(base)
if os.path.isdir(output_path):
    shutil.rmtree(output_path) 
    os.makedirs(output_path)
else :
    os.makedirs(output_path)

if os.path.isdir(graph_path):
    shutil.rmtree(graph_path) 
    os.makedirs(graph_path)
else :
    os.makedirs(graph_path)

# input filename
os.chdir(temp_path)
for line in open (u'tmp.log'):
    # convert "\" to "/"
    line = os.path.normpath(line)

    # get file name    
    log_path = os.path.dirname(line)    
    log_file = os.path.basename(line)
    log_file = log_file.rstrip('\n')
    
    os.chdir(log_path)

    # read target file(csv)
    log = pd.read_csv(log_file, delimiter = r'\t' ,header = None, engine='python')
    #log.columns = ['full_path', 'timestamp', 'elapsed_time']
    log.columns = ['timestamp', 'logInfo', 'id', 'url', 'elapsed_time']    
                
    """ resample **************************************************************  
    S:seconds    
    T:minutes
    H:hours
    D:days
    M:months
    
    <loffset>
    output from loffset
    ************************************************************************"""       
    #*************************************************************************#
    # summary
    # create_date, excetion_count, elapsed_time    
    #*************************************************************************#

    # prepared resampling 
    log.index = pd.to_datetime(log.ix[:, 'timestamp'], format= '%Y/%m/%d %H:%M:%S')        
    #print log
    dateTimeIndex = pd.DatetimeIndex(log['timestamp'])    
    
    # per 10minutes
    #df_count = log.ix[:, 'timestamp'].resample('10T').count()    
        
    #df_elapsed_time_mean = log.ix[:, 'elapsed_time'].resample('10T').mean().fillna(0)
    df_elapsed_time_max = log.ix[:, 'elapsed_time'].resample('10T').max().fillna(0)
    df_elapsed_time_90perile = log.set_index(dateTimeIndex).groupby('url').resample('10T', how=lambda x: x.quantile(0.9)).fillna(0).drop('id',1).reset_index()
    df_elapsed_time_90perile.columns = ['url', 'timestamp', 'elapsed_time']
    df_output = df_elapsed_time_90perile.pivot_table(df_elapsed_time_90perile, index='timestamp', columns='url', fill_value=0)
    df_output.to_csv(output_path + '\\resample_90ile_' + log_file, index = False, sep='\t')
    
    """
    # merge with index
    log_resampling = pd.concat([df_count, df_elapsed_time_mean, df_elapsed_time_90perile, df_elapsed_time_max], axis = 1)
    log_resampling.columns = ['exection_count', 'elapsed_time_mean', 'elapsed_time_90perile', 'elapsed_time_max']
    log_resampling.to_csv(output_path + '\\resample_' + log_file, index = True, sep='\t')
    """
    """        
    # filter between '%H:%M:%S' and '%H:%M:%S' 
    log_resampling_period = log_resampling.ix[log_resampling.index.indexer_between_time(start_time = '08:00:00', end_time = '21:00:00', include_start = True, include_end = True)]
    log_resampling_period.to_csv(output_path + '\\priod_resample_' + log_file, index = True, sep='\t')
    """
    
    #*************************************************************************#
    # create graph
    # log_count, log_date_diff  
    #*************************************************************************#    
    # create graph
    df_output.plot.line(
                x= [df_output.index],
                y= [r'elapsed_time'], alpha=0.5, figsize=(16,10)) 
    
    plt.xlabel(r'timestamp') 
    plt.ylabel('elapsed_time')
    plt.savefig(graph_path + '/elapsed_time_' + log_file + r'.png', dpi=300)
    plt.close()
        
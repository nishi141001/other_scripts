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
    log = pd.read_csv(log_file, delimiter = ',' ,header = None)
    log.columns = ['full_path', 'timestamp', 'elapsed_time']
    
    # split path (sep = '\')    
    split_path = log.loc[:, 'full_path'].str.split('\\\\', expand = True)    

    # カラムのうち後ろから2列のみ取得
    columns_count = str(len(list(split_path)))
    
    log.loc[:, 'folder'] = split_path.ix[:, int(columns_count)-2] 
    log.loc[:, 'file'] = split_path.ix[:, int(columns_count)-1] 
    
    # add row_number column in all index
    log.loc[:, 'row_number'] = float('NaN')
    log.loc[:, 'row_number'] = log.sort_values(['timestamp', 'elapsed_time'], ascending = True).groupby(['folder']).cumcount()

    log.loc[:, 'row_number+1'] = float('NaN')
    log.loc[:, 'row_number+1'] = log.sort_values(['timestamp', 'elapsed_time'], ascending = True).groupby(['folder']).cumcount()+1

    log = log.sort_values(['folder', 'timestamp', 'elapsed_time'], ascending = True)        
       
    """ SQL like **************************************************************
    select a.*,b.*
        from  log as a
        left outer join log as b 
           on   a.folder        = b.folder 
          and   a.[row_number]  = b.[row_number+1]
    ************************************************************************"""    
    log_merge = pd.merge(log, log, left_on = ['folder', 'row_number'], right_on = ['folder', 'row_number+1'],  how='left')    
    
    # left joinの欠損値をNaN⇒0埋め
    log_merge.ix[:, 'elapsed_time_y'] = log_merge.ix[:, 'elapsed_time_y'].fillna(0)
    # drop needless columns
    log_merge =log_merge.drop(['row_number+1_x', 'full_path_y', 'timestamp_y', 'file_y', 'row_number_y', 'row_number+1_y'], axis=1)
            
    #*************************************************************************#
    # datediff    
    #*************************************************************************# 
    log_merge.ix[:, 'datediff'] = log_merge.ix[:,'elapsed_time_x'] - log_merge.ix[:,'elapsed_time_y']

    # output csv file(add row_number)
    log_merge.to_csv(output_path + '\\' + log_file, index = False, sep=',')
        
    log_date_summary = log_merge.ix[:, ['timestamp_x', 'datediff']]    
    log_date_summary.columns = ['create_date','elapsed_time']
    
    log_date_summary.to_csv(output_path + '\\presummary_' + log_file, index = True, sep='\t')
    
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
    log_date_summary.index = pd.to_datetime(log_date_summary.ix[:, 'create_date'], format= '%Y/%m/%d %H:%M:%S')        
    
    # per 10minutes
    df_count = log_date_summary.ix[:, 'create_date'].resample('10T').count()    
    df_elapsed_time_mean = log_date_summary.ix[:, 'elapsed_time'].resample('10T').mean().fillna(0)
    df_elapsed_time_max = log_date_summary.ix[:, 'elapsed_time'].resample('10T').max().fillna(0)
    df_elapsed_time_90perile = log_date_summary.ix[:, 'elapsed_time'].resample('10T', how=lambda x: x.quantile(0.9)).fillna(0)
    
    # merge with index
    log_resampling = pd.concat([df_count, df_elapsed_time_mean, df_elapsed_time_90perile, df_elapsed_time_max], axis = 1)
    log_resampling.columns = ['exection_count', 'elapsed_time_mean', 'elapsed_time_90perile', 'elapsed_time_max']
    log_resampling.to_csv(output_path + '\\resample_' + log_file, index = True, sep='\t')
    
    # filter between '%H:%M:%S' and '%H:%M:%S' 
    log_resampling_period = log_resampling.ix[log_resampling.index.indexer_between_time(start_time = '08:00:00', end_time = '21:00:00', include_start = True, include_end = True)]
    log_resampling_period.to_csv(output_path + '\\priod_resample_' + log_file, index = True, sep='\t')
    
    #*************************************************************************#
    # create graph
    # log_count, log_date_diff  
    #*************************************************************************#    

    # create graph(exection_count)
    log_resampling_period.plot.bar(
                x= [log_resampling_period.index],
                y= [r'exection_count'], alpha=0.5, figsize=(16,16)) 
                
    plt.xlabel(r'date') 
    plt.ylabel('exection_count')    
    plt.savefig(graph_path + '/exection_count_' + log_file + r'.png', dpi=300)
    plt.close()
    
    # create graph
    log_resampling_period.plot.line(
                x= [log_resampling_period.index],
                y= [r'elapsed_time_mean', 
                    r'elapsed_time_90perile', 
                    r'elapsed_time_max'], alpha=0.5, figsize=(16,10)) 
    
    plt.xlabel(r'date') 
    plt.ylabel('elapsed_time')
    plt.savefig(graph_path + '/elapsed_time_' + log_file + r'.png', dpi=300)
    plt.close()



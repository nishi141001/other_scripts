# -*- coding: utf-8 -*-
"""
###################################
input     :../tmp/.log
output    :../output/.log
###################################
\**********************************\
columns in log
'timestamp','thread','method','jobid','message'
\**********************************\
"""
import os
import os.path
import pandas as pd
import shutil
import datetime
import re
import numpy as np
import seaborn as sns
import matplotlib.dates as mdates
import matplotlib.pyplot as plt

# visual setting
font = {'family' : 'meiryo'}

# scripts root path
# input filepath
file_path = os.getcwd()
os.chdir(r"../")
root_path = os.getcwd()
os.chdir(r"tmp")

# remove output folder
# check exists
if os.path.isdir(r'../output'):
    shutil.rmtree(r'../output') 
else :
    pass

# input filename
for line in open (u'tmp.log'):
    # convert "\" to "/"
    line = os.path.normpath(line)

    # get file name    
    log_path = os.path.dirname(line)    
    log_file = os.path.basename(line)
    log_file = log_file.rstrip('\n')    
    os.chdir(log_path)

    # read target file(tsv)
    log = pd.read_csv(log_file, delimiter='\t' ,header=None)
    #print log #header check
    log.columns = ['timestamp','thread','method','jobid','message']    
    
    # grep    
    log_grep = log[log['jobid'].str.contains('jobid-038|jobid-039')]
    
    # create tsvfile path
    output_tsv_path = root_path + '/output'

    # mkdir output folders
    if os.path.isdir(output_tsv_path):
        pass
    else :        
        os.makedirs(output_tsv_path)
    
    # add row_number column in all index
    log_grep.loc[:, 'row_number'] = float('NaN')
    log_grep.loc[:, 'row_number'] = log_grep.sort_values(['timestamp'], ascending = True).groupby(['thread','jobid']).cumcount()+1
    
    # output tsv file(add row_number)
    log_grep.to_csv(output_tsv_path + '/' + log_file, index = False, sep='\t')
    
    #*************************************************************************#
    # datediff    
    #*************************************************************************#
    # filter start 
    log_date_start = log_grep.query("jobid == 'jobid-038'")
    # regex=True need to replace part of str     
    log_date_start.loc[:, 'timestamp'] = log_date_start.loc[:, 'timestamp'].replace('\[|\]','',regex=True)
   
    # filter end
    log_date_end = log_grep.query("jobid == 'jobid-039'")
    # regex=True need to replace part of str
    log_date_end.loc[:, 'timestamp'] = log_date_end.loc[:, 'timestamp'].replace('\[|\]','',regex=True)


    """ SQL like **************************************************************
    select start.*,end.* ,datediff(ss,start.timestamp,end.timestamp)
        from  start 
        inner join end 
           on  start.thread = end.thread 
          and start.row_number = end.row_number 
          and start.jobid = 'jobid-038'
          and end.jobid = 'jobid-039'
    ************************************************************************"""    
    log_date_diff = pd.merge(log_date_start, log_date_end, on=['thread','row_number'], how='inner')
    
    # add column diff timestamp
    #log_date_diff.loc[:,'datediff'] = float('NaN')    
    log_date_diff.ix[:, 'datediff'] = pd.to_datetime(log_date_diff.ix[:,'timestamp_y']) - pd.to_datetime(log_date_diff.ix[:,'timestamp_x'])

    # drop needless columns
    log_date_diff =log_date_diff.drop(['row_number', 'method_x', 'method_y', 'message_x', 'message_y',], axis=1)
    
    # output tsvfile
    log_date_diff.to_csv(output_tsv_path + '/merge_' + log_file, index = False, sep='\t')
        
    #*************************************************************************#
    # summary
    # excetion_count, elapsed_time    
    #*************************************************************************#
    log_date_summary = log_date_diff.ix[:, ['timestamp_x', 'datediff']]    
    log_date_summary.columns = ['start_date','elapsed_time']
    
    # prepared resampling 
    log_date_summary.index = pd.to_datetime(log_date_summary['start_date'], format= '%Y/%m/%d %H:%M:%S')    

    """ resample **************************************************************  
    S:seconds    
    T:minutes
    H:hours
    D:days
    M:months
    
    <loffset>
    output from loffset
    ************************************************************************"""       
    df_date = log_date_summary.ix[:, 'start_date']

    # convert timedelta64(ns) to seconds
    df_elapsed = log_date_summary.ix[:, 'elapsed_time']/np.timedelta64(1, 's')

    # per 3minutes
    df_count = df_date.resample('3T').count()
    df_elapsed_mean = df_elapsed.resample('3T').mean().fillna(0)

    # merge with index
    df_concat = pd.concat([df_count, df_elapsed_mean], axis = 1)

    df_concat.columns = ['exection_count', 'elapsed_time']
    df_concat.to_csv(output_tsv_path + '/summay_' + log_file, index = True, sep='\t')
    
    #*************************************************************************#
    # create graph
    # log_count, log_date_diff  
    #*************************************************************************#    

    # create graphfile path
    output_graph_path = root_path + '/graph'

    # mkdir output folders
    if os.path.isdir(output_graph_path):
        pass
    else :        
        os.makedirs(output_graph_path)
        
    # create graph(exection_count)
    df_concat.plot.bar(
                x= [df_concat.index],
                y=[r'exection_count'], alpha=0.5, figsize=(16,16)) 

    plt.xlabel(r'time') 
    plt.ylabel('exection_count')
    plt.savefig(output_graph_path + '/exection_count_' + log_file + r'.png', dpi=300)
    plt.close()
    
    # create graph
    df_concat.plot(
                x= [df_concat.index],
                y=[r'elapsed_time'], alpha=0.5, figsize=(16,10)) 
    
    plt.xlabel(r'time') 
    plt.ylabel('elapsed_time')
    plt.savefig(output_graph_path + '/elapsed_time_' + log_file + r'.png', dpi=300)
    plt.close()

    
    """
    fig, ax1 = plt.subplots()
    
    # X axis
    x = df_concat.index
    
    ax1.bar(x, df_concat['exection_count'], color= 'b')
    
    # relation 2axis
    ax2 = ax1.twinx()

    ax2.plot(x, df_concat['elapsed_time'], color = 'g', alpha=0.5)     
    """



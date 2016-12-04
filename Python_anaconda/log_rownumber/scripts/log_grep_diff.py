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


# function to grep
def grep_log(log_path, log_file, str1, str2):
    ld = open(log_path + '/' + log_file)
    lines = ld.readlines()
    ld.close()
    
    # remove tmp folder
    if os.path.exists(root_path + '/tmp/' + log_file + '_grep_tmp.log') :
        os.remove(root_path + '/tmp/' + log_file + '_grep_tmp.log')
    else :
        pass    
    # write tmp file
    grep_result = open(root_path + '/tmp/' + log_file + '_grep_tmp.log', 'a')    
    for line in lines:
        if line.find(str1) >= 0:
            grep_result.writelines(line[:-1] + "\n")
        elif line.find(str2) >= 0:
            grep_result.writelines(line[:-1] + "\n")
    grep_result.close()
        
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
#    os.chdir(log_path)
    
    # grep before pandas read file
    grep_log(log_path, log_file, 'jobid-038', 'jobid-039')

    log_path = root_path + '/tmp/'   
    log_file = log_file + '_grep_tmp.log'
    os.chdir(log_path)    
    # grep output path
    #log_file = root_path + '/tmp/' + log_file + '_grep_tmp.log'

    # read target file(tsv)
    log = pd.read_csv(log_file, delimiter='\t' ,header=None)
    #print log #header check
    log.columns = ['timestamp','thread','method','jobid','message']    
    
    # grep    
    #log_grep = log[log['jobid'].str.contains('jobid-038|jobid-039')]
    
    # create tsvfile path
    output_tsv_path = root_path + '/output'

    # mkdir output folders
    if os.path.isdir(output_tsv_path):
        pass
    else :        
        os.makedirs(output_tsv_path)
    
    # add row_number column in all index
    log.loc[:, 'row_number'] = float('NaN')
    log.loc[:, 'row_number'] = log.sort_values(['timestamp'], ascending = True).groupby(['thread','jobid']).cumcount()+1
    
    # output tsv file(add row_number)
    #log.to_csv(output_tsv_path + '/' + log_file, index = False, sep='\t')
    
    #*************************************************************************#
    # datediff    
    #*************************************************************************#
    # filter start 
    log_date_start = log.query("jobid == 'jobid-038'")
    # regex=True need to replace part of str     
    log_date_start.loc[:, 'timestamp'] = log_date_start.loc[:, 'timestamp'].replace('\[|\]','',regex=True)
   
    # filter end
    log_date_end = log.query("jobid == 'jobid-039'")
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
    #log_date_diff.to_csv(output_tsv_path + '/merge_' + log_file, index = False, sep='\t')
        
    #*************************************************************************#
    # summary
    # excetion_count, elapsed_time    
    #*************************************************************************#
    log_date_summary = log_date_diff.ix[:, ['timestamp_x', 'datediff']]    
    log_date_summary.columns = ['start_date','elapsed_time']
    
    # prepared resampling 
    log_date_summary.index = pd.to_datetime(log_date_summary.ix[:, 'start_date'], format= '%Y/%m/%d %H:%M:%S')
    
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
    df_count = df_date.resample('1T').count()
    df_elapsed_mean = df_elapsed.resample('1T').mean().fillna(0)

    # merge with index
    df_concat = pd.concat([df_count, df_elapsed_mean], axis = 1)

    df_concat.columns = ['exection_count', 'elapsed_time']
    df_concat.to_csv(output_tsv_path + '/summay_' + log_file, index = True, sep='\t')

    # filter between '%H:%M:%S' and '%H:%M:%S' 
    df_concat_period = df_concat.ix[df_concat.index.indexer_between_time(start_time = '00:50:00', end_time = '01:00:00', include_start = True, include_end = True)]
    df_concat_period.to_csv(output_tsv_path + '\\priod_resample_' + log_file, index = True, sep='\t')
    
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
    plt.savefig(output_graph_path + r'/01_exection_count_' + log_file + r'.png', dpi=300)
    plt.close()
    
    # create graph(elapsed_time)
    df_concat.plot(
                x= [df_concat.index],
                y=[r'elapsed_time'], alpha=0.5, figsize=(16,10)) 
    
    plt.xlabel(r'time') 
    plt.ylabel('elapsed_time')
    plt.savefig(output_graph_path + r'/02_elapsed_time_' + log_file + r'.png', dpi=300)
    plt.close()
    
    # create graph(merge)
    ax = df_concat.plot(
                x = [df_concat.index],
                y = [r'exection_count'],
                kind = 'area', 
                alpha = 0.5, 
                figsize = (16,4),
                color = 'g', 
                ylim = (0,10)
                ) 
    # 凡例位置:右下
    ax.legend(loc = 4)
    ax.set_ylabel("exection_count")
    
    ax2 = ax.twinx()
    ax3 = df_concat.plot(
                x = [df_concat.index],
                y = [r'elapsed_time'], 
                kind = 'line',
                alpha = 0.5, 
                figsize = (16,4), 
                color = 'b', 
                ylim = (0,4000), 
                ax = ax2
                )
                
    # 凡例位置:右上
    ax3.legend(loc = 1)
    ax3.set_ylabel("Average_elapsed_time(sec)")
    graph_title = "03_exection_count_elapsed_time"    

    plt.title(graph_title.decode('mbcs'), size=16)
    plt.savefig(output_graph_path + r'/' + graph_title + '_' + log_file + r'.png', dpi=300)
    # 作成したグラフオブジェクトを閉じる    
    plt.close()
    

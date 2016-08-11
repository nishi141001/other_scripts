# -*- coding: utf-8 -*-
"""
###################################
input     :../tmp/.log
output    :../output/.log
###################################
"""
import os
import os.path
import pandas as pd
import shutil
import datetime
import re

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
    log_grep.loc[:,'row_number'] = float('NaN')
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


    """ SQL like**************************************************************
    select start.*,end.* ,datediff(ss,start.timestamp,end.timestamp)
        from  start 
        inner join end 
           on  start.thread = end.thread 
          and start.row_number = end.row_number 
          and start.jobid = 'jobid-038'
          and end.jobid = 'jobid-039'
    ***********************************************************************"""    
    log_date_diff = pd.merge(log_date_start, log_date_end, on=['thread','row_number'], how='inner')
    
    # add column diff timestamp
    #log_date_diff.loc[:,'datediff'] = float('NaN')    
    log_date_diff.loc[:, 'datediff'] = pd.to_datetime(log_date_diff.loc[:,'timestamp_y']) - pd.to_datetime(log_date_diff.loc[:,'timestamp_x'])
    log_date_diff.to_csv(output_tsv_path + '/merge_' + log_file, index = False, sep='\t')
    

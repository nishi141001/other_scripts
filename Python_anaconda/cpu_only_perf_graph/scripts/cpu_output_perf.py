# -*- coding: utf-8 -*-
"""
###################################
input     :../log/*
output    :../output/*.csv
          ,../graph/*.
###################################
"""
import pandas as pd
import os
import os.path
import shutil
import numpy as np
import pandas as pd

# visual setting
font = {'family' : 'meiryo'}

# input filepath
file_path = os.getcwd()
os.chdir(u"../tmp")

# input filename
for line in open (u'tmp.log'):
    # convert "\" to "/"
    line = os.path.normpath(line)

    # get file name    
    df_perf_path = os.path.dirname(line)    
    df_perf_file = os.path.basename(line)
    df_perf_file = df_perf_file.rstrip('\n')    
    os.chdir(df_perf_path)


    # create csvfile path
    output_csv_path = df_perf_path.replace('log', 'output')

    # mkdir output folders
    if os.path.isdir(output_csv_path):
        pass
    else :        
        os.makedirs(output_csv_path)
        
    # read csv
    df_perf = pd.read_csv(df_perf_file)
     
    # extract columns
    df_perf_server = df_perf[[r"(PDH-CSV 4.0) (",
                              r"\\YUUSUKE-VAIO\Processor(_Total)\% Processor Time"
                              ]]
    
    df_perf_server.columns = [r"date",
                              r"CPU_Usage"
                              ]
                              
    # ""は"欠損値NaNに変換    
    df_perf_server.ix[:, df_perf_server.columns != r"date"] = df_perf_server.ix[:, df_perf_server.columns != r"date"].replace(r"\s+", np.nan, regex = True)
    
    # 欠損値NaNは直後の値で穴埋め
    df_perf_server = df_perf_server.fillna(method = 'bfill')

    df_perf_server = df_perf_server.set_index(r"date")    
    df_perf_server.index = pd.to_datetime(df_perf_server.index)    

    df_perf_server.ix[:, r"CPU_Usage"] = df_perf_server.ix[:, r"CPU_Usage"].astype(float)

    # create csvfile 
    df_perf_server.to_csv(output_csv_path + '/' + df_perf_file, index = True)     
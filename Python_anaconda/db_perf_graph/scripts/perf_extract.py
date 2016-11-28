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
import glob
import shutil
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib.dates as mdates
from matplotlib.ticker import *

# visual setting
font = {'family' : 'meiryo'}

# input filepath
file_path = os.getcwd()
os.chdir(u"../tmp")

# remove output folder
# check exists
if os.path.isdir(u'../output'):
    shutil.rmtree(u'../output') 
else :
    pass

if os.path.isdir(u'../graph'):
    shutil.rmtree(u'../graph') 
else :
    pass

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
        

    # create graphfile path
    output_graph_path = df_perf_path.replace('log', 'graph')
    output_graph_file = df_perf_file.rstrip(r'.csv')
    # mkdir graph folders
    if os.path.isdir(output_graph_path):
        pass
    else :        
        os.makedirs(output_graph_path)

    # read csv
    # 欠損値は平均で穴埋め
    df_perf = pd.read_csv(df_perf_file)
    df_perf = df_perf.fillna(df_perf.mean())

    # extract columns
    df_perf_db = df_perf[["(PDH-CSV 4.0) (",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Memory Manager\Database Cache Memory (KB)",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Memory Manager\Stolen Server Memory (KB)",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Memory Manager\Free Memory (KB)",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Buffer Manager\Page life expectancy",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Buffer Manager\Lazy writes/sec",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Buffer Manager\Buffer cache hit ratio"
    ]]
    
    
    df_perf_db.columns = [r"(PDH-CSV 4.0) (",
                            r'Memory Manager\Database Cache Memory (MB)', 
                          r'Memory Manager\Stolen Server Memory (MB)',
                          r'Memory Manager\Free Memory (MB)',
                          r'Buffer Manager\Page life expectancy',
                          r'Buffer Manager\Lazy writes/sec',
                          r'Buffer Manager\Buffer cache hit ratio']
                          

    df_perf_db.ix[:,r'Memory Manager\Database Cache Memory (MB)'] = df_perf_db.ix[:,r'Memory Manager\Database Cache Memory (MB)'] /1024
    df_perf_db.ix[:,r'Memory Manager\Stolen Server Memory (MB)'] = df_perf_db.ix[:,r'Memory Manager\Stolen Server Memory (MB)'] /1024
    df_perf_db.ix[:,r'Memory Manager\Free Memory (MB)'] = df_perf_db.ix[:,r'Memory Manager\Free Memory (MB)'] /1024

    # create csvfile 
    df_perf_db.to_csv(output_csv_path + '/' + df_perf_file, index = False) 

    # area graph
    df_perf_db.plot.area(
                x= [r"(PDH-CSV 4.0) ("],
                y=[ r'Memory Manager\Database Cache Memory (MB)',
                    r'Memory Manager\Stolen Server Memory (MB)',
                    r'Memory Manager\Free Memory (MB)'
                    ], 
                    alpha=0.5, figsize=(16,4), stacked = True) 

    graph_title = output_graph_file.replace('/s', '_')
    plt.title(graph_title.decode('mbcs'), size=16)
    plt.xlabel("time") 
    plt.ylabel("memory(MB)")

    plt.savefig(output_graph_path + '/' + output_graph_file + r'.png', dpi=300)
    
    # 作成したグラフオブジェクトを閉じる    
    plt.close()
    




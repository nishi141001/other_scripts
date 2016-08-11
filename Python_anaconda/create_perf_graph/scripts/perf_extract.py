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
    r"\\YUUSUKE-VAIO\Memory\Available Bytes",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Memory Manager\Connection Memory (KB)",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Memory Manager\Database Cache Memory (KB)",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Memory Manager\Free Memory (KB)",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Memory Manager\Granted Workspace Memory (KB)",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Memory Manager\Lock Memory (KB)",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Memory Manager\Optimizer Memory (KB)",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Memory Manager\Reserved Server Memory (KB)",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Memory Manager\SQL Cache Memory (KB)",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Memory Manager\Stolen Server Memory (KB)",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Memory Manager\Log Pool Memory (KB)",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Memory Manager\Total Server Memory (KB)",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Buffer Manager\Buffer cache hit ratio",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Buffer Manager\Page life expectancy",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Plan Cache(_Total)\Cache Hit Ratio",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Plan Cache(_Total)\Cache Pages"]]
    
    # create csvfile 
    df_perf_db.to_csv(output_csv_path + '/' + df_perf_file, index = False) 

    # area graph
    df_perf.plot.area(
                x= [r"(PDH-CSV 4.0) ("],
                y=[
                    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Memory Manager\Connection Memory (KB)",
                    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Memory Manager\Lock Memory (KB)",
                    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Memory Manager\Optimizer Memory (KB)",
                    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Memory Manager\SQL Cache Memory (KB)",
                    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Memory Manager\Log Pool Memory (KB)"
                    ], 
                    alpha=0.5, figsize=(16,4)) 

    graph_title = output_graph_file.replace('/s', '_')
    plt.title(graph_title.decode('mbcs'), size=16)
    plt.xlabel("time") 
    plt.ylabel("memory(KB)")

    """        
    # x軸主目盛り
    # 分単位
    minutes = mdates.MinuteLocator()
    daysFmt = mdates.DateFormatter('%m/%d/%Y %H:%M:%S')
    ax.xaxis.set_major_locator(minutes)
    ax.xaxis.set_major_formatter(daysFmt)
    """
    
    plt.savefig(output_graph_path + '/' + output_graph_file + r'.png', dpi=300)
    
    # 作成したグラフオブジェクトを閉じる    
    plt.close()
    




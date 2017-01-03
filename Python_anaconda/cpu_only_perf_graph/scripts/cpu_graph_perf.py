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

# input filename
for line in open (u'tmp_output_list.log'):
    # convert "\" to "/"
    line = os.path.normpath(line)

    # get file name    
    df_perf_path = os.path.dirname(line)    
    df_perf_file = os.path.basename(line)
    df_perf_file = df_perf_file.rstrip('\n')    
    os.chdir(df_perf_path)

    # create graphfile path
    output_graph_path = df_perf_path.replace('output', 'graph')
    output_graph_file = df_perf_file.rstrip(r'.csv')

    # mkdir graph folders
    if os.path.isdir(output_graph_path):
        pass
    else :        
        os.makedirs(output_graph_path)

    # read csv
    df_perf = pd.read_csv(df_perf_file)
     
    # extract columns
    df_perf_server = df_perf[[r"date",
                              r"CPU_Usage"
                              ]]

    df_perf_server = df_perf_server.set_index(r"date")    
    df_perf_server.index = pd.to_datetime(df_perf_server.index ,format = '%Y-%m-%d %H:%M:%S.%f')    

    # CPU graph
    ax = df_perf_server.plot(
                x= [df_perf_server.index],
                y= [r"CPU_Usage"], 
                    kind = 'area',
                    alpha=0.5, 
                    figsize=(16,10), 
                    ylim = (0,100)
                    ) 
                    
    ax.set_xticklabels(df_perf_server.index, rotation = 'vertical')    
    # x軸目盛り：分間隔(10分)
    ax.xaxis.set_major_locator(mdates.MinuteLocator(interval = 10))
    # x軸目盛り表示形式
    ax.xaxis.set_major_formatter(mdates.DateFormatter("%m/%d %H:%M")) 

    graph_title = output_graph_file.replace('/s', '_')
    plt.title(graph_title.decode('mbcs'), size=16)
    plt.xlabel("time") 
    plt.ylabel("CPU_Usage(%)")
    
    plt.savefig(output_graph_path + '/' + output_graph_file + r'_cpu.png', dpi=300)
    
    # 作成したグラフオブジェクトを閉じる
    plt.close()

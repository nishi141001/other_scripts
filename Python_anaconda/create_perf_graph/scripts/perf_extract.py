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
    df_perf = pd.read_csv(df_perf_file)
     
    # extract columns
    df_perf_server = df_perf[[r"(PDH-CSV 4.0) (",
                              r"\\YUUSUKE-VAIO\Processor(_Total)\% Processor Time",
                              r"\\YUUSUKE-VAIO\Memory\Available MBytes",
                              r"\\YUUSUKE-VAIO\Process(sqlservr)\Working Set",
                              r"\\YUUSUKE-VAIO\Process(_Total)\Working Set"
                              ]]
    
    df_perf_server.columns = [r"date",
                              r"CPU_Usage",
                              r"Available MBytes",
                              r"\Process(sqlservr)\Working Set(MB)",
                              r"\Process(_Total)\Working Set(MB)"
                              ]
                              
    # ""は"欠損値NaNに変換    
    df_perf_server.ix[:, df_perf_server.columns != r"date"] = df_perf_server.ix[:, df_perf_server.columns != r"date"].replace(r"\s+", np.nan, regex = True)
    
    # 欠損値NaNは直後の値で穴埋め
    df_perf_server = df_perf_server.fillna(method = 'bfill')
   
    df_perf_server.ix[:,r"\Process(sqlservr)\Working Set(MB)"] = df_perf_server.ix[:,r"\Process(sqlservr)\Working Set(MB)"] /1024/1024
    df_perf_server.ix[:,r"\Process(_Total)\Working Set(MB)"] = df_perf_server.ix[:,r"\Process(_Total)\Working Set(MB)"] /1024/1024

    df_perf_server = df_perf_server.set_index(r"date")    
    df_perf_server.index = pd.to_datetime(df_perf_server.index)    
    df_perf_server.ix[:, df_perf_server.columns != "date"] =  df_perf_server.ix[:, df_perf_server.columns != "date"] .astype(float)

    # create csvfile 
    df_perf_server.to_csv(output_csv_path + '/' + df_perf_file, index = True)     

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
    
    plt.savefig(output_graph_path + '/' + output_graph_file + r'_01_cpu.png', dpi=300)
    
    # 作成したグラフオブジェクトを閉じる    
    plt.close()
    
    # Memory(Available) graph
    ax = df_perf_server.plot(
                x= [df_perf_server.index],
                y= [r"Available MBytes"], 
                    kind = 'area',            
                    alpha=0.5, 
                    figsize=(16,10), 
                    ylim = (0,4096), 
                    stacked = False
                    ) 
    ax.set_xticklabels(df_perf_server.index, rotation = 'vertical')    

    # x軸目盛り：分間隔(10分)
    ax.xaxis.set_major_locator(mdates.MinuteLocator(interval = 10))
    # x軸目盛り表示形式
    ax.xaxis.set_major_formatter(mdates.DateFormatter("%m/%d %H:%M")) 
    
    graph_title = output_graph_file.replace('/s', '_')
    plt.title(graph_title.decode('mbcs'), size=16)
    plt.xlabel("time") 
    plt.ylabel("Available_Memory(MB)")
    
    plt.savefig(output_graph_path + '/' + output_graph_file + r'_02_available_memory.png', dpi=300)
    
    # 作成したグラフオブジェクトを閉じる    
    plt.close()

    # Memory(Workingset) graph
    ax = df_perf_server.plot(
                x= [df_perf_server.index],
                y= [r"\Process(sqlservr)\Working Set(MB)",
                    r"\Process(_Total)\Working Set(MB)"],
                    kind = 'area',            
                    alpha=0.5, 
                    figsize=(16,10), 
                    ylim = (0,4096), 
                    stacked = False
                    ) 
    ax.set_xticklabels(df_perf_server.index, rotation = 'vertical')    

    # x軸目盛り：分間隔(10分)
    ax.xaxis.set_major_locator(mdates.MinuteLocator(interval = 10))
    # x軸目盛り表示形式
    ax.xaxis.set_major_formatter(mdates.DateFormatter("%m/%d %H:%M")) 
    
    graph_title = output_graph_file.replace('/s', '_')
    plt.title(graph_title.decode('mbcs'), size=16)
    plt.xlabel("time") 
    plt.ylabel("Memory(MB)")
    
    plt.savefig(output_graph_path + '/' + output_graph_file + r'_03_workingset_memory.png', dpi=300)
    
    # 作成したグラフオブジェクトを閉じる    
    plt.close()
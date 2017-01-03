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
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Memory Manager\Total Server Memory (KB)",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Memory Manager\Connection Memory (KB)",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Memory Manager\Lock Memory (KB)",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Memory Manager\Optimizer Memory (KB)",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Memory Manager\SQL Cache Memory (KB)",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Plan Cache(_Total)\Cache Pages",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Memory Manager\Reserved Server Memory (KB)",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Memory Manager\Granted Workspace Memory (KB)",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Buffer Manager\Page life expectancy",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Buffer Manager\Lazy writes/sec",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Buffer Manager\Buffer cache hit ratio",
    r"\\YUUSUKE-VAIO\MSSQL$INS_NISHI2016:Plan Cache(_Total)\Cache Hit Ratio"
    ]]
    
    
    df_perf_db.columns = [r'(PDH-CSV 4.0) (',
                          r'Memory Manager\Database Cache Memory (MB)', 
                          r'Memory Manager\Stolen Server Memory (MB)',
                          r'Memory Manager\Free Memory (MB)',
                          r'Memory Manager\Total Server Memory (MB)',
                          r'Memory Manager\Connection Memory (MB)',
                          r'Memory Manager\Lock Memory (MB)',
                          r'Memory Manager\Optimizer Memory (MB)',
                          r'Memory Manager\SQL Cache Memory (MB)',
                          r'Plan Cache(_Total)\Cache Memory (MB)',
                          r'Memory Manager\Reserved Server Memory (MB)',
                          r'Memory Manager\Granted Workspace Memory (MB)',
                          r'Buffer Manager\Page life expectancy',
                          r'Buffer Manager\Lazy writes/sec',
                          r'Buffer Manager\Buffer cache hit ratio',
                          r'Plan Cache(_Total)\Cache Hit Ratio']
                          

    df_perf_db.ix[:,r'Memory Manager\Database Cache Memory (MB)'] = df_perf_db.ix[:,r'Memory Manager\Database Cache Memory (MB)'] /1024
    df_perf_db.ix[:,r'Memory Manager\Stolen Server Memory (MB)'] = df_perf_db.ix[:,r'Memory Manager\Stolen Server Memory (MB)'] /1024
    df_perf_db.ix[:,r'Memory Manager\Free Memory (MB)'] = df_perf_db.ix[:,r'Memory Manager\Free Memory (MB)'] /1024
    df_perf_db.ix[:,r'Memory Manager\Total Server Memory (MB)'] = df_perf_db.ix[:,r'Memory Manager\Total Server Memory (MB)'] /1024
    df_perf_db.ix[:,r'Memory Manager\Connection Memory (MB)'] = df_perf_db.ix[:,r'Memory Manager\Connection Memory (MB)'] /1024
    df_perf_db.ix[:,r'Memory Manager\Lock Memory (MB)'] = df_perf_db.ix[:,r'Memory Manager\Lock Memory (MB)'] /1024
    df_perf_db.ix[:,r'Memory Manager\Optimizer Memory (MB)'] = df_perf_db.ix[:,r'Memory Manager\Optimizer Memory (MB)'] /1024
    df_perf_db.ix[:,r'Memory Manager\SQL Cache Memory (MB)'] = df_perf_db.ix[:,r'Memory Manager\SQL Cache Memory (MB)'] /1024    
    #Plan Cache is page(8k)    
    df_perf_db.ix[:,r'Plan Cache(_Total)\Cache Memory (MB)'] = df_perf_db.ix[:,r'Plan Cache(_Total)\Cache Memory (MB)'] *8/1024
    df_perf_db.ix[:,r'Memory Manager\Reserved Server Memory (MB)'] = df_perf_db.ix[:,r'Memory Manager\Reserved Server Memory (MB)'] /1024
    df_perf_db.ix[:,r'Memory Manager\Granted Workspace Memory (MB)'] = df_perf_db.ix[:,r'Memory Manager\Granted Workspace Memory (MB)'] /1024


    # create csvfile 
    df_perf_db.to_csv(output_csv_path + '/' + df_perf_file, index = False) 

    df_perf_db.index = pd.to_datetime(df_perf_db.ix[:, r'(PDH-CSV 4.0) ('])    
    # area graph "SQL Server MaxMemory Breakdown"
    ax = df_perf_db.plot(
                x= [df_perf_db.index],
                y= [r'Memory Manager\Database Cache Memory (MB)',
                    r'Memory Manager\Stolen Server Memory (MB)',
                    r'Memory Manager\Free Memory (MB)'
                    ], 
                    kind = 'area',
                    alpha=0.5, 
                    figsize=(16,10), 
                    ylim = (0,2048), 
                    stacked = True
                    ) 
    # 凡例位置:右下
    ax.legend(loc = 4)
    ax.set_ylabel("memory(MB)")

    ax2 = ax.twinx()
    ax3 = df_perf_db.plot(
                x= [df_perf_db.index],
                y= [r'Memory Manager\Total Server Memory (MB)'
                    ], 
                    kind = 'line',
                    linestyle = 'dotted', 
                    alpha=0.5, 
                    figsize=(16,10), 
                    color = 'b', 
                    ylim = (0,2048), 
                    ax = ax2
                    )
    # 凡例位置:右上
    ax3.legend(loc = 1)
    
    # x軸ラベルを90度回転
    ax.set_xticklabels(df_perf_db.index, rotation = 'vertical')    
    # x軸目盛り：分間隔(10分)
    ax.xaxis.set_major_locator(mdates.MinuteLocator(interval = 10))
    # x軸目盛り表示形式
    ax.xaxis.set_major_formatter(mdates.DateFormatter("%m/%d %H:%M")) 

    graph_title = "01_SQL_Server_MaxMemory_Breakdown"
    plt.title(graph_title.decode('mbcs'), size=16)
    plt.savefig(output_graph_path + '/' + graph_title + '_' + df_perf_file + r'.png', dpi=300)
    # 作成したグラフオブジェクトを閉じる    
    plt.close()

    
    # area graph "Stolen Server Memory Breakdown"
    ax = df_perf_db.plot(
                x= [df_perf_db.index],
                y= [r'Memory Manager\Stolen Server Memory (MB)'
                    ],
                    kind = 'area', 
                    alpha=0.5, 
                    figsize=(16,10)
                    )                    
    df_perf_db.plot(
                x= [df_perf_db.index],
                y= [r'Memory Manager\Connection Memory (MB)',
                    r'Memory Manager\Lock Memory (MB)',
                    r'Memory Manager\Optimizer Memory (MB)',
                    r'Memory Manager\SQL Cache Memory (MB)',
                    r'Plan Cache(_Total)\Cache Memory (MB)',
                    r'Memory Manager\Reserved Server Memory (MB)'
                    ], 
                    kind = 'area', 
                    alpha=0.5, 
                    figsize=(16,10), 
                    stacked = True, 
                    ax = ax
                    )

    graph_title = "02_Stolen_Server_Memory_Breakdown"
    plt.title(graph_title.decode('mbcs'), size=16)
    plt.xlabel("time") 
    plt.ylabel("memory(MB)")

    # x軸ラベルを90度回転
    ax.set_xticklabels(df_perf_db.index, rotation = 'vertical')    
    # x軸目盛り：分間隔(10分)
    ax.xaxis.set_major_locator(mdates.MinuteLocator(interval = 10))
    # x軸目盛り表示形式
    ax.xaxis.set_major_formatter(mdates.DateFormatter("%m/%d %H:%M")) 
    
    plt.savefig(output_graph_path + '/' + graph_title + '_' + df_perf_file + r'.png', dpi=300)
    # 作成したグラフオブジェクトを閉じる    
    plt.close()

    # line graph "Cache hit ratio and Page life(buffer Cache) Breakdown"
    ax = df_perf_db.plot(
                x= [df_perf_db.index],
                y= [r'Buffer Manager\Page life expectancy'
                    ],
                    kind = 'line', 
                    alpha=0.5, 
                    figsize=(16,10), 
                    color = 'g', 
                    ylim = (0,700)
                    )
    ax.legend(loc = 4)
    # 2軸グラフ用に変換
    ax.set_ylabel("Sec")
    ax2 = ax.twinx()
    
    ax3 = df_perf_db.plot(
                x= [df_perf_db.index],
                y= [r'Buffer Manager\Buffer cache hit ratio',
                    r'Plan Cache(_Total)\Cache Hit Ratio'
                    ], 
                    kind = 'line',
                    alpha=0.5, 
                    figsize=(16,10), 
                    color = ['b','c'], 
                    ylim = (70,100), 
                    ax = ax2
                    )
    ax3.legend(loc = 1)
    ax3.set_ylabel("%")
    graph_title = "03_Cache_hit_ratio_and_Page_life(buffer_Cache)_Breakdown"
    plt.title(graph_title.decode('mbcs'), size=16)

    # x軸ラベルを90度回転
    ax.set_xticklabels(df_perf_db.index, rotation = 'vertical')    
    # x軸目盛り：分間隔(10分)
    ax.xaxis.set_major_locator(mdates.MinuteLocator(interval = 10))
    # x軸目盛り表示形式
    ax.xaxis.set_major_formatter(mdates.DateFormatter("%m/%d %H:%M")) 
    
    plt.savefig(output_graph_path + '/' + graph_title + '_' + df_perf_file + r'.png', dpi=300)
    # 作成したグラフオブジェクトを閉じる    
    plt.close()



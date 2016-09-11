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

# concat file count
counter = 0     

for line in open (u'tmp.log'):
 
    # convert "\" to "/"
    line = os.path.normpath(line)

    # get file name    
    log_path = os.path.dirname(line)    
    log_file = os.path.basename(line)
    log_file = log_file.rstrip('\n')
    
    os.chdir(log_path)

    # read target file(csv)
    log = pd.read_csv(log_file, delimiter = ',')
    log.columns = ['date', log_file + '_count']    
    log.index = log.ix[:, 'date']
        
    if counter == 0:
        log_join = log    
        log_join.columns = ['index_date', log_file + '_count']    
        log_join.index = log_join.ix[:, 'index_date']
        log_join = log_join.drop(['index_date'], axis = 1)
        
    else :
        log = log.drop(['date'], axis = 1)
        
        # index をキーとしたjoin        
        log_join = log_join.join(log, how = 'outer')

    counter = counter +1

# index の joinで発生したすべての欠損値 NaN を 0 で埋め
log_join = log_join.fillna(0)

# add sum column
log_join.loc[:, 'sum'] = float('NaN')

# row単位で合計を算出sum(axis = 1)
log_join.loc[:, 'sum'] = log_join.sum(axis = 1)
    
# output csv file(merge all  file)
log_join.to_csv(output_path + '\\log_join.csv', index = True, sep=',')

#*************************************************************************#
# create graph
# date, count
#*************************************************************************#    

# create graph(exection_count)
log_join.plot.line(
            x= [log_join.index]
            , alpha=0.5
            , figsize=(16,16)
            ) 
                
plt.xlabel(r'date') 
plt.savefig(graph_path + '/count_' + log_file + r'.png', dpi=300)
plt.close() 


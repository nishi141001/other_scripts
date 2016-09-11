# -*- coding: utf-8 -*-
"""****************************************************************************
MSSQL serverから直接pandasへの取り込み
****************************************************************************"""
import os
import os.path
import shutil
import numpy as np
import pymssql
import pandas as pd
import ConfigParser
import matplotlib.dates as mdates
import matplotlib.pyplot as plt

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

# connect db
conn = pymssql.connect(server   = 'YUUSUKE-VAIO\INS_NISHI2016' , 
                       user     = 'sa'                         , 
                       password = 'system'                     , 
                       port     = '1434'                       ,
                       timeout  = '10'      
                       )
stmt = 'SELECT * FROM sales.dbo.employees ORDER BY HIRE_DATE ASC'
df = pd.read_sql(stmt, conn) 
df.index = pd.to_datetime(df.ix[:, 'HIRE_DATE'], format= '%Y-%m-%d')        
df_salary_mean = df.ix[:, 'SALARY'].resample('12M').mean().fillna(0)

df_salary_mean.to_csv(output_path + '\\df.csv', index = True, sep=',')

# create graph
df_salary_mean.plot(
        x= [df_salary_mean.index],
        alpha=0.5, 
        figsize=(16,10)
        ) 

plt.xlabel(r'date') 
plt.ylabel('SALARY')
plt.savefig(graph_path + r'/sample.png', dpi=300)
plt.close()


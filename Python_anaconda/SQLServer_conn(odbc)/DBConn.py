# -*- coding: utf-8 -*-
"""
Created on Sun Feb 12 21:20:45 2017

@author: yuusuke
"""
import pyodbc
import pandas as pd
import seaborn as sns

pd.set_option('line_width', 100)

conn = pyodbc.connect(
                      r'DRIVER={ODBC Driver 13 for SQL Server};'
                      r'SERVER=YUUSUKE-VAIO\INS_NISHI2016;'
                      r'DATABASE=sales;'
                      r'UID=sa;'
                      r'PWD=system'
                      )

df = pd.read_sql(
                '''SELECT * FROM [dbo].[EMPLOYEES]'''
                ,conn
                ,index_col = 'HIRE_DATE'
                ,parse_dates = 'HIRE_DATE'
                )
print df.head(10)


query = 'EXEC sp_test'
df1 = pd.read_sql(
                query
                ,conn
                ,index_col = 'HIRE_DATE'
                ,parse_dates = 'HIRE_DATE'
                )
print df1.head(10)


query = 'EXEC sp_test2 @Param = 2'
df2 = pd.read_sql(
                query
                ,conn
                ,index_col = 'HIRE_DATE'
                ,parse_dates = 'HIRE_DATE'
                )

df_mean = df2.resample('1A', loffset = '1A').mean().fillna(0)

# create graph(SALARY)
df_mean.plot.bar(
            x= [df_mean.index],
            y= [r'SALARY'], alpha=0.5, figsize=(10,5)) 


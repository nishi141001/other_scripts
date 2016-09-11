# -*- coding: utf-8 -*-
"""
###################################
input     :../log/*.*
output    :../tmp/tmp.txt
###################################
"""
import os
import os.path
import pandas as pd
import shutil

# move file path
os.chdir(r'../log')
file_path = os.getcwd()

# remove tmp folder
if os.path.isdir(r'../tmp') :
    shutil.rmtree(r'../tmp')
else :
    pass

# mkdir tmp folder
os.mkdir(r'../tmp')


# file list of "log" folder 
for root, dirs, files in os.walk(file_path):
    for file in files:
        file_list = os.path.join(root, file)                
        # move file path
        os.chdir('../tmp')
        # write tmp file 
        file_tmp_txt = open('tmp.log', 'a')
        print file_list
        file_tmp_txt.writelines(file_list + "\n")    
        file_tmp_txt.close()

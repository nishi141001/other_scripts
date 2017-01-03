# -*- coding: utf-8 -*-
"""
Created on Sun Jul 24 18:11:27 2016

###################################
input     :../log/*.*
output    :../tmp/tmp.txt
###################################
"""
import os
import os.path

# move file path
os.chdir('../output')
file_path = os.getcwd()

# remove tmp folder
if os.path.isdir('../tmp') :
    pass
else :
    os.mkdir('../tmp')

# file list of "log" folder 
for root, dirs, files in os.walk(file_path):
    for file in files:
        file_list = os.path.join(root, file)                
        # move file path
        os.chdir('../tmp')
        # write tmp file 
        file_tmp_txt = open('tmp_output_list.log', 'a')
        print file_list
        file_tmp_txt.writelines(file_list + "\n")    
        file_tmp_txt.close()

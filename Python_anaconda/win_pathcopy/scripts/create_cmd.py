# -*- coding: utf-8 -*-
###################################
# インプットとなるファイル名のみ実行前にconfで指定すること
###################################

import os
import os.path
import pandas as pd
import shutil
import json
import sys

# scripts root path
script_path = os.path.dirname(os.path.abspath('__file__'))
os.chdir(script_path)
os.chdir('..')
base = os.getcwd()

# read config
# set path
conf = open('.\conf\config.json', 'r')
jsondata = json.load(conf)

input_path = base + '\\' + jsondata["input"]
output_path = base + '\\' + jsondata["output"]
temp_path = base + '\\' + jsondata["temp"]
script_path = base + '\\' + jsondata["script"]
source = jsondata["source"]
target = jsondata["target"]
target_path = base + '\\' + jsondata["target"]
input_file = input_path + '\\' + jsondata["input_file"]
conf.close()

# remove output folder
# check exists and make dir
os.chdir(base)
if os.path.isdir(target_path):
    shutil.rmtree(target_path) 
    os.makedirs(target_path)
else :
    os.makedirs(target_path)

# cd input
os.chdir(input_path)

# read target file(tsv)
path_copy = pd.read_csv(input_file, delimiter = '\t')
path_copy.loc[:, "cmd"] = "echo F|xcopy /E"
path_copy.loc[:, "moto"] = "..\\" + source + "\\" + path_copy["path"] + "\\" + path_copy["filename"]
path_copy.loc[:, "saki"] = "..\\" + target + "\\" + path_copy["path"] + "\\"

path_copy = path_copy.drop("path", axis = 1)
path_copy = path_copy.drop("filename", axis = 1)

# output cmd file
path_copy.to_csv(output_path + '\\exec_cmd.bat', index = False, header = False, sep='\t')

write_file = open(output_path + '\\exec_cmd.bat', 'a')
write_file.writelines("pause" + "\n")    
write_file.close()

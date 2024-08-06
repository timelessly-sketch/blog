#!/bin/bash
hexo clean && hexo deploy && 

rsync -avzP -e "ssh -p20631" /Users/ylin/Documents/meng/public/ root@121.54.189.30:/www/wwwroot/link.71ll.cc

hexo clean

echo "上传成功！"
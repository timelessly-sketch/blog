#!/bin/bash
hexo clean && hexo deploy && hexo clean

rsync -avzP -e "ssh -p20631" /Users/ylin/Documents/meng/public/ root@121.54.189.30:/www/wwwroot/link.71ll.cc
echo "上传成功！"
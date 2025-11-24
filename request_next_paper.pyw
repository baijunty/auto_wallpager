#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Python script to request next wallpaper from local server
发送HTTP请求到本地服务获取下一张壁纸
"""

import requests
import sys

def request_next_paper():
    url = "http://127.0.0.1:8987/nextPaper"
    
    try:
        print("正在请求 {} ...".format(url))
        response = requests.get(url)
        response.raise_for_status()  # 如果响应状态码不是200系列，会抛出异常
        
        print("请求成功!")
        print("状态码:", response.status_code)
        print("响应内容:", response.text)
        
    except requests.exceptions.ConnectionError:
        print("连接错误: 无法连接到服务器，请确保服务正在运行")
        sys.exit(1)
    except requests.exceptions.Timeout:
        print("超时错误: 请求超时")
        sys.exit(1)
    except requests.exceptions.RequestException as e:
        print("请求失败:", str(e))
        sys.exit(1)

if __name__ == "__main__":
    request_next_paper()
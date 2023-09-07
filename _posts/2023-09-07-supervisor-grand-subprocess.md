---
layout: article
title:  "supervisor python multiprocessing 监听信号 实现所有进程同时退出"
date:   2023-09-07 20:00:07 +0800
categories: engineering
tags: 
    - supervisor
    - python
    - multiprocessing
---

## supervisor 多进程管理

使用 supervisor 管理进程，如果被管理的项目是多进程模式，就需要注意一下：

　　1、程序内是否有接收处理 kill -15 | SIGnal。

　　2、python 程序无法监听 kill -9 信号（其他编程语言没有了解，但按理说应该是一样的），也无法拒绝（kill -9 是立马强制结束进程），所以不要随便使用 kill -9 结束一个进程(kill params[pid], 会允许程序延迟退出，所以程序内可以监听 kill -15 | SIGnal)，如果使用 kill -9 结束了一个主进程，那么它的子进程就会成为孤儿进程，使用 kill -9 结束某个子进程，就会有可能导致其成为僵尸进程。

　　3、如果确实有需要强制结束某个进程，为了安全起见，可以使用 kill  -9  -params[gpid] 代替， 如 kill  -9  -7634，强制立马结束 7634 进程组内的所有进程，正常情况下，主进程的 pid 和该进程组的 gpid 相同，但意义不一样。

　　4、kill -15 (默认)和 kill -9 是两种不同的信号，python 程序可以监听 kill -15(也就理所当然的可以拒绝kill -15)，但是无法监听 kill -9(也就无法拒绝)

    如果程序没有监听并处理 kill | SIGnal 就需要到相应服务的 supervisor 管理配置文件声明：stop 服务时，允许 supervisor stop 该进程组下的所有进程：

```python

killasgroup=true  # 允许杀死该进程组内的所有进程
stopasgroup=true  # 允许停止该进程组内的所有进程

```
但是如果子进程里又新开了子进程，采用上述方式用supervisor是关闭不掉的，可以使用os和| SIGnal模块，用内核功能帮助完成必要的辅助操作，不影响应用层持续执行。


## 常用信号量

| 信号    | 值       | 处理动作 | 发出信号的原因                                                                                          |
| ------- | -------- | -------- | ------------------------------------------------------------------------------------------------------- |
| SIGHUP  | 1        | A        | 终端挂起或者控制进程终止                                                                                |
| SIGINT  | 2        | A        | 键盘中断（如break键被按下：如 control + c）                                                             |
| SIGQUIT | 3        | C        | 键盘的退出键被按下                                                                                      |
| SIGILL  | 4        | C        | 非法指令                                                                                                |
| SIGABRT | 6        | C        | 由abort(3)发出的退出指令                                                                                |
| SIGFPE  | 8        | C        | 浮点异常                                                                                                |
| SIGKILL | 9        | AEF      | Kill信号 (无法被程序捕获，程序也无法拒绝)                                                               |
| SIGSEGV | 11       | C        | 无效的内存引用                                                                                          |
| SIGPIPE | 13       | A        | 管道破裂: 写一个没有读端口的管道                                                                        |
| SIGALRM | 14       | A        | 由alarm(2)发出的信号                                                                                    |
| SIGTERM | 15       | A        | 终止信号 （程序内可以监听该信号，当多进程中的任意进程监听到该信号，就退出所有进程，实现多进程安全退出） |
| SIGUSR1 | 30,10,16 | A        | 用户自定义信号1                                                                                         |
| SIGUSR2 | 31,12,17 | A        | 用户自定义信号2                                                                                         |
| SIGCHLD | 20,17,18 | B        | 子进程结束信号                                                                                          |
| SIGCONT | 19,18,25 |          | 进程继续（曾被停止的进程）                                                                              |
| SIGSTOP | 17,19,23 | DEF      | 终止进程                                                                                                |
| SIGTSTP | 18,20,24 | D        | 控制终端（tty）上按下停止键                                                                             |
| SIGTTIN | 21,21,26 | D        | 后台进程企图从控制终端读                                                                                |
| SIGTTOU | 22,22,27 | D        | 后台进程企图从控制终端写                                                                                |




python 多进程处理 SIGINT SIGTERM 方式, 示例如下：

```python

import os
import sys
import time
import signal
import multiprocessing
from multiprocessing import Process


def fun_grandchild(x):
    while True:
        print("grand current pid is % s, group id is % s" %
              (os.getpid(), os.getpgrp()))
        time.sleep(1)


def fun(x):
    t = Process(target=fun_grandchild, args=(str(1),))
    t.daemon = False
    t.start()
    try:
        t.join()
    except Exception as e:
        print(str(e))

    while True:
        print("current pid is % s, group id is % s" %
              (os.getpid(), os.getpgrp()))
        time.sleep(1)


def term(signals, frame):
    print("====current pid is % s, group id is % s" %
          (os.getpid(), os.getpgrp()))

    # os.getpid() 获取当前进程号
    # os.getpgid(params[pid]) 获取当前进程号的所在的组的组进程号

    # 杀死某个进程：os.kill(params[pid], params[signal.SIGKILL])
    # 杀死某个进程组下的所有进程：os.killpg(params[gpid], params[signal.SIGKILL])

    # os.kill(os.getpid(), signal.SIGKILL)

    os.killpg(os.getpgid(os.getpid()), signal.SIGKILL)

    print("-------")  # 这行代码永远也不会被执行


def signal_handler(signals, frame):
    print('You pressed Ctrl+C，进程号{}'.format(os.getpid()))
    # 优雅地退出（让 control + c 不抛出异常信息）
    sys.exit(0)


if __name__ == "__main__":

    # 监听信号，注册回调函数(主进程或者子进程都会监听)
    signal.signal(signal.SIGINT, signal_handler)  # control + c 会发送该信号
    signal.signal(signal.SIGTERM, term)

    # 程序无法捕获 signal.SIGKIL，会报错（但是可以发送，如 term() 中所示）
    # signal.signal(signal.SIGKILL, term)

    processes = list()
    print("currentpid is % s" % os.getpid())
    for i in range(3):
        t = Process(target=fun, args=(str(i),))
        t.daemon = False
        t.start()
        processes.append(t)

    try:
        for p in processes:
            p.join()
    except Exception as e:
        print(str(e))


```


--- 
1. https://www.cnblogs.com/lowmanisbusy/p/12733695.html



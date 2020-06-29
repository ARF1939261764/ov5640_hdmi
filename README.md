# ov5640_hdmi
本次设计主要是实现ov5640的控制器，利用sdram作为中间缓冲，最后通过hdmi显示出来。

![总体框架图](README/%E6%80%BB%E4%BD%93%E6%A1%86%E6%9E%B6%E5%9B%BE.png)

2020年6月29日：

基本可以显示了，还没有实现截图功能，第0列和第512列(估计)有问题。分辨率为1024*768。

![image-20200629110853805](README/image-20200629110853805.png)

再找一下Bug吧。

说一下大体思路：

![总体框架图](README/%E6%80%BB%E4%BD%93%E6%A1%86%E6%9E%B6%E5%9B%BE-1593400377242.png)

上图是总体框图。

分为3个块，总共4个时钟域。

`IIC_Config`module属于一个时钟域，负责使用SCCB总线来对OV5640进行一些配置。

`Get Frame`和`FIFO`的写入端属于一个时钟域，`Get Frame`负责将OV5640给出8bit数据转换成16bit数据，然后写入到`FIFO`。

图中第3块属于一个时钟域，`AVL Bus Controller`是一个总线控制器，AVL总线是做毕设的时候自定义的一个总线协议(现在发现还有一些问题，不过也还能用)，并实现了它的总线控制器，总线控制器主从机数量都可以设置，这次设置的为4主机、1从机，负责将SDRAM转换成一个可以多端口分时复用的多端口SDRAM，以在宏观上实现同时读写，SDRAM采用页突发读写，以提高SDRAM带宽，支持突发长度为2-512（必须是偶数）。

为了避免画面撕裂，第三部分采用三缓冲。实际上SDRAM内部设置了4块缓冲画面的区域，一张1024*768的RGB565格式的图片需要约1.5MByte的空间，为了方便起见，每块缓冲区设置大小为2MByte。在任一时刻，4块缓冲区中只有3块被用于缓冲图像，另一块则保留截图键按下时屏幕上显示的画面，当截图键按下时，截图模块会锁存住当前正在显示的缓冲区编号，然后接下来这个缓冲区将会被`Frame Write`和`Frame Read`模块忽略，而使用另外的三块缓冲区进行缓冲，这一块缓冲区则保留了截图键按下时的图像，然后截图控制器再慢慢的读取截取到的图像，写入到SPI Flash中，当需要显示时，则只需任意占用一块缓冲区，让`Fram Read`模块一直读取这个缓冲区，截图控制器读取SPI Flash中对应的数据写入到这个缓冲区即可。

第2块则是HDMI显示部分。
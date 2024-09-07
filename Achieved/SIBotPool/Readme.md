## SIPool - Special Infected Bot Pool

> 用于在有大量刷特需求时（如：28特0秒）减少CreateFakeClient操作，节省CPU与带宽资源，提高服务器性能。

经测试效果显著，结果如下（28特0秒）：  
没有 SIPool时，在`for循环`内使用`CreateFakeClient()`时，服务器的tickrate从 **100** 降低到 **80-**；  
使用 SIPool后，在`for循环`内使用`RequestSIBot()`时，服务器的tickrate从 **100** 降低到 **90+**；

https://forums.alliedmods.net/showthread.php?t=346270
---
layout: post
title: "Android 内存管理机制"
subtitle: "Android 内存管理机制"
date: 2018-04-19 22:10:00
author: "rank"
header-img: "img/post-bg-nextgen-web-pwa.jpg"
catalog: true
tags:
  - Android
---

####基于 Linux 内存管理

Android 系统虽然是基于 Linux 2.6 内核开发的开源操作系统，但是 Android 系统对 Linux 的内存管理系统进行了优化，Linux 系统会在进程活动停止后就结束该进程，而 Android 系统则将这些进程都保留在内存中（即使你是退出该程序而不是 Home 键，任然会保留空置进程），这些保留在内存里的进程通常不会影响整体系统的运行，并且当用户再次激活这些进程时，提升了进程的启动速度和保留了状态。

#### 内存分配

Android 系统会对每个进程的 Dalvik 设置了严格的 Heap 使用限制，如果应用达到内存限制容量后仍然继续申请内存就会触发内存溢出错误。你可以通过 `getMemoryClass()` 查询可以使用的 Heap 大小，它会以 M 为单位返回。在非常特殊的场景你可以通过设置 `largetHeap`属性为 `true` 到 Application 标签来申请大尺寸内存。但是系统不一定会调整分配。这种情况你更应该去解决内存使用过大的问题而不是依赖它

> // 1、通过 ActivityManager 获取
> ActivityManager activityManager=(ActivityManager)context.getSystemService(Context.ACTIVITY_SERVICE);
> activityManager.getMemoryClass();
> activityManager.getLargeMemoryClass();
>
> // 2、通过 Runtime 获取
> Runtime rt = Runtime.getRuntime();
> rt.getFreeMemory();
> rt.getMaxMemory();
> rt.getTotalMemroy();
>
> // 注意：ActivityManager.getMemroyInfo()，这个方法不是用来获取 dalvik 内存的，这是获取系统总内存的，我们设置缓存大小时，一般不以它有依据；

当系统需要更多内存时候，垃圾处理器会进行内存回收机制。Android 系统会根据进程的优先级和最少使用次数等因素来关闭进程回收内存。它们按优先级排序为：前台进程、可见进程、次要服务、后台进程、内容供应节点、和空进程。

#### 管理内存

1. **有节制的使用 service 在后台运行工作**。当一个程序在后台但有 service 在持续运行时，系统会保持该进程的工作状态，service 使用的内存资源不能被其他进程使用和移除，同时也减少了进程 LRU 可用的缓存大小，使得应用切换效率更低。
   最好合理的使用 service，当任务的工作周期明确的时候应当使用 IntentService。
2. **在界面被隐藏时释放内存资源**。当用户对此界面不可见的时候，开发人员应当主动释放该界面的大块内存资源。此时释放资源可以显著的提升系统的进程缓存容量，从而直接影响用户体验。
3. **合理的使用多进程**。通过把应用的组件划分到多个进程可以帮助你增加应用的内存占用。但是多进程在大多数情况下都是弊大于利的，进程之间无法共享内存，静态成员和单例模式失效等等。
4. **使用 zipalign 优化**。在应用的 build.gradle 文件中 将 `zipalignEnable` 属性设置为 true
   系统会对应用进行优化，既对应用的资源、代码进行偏移 4 的整倍数达到 DSA 标准。减少应用的内存资源占用和加快整体执行效率。

#### 代码内内存优化

1. **合理的使用 Bitmap**。图片资源算是 Android 里的内存消耗大户了，3.0 以后虽然不用手动释放内存，但是在加载图片的时候应该按需加载来节省内存。裁剪至合适的尺寸，当图片是高分辨率且不需要时因尽可能的压缩它。
2. **合理的创建使用 UI 布局**。减少页面的绘制层级（通过开发者工具来检测），避免在 onDraw 里创建对象。
3. **使用优化过的容器类**。Android 提供了一系列的优化的容器，如 SparseArray、ArrayMap 等容器，它们在数据量较少的情况下（0~1000 数量级，SparseArray 使用二分查找来定位 index，且避免了对 key 的自动装箱）比 HashMap 更加高效和减少内存使用。
4. **避免使用枚举**。单个枚举的内存占用是静态常量的 13 倍，使用注解库内的 StringDef/IntDef 或者静态常量来代替注解。
5. **使用缓存**。对数据进行合理的缓存来避免短时间内大量创建对象造成内存抖动。

#### 常见的内存泄露

- 静态变量/容器持有 Activity 实例

- Handler 内存泄露

- 需要手动回收的资源没有回收

#### 常见的内存检测工具

- [Leak Canary](https://github.com/square/leakcanary)
- Heap Viewer
- Allocation Tracker
- Memory Monitor

### 参考文章

[Android 内存优化容器](https://blog.csdn.net/u010687392/article/details/47809295)

[Zipalign 工具详解](https://blog.csdn.net/ljchlx/article/details/52473297)

[Android 内存管理开发](https://mp.weixin.qq.com/s?__biz=MzA4MjA0MTc4NQ==&mid=401914785&idx=1&sn=73e28432b9b23a314247707a145c6bdd#rd)

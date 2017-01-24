---
layout: post
title: "RxAndroid学习笔记"
subtitle: "\"新的一天!\""
date: 2017-01-24  10:42:00
atuhor:  "chenzhaojun"
header-img:  "img/reactivex_bg"
tags:
    - Android
---

> 万物始于微而后成,始于无而后生



## 前言

`RxJava`在项目中早就开始使用了，但是一直都是结合`Retrofit`来做一些简单的数据处理，和异步操作。用到操作符并不不多且对RxJava没有很清晰的概念，这篇文章就是加深对`RxJava`的认识，以及一些常用的操作符的使用。



## 正文

`RxAndorid`是`RxJava`在Android上的一个扩展，它让我们更方便的在UI和子线程中切换。所以在日常开发中，我们一般两个库都要依赖。

```groovy
//jcenter
compile 'io.reactivex.rxjava2:rxandroid:2.0.1'
compile 'io.reactivex.rxjava2:rxjava:2.0.1'
```



`subscribeOn`和`observeOn`

`suscribeOn`应该在调用链中只被调用一次。如果并非如此的话，那会以第一次调用的线程为准。`suscribeOn`指定了`observeOn`会在哪个线程被订阅（例如，被创建）。如果你在Android的View中使用`observeOn`发出时间事件，你需要确定订阅是在Android Ui线程中执行。

而另一方面，`observeOn`在调用链中执行多少次都是可以的。`observeOn`指定了调用链中下一个操作符执行的线程，例如：

```java
myObservable //observable将会在io线程中订阅
  .sucribeOn(Schedulers.io())
  .observeOn(AndroidScheduler.mianThread())
  .map(/*将会在Android  Ui线程中执行*/)
  .doOnNext(/*下面的代码会等到下次observeOn执行*/)
  .observeOn(Schedulers.io())
  .subcribe(/*将会在i/o线程中执行*/);
```

常用的调度器有如几种：

- `Schedulers.io()` ：适合在I/O线程执行的工作，例如网络请求和磁盘操作

- `Scheduler.io()`：计算性任务，比如事件的轮询或者处理回调等。

- `AndroidScheduler.mainThread()` :  `RxAndroid`对`RxJava`所做的扩展，在Android UI线程执行下一个操作符的操作。

  ​


---
layout: post
title: "RxAndroid学习笔记"
subtitle: "\"新的一天!\""
date: 2017-01-24  10:42:00
atuhor:  "chenzhaojun"
header-img:  "img/reactivex_bg.jpg"
tags:
    - Android
---

> 万物始于微而后成,始于无而后生



## 前言

`RxJava`在项目中早就开始使用了，但是一直都是结合`Retrofit`来做一些简单的数据处理，和异步操作。用到操作符并不不多且对RxJava没有很清晰的概念，所以想写一篇文章将学习和用到的东西总结一下。本文并不是`RxJava`的理解与教学，网上这类优秀的文章已经很多了。更多的是介绍开发中需要注意的细节，和`RxJava2.X`的迭代。



## 正文

### 使用RxJava

`RxAndorid`是`RxJava`在Android上的一个扩展，它让我们更方便的在UI和子线程中切换。所以在日常开发中，我们一般两个库都要依赖。

```groovy
//jcenter
compile 'io.reactivex.rxjava2:rxandroid:2.0.1'
compile 'io.reactivex.rxjava2:rxjava:2.0.1'
```

#### 异步操作

正常情况下RxJava是在默认线程中，且上游和下游都在同一个线程，在Android中也就是默认在主线程中执行，当我们需要执行异步操作时就需要我们通过`subscribeOn`和`observeOn`来手动的切换执行事件的线程。

`suscribeOn`一般在调用链中应该只被调用一次。如果并非如此的话，那会以第一次调用的线程为准。`suscribeOn`通俗的讲就是指定上游发送事件的线程。

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

- `Schedulers.io()`  :  **适合在I/O线程执行的工作，例如网络请求和磁盘操作，内部有一个线程池可以重复使用**
- `Scheduler.computation()` : **计算性任务，比如事件的轮询或者处理回调等。**
- `Schedulers.newThread()  `  :  **代表一个常规的新线程**
- `AndroidScheduler.mainThread()` :   `RxAndroid`对`RxJava`所做的扩展， **在Android UI线程执行下一个操作符的操作**


#### 贴士

- 只有当观察者和被观察者建立连接之后，上游才会开始发送事件，也就是调用`suscribe()`方法后，被观察者才会向观察者发送事件
- `flatMap`并不保证发送的顺序，如果要求严格按照顺序请使用`concatMap`
- 如果需要多个接口的数据同步处理那么`zip`操作符可以帮助到你



### RxJava2.X



#### Environment

如果你在项目中使用了`Retrofit`+`RxJava`，且你想要切换到2.x你会返现`Retrofit`目前的`RxJava`适配器并不支持2.x.但是没关系jake大神已经为我们写好了新的适配器。

```groovy
compile 'com.jakewharton.retrofit:retrofit2-rxjava2-adapter:1.0.0'
```

在创建Retrofit对象是将RxJava的Factory替换掉

```java
Retrofit retrofit = new Retrofit.Builder()
    .baseUrl(BASE_URL)
    .addConverterFactory(GsonConverterFactory.create())
    .addCallAdapterFactory(RxJava2CallAdapterFactory.create())//1.X为RxJavaCallAdapterFactory
    .build();
```



#### Flowable

`Flowable`是RxJava2.0后增加的,为了解决无法意料的`MissingBackpressureException`，但是使用起来更加繁琐，它要求强制的处理上下游的接受发送的事件的效率以及决定背压的处理方式。我们原先的`Observable`仍然可以使用，用来解决非背压式的问题。如果我们要使用`Flowable`必须这样写:

```java
//创建订阅者
Subscriber<String> subscriber = new Subscriber<String>() {
    @Override
    public void onSubscribe(Subscription s) {
    //这一步是必须，我们通常可以在这里做一些初始化操作，调用request()方法表示初始化工作已经完成
    //调用request()方法，会立即触发onNext()方法
    //在onComplete()方法完成，才会再执行request()后边的代码
    s.request(Long.MAX_VALUE);
    }

    @Override
    public void onNext(String value) {
        Log.e("onNext", value);
    }

    @Override
    public void onError(Throwable t) {
        Log.e("onError", t.getMessage());
    }

    @Override
    public void onComplete() {
    //由于Reactive-Streams的兼容性，方法onCompleted被重命名为onComplete
        Log.e("onComplete", "complete");
    }
};

Flowable.create(new FlowableOnSubscribe<String>() {
    @Override
    public void subscribe(FlowableEmitter<String> e) throws Exception {
        e.onNext("Hello,I am China!");
    }
}, BackpressureStrategy.BUFFER)
    .subscribe(subscriber);  
```

`Flowable`在上游有一个默认长度为**128**的缓冲池来放置上阻塞的事件，使用`Flowable`创建一个事件时候，我们必须使用`BackpressureStrategy`这个类中的常量来管理缓冲池:

- `BackpressureStrategy.ERROR` :  **当事件的长度的积累超过缓冲池的长度时直接抛出Exception**
- `BackpressureStrategy.BUFFER ` :  **缓冲池的长度没有限制**
- `BackpressureStrategy.DROP` :  **超过缓冲池长度的事件直接丢弃**
- `BackpressureStrategy.LATEST` :  **超过缓冲长度的事件会丢弃最旧的，保留最新的**

像`interval`等不是自己创建的事件我们指定背压策略是可以使用以下函数来: 

- `onBackpressureBuffer()`
- `onBackpressureDrop()`
- `onBackpressureLatest()`

```java
Flowable.interval(1, TimeUnit.MICROSECONDS)
                .onBackpressureDrop()  //加上背压策略
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(subscriber);
```



需要注意的是`Flowable`现在和`Observable`的性能还是有一定的差距的，所以不要为了最求新颖盲目的使用`Flowable`且使用不当很容易造成一些致命的错误。



#### Dispoasble

`Subscription`命名修改为`Dispoasble`，相关的api也被修改了，例如`CompositeSubscription`修改为`CompositeDisposable`。且需要注意的是2.X中`subscribe(subscriber)`这个重构方法是没有返回值的,但是通常我们将返回的`Subscription`添加到`CompositeSubscription`来管理，所以为了适配1.X可以使用`E subscribeWith(E subscriber)`方法来返回一个`Dispoable`对象，将它添加到`CompositeDisposable`中来管理。



#### Consumer

`Action1`使用`Consumer`来代替,如果是两个参数，则用`BiConsumer`来代替`Action2`,多个参数则用`Consumer<Object[]>`,删除了`Action3-9`.



#### Function

`func`也被`Function`替代。同理，`func1`和`func2`更改为`Function`和`BiFunction`，多参数的`FuncN`被`Function<Object,R>`替代，`func3-9`的功能并没有被删除，被`Function3-9`替换了。



#### fromArray,fromIterable,fromFuture

由于在`Java8`编译时，`javac`不能区分接口类型，所以`from`在2.X被分为了`fromArray`、`fromIterable`和`fromFuture`。






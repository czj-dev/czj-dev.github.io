---
layout: post
title: "Retrofit与OkHttp源码解析"
subtitle: "源码解析"
date: 2019-10-15 13:49:22
author: "rank"
header-img: "img/post-bg-android.jpg"
catalog: true
tags:
  - Android
---

### Android 网络框架解析

从 2016 Retrofit 开源以来，Retrofit 以它优雅的设计，方便的使用迅速征服了很多开发者，Retrofit+OkHttp 成了 Android 网络开发开源解决方案的佼佼者。 Retrofit 已经在实际项目使用很久了，也对 Retorfit 和 OkHttp 实现原理有一定的了解，但却一直没有书面的记录，网上已经有很多相关的优秀文章，但本着思前想后千万遍,*不如动笔*写下来的道理，还是打算写一整篇 Retrofit、OkHttp 以及 Okio 的解析，整理和完善相关的知识，总结和归纳比阅读更重要。

Retrofit、OkHttp、Okio 三者本身都是非常优秀的开源框架，它们组合在一起汇聚成了一套在 Android 完善的网络解决框架，它们的网络 IO 流程如下：

<img src="https://blog.piasy.com/img/201608/okio_okhttp_retrofit.png" alt="网络数据传输流程" style="zoom:38%;" />

Retrofit 通过很多精妙的设计，可以让开发者在方便快捷的实现网络操作的请求和响应，而 OkHttp 则是网络具体实现的核心，它负责网络的具体请求，连接池复用、网络拦截， Http1、http2 的兼容等，Okio 则处理所有的 IO 问题，磁盘缓存、网络 IO 等都可以看到它的身影，下面我们就来逐个介绍它们。

### Retrofit

#### 1.0.0 Create

本文的 Retrofit 版本为 `2.3.0` ,我们先从 Retrofit 的入口 `create` 函数来了解 :

![create](https://s2.ax1x.com/2019/10/12/uOovh4.md.png)

在解析入口之前，我们先回顾一下我们是如何使用 Retrofit 的，通常我们会先声明一个 ServiceInterface

![AccountApiService](https://s2.ax1x.com/2019/10/12/uO7DsI.png)

然后通过 Rerofit 的实例调用 `create` 方法，我们可以获得 `AccountApiService` 的实例并且可以使用 `login(username,password)` 来发起网络请求了。但其实 `AccountApiService`并没有什么具体的实现类，我们调用其内部的某个方法时都被我们 `create` 中`Proxy.newProxyInstance()`创建的动态代理所拦截了。这就是 Retrofit 设计的第一个巧妙的点——所有业务层面的具体实现都会汇聚到 `create` 里的 Proxy 中，上层组件对这一过程是没有感知的，这也是设计模式中的`动态代理`模式。

接下来短短的几句代码也是整个 Retrofit 的思路与核心，通过 **ServiceMethod** 来将 Interface 中声明的抽象方法给处理为真正的 `request` ，**OkHttpCall** 则对 okHttp 进行包装扩展，负责实际的网络请求，而 serviceMethod 中的 **callAdapter** 则负责处理响应的数据的解析、格式化、转换等。

看似简单，但是 Retrofit 以漂亮的解耦扩展了强大的功能和留下了很多插槽以供扩展，我们可以看下 [Stay](http://notes.stay4it.com/2016/04/05/read-the-fcking-code-of-retrofit/retrofit01.png) 画的流程图

![retrofit](https://s2.ax1x.com/2019/10/12/uOL4hT.png)

#### 2.0.0 ServiceMethod

![ServiceMethod](https://s2.ax1x.com/2019/10/14/uzwZEn.md.png)

ServiceMethod 就是通过动态代理得到的我们所调用的方法所代表的对象—— `Method` ， 解析对象获得方法的参数、注解来拼接生成网络请求所需要的 url、header、httpMethod 等参数，除此之外 ServiceMethod 还存储了`callFactory`、`callAdapter`、`converter` 等为下一步的网络请求做准备。 `CallAdapter`、`converter` 我们之后再做详细解释。`callFactory` 就是我们通过 Builder 模式构建 Retrofit 时所传递的 `OkHttpClient` 实例，如果没有传递则会默认创建一个。除此之外，ServiceMethod 还做了缓存处理，同一个 API 的同一个方法，只会创建一次。之后会直接从缓存池中获取。可以看下边的代码：

![ServiceMethod](https://s2.ax1x.com/2019/10/12/uXkIXt.md.png)

#### 3.0.0 OkHttpCall

OkHttpCall 对 `OkHttp` 的同步请求 `execute` 异步请求 `enqueue` 做了简单的包装，让其可以使用之前准备好的`callfactory` 以及 ServiceMethod 处理好的参数，同时也对基本的网络成功和失败可以直接进行判断 。我们对 OkHttpCall 的同步请求做简单的分析 :

![okHttpCall 同步请求](https://s2.ax1x.com/2019/10/14/uzrqw4.md.png)

异步响应增加了 `callback` 的机制，但是处理模式类似，这里就不做赘述了，感兴趣的同学可以自己去翻看源码。虽然 rertrofit 没有提供网络请求库的更换，但是得益于 Retrofit 漂亮的设计我们也可以用别的网络框架实现 `Call<T>` 接口然后修改源码很轻松的替换网络请求源。

#### 4.0.0 CallAdapter

从上面的流程图我们可以看到 retrofit 提供了非常多适配器（Adapter）来处理响应数据，Retrofit 本身只内置了`DefaultCallAdapterFactory` 和 `ExcuterCallAdapterFactory` 它们适用于网络请求的返回值为 `Retrofit.Call<T>` 的情况下，而如果需要其它的响应类型则是需要额外扩充的，Retrofit 预留了 `CallAdaptter.Facotry` 的接口，让开发者可以自己实现相应的适配器工厂。

#### 4.1.0 Converter

converter 的功能是将网络响应的主体内容部分的 json、xml、String 等特定的数据格式转换成我们更容易处理的实体对象，Retrofit 本身只提供了 `BuildInConverters`（提供一些基础的数据转换 steam string 等 ） 的实现，来提供基本功能。但是和 `CallAdapter` 一样提供了`Converter.Factory` 来让开发者扩展使用。

至此，Retrofit 的核心的解析就完了，这里没有长篇大论剖析代码，主要是秉着知道轮子怎么造以及如何更好地造，找到框架中真正值得学习的思路和设计。接下来我们就看看 OkHttp 的魅力所在吧

### OkHttp

#### 概览

<img src="https://s2.ax1x.com/2019/10/14/uzf1W4.md.jpg" alt="okHttp架构" style="zoom:80%;" />

在剖析之前 我们先来了解一下 OkHttp 的架构，从下图我们可以看到 OKHttp 分为

- **应用层** 应用层的核心类都是由开发者直接使用的，`OkHttpClient` 用来构造我们需要的网络请求所对应的实例对象 `Call`，`Call` 用来发送接收网络请求，而 `Dispatcher` 则用来管理网络请求的队列。
- **协议层** 协议层用来具体化 Http1、Http2、Https 以及 WebSocket 等协议在网络通信中具体实现和交互，让开发者只需要关注网络请求和响应本身
- **连接层** 连接层用来管理网络请求的线程池连接池复用，任务调度
- **缓存处理** 对支持的 HTTP 响应和请求做缓存和复用，优化网络质量
- **I/O 处理** 磁盘缓存、网络 IO 的具体操作都是依赖于此，它的具体工作是由 `Okio` 框架来完成的
- **拦截器** 从图中也可以看出`Interceptor` 是贯穿整个 OkHttp 的核心，它以责任链的模式将整个流程优雅的分发处理，是整个 OkHttp 的重中之重。

接下来我们按照一个网络请求在 OkHttp 中的流程来解析了解 OkHttp 的内部设计是怎么样的

<img src="https://blog.piasy.com/img/201607/okhttp_full_process.png" alt="网络请求经过" style="zoom:60%;" />

`OkHttpClient` 即 OkHttp 框架的使用入口，本身通过 `Builrder` 模式可以灵活配置非常多的参数, 具体的内部我们就不做赘述了，我们直接来看一个网络请求是怎么发起的：

```java
String run(String url) throws IOException {
  OkHttpClient client = new OkHttpClient();
  Request request = new Request.Builder()
      .url(url)
      .build();

  Response response = client.newCall(request).execute();
  return response.body().string();
}
```

我们通过 `reuqest` 构建一个 HTTP 请求，通过 client 的 `newCall` 去创建一个 `call` 然后直接 `execute` 发起一个同步的网络请求。这也与我们上边的流程图所展示的一致，接下里我们就看看 `newCall` 里面有什么东西吧。

#### RealCall

![RealCall constructor](https://s2.ax1x.com/2019/10/14/KSeaHH.png)

`newCall` 创建了 `RealCall`， 由`RealCall` 来负责实际的网络请求，它实现了 `Call` 的相关接口 `execute` 与 `enqueue` 来处理同步和异步请求。

我们先从同步请求的具体实现来看看 :

![execute()](https://s2.ax1x.com/2019/10/15/K9yJte.md.png)

`execute()` 中先把当前的 `RealCall` 添加到了调度器 `Dispatcher` 中，等待结束 `Finally` 后再被调度器移出。**Dispatcher** 的具体实现的我们之后再单独讲解。从图中我们发现 `execute ()`用寥寥几行的代码就拿到了网络请求的响应 `Response` 。很显然这里并不是真正处理的网络请求的地方，要解决心中的疑惑还是继续往下看`getResponseWithInterceptorChain()` 里究竟实现了什么

![getResponseWithInterceptorChain()](https://s2.ax1x.com/2019/10/14/KSKuxx.md.png)

`getResponseWithInterceptorChain` 显示添加了需要拦截器 `Interceptor` 然后在方法的最后构建了一个 `RealInterceptorChain` 调用 `proceed` 开始进行网络请求，它会逐层的触发拦截器，激活它们的 `intercept` 方法，将整个网络请求包装调用起来。

#### Interceptor

初看可能觉得莫名其妙，这里为什么会添加一大堆的的拦截器。其实结合 OkHttp 架构图和流程图你就不难发现，`Interceptor` 是 OkHttp 最核心的一个东西，不要误以为它只负责拦截请求一些进行额外的处理（例如 Auth、NetworkListener），实际上它贯穿了整个 OkHttp ，把实际的网络请求，缓存，压缩等功能都统一了起来，每一个功能只是一个 `Interceptor` ,它们再连接成一个 `Interceptor.Chain` ，环环相扣，最终圆满完成了一次网络请求

从 `getResopnseWithInterceptorChain` 函数我们可以看到，`Interceptor.Chain` 的分部依次是：

1. 在 OkHttpClient 中配置的 `Interceptor`

2. 负责失败重试以及重定向的 `RetryAndFollowUpInterceptor`

3. 负责把用户的构造请求转换为发送到服务器的请求、把服务器的请求返回的响应转换为用户友好的响应 `BridgeInterceptor`

4. 负责读取缓存直接返回、更新缓存的 `CacheInterceptor`

5. 负责创建分配 HTTP 连接的 `ConnectInterceptor`

6. 配置 OkHttpClient 时设置的 `NetworkInterceptor`

7. 负责向服务器发送请求数据、从服务器读取响应数据的 `CallServerInterceptor`

它们的显示层级也对应了当一个 HTTP 请求发生的时候它们的调用顺序，我们逐个的去了解它们具体的工作职责与原理。

##### **RetryAndFollowUpInterceptor**

RetryAndFolllowUpInterceptor 主要职责是如它的名字一样，将网络重试或者转发。具体情况就是遇到如服务器返回 HTTP 状态码 300、301、302 之类的自动重定向，遇到 401（需要认证） 调用 client.authenticator() (如果开发者有实现的话) 自动去认证，除此之外还有代理认证等等，因为逻辑代码较多就不贴出来了，感兴趣的可以自己去看看源码实现

##### **BridgeInterceptor**

BridgeInterceptor 具体主要是处理请求和响应中的 `header `部分，如果数据有压缩步骤，例如 `gzip` 等处理，那么它还负责将数据解压缩完成，涉及 `Content-Type`、`Content-Length`、`Transfer-Encoding` 等`header` 的处理

##### **CacheInterceptor**

CacheInterceptor 会将符合要求的 `request`和与之对应的 `Response` 缓存起来，如果下次 `request` 没有超过缓存时效，这一步会拦截器会直接返回 `Response`，不会再触发之后的拦截器经行网络请求了 ；而如果没有找到对应的 `response` 则会先继续向下获取网络响应然后尝试缓存。值得一提的是 CacheInterceptor 的缓存机制是非常严格的，必须符合 Http 对缓存制定的标准且是 GET 请求。

##### **ConnectInterceptor**

ConnectIntercetpor 则是负责 HTTP 连接创建、复用与分配。算是我们需要了解的重难点了，~~敲黑板，记笔记~~。

![connectIntercetpor](https://s2.ax1x.com/2019/10/14/KSfZuR.png)

从上图中我们得知几个关键的对象 `StreamAllocation`、`HttpCodec`、`RealConnection` 。

StreamAllocation 是 `HttpCodec` 和 `RealConnection` 的载体，它在 RetryAndFollowUpIntercetpor 中创建，通过 `newStream` 方法中去申请分配一个 `RealConnection` ，`RealConnection` 代表的就是一个可用的 TCP/IP 连接。那么连接池是如何运作的，又是如何拿到一条可用的连接呢，我们从 `newStream` 去看:

![newStream](https://s2.ax1x.com/2019/10/14/KSqEFA.md.png)

`newStream` 整个流程的实际代码还是挺长的，我们节选了部分并只关注高亮部分来讲解。

- `newStream` 通过`findHealthyConnection`从连接池内取出可用的连接，如果没取到就重复`findConnection` 的过程。
- `findHealthyConnection()` 负责确认取出的连接是可用的，而 `findConnection()` 用来从连接池中取出连接和创建连接。
- `findConnection()` 先尝试 44 行的 `Internal.instance.get(connectionPool,address,this,null)` 取出连接， `Internal.instance` 的实例是在 OkHttpClient 创建的匿名类对象，`get()` 方法只是调用 `ConnectionPool` 的`get` 方法。`ConnectionPool` 顾名思义就是我们的连接池的实现了，这个稍后再细讲。
- 如果连接池里没有可用的连接。那么就会重新创建一个 `RealConnection` 并去执行 TCP 握手，然后将它加入到 `connectionPool` 中。至此一个寻找可用的 `conncetion` 的步骤就完成了。

找到可用的连接后，接下来通过`newCodec` 创建一个 `HttpCode` 实例， `HttpCode`是对 HTTP 协议操作的抽象，有两个实现：`Http1Codec` 和 `Http2Codec`，顾名思义，它们分别对应 HTTP/1.1 和 HTTP/2 版本的实现。

管道连接、协议实现这些都准备完毕后，`ConnectInterceptor` 的职责也就完成了。下面先回过头来看看 Connection 的核心 `ConnectionPool` ，它负责了对连接池的复用维护管理。对外它只暴露的简单的 `get`、`put` 方法，内里的实现机制又是如何的呢

**ConnectionPool**

![connectionPool](https://s2.ax1x.com/2019/10/14/Kp9rDI.png)

从代码中我们可以看出

- ConnectionPool 维护了一个线程池`Executor` 用于执行清理空闲、超时以及超过数量的 `Connection` 连接
- connections 是一个双向队列（Deque），用来管理 `RealConnection` 连接，最大的保持数量是 `5` 最长的`keepAlive` 持续时间为 `5 minutes`。`RealConnection` 是 `socket` 物理连接的包装
- routerDatabase 用来记录连接失败的线路名单
- 向连接池添加新的连接时会触发清理空闲连接的任务。`excutor.execute(clearRunnable);`

`ConnectionPool` 的职责很清晰，它负责维护真实的 socket 连接复用，并清理空闲的连接。

##### **CallServerInterceptor**

接下来就到流程的最后一个拦截器——`CallServerIntercaptor`，前边的拦截器已经将我们的请求给包装好， 网络请求所需要的 connection、httpCodec 也都已经初始化完毕，这里就开始正式的网络通讯：

![callServerInterceptor](https://s2.ax1x.com/2019/10/15/K9wjnU.md.png)

我们看 `intercept` 方法高亮的实现部分来看看 `CallServerIntercptor` 做了哪些事情

1. 拿到之前配置好的 `HttpCode`、`conncetion`、`streamAllocation` 以及 `request` 开始进行请求
2. 通过 `HttpCode` 发送`reuqest` 的 `header` 部分。
3. 发送完毕后如果`request` 还有 `body`（服务器返回 `Except:100-continue`），那么就继续发送信息主体部分
4. 开始接受 `Response` 的`Header` ，并创建一个 `response` 承载
5. 判断 `Response` 的 `header` ，判断`Response` 是否有 `body` ，如果有就重新创建一个 `response` 然后开始接收 `Response` 的信息主体
6. 进行一些 `header` 和状态码判断没有问题后就返回 `response` ，网络请求完成。

到这里整个网络请求就完成了，可以看到整个流程和物理的网络模型一样，层层递进，分层简化了每层的逻辑、共同完成复杂的任务。

#### Dispatcher

前面我们跟着同步网络请求 `execute` 基本摸清楚了整个 OkHttp 的脉络和流程。但是有一点我们略过了那就是 `Dispatcher` ，它也是同步和异步调用的最大区别。

![execute 和 enqueue](https://s2.ax1x.com/2019/10/15/K9cHyR.md.png)

我们可以看到两者在使用调度器上有些许差别。

-  `execute()` 在调用`Dispatcher` 时使用的是 `Dispatcher .executed()` 来执行然后在 `finally` 后调用`finished` 结束流程。
- 而 `enqueue()` 则调用了 `enqueue` 将自己添加进入调度器，且包装了一个 `AsyncCall` ，`AsyncCall` 继承了 `NamedRunnable` 它是一个`Runnable` 在`run()` 方法被执行后会触发 `execute()` 方法，而另一个主要方法 `executeOn` 则是将自己添加到传入的线程池执行，两者环环相扣。`AsyncCall` 中 `execute()` 的方法操作与同步请求 `execute()`内的代码逻辑大同小异。具体原因我们去看看 `Dispatcher` 的具体实现 ：

![Dispatcher](https://s2.ax1x.com/2019/10/15/K9202Q.md.png)

可以看到 `Dispatcher`维护着三个双向队列

1.  预备异步队列 `readyAsyncCalls` 一些还没有被放入线程池执行的任务会先放到之类
2.  运行异步队列 `runningAsyncCalls` 一些已经在执行中的任务在这里管理
3.  运行同步队列 `runningSyncCalls` 已经执行的同步网络任务在这里管理

**Dispatcher维护了一个懒加载的线程池 `executorService`，线程池没有核心线程，非核心线程最大数量很大，比较适合执行大量的耗时较少的任务。最大的并发请求数量限制为了 60。每个主机的最大请求数量限制为 5。所有的异步任务都是在这个线程池中执行的.**

同步请求 `execute` 的入口也是 `excute` 方法，出口则是 `finished`。我们观察它仅仅只是运行的收扔进队列，结束后被 remove 移出，起到管理作用。没有放入线程池总，也就是说 **`execute` 的执行环境为发起同步请求的线程，这也是为什么我们在 UI 线程中调用同步请求会触发 `NetworkOnMainThread` 的根本原因**

异步请求 `enqueue` 会将方法放入 `readyAsyncCalls` 然后执行 `PromoteAndExcute` 方法，它会将`readyAsyncCalls` 中的任务放到 `runningAsyncCalls` 中，然后调用每个任务的 `executeOn` 将线程池 `excutorServier` 传递给他们调用。线程池会执行开始执行任务而后又触发每个 `AsyncCall` 的 `execute` 方法执行网络请求，这时网络请求运行的环境就位于线程池内了，之后结果会通过`enqueue` 传递的 `responseCallback` 回调到发起线程。

到这里整个 OkHttp 的请求流程我们就解析完毕了。其中一些例如缓存策略并没有细致的展开，还有 HttpCode 的具体实现，它是如何对 TCP/IP 网络请求的抽象的。但已经对 OkHttp 建立了一个大致的脉络，由 0 跨越到了 1 ，对整个请求流程有了一定了解。再次不由得再次佩服框架的开发者，设计了如此精美强大的网络请求开源方案。

### 总结

从 Retorfit 分析到 OkHttp ，我们了解调用的 Api 是如何循序渐进的从一两行的代码变为一整个完整 HTTP 请求，之后又是怎么将网络响应便捷的转换为我们需要结果。体验了程序设计之美。也希望以后的开发过程中可以学以致用，将这些知识真正的纳为己用。


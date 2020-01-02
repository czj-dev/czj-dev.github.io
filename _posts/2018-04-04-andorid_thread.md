---
layout: post
title: "Android 的线程和线程池"
subtitle: "Android 艺术开发探索"
date: 2018-04-01 19:44:00
author: "rank"
header-img: "img/post-bg-android.jpg"
catalog: true
tags:
  - Android
---

这篇文章主要是复习 Android 开发艺术探索的第 10 章和 第 11 章，整理了 Android 中关于线程的知识点。

## ThreadLoacal

ThreadLocal 是一个线程内部的数据存储类，通过它可以在指定的线程中存储数据，数据存储以后，只有在指定线程中可以获取到存储的数据，对于其他线程来说则无法获取到数据。

ThreadLoacal 的另一个使用场景是复杂逻辑下的对象传递，例如监听器，有些时候一个线程中的任务过于复杂，这可能表现为函数调用栈比较深以及入口的多样性，在这种情况下使用 ThreadLocal 可以让监听器作为线程内的全局对象存在，只要在当前线程，就可以通过 get 方法获取到监听器。

ThreadLocal 在不同的对象操作的都只是当前线程的容器对象，因此在不同线程访问同一个 ThreadLocal 的 set 和 get 方法，它们对于 ThreadLocal 所做的读/写操作仅限于各自线程的内部。

在 Handle 中是用 ThreadLocal 来存储 Lopper，使得各个线程的消息队列都是独立的。至于主线程， 单独使用了一个全局静态变量来存储，保证可以在子线程获取到主线程的 Lopper 从而能够将消息加入到主线程的消息队列中处理。

## AsyncTask

AsyncTask 是一种轻量级的异步任务类，它可以在线程池中执行后台任务，然后执行了的进度和最终传递给主线程并在主线程更新 UI。从实现上来说，AsyncTask 是 Thread 和 handle 的封装，通过 AsyncTask 可以更方便的更新 UI ，但是 AsyncTask 并不设和进行特别耗时的后台任务，对于特别耗时的任务来说，建议使用线程池。

###AsyncTask 的工作原理

从 `execute` 方法分析可以得出，在 AsyncTask 在执行的 `execute` 方法时，系统会把 Params 参数封装成一个 FutureTask 对象，FutureTask 是一个并发类，这里它充当了 Runnable 的作用。然后将 FutureTask 交给 SerialExecutor 的 excute 方法执行，它会将 FutureTask 放入 mTask 这个队列中，如果这个时候没有活动的 AsyncTask 任务，那么它就直接调用 scheduleNext() 方法把这个任务放入 threadPoolExecutor 这个线程池执行任务，任务执行完成后又会继续调用 scheduleNext 方法来执行下一个任务，直至所有的任务都执行完毕，所以 AsyncTask 默认是一个串行执行的（3.0 及以上），如果想要 3.0 以上执行，那么可以采用 AyncTask 的 excuteOnExecutor 方法，它接受一个线程池并将任务直接放入线程池中执行，可以跳过 excute 方法的排队步骤。

当 任务执行完成后会调用 postResult 通过 InternalHandler 发送一个消息，将结果发送回主线程并回调 onPostEvexute 方法。这里的 Handle 是静态的，这也就意味着 AsyncTask 的实例 必须在主线程中创建。

## HandlerThread

我们平时想在子线程中创建使用 Handler 的时候，会在 Thread 的 run 方法使用 Looper.prepare() 来创建 Looper 并通过 Looper.loop() 开启消息循环，最后再创建和使用 Handler ，这样 Handler 就能正常工作了。而 Android 系统的 HandlerThread 本身就自己完成了这类工作， 并且更加的完善和规范，例如它获取 Looper 的时候考虑到了线程活跃:

```java
  public Looper getLooper() {
        if (!isAlive()) {
            return null;
        }

        // If the thread has been started, wait until the looper has been created.
        synchronized (this) {
            while (isAlive() && mLooper == null) {
                try {
                    wait();
                } catch (InterruptedException e) {
                }
            }
        }
        return mLooper;
    }
```

提供了`quit` 和`quitSafely` 在任务执行的时候结束当前线程的执行，养成良好的编程习惯。 HandlerThread 的具体实践就是 IntentService 这个接下来讲。

## IntentService

IntentService 是一个特殊的 Service ，主要是用于执行后台的耗时任务，当任务执行完毕后它会自动停止，同时由于它是 Service 的原因 这导致它的优先级别普通的 Thread 要高很多，这让它不容易被系统杀死。

IntentService 中封装了 HandlerThread 和 Handler ，会在 onCreate 时创建一个 HandlerThread 并使用 HandlerThread 的 looper 来创建 Handler 。

```java
    @Override
    public void onCreate() {
		...
        super.onCreate();
        HandlerThread thread = new HandlerThread("IntentService[" + mName + "]");
        thread.start();

        mServiceLooper = thread.getLooper();
        mServiceHandler = new ServiceHandler(mServiceLooper);
    }
```

IntentService 每次被启动的时候会调用 onStartCommand ，onStartCommand 有调用了 onStart ，onStart 方法会通过 mServiceHandler 发送一个消息，将 startId 和 启动 service 的 Intent 对象发送出去，由 onHandlerIntent 方法来处理。

```java
    @Override
    public int onStartCommand(@Nullable Intent intent, int flags, int startId) {
        onStart(intent, startId);
        return mRedelivery ? START_REDELIVER_INTENT : START_NOT_STICKY;
    }

	@Override
    public void onStart(@Nullable Intent intent, int startId) {
        Message msg = mServiceHandler.obtainMessage();
        msg.arg1 = startId;
        msg.obj = intent;
        mServiceHandler.sendMessage(msg);
    }

   private final class ServiceHandler extends Handler {
        public ServiceHandler(Looper looper) {
            super(looper);
        }

        @Override
        public void handleMessage(Message msg) {
            onHandleIntent((Intent)msg.obj);
            stopSelf(msg.arg1);
        }
    }
```

onHandlerIntent 执行完毕后会调用 stopSelf（startId） 来尝试结束服务，stopSelf（startId）会判断最近启动次数是否和 startId 一致，如果不一致则说明还有未处理的消息，那么就等待消息处理完毕。否则就立刻停止服务。所以，如果我们在同一时间 startService 一个 IntentService 它们仍是一个实例在处理，任务则是串行处理的。

## 线程池

线程池的好处：

1. 重用线程池中的线程，避免因为线程的创建和销毁所带的性能开销。
2. 能有效的控制线程的最大并发数量，避免大量线程之间因为互相抢占系统资源而导致的阻塞现象。
3. 能够对线程进行简单的管理，并提供定时执行以及间隔循环执行等功能。

Android 的线程池的概念来源于 Java 的 Executor 接口，真正的实现类则是 ThreadPoolExecutor 。常听说的 Android 的四种类程池也都是通过直接或间接配置 ThreadPoolExecutor 来实现的。

### ThreadPoolExecutor

Thread 提供了一系列的参数来配置线程池，这些参数会直接影响线程池的功能特性：

#### corePoolSize

线程池的核心线程数量，默认情况下，核心线程池会在线程池中一直存活，即使它们处于闲置状态。如果 ThreadPoolExcutor 的 allowCoreThreadTimeOut 属性设置为 true，那么闲置的核心线程在等待新人任务到来的时候会有超时策略，这个时间由 keepAliveTime 所指定。

#### maximumPoolSize

线程池所能容纳的最大线程数量，达到这个数值后，新的任务会被阻塞。

#### keepAliveTime

非核心线程的超时时长，当超过这个时间后，非核心线程就会被回收，如果 allowCoreThreadTimeOut 为 true 的话，该限制同样作用于 核心线程。

#### unit

指定 KeepAliveTime 的时间单位(SECONDS、MILLISECONDS....)

#### workQueue

线程池中的任务队列,通过线程池的 execute 方法提交的 Runnable 对象会存储在这个队列中。

#### threadFactory

线程工厂，为线程提供创建新线程的功能。它是一个接口，只有 Thread newThread（Runnable a）方法

#### RejectedExecutionHandler

当线程池无法执行新任务时，可能由于队列已满或是无法成功执行任务，这时候 ThreadPoolExcutor 会调用 handler 的 RejectedExecutionHandler 方法来统治回调者，它提供了四种实现 CallerRunsPolicy、AbortPolicy、DiscardPolicy 和 DiscardOldestPolicy

####ThreadPoolExecutor 的执行任务的步骤：

1. 如果线程池中的线程数量为达到核心线程的数量，那么会直接启动一个核心线程来执行任务。
2. 如果线程池种的线程数量已经达到或超过核心线程的数量，那么任务会被插入到任务队列中排队等待执行。
3. 如果在步骤 2 中无法将任务插入到任务队列中，这往往由于任务队列已满，这时候如果线程数量未达到线程池规定的最大值，那么立刻启动一个非核心线程来执行任务
4. 如果第 3 步执行的线程池数量已经达到线程池规定的最大值，那么就拒绝执行此任务，调用 RejectedExecutionHandler 通知回调者

### 线程池的分类

Executors 提供大量的创建线程池的方法，使用它可以让我们快速的配置适合我们的 ThreadPoolExcutor，他们具有不同的功能特性大致分为四类，分别是 FixedThreadPool、CachedThreadPool、ScheduledThreadPool 以及 SingleThreadExecutor。

#### FiexdThreadPool

通过 Executors 的 newFixedThreadPool 方法来创建。它是一种线程数量固定的线程池，当线程处于空闲状态时，它们也不会被回收，除非线程池被关闭了。当所有线程都处于活动状态时，新任务会处于等待状态。队列的大小是没有任何限制的。同时也没有超时机制。

#### CachedThreadPool

通过 Executors 的 newCachedThreadPool 方法来创建。它是一种线程数量不定的线程池，它只有非核心线程，并且最大的线程池数量为 Integer.MAX_VALUE.它的线程等待时长为 60 秒，超过 60 秒限制线程就会被回收。CachedThreadPool 比较适合执行大量的耗时任务较少的任务。

#### ScheduledThreadPool

它的核心线程数量是固定的，非核心线程数量没有限制，并且当非核心线程闲置的时候会被立刻回收。这类线程池主要执行定时任务和固定周期的重复任务。

#### SingleThreadExecutor

这个线程池内部只有一个核心线程，它确保所有的任务都在同一个线程中按顺序执行，使得任务不需要处理线程同步的问题。

除了 Excutors 提供的线程实现，我们也可以根据实际需要灵活地配置线程池，比如之前的 AsyncTask 它内部的线程池实现:

```java
        ThreadPoolExecutor threadPoolExecutor = new ThreadPoolExecutor(
                CORE_POOL_SIZE, MAXIMUM_POOL_SIZE, KEEP_ALIVE_SECONDS, TimeUnit.SECONDS,
                sPoolWorkQueue, sThreadFactory);
        threadPoolExecutor.allowCoreThreadTimeOut(true);
// CORE_POOL_SIZE = Math.max(2, Math.min(CPU_COUNT - 1, 4));  核心线程数量
// MAXIMUM_POOL_SIZE= CPU_COUNT * 2 + 1;  最大线程数量
// KEEP_ALIVE_SECONDS = 30 超时时间
// sPoolWorkQueue = new LinkedBlockingQueue<Runnable>(128); 容量为 128 的队列
```

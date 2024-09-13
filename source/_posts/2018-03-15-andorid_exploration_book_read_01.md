---
layout: post
title: "Android 艺术开发探索笔记"
subtitle: "第一章"
date: 2018-03-15 13:30:00
author: "rank"
header_image: "img/post-bg-android.jpg"
catalog: true
tags:
  - Android
  - Note
---



###activity的生命周期

activity a 启动 activity b 然后返回activity a 再返回到桌面 它们的生命周期是怎样变化的?

A onCreate —> A onStart —> A onResume —> 跳转 —> A onPause —> B onCreate —> B onStart —> B onResume —> A onStop —> 返回 —> B onPsuse —>  A onRestart —>  A onStart —> A onResume —> B onStop —> B onDestroy —> 返回 —> A onPause —> A onStop —> A onDestroy

### 异常情况下的生命周期分析

当 Activity 被异常终止的时候系统会调用 onSaveInstanceState 方法,该方法的调用一定是在 onStop之前,而和 onPause 的调用顺讯则不是一定的;Activity 被重建后系统会把 onSaveInstanceState 方法所保存的 budle 对象存储到 onRestoreInstanceState 和 onCreate 方法,我们在这两个方法中可以开始我们的重建工作.

onSaveInstanceState 和 onRestoreInstanceState 一定是在Activity被异常销毁的情况下才会被调用,且 onRestoreInstanceState 一单被调用则参数 bundle 一定不为空,而 onCreate 则不一定.

### Activity 的启动模式

Android 目前有四种启动模式 standard、singleTop、singleTask、singleInstance:

1. standard: 模式每次启动 Activity 都会重新创建一个新的实例,不管这个实例是否存在.它的 onCreate  onStart onResume 都会被调用. 这种模式下,谁启动了这个 Activity, 这个 Activity 就会运行在它的那个 Activity 所在的栈.比如 activity A 启动了 Activity B 那么 B 就会进入 Activity 所在的栈中.这就解析了我们为什么通过 ApplicationContext 去启动一个 Standard 模式的Activity 会报 `Calling startActivity from outside of an Activity context requires the FLAG_ACTIVITY_NEW_TASK flag .is this really waht you wan?` 这是因为 Standard 模式的 Activity 会默认进入启动它的 Activity 的人物栈中,但是非 Activity 类型的 Context 并没有所谓的任务栈. 但我们使用 `FLAG_ ACTIVITY_NEW_TASK` 这个标记启动 Activity 解决问题时候,其实它是把 Activity 换为 singleTask 启动的.
2. singleTop :  栈顶复用模式.当要被启动的 Activity 已经存在任务栈顶,那么就不会创建一个新的实例而是调用栈顶 Activity onNewIntent() 方法.通过它我们可以获得传递数据.此时栈顶 Activity 的 onCreate 不会再被调用;当要启动的 Activity 不存在或者不在任务栈顶那么它就会想 Standard 模式一样重新创建一个实例.
3. singleTask: 栈内复用模式.一个 singleTask 模式的 Activity A 被启动时,系统会先寻找是否有 A 想要的任务栈,如果不存在就重新创建一个任务栈,然后创建的 A 实例后把 A 放到栈中.如果存在 A 想要的栈,则要先判断 A 实例是否存在.如果存在则将 A 移动到栈顶并回调到 A 的 onNewIntent 方法,如果不存在则创建 A 的实例并将它压入栈内.举例:
   - 如果目前任务栈 S1 内有三个 Activity ABC. .通过 C 启动一个 singleTask 模式的 Activity D,它的目标栈是 S2 .则系统会新建 S2 栈然后创建 Activity D 的实例压入 S2 栈内
   - 如果目前任务栈中有 ADBC 四个Activity,现在再次启动 Activity D 它的启动模式为 singleTask。那么系统就会将 D 移动到栈顶并回调它的 onNewIntent 方法.且由于 SingleTask 默认具欧 clearTop 的效果,会导致 D 上面的所有 Activity 出栈,最后栈内的情况就为 AD。
4. singleInstance 单实例模式 . 这是一种加强的 singleTask 模式.具有此种模式的 activity 智能单独存于一个栈中.系统会为它创建一个单独栈.由于栈内复用的特性,后续的请求均不会创建新的Activity,除非这个栈被系统销毁了.

### Activity的任务栈

Android 的任务栈(Task),它是一个栈结构,具有后进先出的特性,用于存放我们的 Activity 组件.

- Android 系统通过 task 管理每个 Activity ,并决定哪个 Activity 与用户交互,只有栈顶的 Activity 才可以和用户交互.  
- 需要注意的是,一个 App 中可能不止一个任务栈.一个 task 的Activity 可以来自不同的 App.
- 除了之前说的启动模式可以影响 Activity 和 task 的运行状态之外,还可以通过 manifests 理定制属性 和 Intent 的 Flags 来影响.
- 任务栈分为前台任务栈和后台任务栈,后台任务栈中的 Activity 位于暂停状态,用户可以通过切换将后台任务再次调到前台

#### Task 相关属性

每一个 Activity 都有一个参数 `taskAffinity` 标示了这个Activity 启动所需要任务栈的名称,默认情况下所有 Activity 所需要的任务栈的名称都是该应用的包名我们可以通过 `taskAffinity` 属性来指定启动 Activity 所需要的任务栈. `taskAffinity` 特点如下:

- taskAffinity 属性的值不能和当前应用的包名相同,非则无效.

- taskAfinity 的命名规范和应用包名类似必须要使用`.`来间隔

- taskAfinity 主要结合 singleTask 或者 allTaskReparenting使用,其他情况没有什么意义

**和 singleTask 结合使用**.启动 Activity 时候系统将它运行在名字和 TaskAffinity 相同的任务栈中 应用场景:

>假如现在有这么一个需求,我们的客户端app正处于后台运行，此时我们因为某些需要，让微信调用自己客户端app的某个页面，用户完成相关操作后，我们不做任何处理，按下回退或者当前Activity.finish()，页面都会停留在自己的客户端（此时我们的app回退栈不为空），这显然不符合逻辑的，用户体验也是相当出问题的。我们要求是，回退必须回到微信客户端,而且要保证不杀死自己的app.这时候我们的处理方案就是，设置当前被调起Activity的属性为：`LaunchMode=""SingleTask"taskAffinity="com.tencent.mm"` 其中com.tencent.mm是借助于工具找到的微信包名，就是把自己的Activity放到微信默认的Task栈里面，这样回退时就会遵循“Task只要有Activity一定从本Task剩余Activity回退”的原则，不会回到自己的客户端；而且也不会影响自己客户端本来的Activity和Task逻辑。

**和 allowTaskReparenting 结合使用**; allowTaskReparenting 主要作用是应用的迁移,即从一个 task 迁移到另一个 task.当一个应用 A 启动了应用 B 某个 Activity 后,如果这个这个 Activity 的 allowTaskReparenting 属性为“true ”的话. 那么当应用 B 被切换到前台启动的时候这个 Activity 就会从应用 A 的任务栈转移到应用B的任务栈中.应用场景

> 一个e-mail应用消息包含一个网页链接，点击这个链接将出发一个activity来显示这个页面，虽然这个activity是浏览器应用定义的，但是activity由于e-mail应用程序加载的，所以在这个时候该activity也属于e-mail这个task。如果e-mail应用切换到后台，浏览器在下次打开时由于allowTaskReparenting值为true，此时浏览器就会显示该activity而不显示浏览器主界面，同时actvity也将从e-mail的任务栈迁移到浏览器的任务栈，下次打开e-买了时并不会再显示该activity 

#### Activity 的 Flags

Activity的标记位功能有很多,有的可以影响 Activity 的运行状态,有得可以指定启动模式.大部分情况下我们不需要为 Activity 指定标记位.列举一些常用的标记位.

#### FLAG_ACTIVITY_NEW_TASK

这个标记的作用是为 Activity 指定 singleTask 启动模式

#### FLAG_ACTIVITY_SINGLE_TOP

这个标记的作用是为 Activity 指定 singleTop 启动模式

#### FLAG_ACTIVITY_CLEAR_TOP

具有此标记位的 Activity ,当它启动时候.如果它已经在栈内存在,它为singleTask 模式时候位于它上面的所有Activity 都会出栈,如果它为 standard 模式启动,那么它连同它之上的所有Activity都会出栈,系统会创建新的 Activity 压入栈.

#### FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS

这个标记的 Activity 不会出现在历史 Activity 的列表中,它等同与 Activity 的 `android:excludeFromRecents=true`的属性

#### intentFilter 的匹配规则

当Intent不明确指用调用组件,采用隐式调用时,需要 Intent 能够匹配目标组件的 IntentFilter 中所设置的过滤信息,如果不匹配将无法启动目标 Activity. Intent 中的过滤信息有 Action 、category、data。为了匹配过滤列表中的 action、category、data 信息，否则匹配失败。一个过滤列表中的 action、category、data 信息，否则匹配失败。一个过滤列表中的 action、category和 data 可以有多个。同一类别的信息共同约束当前类别的匹配过程。只有一个Intent 同时匹配所有类别，才能成功启动目标 Activity。一个 Activity 中可以有多个 intent-filter，一个 Intent 只要能匹配任何一组 Intent-filter 即可成功启动对应的 Activity。各标签过滤规则：

- **action** action 的匹配规则是 Intent 中的 action 必须能够和过滤规则中的 action 字符串值完全一致。一个过滤规则中可以有多个 action，那么只要 Intent 中的 action 能够和过滤规则中的任何一个 action 相同即可匹配成功。
- **category** category 的匹配规则是如果 Intent 中含有 category ，那么所有的 category 都必须和过滤规则中的其中的一个 category 相同。和 action 不同的是如果 Intent 中没有 ccategory 这个Intent仍然可以匹配成功，但是一旦有就必须全部匹配。
- **data** data 的数据格式比较复杂，自行了解。data 的匹配规则也和 action 类似，它也要求 Intent 中必须含有 data 数据，并且 data 数据能够完全匹配过滤规则中的某一个 data 

我们试图通过 Intent 去启动一个 Activity 的时候可以通过 PakcageManager 或者 Intent 的resolveActivity 方法来查找是否有匹配的 Activity。另外PackageManger 还提供了 queryIntentActivities 方法。


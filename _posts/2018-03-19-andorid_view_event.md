---
layout: post
title: "Android View 事件体系"
subtitle: "Android 艺术开发探索笔记"
date: 2018-03-19 20:00:00
author: "rank"
header-img: "img/post-bg-android.jpg"
catalog: true
tags:
  - Android
  - Note
---



### View 的位置

View 的位置由它的四个顶点来决定，分别对应于 View 的四个属性：top、left、right、bottom，其中 top 是左上角纵坐标，left 是左上角横坐标，right 是右下角横坐标，bottom 是右下角纵坐标。这些坐标都是相对于 View 的父容器来说的，因此它是一种相对坐标。它们的关系以及获取的 API 如下图。

![](http://img.blog.csdn.net/20150115155321445?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvamFzb24wNTM5/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/Center)

#### MotionEvent 和 TouchSlope

##### MotionEvent

在手指接触屏幕后触发的一系列事件，典型的如下：

- ACTION_DWON 手指刚接触屏幕
- ACTION_UP  手指离开屏幕
- ACTION_MOVE 手指在屏幕上滑动

在正常情况下，一次手指触摸的行为会触发一系列事件，例如：

- 点击屏幕后手指离开，触发事件为 DOWN -> UP;
- 点击屏幕滑动一会再离开，时间序列为 DOWN -> MOVE ->…. >MOVE -> UP 


##### TouchSlop

TouchSolp 是系统能够识别出的被认为的最小滑动距离，如果手指在屏幕上滑动时，如果两次滑动之间的距离小于这个常量，那么系统就不认为你是在进行滑动操作。这是一个常量和设备有关，在不同的设备可能是不同的，通过 `ViewConfiguration.get(context).getScaledTouchSlop()` 当我们在处理滑动事件的时候，可以利用这个常量来做一些过滤。

#### VelocityTracker、GestureDetector 和 Scroller

##### velocityTracker

速度追踪，用于追踪手指在滑动过程中的速度，包括水平和竖直的速度。它的使用过程很简单，首先，在 View 的 onTouchEvent 方法中追踪当前单击事件的速度。

```java
VelocityTracker velocityTracker = VelocityTracker.obtain();
velocityTracker.addMovement(envent);
```

接着，当我们先知道当前的滑动速度时，这个时候可以采用如下方式来获得当前的速度：

```java
velocityTracker.computeCurrentVelocity(1000);
int xVelocity = (int) velocityTracker.getXVelocity();
int yVelocity = (int) velocityTracker.getYVelocity();
```

有两点需要注意，第一点，在获取速度之前必须要计算速度，也就是调用 `computeCurrentVelocity`方法；第二点，这里的速度指的是一段时间内手指所划过的像素数，比如将时间间隔设为1000ms 时,在 1s 内，手指在水平方向从左向右滑过 100 像素，那么水平速度就是 100 。 注意速度可以为负数，当手指从右向左时，水平方向速度即为负值。 速度的计算公式大致如下：

```
速度=（终点-起点位置）/时间
```

最后，当不需要使用它的时候，需要调用 clear 方法来充值并回收内存

```java
velocityTracker.clear();
velocityTracker.recycle();
```

##### GestureDetector

手势检测，用于辅助检测用户的单击、滑动、长按、双击等行为。

创建一个 GestureDetector 对象并实现 OnGestureDetector 接口

```java
GestureDetector getsture = new GestureDetector(this);
//解决长屏幕无法拖动的现象
gesture.setIsLongpressEnable(false);
```

接着，在 onTouchEvent 中添加实现接管 View  的 onTouchEvent ：

```java
boolean consume =gesture.onTouchEnvent(ev);
return consume;
```

GestureDetector 中有很多方法，我们可以有选择的实现我们所需要的，常用的有：onSingleTapUp(单击)、onFling（滑动）、onScroll（滑动）、onLongPress（长按）、和 onDoubleTap（双击）。在实际开发中，如果只是监听滑动相关的，建议自己在onTouchEvent 中实现，如果要监听双击这种行为的话，那么就使用 GestureDetector。

#### Scroller

弹性滑动对象，用于实现 View 的弹性滑动。我们知道，当使用 View 的 scrollTo/scrollBy方法来进行 滑动时，其过程是瞬间完成的，这个没有过度效果的滑动用户体验不好。这个时候就可以使用 Scroller 来实现过渡效果的滑动。Scroller 本身无法让 View 弹性滑动，它需要和 View 的 computeScroll 方法配合使用才能完成和功能。那么如何使用它呢，它的使用方法是固定的：

```java
Scroller mScroller = new Scroller(context);

private void smoothScrollTo(int destX,int destY){
    int scrollX = getScrollX();
    int delta =destX-scrollX;
    // 1000ms 内滑向 dest，效果就是慢慢滑动
    mScroller.startScroll(scrollX,0,delta,0,1000);
    invalidate();
}
@Override
public void computeScroll(){
    if(mScroller.computeScrollOffset()){
        scrollTO(mScroller.getCurrX(),mScroller.getCurrY());
        postInvalidate();
    }
}
```

### View 的滑动

滑动在 Android 开发中具有很重要的作用，不管一些效果多么绚丽，归根结底，它们都是由不同的滑动外加一些特效组成。因此，掌握滑动的方法是实现绚丽的自定义控件的基础。通过三种方式可以实现 View 的滑动。

####使用 scrollTo/scrollBy

为了实现 View 的滑动 ，View 专门提供了这两种方法来实现这个功能，就是 scrollTo 和 scrollBy。

scrollBy 实际也是调用 scrollTo 方法，它实现了基于当前位置的相对滑动，而 scrollTo 则实现了给予所传递参数的绝对滑动。

`mScrollX`和`mScrollY`的滑动规则：

> 在滑动过程中，mScrollX 的值总是等于 View 左边缘和 View 内容左边缘在水平方向的距离，而 ScrollY 的值总是等于 View 上边缘的和 View 内容上边缘的竖直方向的距离。并且当**View 左边缘在 View 内容边缘的右边边时，mScrollX 为正值，反之为负值；当 View 的上边缘在 View 内容上边缘的下方时，mScrollY 为正值，反之为负值。 ** scrollTo 和 scrollBy 只能改变 View 内容的位置而不能改变 View 在布局中的位置。

可能按照文字描述感觉有点不合理或者是抽象，但是结合日常生活习惯就很容易理解了。当我们想要在手机上获取当前屏幕的更多内容时候，我们一般会向下滑动或向右滑动，这对应着我们的日常操作习惯。这时候View 的内容区域会向上偏移向左偏移，滑动的距离就是正值。

#### 使用动画

使用动画来让一个 View  平移，主要是操作 View 的 TranslationX 和 Translation Y 属性，既可以使用传统的View动画，也可以采用属性动画。需要注意的是 View 动画并不能真正改变 View 的位置，而是移动 View 的内容区域。

#### 使用 LayoutParams

也可以通过修改 View 的LayoutParms 属性来达到滑动的效果。

#### 各种滑动方式的对比

scrollTo/scrollBy，它可以比较方便实现滑动效果并且不影响 View 内部元素的单机事件。但它只能滑动 View 的内容，并不能滑动 View 本身。

如果是使用属性动画，那么这种方式没有明显的缺点，如果是 View 动画或者是 3.0 以下使用属性动画，切动画元素还需要响应用户的交互，那就不是很适合了。

改变布局这种方式，除了使用起来麻烦点以外也没有明显的缺点。

实现一个简单的屏幕拖拽 View :

```kotlin
    override fun onTouchEvent(event: MotionEvent?): Boolean {
        var x = 0
        var y = 0
        event?.apply {
            x = rawX.toInt()
            y = rawY.toInt()
            when (action) {
                MotionEvent.ACTION_DOWN -> {
                }
                MotionEvent.ACTION_MOVE -> {
                    val deltaX = x - mLastX
                    val deltaY = y - mLastY
                    Log.i(TAG, "move translationX：$deltaX ___ translationY：$deltaY")
                    translationX += deltaX
                    translationY += deltaY
                }
                MotionEvent.ACTION_UP -> {
                }
            }
        }
        mLastX = x
        mLastY = y
        return super.onTouchEvent(event)
    }
```

#### 弹性滑动

如果直接操作 View 移动到指定的位置，这样生硬的滑动显示体验很差。我们可以将一次大的滑动分成若干次小的滑动并在一个时间段内完成。可以通过 Scroller、Handler等来完成。

### View 事件的分发机制

#### 点击事件的传递规则

所谓的点击事件的分发，其实就是对 MotionEvent 事件的分发过程，当用户和屏幕发生交互产生了一个事件的时候，系统需要把这个事件传递给一个具体的 View 处理，这个传递的过程就是分发过程。分发过程由三个很重要的方法来共同完成：dispatchTouchEvent,onInterceptTouchEvent, onTouchEvent



##### public boolean dipatchTouchEvent(MotionEvent ev)

用来进行事件的分发。如果事件能够传递到此 View 那么此方法一定会被调用，返回结果受当前 View 的 OnTouchEvent 和下级 View 的 dipatchTouch 方法的影响，表示是否消耗当前事件。



##### public boolean onInterceptTouchEvent(MotionEvent ev)

在上述方法内部调用，用来判断是否拦截某个事件，如果当前 View 拦截了某个事件，那么在同一时间序列当中，此方法不不会被调用，返回结果表示是否拦截当前事件。



##### public boolean onTouchEvent(MotionEvent ev)

在dipatchTouchEvent 中调用，用来处理点击事件，返回结果表示是否消耗当前事件，如果不消耗，则在同一事件序列中，当前 View 无法再次接受到事件。

它们之间的关系可以用伪代码来表示：

```java
public boolean dipatchTouchEvent(MotionEvent ev){
    boolean consume =false;
    if(onInterceptTouchEvent(ev)){
      consume = onTouchEvent(ev);
    }
    else{
      consume = child.dipatchTouchEvent(ev);
    }
    return consume;
}
```

1. 同一事件序列是指，从手指在屏幕上按下开始，到手指离开屏幕的那一刻结束，这期间所产生的一些列事件，它是由一个 down 事件开始，中间含有数量不定的 Move ，最后由 up 结束。
2. 正常情况下一个序列事件正能被一个 View 消耗且拦截。因为一旦某个 View 拦截了某次事件，那么整个事件序列都会交给它处理，也就不存在两个 View 消费事件的情况。除非 View  强行把 onTouchEvnet 所传递的事件传递给其他的 View。
3. 某个 View 一旦被拦截，那么这一个事件序列都由它来处理，并且它的onInterceptTouchEvent 方法不会被调用。因为系统已经决定它来处理了，也就不需要再去询问了。
4. 某个 View 一旦开始处理事件，如果它不消耗 ACTION_DOWN 事件（TouchEvent返回了false） 那么同一事件序列的所有事件都不会再交给它处理，并且事件重新提交给父容器，父容器的onTouchEvent 事件会被调用。
5. 如果 View 不消除 ACTION_DOWN以外的事件，这个点击事件会消失，父容器的onTouchEvent 也不会调用，View 也可以一直收到后续的事件，最终这些消失的事件会交给 Activity 处理。
6. ViewGroup 默认不拦截任何事件，代码实现中 ViewGroup 的 onInterceptTouchEvent 返回为 flase.
7. View 没有 onInterceptTouchEvent 方法，一旦有点击事件传给它，它的 onTouchEvent 方法就会被调用
8. View 的 enable 属性不影响 onTouchEvent 的默认返回值。哪怕一个 View 是 disable 方法，只要它的click 或者 LongClickable 方法为ture ，那么它的 onTouchEvent 就返回 true。
9. View 的 onTouchEvent 默认都是会消耗事件的，除非它是不可点击的。
10. onClick 发生的前提是它是可点击的，能够接受到 down 和 up 事件
11. 事件传递过程是由外向内的，即事件总是先传递向父元素，然后再由父元素分发给子 View。通过 requestDisallowInterceptTouchEvent 方法可以在子元素中干预父元素的事件分发过程，但是 ACTION_DOWN 除外。

#### 事件分发的源码解析

#####Activity 对点击事件的分发过程

当一个时间产生的时候，事件最先传递给当前的 Activity，由 Activity 的 dispatchTouchEvent 进行事件派发，具体的工作是由 Activity 的 Windows 完成的。windows（PhoneWindow）会将事件传递给 decorView（Activity 根容器）。

```java
public boolean dispatchTouchEvent(MotionEvent ev){
    if(ev.getAction==MotionEvent.ACTION_DOWN){
        //空方法
        onUserInteraction()
    }
    //window 是一个接口 实际的唯一实现类是 PhoneWindow ，它会调用 decorView 的 dispatchTouchEvent 方法.
    if(getWindow().superDispatchTouchEvent(ev)){
        return true;
    }
    return onTouchEvent(ev);
}
```

##### 顶级 View 对点击事件的分发过程

顶级 View 也就是 ViewGroup。经过源码分析可以看出几点：

- 子 View 可以通过`requestDisallowInterceptTouchEvent`方法来影响 ViewGroup 的 `FLAG_DISALLOW_INTERCEPT` 标记，这会使得 ViewGroup 无法拦截除了 ACTION_DOWN 以外的事件。因为在ACTION_DOWN 的时候 View 会重置这个标志位。


- 当面对 ACTION_DOWN 事件的时候，ViewGroup 总会调用自己的 onInterceptTouchEvent 来询问自己是否要拦截事件。
- 当 ViewGroup 决定拦截事件后，那么后续的所有事件都会默认给它处理而不会调用 onInterceptTouchEvent

##### View 对点击事件的处理过程

View 对点击事件的处理过程简单一些。

- onTouchListener 的优先级要比 onTouchEvent 高
- View 即使处于不可用状态仍然会消耗点击事件



总的来说就是验证了上面总结的 11 条结论。

### 


---
layout: post
title: "Android View 工作原理"
subtitle: "Android 艺术开发探索笔记"
date: 2018-03-25 20:00:00
author: "rank"
header-img: "img/post-bg-android.jpg"
catalog: true
tags:
  - Android
  - Note
---



### 初识 ViewRoot和DecorView

ViewRoot 对应 ViewRootImpl 类，它是连接 WindowManager 和 DecorView 的纽带， View 的三大流程均是通过 ViewRoot 来完成的。在 ActivityThread 中，当 Activity 对象被创建完毕后，会将 DecorView 添加到 Window 中，同时会创建 ViewRootImpl对象，并将 ViewRootImpl 和 DecorView 建立关联。源码如下：

```java
root =new ViewRootImpl(view.getContext(),display);
root.setView(View,wparams,panelParentView);
```

View 的绘制流程是从 ViewRoot 的 prefromTraversals 方法开始的，它经过 measure 、lalyout 和 draw 三个过程才能最终将一个 View 绘制出来，其中 measure 用来测量 View 的宽高，layout 用来确定 View 在父容器中的放置位置，而 draw 则负责将 View 绘制在屏幕上。

ViewRoot 的 prefromTraversal 会分别依次调用 prefromMeasure、prefromLayout、prefromDraw 三个方法，这三个 View 分别完成顶级 View 的 measure、layout、和 draw 这三大流程。

Measure  过程决定了 View 的宽/高, Measure 完成以后，可以通过 getMeasuredWidth 和 getMeasureHeight 方法来完成 View 测量后的宽/高,在几乎所有的情况下它都等同于 View 的最终宽高，但特俗情况除外，这点在本章后面会进行说明。layout 过程决定了 VIew 的四个顶点坐标和实际的 View 的宽/高,完成以后可以通过 getTop()、getleft()、getRight()、getBottom() 来拿到 View 的四个顶点的位置，只有 draw 方法完成以后 View 的内容才能呈现到屏幕上。

#### MeasureSpec

MeasureSpec 代表一个 32 位的 int 值，高 2 位代表 SpecMode ,低30位代表 SpecSize。SepcMode 之测量模式，有如下几种规格：

- **UNSPECIFIED** 父容器不对 View 有任何限制，要多大给多大，这种情况一般用于系统内部，表示一种测量的状态。
- **EXACTLY** 父容器已经检测出 View 所需要的精确大小，这个时候 VIew 的最终大小就是 SpzeSzie 所指定的值。它对应于 LayoutParams 中的 match_parent 和具体的数值。
- **AT_MOST**  父容器制定了一个可用大小值，即 SpecSize，View 的大小不能大于这个值，具体是什么值要看不同 View 的具体实现。它对应于 LayoutParams 的 warp_content。

#### View 的工作流程

##### View 的 measure 过程

View 的 measure 过程由其 measure 方法来完成， measure 方法是一个 final 类型的方法，这意味着子类不能重写此方法，在 View 的 measure 方法中回去调用 View 的 onMeasure 方法，因此只需要看 onMeasure 的实现即可。

View 的 onMeasure 方法非常简洁，通过 setMeasureDimension 方法设置 View 由 getDefaultSize 方法得到的宽高的测量值，getDefaultSzie 的源码如下：

```java
public static int getDefaultSize(int size,int measureSpec){
    int result =size;
    int specMode =MeasureSpec.getMode(measureSpec);
    int specSize =MeasureSpec.getSize(measureSpec);
    
    switch(specMode){
        case MeasureSpec.UNSPECIFIED:
            result =size;
            break;
        case MeasureSpec.EXACTLY:
        case MeasureSpec.AT_MOST:
            result=specSize;
            break;
    }
}
```

从 getDefault 的实现可以看出,View 的宽/高由 specSzie 决定，所以我们可以得出如下结论：

> 直接继承 View  的自定义控件需要重写 onMeasure 方法并设置 wrap_content 时的自身大小，否则在布局中使用 wrap_content 相当于使用 match_parent。

为什么呢？因为如果 View 在布局中使用 wrap_content ，那么它所对应的测量模式就是 AT_MOST ，最后的取值也就是 specSize，在这种情况下 specSize 是 parenSize,而 parenSize  是父容器中目前可使用的大小。就使得 View 的宽高和父容器剩余空间的大小一致，这种效果就和 match_parent 完全一致的。

如果 View 的测量模式等于 UNSPECIFIED 模式，它的宽高是如何取值的呢？这种情况 View 的大小等于 getSuggestedMinimumWidth/Height 的值。源码如下:

```java
protected int getSuggestedMinimumWidth(){
    return (mBackground==null)?mMinWidth : max(mMinWidth,mBackground.getMinimumWidth);
}
```

Height 方法也类似。总结一下逻辑：如果 View 没有设置背景，那么返回 View 的 minWidth 否则返回 View 的背景的宽度和 View 的 minWidth 的最大值。

##### ViewGroup 的 measure 过程

  对于 ViewGroup 来说，除了完成自己的 measure 过程以外，还会遍历去调用所有子元素的 measure 方法，各个子元素在递归去执行这个过程。和 View 不同的是，ViewGroup 是一个抽象类，因此它没有重写 View 的 onMeasure 的方法，但是它提供了一个叫 measureChildren的方法：

```java
protected void measureChildren(int widthMeasureSpec ,int heightMeasureSpec){
    final int size = mChildrenCount;
    final View[] children = mChildren;
    for(int i = 0;i < size;++i){
        final View child = children[i];
        if((child.mViewFlags & VISIBILITY_MASK)!=GONE){
            measureChild(child,widthMeasureSpec,heightMeasureSpec);
        }
    }
}
```

measureChild 就是取出子 View 的 LayoutParams ，然后通过 getChildMeasureSpec 来创建子元素的 MeasureSpec，接着将 MeasureSpec 直接传递给 View 的  measure 方法来进行测量。

我们知道，ViewGruop 并没有定义其测量的具体过程，这是因为 ViewGroup 是一个抽象类，其测量过程的 onMeasure 方法需要各子类去具体实现。

##### 如何取得在Activity View 的宽高

在 Activity 的 onCreate、onResume、onStart 均无法正确的获得 View 的宽高，这是因为 View 的 measure 过程和 Activity 的生命周期方法不是同步执行的，因此无法保证。有四种方法获得 View 的宽高 :

- **Activity/View#WindowFocusChanged ** ViewFocusChanged 会在 Activity 得到和失去焦点的时候会被调用，这时 View 已经初始化完毕了，宽高已准备好了。需要注意的是这个方法会被多次调用

- **view.post(runnable)** 通过 post 可以将一个 runnable 投递到消息队列的尾部，然后等待 Looper 调用此 runnable 的时候，View 也已经初始化好了。

- **ViewTreeObserver** 使用 ViewObserver 的众多回调可以完成这个功能。

- **手动对 View 进行 measure 来得到宽高** 通过 view.measure 来手动的测量 View 的宽和高，但是也是分情况的：

  - **match_parent** ：这种事无法测量出 View 的宽高的。因为构造 MeasureSpec 的时候我们需要知道 parentSize ，既父容器的空间大小，而这时我们无法确定 parentSzie 的大小，所以理论上无法测量出 Veiw 的大小

  - **warp_content** ：这时我们通过构造一个View理论上最大值的 measureSpec 来去测量。View 的尺寸用二进制表示，最大值是30个1（既 2^30-1,也就是 1<< 30 - 1 ）

    ```java
    int widthMeasureSpec =MeasureSpec.markMeasureSpec((1 >> 30)-1,MeasureSpec.AT_MOST);
    int heightMeasureSpec =MeasureSpec.markMeasureSpec((1 >> 30)-1,MeasureSpec.AT_MOST);
    view.measure(widthMeasureSpec,heightMeasureSpec);
    
    //网上还有两种错误的用法,因为它们违背了系统的内部的实现规范，无法通过 MeasureSpec 获得合法的 SpecMode。当父View对子View的高度不满意时，子控件没有测量模式来限制宽高，父空间会重新调用 onMeasure 测量，所以测量结果不一定准确
    
    int widthMeasureSpec =MeasureSpec.markMeasureSpec(-1,MeasureSpec.UNSPECIFIED);
    int heightMeasureSpec =MeasureSpec.markMeasureSpec(-1,MeasureSpec.UNSPECIFIED);
    view.measure(widthMeasureSpec,heightMeasureSpec);
    
    view.measure(LayoutParams.WRAP_CONTENT,LayoutParams.WRAP_CONTENT);
    ```


    ```
    
    ​

##### layout 过程

Layout 的作用是 ViewGroup 用来确定子元素的位置，当 ViewGroup 的位置被确定后，它在 onLayout 中遍历所有的子元素并调用其 layout 方法，在 layout 方法中 onLayout 方法会被调用。layout 方法确定 View 本身的位置，而 onLayout 方法则会确定所有子元素的位置。

```java
public void layout(int l,int t,int r,int b){
    if(mPrivateFlags3&PFLAG3_MEASURE_NEEDED_BEFFORE_LAYOUT!=0){
        onMeasure(mOldWidthMeasureSpec,mOldHeightMeasureSpec);
        mPrivateFlag3 &=~ PFLAG3_MEASURE_NEEDED_BEFFORE_LAYOUT；
    }
    int oldL = mLeft;
    int oldT = mTop;
    int oldB = mBootom;
    int oldR = mRIght;
    boolean changed = isLayoutModeOption(mParent)?setOpticalFram(l,t,r,b):setFrame(l,t,r,b);
        if(changed||(mPrivateFlags&PFLAG_LAYOUT_REQUIRED)==PFLAG_LAYOUT_REQUIRED){
            onLayout(changed,l,t,r,b);
            ....
            ....
        }
}
```

大致流程如下：首先通过 setFrame 放来来设定 View 的四个顶点的位置，即初始化 mLeft,mRight,mTop,mBottom 四个值，View 的四个顶点一旦确定，那么 View 在容器中的位置也就确定了；接着调用 onLayout 方法，这个方法用途是父容器确定子元素的位置，和 onMeasure 类似, onLayout 的具体实现同样和具体的布局有关，所以 View 和 ViewGroup 没有具体的实现。

#### Draw 过程

Draw 过程就比较简单了，它的作用是将 View 绘制到屏幕上。遵循以下几步：

- 绘制背景 background.draw(canvas)
- 绘制自己 onDraw
- 绘制 children (dispatchDraw)
- 绘制装饰(onDrawScrollBars)

### 


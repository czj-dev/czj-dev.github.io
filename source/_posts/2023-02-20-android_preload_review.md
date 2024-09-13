---
layout: post
title: "Android 列表预加载分析"
subtitle: "方案调研"
date: 2023-02-22 14:13:00
author: "rank"
header_image: "img/about-bg-walle.jpg"
catalog: true
tags:
  - Android
  - RecyclerView
---


当今移动应用开发中，列表控件是最常用的UI控件之一，它可以显示各种信息，如图片、文本、视频等等。然而，在移动设备上，列表数据的加载和显示是非常耗费资源的操作。当列表中的数据量较大时，用户往往需要等待较长的时间才能看到完整的列表。为了提高用户体验，开发人员需要采取一些策略来减少加载时间，如预加载。
预加载是指在用户滑动列表之前，提前加载一部分列表数据，以便在用户滑动到这些数据时可以立即显示，从而提高用户的体验和感知速度。Android系统提供了一些API和技术来实现列表预加载，本课题旨在对Android列表预加载进行深入研究和分析，探究其实现原理、优化策略和性能影响，为开发人员提供参考和指导。
 

接下来我们就深入研究几种预加载列表的方法，它们或是通过 Android 系统的 API 扩展或是各种第三方框架完备的实现，了解它们的实现原理，方便我们根据具体的业务需求和性能要求进行综合评估和比较，从而选择最合适的方案来实现列表预加载功能。

## RecyclerView.OnScrollListener

通过 RecyclerView 的 addOnScrollListener 接口，我们可以监听到 RecyclerView 的滑动状态，然后通过该 RecyclerView 装载的 LayoutManager 来得到当前滑动最下方或最上方展示的 item 的索引，痛殴索引来判断我们是否需要执行预加载逻辑。


```dart
rvList.addOnScrollListener(new RecyclerView.OnScrollListener() {
    @Override
    public void onScrolled(@NonNull RecyclerView recyclerView, int dx, int dy) {
        super.onScrolled(recyclerView, dx, dy);
        // 获取 LayoutManger
        RecyclerView.LayoutManager layoutManager = recyclerView.getLayoutManager();
        // 如果 LayoutManager 是 LinearLayoutManager
        if (layoutManager instanceof GridLayoutManager) {
            GridLayoutManager manager = (GridLayoutManager) layoutManager;
            int nextPreloadCount = 8;
            int previousPreloadCount = 4;
            if (dy > 0
                    && manager.findLastVisibleItemPosition()
                    == layoutManager.getItemCount() - 1 - nextPreloadCount) {
                mViewModel.loadNext();
            } else if (dy > 0 && manager.findFirstVisibleItemPosition() == previousPreloadCount) {
                mViewModel.loadPrevious();
            }
        }
    }
});
```

通过给列表页的 RecyerView 增加这一段代码，我们就可以很轻松的实现列表的预加载，在有本地本地数据缓存排除网络状态的情况下，和之前通过框架的 `loadMore` 触发有着显而易见的差别。但于此同时，在查看日志是就很容易发现，`onScrolled` 方法会在一次滑动中多次重复调用，造成同一个页面加载的多次调用，网络加载下对性能以及数据流量有很大的影响，需要业务逻辑上做去重处理。


### 结论

`RecyclerView.onScrollListener` 的实现和集成方式大致如上，通过实践我们可以得出以前结论：  

**优点**：

- 编码简单
- 代码入侵性低，无需修改现有的 RecyclerView 或 adapter

**缺点**：

- `onScrolled` 方法会在一次滑动中多次重复调用，需要业务逻辑自行做去重判断
- 不同的 `LayoutManager`  会有不同的判断逻辑，需要不停的兼容扩展

## Adapter.onBindViewHolder

我们监听列表的原因是想知道当前滑动到第几项目，从而来决定是否要开始预加载，为此需要拿到滑动的状态和 `LayoutManager`  .  实际上 Adapter 就有天生的简单易用的回调，那就是 `onBindViewHolder`  `onBindViewHolder` 在 `RecyclerView` 需要显示指定的 `Position` 的 数据时才会通知，这时我们就可以根据 `BindViewHolder` 的 `Position` 以及整个列表的数据对比来判断我们是否需要进行预加载，而无需实时的关心列表的滑动状态和 `LayoutManager` 的类型


接下来我们就使用 Adpater 的 onBindViewHolder 来实现以下预加载：

```java
public class ListAdapter extends RecyclerView.Adapter<ViewHolder> {

	private int nextPreloadCount = 8;

	private int previousPreloadCount = 4;
	
	private boolean isScroll

	public void onBindViewHolder(@NonNull VH holder, int position,
                @NonNull List<Object> payloads) {
			checkPreload(position);
  }

	public void bindRecyelerView(@NonNull RecyclerView recyclerView ) {
		 if (newState == RecyclerView.SCROLL_STATE_IDLE) {
         isScroll = false;
     } else {
			 	 isScroll = true;
		 }
	}
	
	private void checkPreload(int position) {
		 if (!isScroll){
				return;
		 }
     if (position == previousPreloadCount) {
          mViewModel.loadPrevious();
     } else if (position == getItemCount() - 1 - nextPreloadCount) {
          mViewModel.loadNext();
     }
    }
}
```

代码整体实现也简单易懂，列表滑动过程中所有的列表项的加载都会经过 `Adapter.onBindViewHolder` 
从而触发预加载检测一致，由于 RecyclerView 的逻辑处理，`onBindViewHolder`  不会存在单次滑动中被多次调用的情况。且由于 Adpater 的 position 获取是与 layoutManger 无关的，所以也不需要 layoutManger 相关的代码逻辑。但是这个方案也仍然优缺点，那就是当触发预加载的 viewHolder 在列表加载过程中被向上滑出了 RecyclerView 的缓存区域时，再向下滑动到页尾时会再次被绑定导致 `onBindViewHolder`  触发，从而使得预加载重复触发。

### 结论

`Adapter.onBindViewHolder` 的实现也并不复杂，且相较于监听列表的实现差异明显

**优点**：

- 代码编写逻辑简单，基类可多处复用，与类型无关
- `RecyclerView` 对页首页尾的 `ViewHolder` 并不会立即回收，不会在正常的滑动事件内触发多次加载

**缺点**：

- 仍会重新触发上拉加载，还是需要做去重操作。

## BaseRecyclerViewAdapterHelpr

`BaseRecyclerViewAdapterHelpr`  是一个强大而灵活的 RecyclerView Adapter ，是一个在 github 拥有 23.4 K star 的库，很多商业项目的的 adapter 都会采用它，以下简称 `BRVAH` 。 我们来探究下它是如何处理预加载方案的，通过文档查看我们发现它的加载更多的逻辑是专门有 `QuickAdapterHelper.kt` 来实现的，直接查看它的预加载方案 ：

#### 加载上一页

```kotlin
leadingLoadStateAdapter?.let {
            mAdapter.addAdapter(it)

            firstAdapterOnViewAttachChangeListener =
                object : BaseQuickAdapter.OnViewAttachStateChangeListener {

                    override fun onViewAttachedToWindow(holder: RecyclerView.ViewHolder) {
                        leadingLoadStateAdapter.checkPreload(holder.bindingAdapterPosition)
                    }

                    override fun onViewDetachedFromWindow(holder: RecyclerView.ViewHolder) {

                    }
                }.apply { contentAdapter.addOnViewAttachStateChangeListener(this) }
```

#### 加载下一页

```kotlin
trailingLoadStateAdapter?.let {
            mAdapter.addAdapter(it)

            lastAdapterOnViewAttachChangeListener =
                object : BaseQuickAdapter.OnViewAttachStateChangeListener {

                    override fun onViewAttachedToWindow(holder: RecyclerView.ViewHolder) {
                        trailingLoadStateAdapter.checkPreload(
                            holder.bindingAdapter?.itemCount ?: 0,
                            holder.bindingAdapterPosition
                        )
                    }

                    override fun onViewDetachedFromWindow(holder: RecyclerView.ViewHolder) {

                    }
                }.apply { contentAdapter.addOnViewAttachStateChangeListener(this) }
        }
```

`BRVAH` 整体对加载的方案采用的是 `ConcatAdapter`  ，加载的头部和尾部通过独立的 adapter 来做逻辑控制，所以两部的代码基本一致，这里我们就拿加载下一页的逻辑来梳理。 `contentAdapter` 就是实际的列表 adapter ，`trailingLoadStateAdapter` 则是专门负责列表尾部逻辑处理的 adapter ，可以看到它创建了一个 `OnViewAttachStateChangeListener`   用来监听 viewHolder 的 onViewAttachedToWindow ,  其具体实现是绑定了  Adapter 的 `onViewAttachedToWindow` ，通过这个契机触发预加载监测机制。具体实现就不在深究了，我们知道它的触发契机和大致实现即可，感兴趣的可以直接去查阅对应的源码，其实际实现也并不复杂。

可以看到 `BRVAH` 虽然采用了对 Adapter 进行封装处理预加载逻辑，但它并没有采用 Adpater 的 `onBindViewHolder`  当作触发契机而是采用了 `onViewAttachedToWindow`  造成这样的差异是什么，我们可以看下这两者的实际差别:

`onViewAttachedToWindow`方法在RecyclerView中显示一个ViewHolder时被调用。当RecyclerView需要显示一个新的ViewHolder时，它会调用Adapter的`onCreateViewHolder`方法来创建一个ViewHolder，然后将这个ViewHolder绑定到数据源中对应的数据上，最后调用ViewHolder的`onBindViewHolder`方法将数据显示在ViewHolder的视图上。这时，如果ViewHolder被成功添加到RecyclerView中，`onViewAttachedToWindow`方法就会被调用。

因此，`onViewAttachedToWindow`方法在ViewHolder显示在RecyclerView上时触发，而**`onBindViewHolder`方法则是在RecyclerView需要更新ViewHolder数据时触发。

从我们的业务场景出发—— 预加载的目的是通过滑动来判断用户可能有向下滑动的意图，提前补充列表数据，避免用户等待。业务场景其实并不太依赖当前视图是否真的展示在界面上了，所以这里没有用生命周期更靠前的 **`onBindViewHolder`** 而用了更靠后的 **`onViewAttachedToWindow`** 从源码角度上来看并没有得到好的解释，去查看仓库也没有相关的提交注释。只能后续看是否能联系上作者询问了

### 结论

`BRVAH` 带了新的预加载方案，虽然目前看本质上与 onBindViewHolder 类似，但是`BRVAH` 除此之外还提供了成套的解决方案，包括防止重复加载以及列表头尾的优雅处理。

 **优点**：

- 集成难度中等
- 有较高的 star 和活跃度，出现问题的概率较小
- 提供了成套的解决方案，避免造轮子

**缺点**：

- 需要引入新的库，修改调整现有的 adapter

## BRV

`BRV` 是一个基于 `SmartRefreshLayout`  框架的扩展库，他在 `SmartRefreshLayout` 的基础上提供了预加载，缺省页，悬停标题等功能，号称拥有比 `BRVAH`   更强大的功能以及实用性，它的其中预加载逻辑如下：

```kotlin
/** 监听onBindViewHolder事件 */
    var onBindViewHolderListener = object : OnBindViewHolderListener {
        override fun onBindViewHolder(
            rv: RecyclerView,
            adapter: BindingAdapter,
            holder: BindingAdapter.BindingViewHolder,
            position: Int,
        ) {
            if (mEnableLoadMore && !mFooterNoMoreData &&
                rv.scrollState != SCROLL_STATE_IDLE &&
                preloadIndex != -1 &&
                (adapter.itemCount - preloadIndex <= position)
            ) {
                post {
                    if (state == RefreshState.None) {
                        notifyStateChanged(RefreshState.Loading)
                        onLoadMore(this@PageRefreshLayout)
                    }
                }
            }
        }
    }
```

可以看到与我们编写 onBindViewHolder 的监听逻辑基本如出一辙，通过当前的触发的　bindViewHolder position  来判断是否要触发预加载，而加载的头部和尾部则是基于 `SmartRefreshLayout`  来的，通过 ViewGruop 单独的 add 添加和 remove 掉。

### 结论

`BRV`  的预加载方案基本与我们自己基于 Adpater 的基本一致，在此基础上增加了去重处理

 **优点**：

- 提供了成套的解决方案，避免数据重复造轮子

**缺点**：

- 集成难度复杂，依赖 `SmartRefreshLayout`  没有引入 `SmartRefreshLayout`  库的话还需要单独引入
- 只提供了向后预加载，不支持向前预加载

## Paging 3

[Paging 库概览  |  Android 开发者  |  Android Developers](https://developer.android.com/topic/libraries/architecture/paging/v3-overview?hl=zh-cn#paging)

Paging 作为 Jetpack 的组件，专门用于加载和显示来自本地和网络中的数据页面，同样也提供了数据预加载的功能，那么作为官方的列表加载方案，它又是如何实现的。

`Paging3`   作为一整套的列表解决方案，它提供了分页数据的内存缓存、内置的请求重复信息删除功能 以及对刷新与重试功能的支持等等，此外， `paging3` 还大量的使用了 Flow 作为数据处理实现，功能调用栈也极深。导致代码阅读复杂较高，这里我们就只了解下 `Paging3`  预加载的契机以及判断逻辑，用于跟其他框架进行对比。

#### 触发契机

首先是触发契机，`Paging3`  提供了 `PagingDataAdapter`  作为 RecyclerView 的适配器，开发者必须使用基于它的 Adapter 来进行列表适配，`PagingDataAdapter`  内置了 diff 机制以及直接管理列表数据，列表设置和更新需要通过 `submitData` 方法，获取数据则通过 `getItem`  方法，而 `paging3` 的预加载机制则就藏匿在 `getItem`  的具体实现中，由于列表数据是完全封装起来的，调用者只能通过 `getItem` 来获取列表数据，而调用 `getItem` 往往是在 `onBindViewHolder` 时，所以 paging3 的分页触发契机也基本等同于 `onBindViewHolder` 方式

#### 判断逻辑

`getItem` 方法触发时，paging3 会生成 `ViewportHint` 的快照，用来存储描述当前列表的状态，同时依据这些信息来判断是否要触发预加载

```kotlin
/**
     * Processes the hint coming from UI.
     */
    fun processHint(viewportHint: ViewportHint) {
        state.modify(viewportHint as? ViewportHint.Access) { prependHint, appendHint ->
            if (viewportHint.shouldPrioritizeOver(
                    previous = prependHint.value,
                    loadType = PREPEND
                )
            ) {
                prependHint.value = viewportHint
            }
            if (viewportHint.shouldPrioritizeOver(
                    previous = appendHint.value,
                    loadType = APPEND
                )
            ) {
                appendHint.value = viewportHint
            }
        }
    }
```

`prependHint`, `appendHint` 本质也分别是一个 `Flow` ，当前符合预加载机制后，它们会将 `viewportHint` 发送到专门用于处理此类数据的 `PageFetcherSnapshot`  将来转换成一个刷新事件从而融入整个数据加载流程。

`Paging3` 的预加载机制大致就是如此，更详细的机制由于代码量太多不变深入，如果对 `Paging3` 不熟悉和感兴趣的可以放下边官方的 CodeLab 做深入了解

### 结论

`paging3`  的预加载只是整个库的冰山一角，但是由此也可以看到官方也是通过 `onBindViewHodler` 作为预加载的判断契机的，给我们挑选更轻量的方案做了一定的背书

**优点**

- 有完备的机制以及官方背书，出现问题的概率较小
- 预加载还加入了锁的处理，考虑了多线程并发,完全解决了可能出现的多次请求问题。

**缺点**

- 集成难度非常大，`paging3` 是一整套列表解决方案，需要各个层级的逻辑变更
- 代码由 kotlin 、Flow 以及协程编写，预读和调适性教差，Java 接入不友好

### CodeLab

Google 提供了两个引导文档来让开发人员快速的学习如何集成和使用 Paging 3

[Android Paging 基础知识  |  Android Developers](https://developer.android.com/codelabs/android-paging-basics?hl=zh-cn#0)

[Android Paging Advanced Codelab  |  Android Developers](https://developer.android.com/codelabs/android-paging?hl=zh-cn#0)

## 总结

在实现列表预加载的过程中，选择合适的技术方案非常关键，今天我们介绍了以下几种列表预加载方案：

1. 使用onScrollListener技术，可以通过监听滚动事件，在滑动到指定位置之前提前加载数据，以此实现列表预加载的功能。它的实现简单，同时缺点也相当明显。
2. 使用 BindViewHolder 技术，可以在绑定 ViewHolder 时进行数据的预加载，以此提高列表数据的加载速度和用户体验。它的逻辑简单明了，也是很多解决方案的核心逻辑。如果考虑自己封装的话，那么以它为蓝本是不二之选。
3. BRV框架是一个开源的Android列表框架，它基于`SmartRefreshLayout`  ，提供了很多常用的列表功能，包括列表预加载。BRV框架可以方便地实现列表预加载，并提供了许多其他的功能，如分组、拖拽等等。遗憾的是并不支持列表向前预加载。
4. Paging框架是一个Android官方提供的用于实现分页加载的框架。它可以方便地实现列表预加载，同时还提供了分页加载、数据缓存等功能。
5. BaseRecyclerViewAdapterHelper是一个轻量级的RecyclerView适配器，它可以快速地构建RecyclerView 列表，并支持列表预加载等功能。

选择哪种方案实现列表预加载，需要根据具体的业务需求和性能要求进行综合评估和比较，从而选择最合适的方案来实现列表预加载功能。

## 参考资料：

[换一个思路，超简单的RecyclerView预加载 - 掘金](https://juejin.cn/post/6885146484791050247)

[预加载/预拉取 - BRV](https://liangjingkanji.github.io/BRV/preload/#_1)

[https://github.com/CymChad/BaseRecyclerViewAdapterHelper](https://github.com/CymChad/BaseRecyclerViewAdapterHelper)

[Paging  |  Android 开发者  |  Android Developers](https://developer.android.com/jetpack/androidx/releases/paging?hl=zh_cn)


/**
 * LiveGallery — 动态照片画廊交互（原生相册式），零依赖 vanilla JS
 *
 * 交互模型（对齐 iPhone 相册网格）：
 *   单击  → 原地播放；播放中单击 → 暂停回静帧；播放结束 → 自动回静帧
 *   双击  → 放行原生 Fancybox 灯箱（动态项带 data-fancybox，起始项/翻页/caption 全原生）
 *
 * 实现要点：handler 注册在 document capture 阶段——
 *   单击时 preventDefault + stopPropagation 阻断 Fancybox 的委托；
 *   双击的第二击不拦截，事件自然冒泡给 Fancybox 原生打开。
 *
 * 用法：
 *   new LiveGallery()                                  // 默认 .gallery-item-video
 *   new LiveGallery({ itemSelector: '.x', dblclickWindow: 300 })
 *
 * DOM 约定：
 *   <a class="gallery-item-video" data-video="x.mp4" data-fancybox="组名" href="x.mp4">
 *     <img src="静帧.jpg">  <video class="live-video" muted playsinline preload="none">
 *   </a>
 */
(function (global) {
    'use strict';

    var DEFAULTS = {
        itemSelector: '.gallery-item-video',
        videoSelector: '.live-video',
        dblclickWindow: 260 // ms，与系统双击阈值接近
    };

    function LiveGallery(opts) {
        this.opts = {};
        for (var k in DEFAULTS) this.opts[k] = DEFAULTS[k];
        if (opts) for (var k2 in opts) this.opts[k2] = opts[k2];
        this._clickTimer = null;
        this._lastItem = null;
        var self = this;
        document.addEventListener('click', function (e) { self._handleClick(e); }, true);
    }

    LiveGallery.prototype._handleClick = function (e) {
        var item = e.target && e.target.closest ? e.target.closest(this.opts.itemSelector) : null;
        if (!item) return; // 非动态项：不干预，Fancybox 原生处理

        // 双击：第二击放行 → 事件冒泡给 Fancybox 原生打开（起始于本项）
        if (this._lastItem === item) {
            this._lastItem = null;
            clearTimeout(this._clickTimer);
            this._stop(item);
            return;
        }
        // 单击：capture 阶段拦截，阻断 Fancybox 委托
        e.preventDefault();
        e.stopPropagation();
        this._lastItem = item;
        var self = this;
        clearTimeout(this._clickTimer);
        this._clickTimer = setTimeout(function () {
            self._lastItem = null;
            self._toggle(item);
        }, this.opts.dblclickWindow);
    };

    LiveGallery.prototype._toggle = function (item) {
        var v = item.querySelector(this.opts.videoSelector);
        if (!v) return;
        if (v.paused) this._play(item, v);
        else this._stop(item);
    };

    LiveGallery.prototype._play = function (item, v) {
        var self = this;
        var onEnd = function () { self._stop(item); };
        v.addEventListener('ended', onEnd, { once: true });
        v.play().catch(function () { /* 自动播放被拦截或网络失败：保持静帧 */ });
        item.classList.add('is-playing');
    };

    LiveGallery.prototype._stop = function (item) {
        var v = item.querySelector(this.opts.videoSelector);
        if (v) { v.pause(); v.currentTime = 0; }
        item.classList.remove('is-playing');
    };

    global.LiveGallery = LiveGallery;

    // memos 页自动初始化（脚本置于模板尾部，DOM 已就绪）
    if (document.querySelector('.memos-page')) {
        new LiveGallery();
    }
})(window);

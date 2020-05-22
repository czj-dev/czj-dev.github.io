---
layout: post
title: "官方文档的重要性"
subtitle: ""
date: 2020-05-22 11:56:00
author: "rank"
header-img: "img/post-bg-alitrip.jpg"
catalog: true
tags:
  - Note
---



今天发生了两件事情,解决方法倒是殊途同亏,都是通过官方文档来解决的.事后回想下来也有总结的必要,在这里聊两句.

一是在看 elm 开源项目源码的时候发现了一个挺奇怪的语法

``` javascript
export const USERINFO =“userInfo”;

export default{

 	[USERINFO]({commit,state}){
    commit("xxx",xx);
  }

}

```

函数中间和逻辑倒是没什么好讨论的,但是函数面前加了一个数组变量,这倒是让我有点晕了,百思不得其解这是什么操作,函数不像函数 变量不像变量的.使用 `node` `babel` 去解释这个函数也无法解释,搜索也不知从何下手,最后求助于万能的群友.群友发来百度知道的链接(没想到呀,百度知道竟然有正儿八经的回答),发现这是一个 ES5 时将方法命名的操作,因为在 es6 之前属性的名称不能是一个变量,所以通过类似的包装方法达成目的,解构出来其实是这样的

```javascript
[USERINFO]:function({commit,staet}){
  commit("xxx",xxx);
}
```

到这里其实还好,只能说不会表达导致搜索不到.但是可笑的这个在 vuex 的官方文档中是明明白白的写有例子的.



第二个是朋友突然找我看郭霖大佬前不久写的一个权限框架中的 一个kotlin 语法糖,为了方便我写了伪代码如下:

```kotlin

class Scope(params: Int) {

    fun showDialog() {
        //部分逻辑
        print("this is dialog")
    }

}

typealias Callback = Scope.(count: Int) -> Unit

class Permission() {


    private val scope = Scope(0)

    private var callback: Callback? = null

    fun setCallback(callback: Callback): Permission {
        this.callback = callback
        return this
    }

    fun request() {
				//.... 业务逻辑
       // 执行 callback
        callback?.let {
            scope.it(1)
        }
    }

}

class MainActiivty {

    fun onCreate() {
        Permission()
            .setCallback {
                //....逻辑代码
                // ... 匿名函数中直接调用了 showDialog 方法
                showDialog()
            }.request()
    }
}
```

库的名字叫做 [PermissionX](https://github.com/guolindev/PermissionX),想了解具体代码和设计的可以去看看,当时看了一下挺惊奇 `showDialog` 可以直接在一个匿名 Function 里可以调起.虽然大致思路可以根据经验略猜一二(别名方法申明的时候定义了一个扩展函数,然后调用的 callback 的时候是在 `scope` 的 `context` 中运作的).之后先根据 kotlin convert java 来看也确实如此:

```java
// Permission.java

public final class Permission {
   private final Scope scope = new Scope(0);
   private Function2 callback;

   @NotNull
   public final Permission setCallback(@NotNull Function2 callback) {
      Intrinsics.checkParameterIsNotNull(callback, "callback");
      this.callback = callback;
      return this;
   }

   public final void request() {
      Function2 var10000 = this.callback;
      if (var10000 != null) {
         Function2 var1 = var10000;
         int var3 = false;
         var1.invoke(this.scope, 1);
      }

   }
}

// MainActiivty.java

public final class MainActiivty {
   public final void onCreate() {
     // calback 部分无法转译
      (new Permission()).setCallback((Function2)null.INSTANCE).request();
   }
}

// Scope.java
public final class Scope {
   public final void showDialog() {
      String var1 = "this is dialog";
      boolean var2 = false;
      System.out.print(var1);
   }

   public Scope(int params) {
   }
}
```

可以看到别名创建的 callback 被转译成了  kotlin 库中 `Function2` 也就是该函数接受两个参数. 最后在 `request` 时 callback 通过 `invkoe` 操作符调用了自身,传递了 Context `Scope` 和 Param `1`  , 如果了解扩展函数的具体实现就会发现,这和扩展函数是一样的 , 扩展函数在编译后会转换为静态方法,被扩展的对象会被当作参数 `this` 传入静态函数,我们可以给 Permisson 增加一个扩展函数 `test` 它转译后如下 :

```java
// T.kt

fun Permission.text(){
  
}

// TKt.java

public final class TKt {
   public static final void test(@NotNull Permission $this$test) {
      Intrinsics.checkParameterIsNotNull($this$test, "$this$test");
   }
}
```

至于 invoke 内部具体是如何执行的,这里 java 代码虽然看不到,但是伪 bytecode 也可以让我们一探究竟

```java
// access flags 0x11
  public final invoke(Lcom/xcar/basicres/ui/Scope;I)V
    // annotable parameter count: 2 (visible)
    // annotable parameter count: 2 (invisible)
    @Lorg/jetbrains/annotations/NotNull;() // invisible, parameter 0
   L0
    ALOAD 1
    LDC "$receiver"
    INVOKESTATIC kotlin/jvm/internal/Intrinsics.checkParameterIsNotNull (Ljava/lang/Object;Ljava/lang/String;)V
   L1
    LINENUMBER 47 L1
    ALOAD 1
    INVOKEVIRTUAL com/xcar/basicres/ui/Scope.showDialog ()V
   L2
    LINENUMBER 48 L2
    RETURN
   L3
    LOCALVARIABLE this Lcom/basicres/ui/MainActiivty$onCreate$1; L0 L3 0
    LOCALVARIABLE $this$setCallback Lcom/basicres/ui/Scope; L0 L3 1
    LOCALVARIABLE it I L0 L3 2
    MAXSTACK = 2
    MAXLOCALS = 3
```

 我们只需要关注 `INVOKESTATIC` 也就是执行方法调用的指令,就不难发现, 最后确实是通过 Scope 调用了showDialog 方法,所以在 callback 中 this 已经转换为 Scope 了 .

虽然一通分析差不多将过程捋清楚了,但是这个通过别名来创建扩展函数且能通过这种方式强化 callback 的语法还是不知道出处.最后抱着试试看的形态去找了官方文档,没想到还真找到了.... 下边是原文,我直接摘抄了方便查看

> ### 函数类型实例调用
>
> 函数类型的值可以通过其 [`invoke(……)` 操作符](https://www.kotlincn.net/docs/reference/operator-overloading.html#invoke)调用：`f.invoke(x)` 或者直接 `f(x)`。
>
> 如果该值具有接收者类型，那么应该将接收者对象作为第一个参数传递。 调用带有接收者的函数类型值的另一个方式是在其前面加上接收者对象， 就好比该值是一个[扩展函数](https://www.kotlincn.net/docs/reference/extensions.html)：`1.foo(2)`，
>
> 例如:
>
> ```kotlin
> val stringPlus: (String, String) -> String = String::plus
> val intPlus: Int.(Int) -> Int = Int::plus
> 
> println(stringPlus.invoke("<-", "->"))
> println(stringPlus("Hello, ", "world!")) 
> 
> println(intPlus.invoke(1, 1))
> println(intPlus(1, 2))
> println(2.intPlus(3)) // 类扩展调用
> 
> ```

可以看到官方文档中的函数类型调用的例子,之前也完整的阅读过官方文档,但这种操作符基本都是一掠而过,虽然网上都把官方文档是一手资料,但之前一直把各路文档当作入门资料罢了.经此事后需要对官方文档改变心态.

ps: 郭霖大佬对语言的理解确实是非常深奥, 别名和扩展调用虽然都是挺常用的使用手法, 但是通过别名加类扩展调用从而将放大扩展函数功能性(`Scope` 的创建是需要条件的,它并不适用于匿名创建)的手法,称得上十分精妙了.


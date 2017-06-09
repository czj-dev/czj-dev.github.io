---
layout: post
title: "Data Binding学习笔记"
subtitle: "从零开始的Booklet(一)"
data: 2017-05-19 16:03:00
author: "just"
header-img: "img/post-bg-alitrip.jpg"
catalog: true
tags:
    - Android
    - Booklet
---
## 前言

Data Binding出来很久了，不过现在连MVP都没有大规模被使用，别说写法用法更颠覆性的Datat Binding这样的了。但Data Binding这种面向MVVM的编程思想前端的使用已经非常普遍了，且确实给开发带来很大的便利。所以还是有必要学习和了解。

## 什么是Data Binding?

简单的来说Data Binding是Google 在Android上的一种MVVM的实现。MVVM是`Model-View-ViewModel`的简写，它是MVP(Model-View-Persenter)模式与WPF结合的应用方式发展演变过来的一种新型架构。而WPF主要带来的特性就是**数据绑定**，这也是Data Binding所实现的功能。

![](http://www.cyxqd.com/wp-content/uploads/2014/10/nmwentill.jpg)

## 数据绑定

数据绑定分为**单项绑定**和**双向绑定**;单向绑定就是将视图上的控件的属性绑定到一个对象的某个属性的方法，当对象的属性发生变化时直接影响到控件上；双向绑定的话就是可以互相影响——例如我们将`User`类的`name`属性绑定到`TextView`的`setText`属性上，这样当我们修改name的值时setText值也发生相应的改变，无需我们自己去setText更新属性。Data Binding不仅可以帮我们在Android上实现这一机制，还为此附带了很多便利，减少了很多工具代码的编写。

- **项目更加解耦，各个组件的依赖性进一步降低，增加可复用性**


- **去掉Activities&Fragment内的大部分UI代码**，例如`onClickListener`、`setText`、`findViewById`等
- **xml的功能增强**。xml不再只是声明UI的界面，还起到数据的绑定，赋值，逻辑判断等功能。
- **性能提高，减少view id的定义**。由于数据绑定直接在xml产生，所以不用绞尽脑汁的其大量的名称且在绑定的时候就一次性的通过gruop将view全部获取，比单个`findViewById`更加的迅速。



## 搭建环境

Data Binding在Android Studio 1.3版本&Gradle1.5后就内置在IDE中了，我们只需要在`gradle.project`中`Android`模块下声明开启Data Binding即可

```groovy
android{
  ...
    dataBinding{
      enabled=true
    }
}
```

## 基础使用

### 编写View

数据绑定需要在xml中声明各种关系，也可以写一些简单的运算。声明一个data Binding Layout只需要在原来的layout xml文件基础加一个标签即可:

```xml
<layout>
//...rootView
</layout>
```

这样在编译时，修改后即可搜索到布局生成的对应的*Binding类。生成的规则默认是通过xml的文件名生成，例如`activity_main.xml`就会对应生成为`ActivityMainBinding.java`的文件。当然我们也可以指定自定生成的文件名称，需要在`layout`标签下加入`data `标签并指定`class`属性即可(生成LoginBinding.java)，除此之外`data`也是我们声明变量的地方，稍后再详细介绍。

```xml
<data class="login">
....
</data>
```

我们来编写一个简单的登录界面:

先使用`variable`绑定我们所需要的对象。`type`为该对象的地址,`name`则随意命名。这里我们声明了一个`Action`和`Presenter`,`Action`用于绑定数据，`Presenter`则用来绑定一些事件和做逻辑处理。

```xml
<layout>   
<data>
        <variable
            name="presenter"
            type="com.example.qhfax.databindingexample.presenter.MainPresenter" />

        <variable
            name="action"
            type="com.example.qhfax.databindingexample.bean.Action" />
    </data>
  
  //...rootView
  </layout>
```

声明好对象后，我们就开始将对象绑定到数据源上。在Data Binding中，我们绑定数据需要使用`@{code}`书写，向插件声明这是一个表达式。这里我们将`name`属性绑定到`TextView`的`setText`上。

```xml
<TextView
            android:layout_width="63dp"
            android:layout_height="wrap_content"
            android:layout_marginLeft="8dp"
            android:layout_marginRight="8dp"
            android:layout_marginTop="60dp"
            android:gravity="center"
            android:text="@{action.name}" />
```

之后在Activity中我们需要使用`DataBindingUtil`获取`ActivityMainDataBinding`的实例

```java
ActivityMainDataBinding mMainBind=DataBindingUtil.setContentView(this,R.layout.activity_main);
```

然后去绑定对象

```java
Action action = new Action();
action.setName("用户名：");
mMainBind.setAction(action)
mMainBind.setPersenter(persenter);
```

运行后就可以发现`TextView`就直接被赋值啦。



### 绑定的原理

嗯....我们可以先观察一下目前的流程是怎么走下来的；

1. 在`xml`文件中绑定控件，然后插件会根据`layout`生成对应的实体类。通过DataBindingUtli来构建对应的Bind实例，查看DataBindingUtil的代码会发现的工作实现十分简单，将属性和view集合传递给我们的DataBinding:

   ```java
   //查找到布局ViewGruop  
   public static <T extends ViewDataBinding> T setContentView(Activity activity, int layoutId,
               DataBindingComponent bindingComponent) {
           activity.setContentView(layoutId);
           View decorView = activity.getWindow().getDecorView();
           ViewGroup contentView = (ViewGroup) decorView.findViewById(android.R.id.content);
           return bindToAddedViews(bindingComponent, contentView, 0, layoutId);
   //遍历所有的View然后调用ViewDataBinding.Bind方法将数据传给我们的实体类`ActivityMainDataBinding`    
   private static <T extends ViewDataBinding> T bindToAddedViews(DataBindingComponent 			component, ViewGroup parent, int startChildren, int layoutId) {
       final int endChildren = parent.getChildCount();
       final int childrenAdded = endChildren - startChildren;
       if (childrenAdded == 1) {
           final View childView = parent.getChildAt(endChildren - 1);
           return bind(component, childView, layoutId);
       } else {
           final View[] children = new View[childrenAdded];
           for (int i = 0; i < childrenAdded; i++) {
               children[i] = parent.getChildAt(i + startChildren);
           }
           return bind(component, children, layoutId);
       }
   }
   ```

   ​

2. 通过Bind实例绑定数据源，关联控件发生改变。那么数据绑定与刷新又是如何发生的呢？在源码中我们可以发现最终应该是调用了`ActivityMainBinding`的`executeBindings()`方法来执行控件刷新的，源码并不复杂。


```java
 protected void executeBindings() {
   //dirtyFlags的作用主要是通过位运算来判断控件的数据源对象是否被绑定，这里我们就不关心具体实现。
        long dirtyFlags = 0;
        synchronized(this) {
            dirtyFlags = mDirtyFlags;
            mDirtyFlags = 0;
        }
   		com.example.qhfax.databindingexample.bean.Action action = mAction;
   		java.lang.String actionName = null;
  		 if ((dirtyFlags & 0x6L) != 0) {
                if (action != null) {
                    // read action.name
                    actionName = action.getName();
                }
      	  }
    if ((dirtyFlags & 0x6L) != 0) {
      // 将我们的textView传递到bindAdapter中进行赋值，由于我们没有给TextView声明ID所有名称是由插件自己生成的名称。
     android.databinding.adapters.TextViewBindingAdapter.setText(this.mboundView2, actionName);
      }
 }
```

可以见看出代码十分的简洁，功能实现都在适配器中进行，这样可以保证情况再复杂代码的可阅读性和适配性也不会层级递增。`TextViewBindingAdapter.setText`方法也就是让`mboundView2`调用`setText`方法显示`actionName`的值，至于Adapter的整体的具体实现等到自定义Adapter时候我们再解析。

```java
  @BindingAdapter("android:text")
    public static void setText(TextView view, CharSequence text) {
        final CharSequence oldText = view.getText();
        if (text == oldText || (text == null && oldText.length() == 0)) {
        //....各种约束判断
        }
        view.setText(text);
    }
```



### 真正的单向绑定

如果你也在写Example就会发现一个问题，当`Action`绑定后，后续`Action`的改变并不会让UI更新即Observable(观察者模式)并没有实现。这显然不是我们想要达到的目的。

![](https://pic3.zhimg.com/079482e5b8748e2e566e9e4eba82e456_b.png)

在Data Binding想要一个View Model被控件订阅就需要它继承`BaseObservable`，这样当`Action`每次改变的时候我们就通知控件数据被改变了，然后控件自己调用相关属性的方法去更新数据。

```java

public class Action extends BaseObservable{
    private String name;
  //通过在get方法上Bindable注解让BR生成对应的flag，确定如何刷新name值
    @Bindable
    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
      //当我们改变值刷新UI，notifyChange()是通知所有订阅者，即使用了actino类中任意绑定了属性都会受到刷新的命令；notifyPropertyChanged()就很明显是通过flag进行单独刷新。
       //notifyChange();
        notifyPropertyChanged(BR.name);
    }
```

如果View Model已经有继承父类我们也可以通过对绑定的属性单独的声明Observable。DataBinding提供了除了基础类型外还有ObservableParcalable与ObservableField来解决大多数场景遇到的对象属性。

```java
public class Action {
  private ObservableField<String> name =new ObservableField<>();
  private ObservableInt age =new ObservableInt();
  
  //这样做的弊端是我们无法直接访问到属性值，需要通过Observable的get/set方法
  public void setName(String name){
    this.name.set(name);
  }
  public String getName(){
    return this.name.get();
  }
}
```

这样的话，当我们运行时候控件和数据的联系就建立起来了，更新`name`的同时TextView的`text`也会同时发生变化。

数据源一定要写个实体类吗，那么不是需要成吨的bean ? 我们可以通过ObservableArrayMap和ObservableArrayList来创建观察者和需要观察的数据。

```java
ObservableArrayMap<String,Object> action = new ObseravbleArryMap<>();
action.put("name","just");
action.put("password","gbk")
ObservableArryList list =new ObservableArryList<>();
list.add("first");
list.add("second")
```

在xml中我们通过key和index访问他们

```xml
<variable name="action" 
          type="android.databinding.ObserableMap"></variable>
<ariable name="user"
         type="android.databing.ObservableList"></ariable>

<TextView
          android:text="@{action["name"]"
          android:layout_width="wrap_content"
          android:layout_height="wrap_content"/>
<TextView
          android:text="@{user[1]"
          android:layout_width="wrap_content"
          android:layout_height="wrap_content"/>
```

### 事件绑定

我们除了可以绑定View各种属性外，我们也可以在xml中直接绑定事件，而不用通过View转发。

我们在Presenter中创建一个监听文本的方法，然后在xml中设置`onTextChanged`属性，方法名必须和对应的listener对应.

```xml
<EditText
  android:layout_width="wrap_content"
  android:layout_height="wrap_content"
  android:onTextChanged="@{presenter::onTextChanged}"
  />
   
```

将Presenter绑定在Activity上后，就可以接受到EditText的改变了

```java
public class Presenter{
  public void onTextChanged(charSequence s,in start ,int before,int count){
    mView.show(s.toString())
  }
}
```



### 表达式

在xml中的dataBinding表达式支持Java中的大部分语法，具体如下：

-   算数 +-*/%
-   字符串合并 +
-   逻辑运算 &&||
-   二元&|^
-   一元+-!~
-   位移>> >>> >>
-   比较 == > <> = <=
-   instanceof操作符
-   Grouping（）
-   文字
-   Cast 类型转换
-   方法调用
-   属性访问
-   数组访问
-   三目运算符？：

尚不支持`super`、`this`、`new`、以及显示的泛型调用。

除此java的这些语法支持外还有一些特殊的支持。

-   空合并运算符——使用`??`来连接两个式子，如果左边的式子为空就取右边的。

    ```xml
    android:text="@{user.name??user.realName}"
    ```

-   直接访问资源文件——可以通过`@resource/name的形式访问资源文件来直接使用

    ```xml
    android:text="@{@String/name(name)}"

    <string name="name">我的名字是%s</string>
    ```



### include

在使用include布局时候需要将该布局使用的数据通过`bind:xxx=@{}`传递进去，并在布局中进行二次绑定。

```xml
<include layout="@layout/empty" bind:info="@{info}"/>
```


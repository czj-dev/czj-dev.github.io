---
layout: post
title: "Gradle的架构和api"
subtitle: ' "Gradle 学习笔记"'
date: 2018-05-26 20:00:00
author: "rank"
header-img: "img/java.jpg"
catalog: true
tags:
  - Gradle
---

## 了解 Gradle 的架构

> 每个 Gradle 构架都包括了三个基本的构建块:项目(Projects)、任务(tasks)、和属性(properties),每个构建至少包括一个项目,项目包括一个或多个任务,项目中有很多属性来控制构建过程.
>
> Gradle 运用了领域驱动的设计理念（DDD）来给自己的领域构建软件建模，因此 Gradle 的项目和任务都在 Gradle 的 API 中有一个直接的 class 来表示，接下来我们来深入了解每一个组件和它对应的 API。

### Project

Project 表示你想要构建的一个目标，对应具体的内容可以是一个项目、组件、jar 等。当开始构建的时候，Gradle 基于我们对项目的配置实例化 `org.gradle.api.Project` 这个类并让这个项目通过 `project` 变量来隐式的获得。下图列出了 API 接口和最重要的方法。

![project](https://lippiouyang.gitbooks.io/gradle-in-action-cn/images/dag24.png)

一个项目可以创建新任务、添加依赖配置、应用插件和其他脚本。而 Project 实例允许你访问你项目中所有的 gradle 特性。当你使用项目的属性和方法时你并不需要显示的使用 project 变量——Gradle 假设你需要操作 project 实例，例如:

```groovy
//直接设置项目描述
setDescription("TestProject")
//通过 Groovy 语法来访问名字和描述
println "Description of project $name:"+project.description
```

每个项目和任务都提供了 setter 和 getter 方法来访问属性,你可以读取和修改这些属性值.我们还可以自定义属性。例如我们常见的在`build.gradle`中通过 `ext` 命名空间来添加一些熟悉和配置:

```groovy
ext{
  myOptions=123
}
ext.kotlin_version="1.2.12"
ext.version=[
    "supportVersion":26
    "compileVersion":26.0.1
]
```

也可以在 /.gradle 路径或者项目根目录下的 gradle.properties 文件来定义属性,然后通过 project 实例来访问。

```groovy
//gradle.properties
exampleProp = oneValue

//build.gradle
assert project.exampleProp == "oneValue"
```

### Task

Gradle 中的 Task 有两个基本概念——动作与依赖。一个动作就是任务需要执行的工作，可以简单到打印出 hello world，也可以复杂到编译整个项目输出 apk；而依赖则是一个任务的输入可能依赖于另一个任务的输出或者初始化时，这样就可以让一个 project 的构建工作分解成若干 task，分工明确。任务同样的有相对应的接口 `org.gradle.api.Task`:

![task](https://lippiouyang.gitbooks.io/gradle-in-action-cn/images/dag25.png)

#### 声明一个 Task

我们可以在`build.gradle` 中通过 `task` 声明一个 task :

```groovy
task simpleTask{
    println "task action"
}
```

然后通过`gradle -q -tasks` 来查看当前项目定义的 task ，我们会发现我们的 simpleTask 。

可以通过 `gradle simpleTask` 来执行这个任务 ：

```
gradle -q -tasks
assemble
build
...
simpleTask

gradle simpleTaskt

task action
```

定义 task 的时候其实可以指定很多参数，如下所示：

| 参数        | 含义                    | 默认值             |
| ----------- | ----------------------- | ------------------ |
| name        | task 的名字             | 不能为空，必须指定 |
| type        | task 的“父类”           | DefaultTask        |
| overwrite   | 是否替换已经存在的 task | false              |
| dependsOn   | 依赖的 task 集合        | []                 |
| group       | 表示任务的逻辑分组      | null               |
| description | task 的描述             | null               |

```groovy
task("detailTask",type:simpleTask,description:"this is a task")｛
	println "orz"
｝
```

#### 声明任务的动作

当我们将任务内容直接写在 task 内部的时候，task 的内容会在 Project 配置过程就直接被执行：

```
gradle clean

> Configure project :
task action

```

我们有时候并不想在装配的时候被执行，而是想要指定的时候再被执行。gradle 提供了两个方法来声明任务的动作`doFirst`和`doLast`， 他们会指定 task 执行的时候才会被执行, 执行顺序如它们的名字一样会是 task 开始时第一个和最后一个操作。

```groovy
task myTask {
   println ' -> '
    doLast{
        println 'World!'
    }
    doFirst{
        println 'Hello'
    }
}

// gradle myTask
-> Hello World!
```

我们还可以在已经创建的 task 中插入动作：

```groovy
task oneTask{
    def a ="xxx"
    println("${a} bbb")
}
oneTask >> {"action"}
```

我们还经常在文档中看到 `oneTask << {}` 这样写法 `<<` 这个操作符其实是 `.letShift` 的缩写，它等同与 `doLast`操作符。

#### 定义任务依赖

task 提供了`dependsOn`方法来声明一个任务依赖于一个或多个任务，被依赖的任务会先于 task 执行

```groovy
task first << {println "first"}
task second << {println "second"}

//在构造函数中声明依赖
task printVersion(dependsOn:[second,first])>>{
    println "version: $version"
}
task third << {println "third"}
//通过方法调用来声明依赖
third.dependsOn("printlnVersion")

//output
first
second
Version: 0.1-SNAPSHOT
third
```

查看执行顺序会发现一个系列，那就是任务的执行顺序和我们方法中声明的顺序没有关系，`first` 是在 `second` 之后声明的但是却先执行了。《Gradle In Action》是这样描素任务的依赖执行顺序的：

> Gradle 并不保证依赖的任务能够按顺序执行，dependsOn 方法只是定义这些任务应该在这个任务之前执行，但是这些依赖的任务具体怎么执行它并不关心，如果你习惯用命令式的构建工具来定义依赖（比如 ant）这可能会难以理解。在 Gradle 里面，执行顺序是由任务的输入输出特性决定的，这样做有很多优点，比如你想修改构建逻辑的时候你不需要去了解整个任务依赖链，另一方面，因为任务不是顺序执行的，就可以并发的执行来提高性能。

重点就是 **gradle 本身并不保证任务的执行顺序，当一个任务的输出和是另一个任务的输入时，这是 gradle 才会确保它们之间的执行顺序。**具体我们在 gradle 的生命周期周期中再讨论。

####终结者任务

之前我们可以通过 `dependsOn` 来指定一些执行任务需要依赖的任务，当执行的任务执行完毕的时候，我们也可以通过 `finalizer` 来指定一个任务来进行收尾工作，例如清理，回收资源等等 :

```groovy
task first << { println "first" }
task second << { println "second" }
//声明first结束后执行second任务
first.finalizedBy second

//output:
first
second
```

到这里 Task 的常见的动作和依赖相关的 api 也都介绍完了。本次主要是介绍了 gradle 的两个重要概念 `project` 和 `task` 以及它们的一些常用 api。下一次准备着手 gradle 的生命周期。

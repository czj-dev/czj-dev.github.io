---
layout: post
title: Gradle的基础概念
subtitle: '"Gradle 学习笔记"'
date: 2018-04-28 10:00:10
author: "rank"
header_image: "img/java.jpg"
catalog: true
tags:
  - Gradle
---

## Gradle 实战(一)

Gradle 是继 Ant 、Maven 之后又一个优秀的 Java 项目构建工具.它同样实现了依赖管理、仓库、约定优于配置等优秀的概念.对 maven 和 Ant 项目与资源也有很好的兼容和支持.相比 Maven 和 Ant 来说 Gradle 的构件脚本是声明式的、可读的,可以清晰的表达意图.它使用一个 DSL 语言 Groovy (类似 java ) 来代替 XML 语言大大减少了构件代码的大小。在 Android Studio 中更是成为了构建 Android 项目的标准工具. 我们就来学习和了解它是如何工作和使用的。

###Groovy

Groovy 是一门 JVM 语言，它最终是要编译成 class 文件在 JVM 上执行的，所以 java 语言支持的 groovy 都支持，也可以混写。

如果有学习过 Kotlin 那么看 Groovy 相关的语法就十分的亲切，Groovy 的语法和 kotlin 同样灵活且有很多相似性，而且也提供了大量的语法糖，实际上 gradle 目前已经支持使用 ktolin 来进行配置开发，这一改变可以让我们更多精力放置在 gradle 的特性上，但是目前 Android Studio 的支持还不是很好，所以还是了解一下 groovy 较好。Groovy 这里也不过多介绍，只是说明一些常用的语法，如果想要详细了解去[查询文档](http://link.zhihu.com/?target=http%3A//www.groovy-lang.org/api.html)无疑是最棒的解决方案。

#### 变量和函数

groovy 通过 `def` 来声明变量和方法，虽然是 JVM 类型要求很严格语言但是 groovy 拥有强大的类型推导，所以我们编写的时候可以省略很多东西：

```groovy
def a =1 // def int a =1
def b ='task'

def action(){
    1;		//最终 action 返回 1 可以省略返回类型和 return 语句
}

//忽略参数的类型声明
def action(str){
    println str //忽略()号 以空格符来间隔声明调用
}

```

#### 容器 List 和 map

groovy 加强了 list 和 map 等容器，从而让他们使用起来十分的方便：

```groovy
//list 可以存储不同的元素类型，并通过下标直接访问、修改
def list =[100,"a",false]
list [0]=20
println list[0]
println list[1]
pritln list.size

//map 同样
def map =["name":"rank","age":23,"sex":true]
def value =map["name"]
map.name="just"
map[name]="rank"
```

还有大量的语法糖，比如判断对象非空的时候不用在意它是数组还是对象亦或者字符串都可以直接使用`if(object){}`，和 kotlin 里的`when` 一样有很强表达范围的 switch:

```groovy
def x = 1.23
def result = ""
switch (x) {
   case "foo": result = "found foo"
   // lets fall through
   case "bar": result += "bar"
   case [4, 5, 6, 'inList']: result = "list"
   break
   case 12..30: result = "range"
   break
   case Number: result = "number"
   break
   case { it > 3 }: result = "number > 3"
   break
   default: result = "default"
}
assert result == "number"
```

等等，这里就不过多具体介绍了。以后的文章里再涉及到在说不迟。

### 搭建环境

通过在[Gradle 仓库](http://services.gradle.org/distributions/)下载对应的安装包然后解压,配置系统环境变量安装就完成了,可以在终端使用 `gradle -v` 命令验证安装。

```
gradle -v

------------------------------------------------------------
Gradle 4.5
------------------------------------------------------------

Build time:   2018-01-24 17:04:52 UTC
Revision:     77d0ec90636f43669dc794ca17ef80dd65457bec

Groovy:       2.4.12
Ant:          Apache Ant(TM) version 1.9.9 compiled on February 2 2017
JVM:          1.8.0_151 (Oracle Corporation 25.151-b12)
OS:           Mac OS X 10.13.3 x86_64
```

### 简述

#### Task

我们新建一个 `Hello` 项目.在项目中创建一个 `build.gradle` 项目,它类似于 maven 的 `pom.xml` 文件,该文件可以定义一些任务(task)来完成构建工作.每个任务都是可配置的,任务之间可以互相依赖.用户也能直接配置缺省任务.我们构建两个简单的任务,任务 B 依赖于任务 A:

```groovy
task taskA << {
    println("i'm task A")
}
task(taskB){
    println("i'm $taskB.name")
}

```

在项目目录下使用 `gradle taskA taskB` 命令来构建缺省任务,可以看到我们预期的输出:

```
i'm task A
i'm taskB
```

#### 仓库

Gradle 不仅继承了 maven 的很多的优秀理念,仓库也是可以直接拿来使用的.我们在 `build.gradle`的`repositories` 节点中设置我们的仓库地址:

```groovy
repositories{
  maven()
  jcenter()
  mavenRepo urls: "http://repository.sonatype.org/content/groups/forge/"
}
```

在上传的时候我们也可以使用 Gradle 的 maven Plugin 插件将 build.gradle 生成 Maven POM 文件.这样即使是一个基于 maven 的大环境使用 Gradle 也几乎不是一个问题.

####约定优于配置

Gradle 给了用户足够的自由去定义自己的任务.我们可以自定义自己的项目布局:

```groovy
sourceSets{
  main{
    java{
      srcDir 'src/java'
    }
    resources{
      srdDir 'src/resources'
    }
  }
}
```

也可以构建自己的生命周期,例如上例我们想每次执行`taskB`的时候先执行 `taskA` 但只想使用最简单的 `$gradle` 命令,那只需要加上默认的任务和任务依赖即可:

```groovy
defaultTasks('taskB')
task taskA << {
    println("i'm task A")
}
....
taskB.dependsOn taskA
```

### 基础命令

####命令行选项

通过 Gradle 来执行一些特定的任务,我们可以在命令中增加一些命令行选项来辅助我们的构建命令,而且一些命令在我们可以使用缩写来快捷的执行，例如 `-build` 可以输入`-b`

- `-i`:Gradle 默认不会输出很多信息，你可以使用-i 选项改变日志级别为 INFO
- `-s`:如果运行时错误发生打印堆栈信息
- `-q`:只打印错误信息
- `-?;-h;--help`:打印所有的命令行选项
- `-b；--buil fileName`:Gradle 默认执行 build.gradle 脚本，如果想执行其他脚本可以使用这个命令，比如`gradle -b test.gradle`
- `--offline`:在离线模式运行 build,Gradle 只检查本地缓存中的依赖
- `-D; --system-prop`:Gradle 作为 JVM 进程运行，你可以提供一个系统属性比如：-Dmyprop=myValue
- `-P;--project -prop`:项目属性可以作为你构建脚本的一个变量，你可以传递一个属性值给 build 脚本，比如：`-Pmyprop=myValue`

* `tasks`:显示项目中所有可运行的任务
* `properties`:打印你项目中所有的属性值

#### 检查构建脚本

我们可以通过 Gradle 提供的辅助的任务 tasks 来检查你的构建脚本,然后显示所有的任务,包含一个描述性的信息 :

```
$gradle -q tasks
```

输出:

```
------------------------------------------------------------
All tasks runnable from root project
------------------------------------------------------------

Default tasks: taskB

Build Setup tasks
...
```

#### 任务执行

要执行一个任务,只需要输入 gradle + 任务名称 ,Gradle 会保证这个任务和它依赖的任务都会执行,要执行多个任务只需要在后面添加多个任务名.

```
$gradle taskA
```

#### 任务名称缩写

Gradle 提高效率的一个办法就是能够在命令行输入任务名的驼峰简写，当你的任务名称非常长的时候这很有用，当然你要确保你的简写只匹配到一个任务，比如下面的情况：

```
task taskAir <<{
  ...
}
task taskAction <<{
  ...
}
```

这时候你使用 `gradle tA` 就会报错.

#### 运行时排除一个任务

运行时你要排除某个任务和它的依赖的任务可以使用 `-x` 命令

```
gradle taskAction -x taskAir
```

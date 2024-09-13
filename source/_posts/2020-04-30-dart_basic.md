---
layout: post
title: "Dart 实践（一）"
subtitle: "Dart 语法基础"
date: 2020-04-30 11:13:00
author: "rank"
header_image: "img/post-bg-dart.jpg"
catalog: true
tags:
  - Flutter
  - Dart
  - 基础
---

##  数据类型

**Dart 中一切都是对象，包含数字、布尔值、函数等，它们和 java 一样继承与 object，所以它们的默认值都是 Null**  这点尤为需要注意，在定义数据类型的时候如 布尔 、数字类型都需要我们手动去设定业务中所需要的默认值。

### 常用数据类型

#### **布尔类型（bool）**

布尔类型与 C 语言一样，使用 `bool` 声明一个布尔类型的对象，拥有 `true` 和 `false` 两个值

``` dart
bool isOpened=true;
```



#### 数字类型（int、double）

在 Dart 中的数字只有类型 `int`、`double` ，它们都继承于 `num` 类，`num` 类是一个抽象类，声明了整数和浮点数的抽象实现，而 `int`、`double` 就是它的具体实现类。

```dart
double size=2.3333;
int width=10;
var height=23.3;
```



#### **字符串类型（string）**

Dart 中的字符串功能与 kotlin 类似，都是十分强大。支持单引号、双引号、三引号保留格式、以及字符串模板。

```dart
String title="App"
String desc="""
Flutter
		Application;
""";
String value="application title = $title";

```




#### **Runes 和 Symbols 类型**

Runes 类型是 UTF-32 字节单元定义的 Unicode 字符串，Unicode 可以使用数字表示字母、数字和符号，然而在 Dart 中，String 是一系列的 UTF-16 的字节单元，所以想要表示 32 位的 Unicode 的值，就需要用到 Runes 类型。我们一般使用 `\uxxxx` 这种形式来表示一个 Unicode 码，`xxxx` 表示 4 个十六进制值。当十六进制数据多余或者少于 4 位时，将十六进制数放入到花括号中，例如，微笑表情（😆）是 `\u{1f600}`。而 Symbols 类型则用得很少，一般用于 Dart 中的反射，但是注意在 Flutter 中禁止使用反射。

``` dart
 Runes input = new Runes(
      '\u2665  \u{1f605}  \u{1f60e}  \u{1f47b}  \u{1f596}  \u{1f44d}');
```



#### **dynamic 类型**

我们知道 Dart 的顶级对象是 Object ，但是像我们在使用 `var` 表示一个对象的时候，它的类型并不像 `kotlin` 那样直接类型推导出来，而是在编译才会进行检查，变量未赋值的时候是无法确定类型的，可能连 Object 也不是，这时候就用另一种类型来定义这个对象，这种类型就叫做 `dynamic` 类型，它也可以像 Object 一样改变类型。但是区别在于 Object 会在编译期间就进行类型检查，而 `dynamic`则不会。

 ``` dart
Map<String,dynamic> config={"a":1,b:"2"};

 ```



## 常用集合

 dart 的集合声明和使用的方式与 javaScript 更类似。对集合的使用和限制都十分的宽松。此外还提供了很多操作符使得处理结构化的数据更加简单明了。

#### List

```dart
var list = new list();
list.add(1);
var list2=[];
list2.addall(list);
// 常用函数以及操作符
list.clear();
list.insert(0,2);
list.forEach((index)=>print(index));

List<int> numbers = [0, 3, 1, 2, 7, 12, 2, 4];
numbers.sort((num1, num2) => num1 - num2); //升序排序
//where、firstWhere、signleWhere
numbers.firstWhere((num) => num == 5, orElse: () => -1)); 
// take 设定区间，skip 跳过前 n 个元素
numbers.take(5).skip(2);
```

#### Map

Map 与现代语言的 map 类型，key-value 形式存储数据。

``` dart
var defaultMap={};
Map<String,int> levelMap=  new Map();
// 如果你使用 Map 构造函数创建一个 map ,默认情况下会创建一个 LinkedHashMap 实例
levelMap["a"]=0;
levelMap["b"]=2;

levelMap.forEach((key,value)=>{
    print("key:$key value:$value");
})
```

除此之外，Dart 的 `collection` 包中还有很多我们耳熟能详的集合实现，例如 `Queue` 、`LinkedLIst`、`LinkedHashMap`、`SplayTreeMap ` 等等，这里就不一一介绍了。



## 属性和类

#### 属性访问器（setter 和 getter）

Dart 与 kotlin 的属性一样，每个元素始终有与之对应的 `setter`、`getter` 属性访问器函数（若用`final` 修饰属性时，对象就只提供 getter 函数）。我们再对实例属性赋值和获取值时，实际上内部都是对 `stter`、`getter` 函数的调用

``` dart
class Rectangle {
  num left, top, width, height;

  Rectangle(this.left, this.top, this.width, this.height);
  set right(num value) => left = value - width;
  set bottom(num value) => top = value - height;
}

main() {
  var rect = Rectangle(3, 4, 20, 15);
  rect.right = 15;
  rect.bottom = 12;
}
```

#### 私有变量

在 Dart 中如果想将成员变量私有化禁止外部访问的话，就直接在属性名前面加下划线`_` 例如 `_amount`、`_age` 。这样名称对应的属性就会拒绝外部类通过访问器函数访问它的状态。

#### top level 

Dart 中也可以在类之外声明变量和函数，这种声明的变量和函数并不在某个具体的类中，而是处于整个代码文件中，我们一般叫它顶层变量和顶层函数。顶层变量相较类变量特殊的是，他们不依赖某个类，可以进行访问，且它们是延迟初始化的，在 `getter` 函数第一次被调用时类变量和顶层变量才执行初始化，也即是第一次应用类变量或顶层变量的时候。

``` dart
class Animal {}
class Dog extends Animal {}
class Cat extends Animal {
    Cat() {
        print("I'm a Cat!");
    }
}


Animal animal = Cat();
main() {
    animal = Dog();
}
```

按照上边所描述的顶层变量具有延迟触发的性质，所以 Cat 对象并没有被创建，因为整个代码并没有去访问 animal，所以无法触发 `getter` 函数，也就导致 Cat 并没有创建。

#### 构造函数

Dart 中的函数不支持重载，构造函数也不例外，所以主构造函数有且只能有一个，如果没有指定主构造函数，那么会默认的自动分配一个无参的主构造函数。

``` dart
class Point {
  final double x, y;
  Point(this.x, this.y);
}
```

不过 Dart 中虽然抛弃了函数重载，但是在构造函数这里还引入了命名构造函数的概念。它可以指定任意参数来构建对象，但函数的命名需要符合特定的结构。而且命名构造函数还可以通过 `this` 重定向到主构造函数

```dart
class Point {
  final double x, y;
   int color;
  Point(this.x, this.y,this.color);
  Point.size(this.x,this.y);
  Point.defaultPoint():this(0,0,0xff333333);
}
```

#### factory 工厂函数

一般来说，构造函数每次总会创建一个新的实例对象。但是有时候并不需要每次都创建新的实例，我们可以通过自定义缓存来实现，但是实现较为复杂。 dart 内置了 `factory` 通过它来修饰构造函数，并且可以从缓存中返回已经创建实例或者返回一个新的实例。在 Dart 中任意构造函数都可以替换成工厂方法，修饰后的构造函数需要返回构造函数所对应的实例对象。

```dart
class Logger {
  
  final String name;
  bool mute = false;

  
  
  static final Map<String, Logger> _cache =
      <String, Logger>{};

  factory Logger(String name) {
    if (_cache.containsKey(name)) {
      return _cache[name]
    } else {
      final logger = Logger._internal(name);
      _cache[name] = logger;
      return logger;
    }
  }

  Logger._internal(this.name);

  void log(String msg) {
    if (!mute) print(msg);
  }
}
```

#### 抽象类与接口

抽象方法就是“声明一个方法而不提供它的具体是显示”，通常我们通过抽象类与接口来定义这一行为，在 Dart 中抽象类与我们常接触 java、kotlin 一致，通过 `abstract` 修饰类来声明一个类单位抽象类。

```dart
abstract class Person {
  String name();
  get age;
}

class Student extends Person {
  @override
  String name() {
    
    return null;
  }

  @override
  
  get age => null;
}
```

接口则稍显不一样， Dart 中没有 `interface ` 之类的关键字来定义接口，因为 Dart 中的每个类都默认隐含的定义了一个接口。如果只想将类当作 `interface` 那么就在声明类的时候使用`implements ` 关键字

```dart
abstract class Person{
    String speak();
}

class XiaoMing implements Person{
    String speak(){
        print("hehe");
    }
}
```

#### Mixins 

Dart 的继承与现代语言类似——通过 `extends` 关键字来声明，子类构造函数会默认调用父类的无参构造函数，如果父类只有有参则需要显示的声明调用父类的构函数。但除此之外 Dart 还引入了 Mixins 的概念，它赋予了 Dart 额外的继承机制，让它能实现类似多继承的效果。要注意的是只是类似，他始终还是只能有一个超类。

**Mixins 可以在不同的类层次结构中多个类之间共享相同的行为、或无法合适抽象出部分子类的共同行为到基类中。**

Mixin 的列子：

```dart
class A {
   void printMsg() => print('A'); 
}
mixin B {
    void printMsg() => print('B'); 
}
mixin C {
    void printMsg() => print('C'); 
}

class BC extends A with B, C {}
class CB extends A with C, B {}

main() {
    var bc = BC();
    bc.printMsg();

    var cb = CB();
    cb.printMsg();
}
```

输出结果：

```dart
C
B

Process finished with exit code 0
```

从上边的结果我们可以知道 Mixins 和我们第一意识到的多继承不一样，它实际上还是单继承；每次 mixin 都是会创建一个新的中间类。并且这个中间类总是在基类的上层。通过下边的结构图我们就可以清楚看到。

![mixins](https://i.loli.net/2020/04/29/EYvUjXRHiNIrL7m.jpg)

在上边的例子中,Mixins 生成了多个中间类，并且通过单继承(extends) 串联起来。所以我们在调用 `printMsg` 方法的时候是逐级调用了最上层的 `printMsg` 实现，所以每个类只有一个实现。

这样我们就理解 Flutter 大量使用的 Mixins 是什么原理和性质。
---
layout: post
title: "装饰者模式(Decorator)"
subtitle: "\"Head First学习笔记（三）\""
data: 2017-02-08 11:31:10
author: "chenzhaojun"
header-img: "java.jpg"
tags:
    - 基础
---

> your internal mediocrity is the moment when you lost the faith of being excellent



## 前言

又到了学习Head First的时间了，今天大名鼎鼎的星巴兹咖啡找到我们，让我们帮忙更新他们的订单系统,他们现在的订单系统是这样的：![system](http://my.csdn.net/uploads/201205/06/1336303779_2807.jpg)



看起来还好不是吗，简单清晰。所有的饮料都继承`Beverage`，具体的饮料用`cost()`来计算价格`description`来描述。但是他们遇到了一个问题，购买咖啡时候，也可以要求在其中加入各种调料，例如 :  `milk(牛奶)`、`Soy(豆浆)`、`Mocha(摩卡)`等等。最后会更具加入的不同调料收取费用。所以订单系统必须考虑的到这些调料。所以他们尝试这样搭建一个系统 :  



![system1](http://my.csdn.net/uploads/201205/06/1336303992_9751.jpg)



是不是看起来很酷，但收银员可不这么想，这对他来说如一个噩梦。而且当修改或增加饮料时候，那么维护起来也非常的恐怖。于是我们的小明又要接手新的活了。



## 正文

作为一个出色的OO程序员，小明也很快完成了他的第一版设计 :  



![system2](http://my.csdn.net/uploads/201205/07/1336354047_2530.jpg)

具体的实现 : 

```java
public class Beverage {
    private static final double milkSort = 0.1;
    private static final double soySort = 0.3;
    private static final double mochaSort = 0.4;
    private static final double whipSort = 0.5;
    private String description;
    private boolean milk;
    private boolean soy;
    private boolean mocha;
    private boolean whip;

    public String getDescription() { return description;}

    public void setDescription(String description) {
        this.description = description;
    }

    public boolean isMilk() { return milk;}

    public void setMilk(boolean milk) {this.milk = milk;}

    public boolean isSoy() {return soy; }

    public void setSoy(boolean soy) {this.soy = soy;}

    public boolean isMocha() {return mocha;}

    public void setMocha(boolean mocha) {this.mocha = mocha;}

    public boolean isWhip() {return whip; }

    public void setWhip(boolean whip) {this.whip = whip;}

    public double cost() {
        double cost = 0;
        if (isMilk()) {
            cost += milkSort;
        }
        if (isSoy()) {
            cost += soySort;
        }
        if (isMocha()) {
            cost += mochaSort;
        }
        if (isWhip()) {
            cost += whipSort;
        }
        return cost;
    }
}
```

当我们要创建饮料时 :

```java
public class DarkRoast extends Beverage{
  public DarkRoast(){
    description = "Most Excellent Dark Roast";
  }
  public double cost{
    return 1.99+super.cost();
  }
}
```

目前看来没有什么问题，但哪些因素会影响这个设计?

- 调整价钱的改变会使得我们更改现有代码。
- 一旦出现新的饮料，我们就需要加上新的方法，并且要修改超类中`cost()`方法。
- 以后可能会开发出新饮料。对这些饮料而言，某些调料可能并不合适，但是在这个设计方式中，子类仍将继承那些不合适的方法。
- 万一顾客想要双倍摩卡的咖啡怎么办？
- 当我们要设计新的功能，例如不同价格的同一调料，那将是巨大的改动。
- 轮到你了



>类应该对扩展开放，对修改关闭

小明去求教了禅雅塔大师，大师告诉他可以用装饰者模式来解决这个问题并给了他一张图 :

![decorator](http://my.csdn.net/uploads/201205/08/1336484138_5451.jpg)



装饰者模式就是 :  **装饰者模式动态的将责任附加到对象上，若要扩展功能，装饰者提供了比继承更具有弹性的替代方案。**

于是小明奖星巴兹的系统也设计成了装饰者模式 :

![decorator_xbz](http://my.csdn.net/uploads/201205/08/1336484312_7020.jpg)



程序实现 :

```java
//基类
public abstract class Beverage {
    public String description;

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public abstract double cost();
}
```

装饰者类,将`getDescription()`抽象化，子类必须实现它 :

```java
public abstract class CondimentDecorator extends Beverage{
    public abstract String getDescription();
}
```

接下来实现具体的饮料和调料类，只各列举个一个列子 :

```java
public class HouseBlend extends Beverage {
    public HouseBlend() {
        setDescription("HouseBlend");
    }

    @Override
    public double cost() {
        return 1.88;
    }
}

public class Mocha extends CondimentDecorator{
    Beverage beverage;
    public Mocha(Beverage beverage)
    {
        this.beverage=beverage;
    }
    public String getDescription()
    {
        return beverage.getDescription()+", Mocha";
    }
    public double cost()
    {
        return 0.20+beverage.cost();
    }
}
```

测试 :

```java
    public static void main(String[] arg) {
        Beverage espresso=new HouseBlend();
        espresso = new Mocha(espresso);
        espresso = new Soy(espresso);
        espresso = new Whip(espresso);
        System.err.println(espresso.getDescription()+": "+espresso.cost());

        Beverage houseBlend = new Espresso();
        houseBlend = new Mocha(new Mocha(new Whip(houseBlend)));
        System.err.println(houseBlend.getDescription()+": "+houseBlend.cost());
    }
```

输出为 :

```
HouseBlend, Mocha,Soy,Whip: 2.88
Espresso,Whip, Mocha, Mocha: 1.69
```

同样完美的实现了星巴兹的功能，虽然看起里稍微复杂一些，但是当我们可以很轻松组合这些调料，增加和修改也不用促及底层的任何代码。这就是装饰者模式。



## 要点

- 继承属于扩展形式之一，但不见得是达到弹性设计的最佳方式。
- 在我们的设计中，应该允许在运行时动态地加上新的行为。
- 除了继承，装饰者模式也可以让我们扩展行为。
- 装饰者类反应出被装饰的组件类型（事实上，他们具有相同的类型，都经过接口或继承实现）。
- 装饰者可以在被装饰者的行为前面/或后面加上自己的行为，甚至将装饰者的整个行为取代掉，从而达到特定的目的。
- 你可以用无数个装饰者包装一个组件。
- 装饰者一般对组件的客户是透明的，除非客户程序依赖与组件的具体类型。
- 装饰者会导致设计中出现许多小对象，如果过度使用，会让程序变得复杂。